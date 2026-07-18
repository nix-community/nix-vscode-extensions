#![allow(dead_code)]

use nix_vscode_extensions_updater::config::{AppConfig, SiteConfig};
use nix_vscode_extensions_updater::logging::{Level, Logger};
use nix_vscode_extensions_updater::marketplace::{
    MarketplaceClient, MarketplaceFetchResult, ReleaseConfigFetchResult, ReleaseLookupFailure,
};
use nix_vscode_extensions_updater::model::{
    CacheRecord, EngineVersion, ExtensionConfig, IsRelease, Name, Platform, Publisher, Target,
    Version,
};
use nix_vscode_extensions_updater::pipeline::Pipeline;
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use std::collections::VecDeque;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};
use tempfile::TempDir;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct LogEntry {
    pub level: Level,
    pub message: String,
}

#[derive(Clone, Default)]
pub struct TestLogger {
    entries: Arc<Mutex<Vec<LogEntry>>>,
}

impl TestLogger {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn entries(&self) -> Vec<LogEntry> {
        self.entries.lock().unwrap().clone()
    }
}

impl Logger for TestLogger {
    fn enabled(&self, _level: Level) -> bool {
        true
    }

    fn log(&self, level: Level, message: &str) {
        self.entries.lock().unwrap().push(LogEntry {
            level,
            message: message.to_string(),
        });
    }
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
        self.release_result.configs = configs;
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
) -> Pipeline<'a, M, P, TestLogger> {
    let logger = Box::leak(Box::new(TestLogger::new()));
    Pipeline {
        config,
        marketplace,
        prefetcher,
        logger,
    }
}

pub fn test_pipeline_with_logger<'a, M, P>(
    config: &'a AppConfig,
    marketplace: &'a M,
    prefetcher: &'a P,
    logger: &'a TestLogger,
) -> Pipeline<'a, M, P, TestLogger> {
    Pipeline {
        config,
        marketplace,
        prefetcher,
        logger,
    }
}
