#![allow(dead_code)]

use nix_vscode_extensions_updater::config::{AppConfig, SiteConfig};
use nix_vscode_extensions_updater::logging::{Level, Logger};
use nix_vscode_extensions_updater::marketplace::{MarketplaceClient, MarketplaceFetchResult};
use nix_vscode_extensions_updater::model::{
    CacheRecord, EngineVersion, ExtensionConfig, IsRelease, Name, Platform, Publisher, Target,
    Version,
};
use nix_vscode_extensions_updater::pipeline::Pipeline;
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use std::collections::VecDeque;
use std::path::{Path, PathBuf};
use std::sync::Mutex;
use tempfile::TempDir;

pub struct TestLogger;

impl Logger for TestLogger {
    fn enabled(&self, _level: Level) -> bool {
        true
    }

    fn log(&self, _level: Level, _message: &str) {}
}

pub struct FakeMarketplace {
    pub latest: MarketplaceFetchResult,
    pub releases: Vec<ExtensionConfig>,
    pub latest_error: Option<String>,
    pub release_error: Option<String>,
    pub requested_release_ids: Mutex<Vec<(Publisher, Name)>>,
}

impl FakeMarketplace {
    pub fn new(latest: MarketplaceFetchResult) -> Self {
        Self {
            latest,
            releases: Vec::new(),
            latest_error: None,
            release_error: None,
            requested_release_ids: Mutex::new(Vec::new()),
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
}

impl MarketplaceClient for FakeMarketplace {
    fn fetch_latest(
        &self,
        _target: Target,
        _site: &SiteConfig,
    ) -> anyhow::Result<MarketplaceFetchResult> {
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
    ) -> anyhow::Result<Vec<ExtensionConfig>> {
        self.requested_release_ids
            .lock()
            .unwrap()
            .extend_from_slice(ids);
        if let Some(err) = &self.release_error {
            return Err(anyhow::anyhow!(err.clone()));
        }
        Ok(self.releases.clone())
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

pub fn test_config(data_dir: &Path) -> AppConfig {
    AppConfig {
        data_dir: data_dir.to_path_buf(),
        open_vsx: SiteConfig {
            enable: true,
            page_count: 1,
            page_size: 1,
            n_threads: 1,
        },
        vscode_marketplace: SiteConfig {
            enable: false,
            page_count: 1,
            page_size: 1,
            n_threads: 1,
        },
        ..AppConfig::default()
    }
}

pub fn test_pipeline<'a, M, P>(
    config: &'a AppConfig,
    marketplace: &'a M,
    prefetcher: &'a P,
) -> Pipeline<'a, M, P, TestLogger> {
    Pipeline {
        config,
        marketplace,
        prefetcher,
        logger: &TestLogger,
    }
}
