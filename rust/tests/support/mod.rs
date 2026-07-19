#![allow(dead_code)]

use nix_vscode_extensions_updater::config::{AppConfig, SiteConfig};
use nix_vscode_extensions_updater::logging::{first_party_filter, level_filter, HumanFormatter};
use nix_vscode_extensions_updater::marketplace::{
    MarketplaceClient, MarketplaceFetchResult, ObservedPlatformMap, ReleaseConfigFetchResult,
    ReleaseLookupFailure,
};
use nix_vscode_extensions_updater::model::{
    CacheRecord, EngineVersion, ExtensionConfig, IsRelease, Name, ObservedVersionKey, Platform,
    Publisher, Target, Version,
};
use nix_vscode_extensions_updater::pipeline::{Pipeline, ShutdownSignal};
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use std::collections::VecDeque;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use tempfile::TempDir;
use tracing_subscriber::filter::FilterExt;
use tracing_subscriber::fmt;
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::prelude::*;

static NO_SHUTDOWN: ShutdownSignal = ShutdownSignal::new();

#[derive(Clone, Default)]
pub struct CapturedLogs {
    bytes: Arc<Mutex<Vec<u8>>>,
}

impl CapturedLogs {
    pub fn lines(&self) -> Vec<String> {
        String::from_utf8(self.bytes.lock().unwrap().clone())
            .unwrap()
            .lines()
            .map(ToString::to_string)
            .collect()
    }
}

pub struct CaptureGuard {
    bytes: Arc<Mutex<Vec<u8>>>,
}

impl Write for CaptureGuard {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.bytes.lock().unwrap().extend_from_slice(buf);
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

impl<'a> tracing_subscriber::fmt::writer::MakeWriter<'a> for CapturedLogs {
    type Writer = CaptureGuard;

    fn make_writer(&'a self) -> Self::Writer {
        CaptureGuard {
            bytes: self.bytes.clone(),
        }
    }
}

pub fn capture_logs<F, T>(config: &AppConfig, run: F) -> (CapturedLogs, T)
where
    F: FnOnce() -> T,
{
    let logs = CapturedLogs::default();
    let subscriber = tracing_subscriber::registry().with(
        fmt::layer()
            .event_format(HumanFormatter::default())
            .with_writer(logs.clone())
            .with_filter(level_filter(config.log_severity).and(first_party_filter())),
    );
    let value = tracing::subscriber::with_default(subscriber, run);
    (logs, value)
}

pub fn capture_pipeline_logs<M, P>(
    config: &AppConfig,
    marketplace: &M,
    prefetcher: &P,
) -> (CapturedLogs, anyhow::Result<()>)
where
    M: MarketplaceClient + Sync,
    P: Prefetcher + Sync,
{
    capture_logs(config, || {
        let pipeline = Pipeline {
            config,
            marketplace,
            prefetcher,
            shutdown: &NO_SHUTDOWN,
        };
        pipeline.run()
    })
}

pub fn assert_has_line(lines: &[String], needle: &str) {
    assert!(
        lines.iter().any(|line| line.contains(needle)),
        "expected log line containing `{needle}`, got:\n{}",
        lines.join("\n")
    );
}

pub fn assert_no_line(lines: &[String], needle: &str) {
    assert!(
        !lines.iter().any(|line| line.contains(needle)),
        "unexpected log line containing `{needle}`, got:\n{}",
        lines.join("\n")
    );
}

pub fn assert_line_prefix(lines: &[String], prefix: &str, needle: &str) {
    assert!(
        lines.iter()
            .any(|line| line.starts_with(prefix) && line.contains(needle)),
        "expected log line with prefix `{prefix}` containing `{needle}`, got:\n{}",
        lines.join("\n")
    );
}

pub fn count_lines(lines: &[String], needle: &str) -> usize {
    lines.iter().filter(|line| line.contains(needle)).count()
}

pub fn find_line<'a>(lines: &'a [String], needle: &str) -> &'a str {
    lines.iter()
        .find(|line| line.contains(needle))
        .map(String::as_str)
        .unwrap_or_else(|| panic!("missing log line containing `{needle}`"))
}

pub fn rendered_logs(logs: &CapturedLogs) -> String {
    String::from_utf8(logs.bytes.lock().unwrap().clone()).unwrap()
}

pub fn debug_lines(lines: &[String]) -> Vec<&str> {
    lines.iter()
        .filter(|line| line.starts_with("DEBUG"))
        .map(String::as_str)
        .collect()
}

pub fn info_lines(lines: &[String]) -> Vec<&str> {
    lines.iter()
        .filter(|line| line.starts_with("INFO "))
        .map(String::as_str)
        .collect()
}

