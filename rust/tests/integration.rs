use nix_vscode_extensions_updater::cache::{read_jsonl_cache, write_jsonl_cache};
use nix_vscode_extensions_updater::config::{AppConfig, SiteConfig};
use nix_vscode_extensions_updater::logging::{Level, Logger};
use nix_vscode_extensions_updater::marketplace::{
    parse_latest_response, parse_release_response, MarketplaceClient, MarketplaceFetchResult,
};
use nix_vscode_extensions_updater::model::{
    CacheRecord, EngineVersion, EngineVersionModifier, ExtensionConfig, IsRelease, Name, Platform,
    Publisher, Target, Version,
};
use nix_vscode_extensions_updater::pipeline::Pipeline;
use nix_vscode_extensions_updater::prefetch::{parse_prefetch_output, Prefetcher};
use serde_json::json;
use std::collections::VecDeque;
use std::sync::Mutex;
use std::path::PathBuf;
use tempfile::TempDir;

struct TestLogger;

impl Logger for TestLogger {
    fn enabled(&self, _level: Level) -> bool {
        true
    }

    fn log(&self, _level: Level, _message: &str) {}
}

struct FakeMarketplace {
    latest: MarketplaceFetchResult,
    releases: Vec<ExtensionConfig>,
}

impl MarketplaceClient for FakeMarketplace {
    fn fetch_latest(
        &self,
        _target: Target,
        _site: &SiteConfig,
    ) -> anyhow::Result<MarketplaceFetchResult> {
        Ok(MarketplaceFetchResult {
            configs: self.latest.configs.clone(),
            pages_failed: self.latest.pages_failed.clone(),
            pages_fetched: self.latest.pages_fetched.clone(),
        })
    }

    fn fetch_release_configs(
        &self,
        _target: Target,
        _ids: &[(Publisher, Name)],
    ) -> anyhow::Result<Vec<ExtensionConfig>> {
        Ok(self.releases.clone())
    }
}

struct FakePrefetcher {
    responses: Mutex<VecDeque<anyhow::Result<CacheRecord>>>,
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

fn version(text: &str) -> Version {
    Version::parse(text).unwrap()
}

fn engine(text: &str) -> EngineVersion {
    EngineVersion::parse(text).unwrap()
}

fn config(publisher: &str, name: &str, release: bool, platform: Platform, version_text: &str) -> ExtensionConfig {
    ExtensionConfig {
        publisher: Publisher(publisher.to_string()),
        name: Name(name.to_string()),
        is_release: IsRelease(release),
        platform,
        version: version(version_text),
        engine_version: engine("^1.0.0"),
    }
}

#[test]
fn compact_cache_record_serde() {
    let record = CacheRecord {
        publisher: Publisher("pub".into()),
        name: Name("ext".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: version("1.2.3"),
        engine_version: engine("^1.2.3"),
        hash: "sha256-abc".into(),
    };
    let json = serde_json::to_value(&record).unwrap();
    assert_eq!(json, json!({"p":"pub","n":"ext","r":1,"P":0,"v":"1.2.3","e":"^1.2.3","h":"sha256-abc"}));
}

#[test]
fn engine_version_parsing() {
    let parsed = engine(">=1.27.0-insider");
    assert_eq!(parsed.modifier, EngineVersionModifier::Gte);
    assert_eq!(parsed.version.to_string(), "1.27.0-insider");
}

#[test]
fn numeric_conversions() {
    assert_eq!(serde_json::to_value(Platform::DarwinArm64).unwrap(), json!(4));
    assert_eq!(serde_json::to_value(IsRelease(false)).unwrap(), json!(0));
    assert_eq!(serde_json::to_value(IsRelease(true)).unwrap(), json!(1));
}

#[test]
fn prefetch_output_parsing() {
    assert_eq!(parse_prefetch_output(r#"{"hash":"sha256-xyz"}"#).unwrap(), "sha256-xyz");
}

#[test]
fn marketplace_parsers_work() {
    let latest = parse_latest_response(include_str!("fixtures/vscode-latest.json")).unwrap();
    assert_eq!(latest.len(), 2);
    let release = parse_release_response(include_str!("fixtures/open-vsx-release.json")).unwrap();
    assert_eq!(release.len(), 2);
}

#[test]
fn pipeline_merges_and_keeps_retained_records() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_dir = data_dir.join("cache");
    std::fs::create_dir_all(&cache_dir).unwrap();
    let cache_file = cache_dir.join("open-vsx-latest.jsonl");

    let retained = CacheRecord {
        publisher: Publisher("keep".into()),
        name: Name("old".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: version("1.0.0"),
        engine_version: engine("^1.0.0"),
        hash: "sha256-retained".into(),
    };
    write_jsonl_cache(&cache_file, &[retained.clone()]).unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("keep", "old", true, Platform::Universal, "1.1.0"),
            config("fresh", "ext", true, Platform::Universal, "2.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::from(vec![Ok(CacheRecord {
            publisher: Publisher("fresh".into()),
            name: Name("ext".into()),
            is_release: IsRelease(true),
            platform: Platform::Universal,
            version: version("2.0.0"),
            engine_version: engine("^1.0.0"),
            hash: "sha256-fresh".into(),
        })])),
    };
    let config = AppConfig {
        data_dir: PathBuf::from(&data_dir),
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
    };
    let logger = TestLogger;
    let pipeline = Pipeline {
        config: &config,
        marketplace: &marketplace,
        prefetcher: &prefetcher,
        logger: &logger,
    };
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 2);
    assert!(cached.iter().any(|r| r.hash == "sha256-retained"));
    assert!(cached.iter().any(|r| r.hash == "sha256-fresh"));
}