pub fn warn_lines(lines: &[String]) -> Vec<&str> {
    lines.iter()
        .filter(|line| line.starts_with("WARN "))
        .map(String::as_str)
        .collect()
}

pub fn error_lines(lines: &[String]) -> Vec<&str> {
    lines.iter()
        .filter(|line| line.starts_with("ERROR"))
        .map(String::as_str)
        .collect()
}

pub struct FakeMarketplace {
    pub latest: MarketplaceFetchResult,
    pub release_result: ReleaseConfigFetchResult,
    pub latest_error: Option<String>,
    pub release_error: Option<String>,
    pub requested_release_ids: Mutex<Vec<(Publisher, Name)>>,
    latest_failures_remaining: Mutex<u32>,
    release_failures_remaining: Mutex<u32>,
}

impl FakeMarketplace {
    pub fn new(latest: MarketplaceFetchResult) -> Self {
        Self {
            latest,
            release_result: ReleaseConfigFetchResult::default(),
            latest_error: None,
            release_error: None,
            requested_release_ids: Mutex::new(Vec::new()),
            latest_failures_remaining: Mutex::new(0),
            release_failures_remaining: Mutex::new(0),
        }
    }

    pub fn with_latest_error(mut self, error: impl Into<String>) -> Self {
        self.latest_error = Some(error.into());
        self
    }

    pub fn with_release_error(mut self, error: impl Into<String>) -> Self {
        self.release_error = Some(error.into());
        self
    }

    pub fn with_release_configs(mut self, configs: Vec<ExtensionConfig>) -> Self {
        self.release_result.observed_platforms = observed_platforms_for(&configs);
        self.release_result.configs = configs;
        self
    }

    pub fn with_release_observed_platforms(mut self, observed_platforms: ObservedPlatformMap) -> Self {
        self.release_result.observed_platforms = observed_platforms;
        self
    }

    pub fn with_latest_observed_platforms(mut self, observed_platforms: ObservedPlatformMap) -> Self {
        self.latest.observed_platforms = observed_platforms;
        self
    }

    pub fn with_release_failures(mut self, failures: Vec<ReleaseLookupFailure>) -> Self {
        self.release_result.failures = failures;
        self
    }

    pub fn fail_latest_attempts(mut self, attempts: u32) -> Self {
        self.latest_failures_remaining = Mutex::new(attempts);
        self
    }

    pub fn fail_release_attempts(mut self, attempts: u32) -> Self {
        self.release_failures_remaining = Mutex::new(attempts);
        self
    }
}

impl MarketplaceClient for FakeMarketplace {
    fn fetch_latest(
        &self,
        _target: Target,
        _site: &SiteConfig,
    ) -> anyhow::Result<MarketplaceFetchResult> {
        let mut remaining = self.latest_failures_remaining.lock().unwrap();
        if *remaining > 0 {
            *remaining -= 1;
            return Err(anyhow::anyhow!(
                self.latest_error
                    .clone()
                    .unwrap_or_else(|| "transient latest failure".to_string())
            ));
        }
        if let Some(err) = &self.latest_error {
            return Err(anyhow::anyhow!(err.clone()));
        }
        Ok(MarketplaceFetchResult {
            configs: self.latest.configs.clone(),
            observed_platforms: self.latest.observed_platforms.clone(),
            pages_failed: self.latest.pages_failed.clone(),
            pages_fetched: self.latest.pages_fetched.clone(),
        })
    }

    fn fetch_release_configs(
        &self,
        _target: Target,
        ids: &[(Publisher, Name)],
    ) -> anyhow::Result<ReleaseConfigFetchResult> {
        self.requested_release_ids
            .lock()
            .unwrap()
            .extend_from_slice(ids);
        let mut remaining = self.release_failures_remaining.lock().unwrap();
        if *remaining > 0 {
            *remaining -= 1;
            return Err(anyhow::anyhow!(
                self.release_error
                    .clone()
                    .unwrap_or_else(|| "transient release failure".to_string())
            ));
        }
        if let Some(err) = &self.release_error {
            return Err(anyhow::anyhow!(err.clone()));
        }
        Ok(self.release_result.clone())
    }
}

pub struct FakePrefetcher {
    responses: Mutex<VecDeque<anyhow::Result<CacheRecord>>>,
}

impl FakePrefetcher {
    pub fn new(responses: Vec<anyhow::Result<CacheRecord>>) -> Self {
        Self {
            responses: Mutex::new(VecDeque::from(responses)),
        }
    }
}

impl Prefetcher for FakePrefetcher {
    fn prefetch(
        &self,
        _target: Target,
        config: &ExtensionConfig,
        _timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        match self.responses.lock().unwrap().pop_front() {
            Some(result) => result,
            None => Ok(CacheRecord {
                publisher: config.publisher.clone(),
                name: config.name.clone(),
                is_release: config.is_release,
                platform: config.platform,
                version: config.version.clone(),
                engine_version: config.engine_version.clone(),
                hash: format!("hash-{}", config.version.raw()),
            }),
        }
    }
}

pub struct TestEnv {
    _tmp: TempDir,
    pub data_dir: PathBuf,
    pub config: AppConfig,
}

impl TestEnv {
    pub fn new() -> Self {
        let tmp = TempDir::new().unwrap();
        let data_dir = tmp.path().to_path_buf();
        let config = test_config(&data_dir);
        Self {
            _tmp: tmp,
            data_dir,
            config,
        }
    }

    pub fn cache_file(&self, site: &str) -> PathBuf {
        self.data_dir.join("cache").join(format!("{site}-latest.jsonl"))
    }

    pub fn debug_file(&self, site: &str, name: &str) -> PathBuf {
        self.data_dir.join("debug").join(format!("{site}-{name}.json"))
    }
}

pub fn version(text: &str) -> Version {
    Version::parse(text).unwrap()
}

pub fn engine(text: &str) -> EngineVersion {
    EngineVersion::parse(text).unwrap()
}

pub fn config(
    publisher: &str,
    name: &str,
    release: bool,
    platform: Platform,
    version_text: &str,
) -> ExtensionConfig {
    ExtensionConfig {
        publisher: Publisher(publisher.to_string()),
        name: Name(name.to_string()),
        is_release: IsRelease(release),
        platform,
        version: version(version_text),
        engine_version: engine("^1.0.0"),
    }
}

pub fn record(
    publisher: &str,
    name: &str,
    release: bool,
    platform: Platform,
    version_text: &str,
    hash: &str,
) -> CacheRecord {
    CacheRecord {
        publisher: Publisher(publisher.to_string()),
        name: Name(name.to_string()),
        is_release: IsRelease(release),
        platform,
        version: version(version_text),
        engine_version: engine("^1.0.0"),
        hash: hash.to_string(),
    }
}

pub fn observed_platforms_for(configs: &[ExtensionConfig]) -> ObservedPlatformMap {
    let mut observed = ObservedPlatformMap::new();
    for config in configs {
        observed
            .entry(ObservedVersionKey {
                publisher: config.publisher.clone(),
                name: config.name.clone(),
                is_release: config.is_release,
                version: config.version.clone(),
            })
            .or_default()
            .insert(config.platform);
    }
    observed
}

pub fn assert_latest_fixture(
    body: &str,
    expected: &[(&str, &str, &str, Platform, bool, &str)],
) {
    assert_configs_match(
        nix_vscode_extensions_updater::marketplace::parse_latest_response(body).unwrap(),
        expected,
    );
}

pub fn assert_release_fixture(
    body: &str,
    expected: &[(&str, &str, &str, Platform, bool, &str)],
) {
    assert_configs_match(
        nix_vscode_extensions_updater::marketplace::parse_release_response(body).unwrap(),
        expected,
    );
}

fn assert_configs_match(
    parsed: Vec<ExtensionConfig>,
    expected: &[(&str, &str, &str, Platform, bool, &str)],
) {
    let parsed = parsed
        .iter()
        .map(|config| {
            (
                config.publisher.0.clone(),
                config.name.0.clone(),
                config.version.to_string(),
                config.platform,
                config.is_release.0,
                config.engine_version.to_string(),
            )
        })
        .collect::<Vec<_>>();
    let expected = expected
        .iter()
        .map(|(publisher, name, version, platform, is_release, engine_version)| {
            (
                (*publisher).to_string(),
                (*name).to_string(),
                (*version).to_string(),
                *platform,
                *is_release,
                (*engine_version).to_string(),
            )
        })
        .collect::<Vec<_>>();
    assert_eq!(parsed, expected);
}

pub fn test_config(data_dir: &Path) -> AppConfig {
    AppConfig {
        data_dir: data_dir.to_path_buf(),
        open_vsx: SiteConfig {
            enable: true,
            page_count: 1,
            page_size: 1,
            metadata_fetch_threads: 1,
            artifact_prefetch_threads: None,
        },
        vscode_marketplace: SiteConfig {
            enable: false,
            page_count: 1,
            page_size: 1,
            metadata_fetch_threads: 1,
            artifact_prefetch_threads: None,
        },
        ..AppConfig::default()
    }
}

pub fn test_pipeline<'a, M, P>(
    config: &'a AppConfig,
    marketplace: &'a M,
    prefetcher: &'a P,
) -> Pipeline<'a, M, P> {
    Pipeline {
        config,
        marketplace,
        prefetcher,
        shutdown: &NO_SHUTDOWN,
    }
}
