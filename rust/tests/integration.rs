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
use std::path::Path;
use std::sync::Mutex;
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
    latest_error: Option<String>,
    release_error: Option<String>,
    requested_release_ids: Mutex<Vec<(Publisher, Name)>>,
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
        _ids: &[(Publisher, Name)],
    ) -> anyhow::Result<Vec<ExtensionConfig>> {
        self.requested_release_ids
            .lock()
            .unwrap()
            .extend_from_slice(_ids);
        if let Some(err) = &self.release_error {
            return Err(anyhow::anyhow!(err.clone()));
        }
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

fn record(
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

fn test_config(data_dir: &Path) -> AppConfig {
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

fn test_pipeline<'a, M, P>(
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
fn numeric_deserialization_rejects_invalid_values() {
    for value in [json!(-1), json!(5), json!("x"), json!(null)] {
        assert!(serde_json::from_value::<Platform>(value).is_err());
    }

    for value in [json!(-1), json!(2), json!("x"), json!(null)] {
        assert!(serde_json::from_value::<IsRelease>(value).is_err());
    }
}

#[test]
fn version_parsing_accepts_supported_forms() {
    for (input, expected) in [
        ("1.2.3", "1.2.3"),
        ("1.2.3-insider", "1.2.3-insider"),
        ("1.2.3-rc.1", "1.2.3-rc.1"),
    ] {
        assert_eq!(version(input).to_string(), expected);
    }

    for input in ["", " ", "1.2", "1.2.3.4", "v1.2.3", "1.2.x", "a.b.c"] {
        assert!(Version::parse(input).is_err());
    }
}

#[test]
fn engine_version_parsing_accepts_supported_forms_and_rejects_bad_inputs() {
    assert_eq!(engine("*").to_string(), "^0.0.0");
    assert_eq!(engine("^1.2.3").to_string(), "^1.2.3");
    assert_eq!(engine(">=1.2.3").to_string(), "^1.2.3");
    assert_eq!(engine("1.x.0").to_string(), "1.0.0");
    assert_eq!(engine(">=1.x.0").to_string(), "^1.0.0");

    for input in ["", " ", "^", ">=", "1.2", "^1.2", ">=1", "1.2.3.4", "1.x", "x.x"] {
        assert!(EngineVersion::parse(input).is_err());
    }
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
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
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
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 2);
    assert!(cached.iter().any(|r| r.hash == "sha256-retained"));
    assert!(cached.iter().any(|r| r.hash == "sha256-fresh"));
}

#[test]
fn dedup_latest_keeps_first_record_for_each_latest_key() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_dir = data_dir.join("cache");
    std::fs::create_dir_all(&cache_dir).unwrap();
    let cache_file = cache_dir.join("open-vsx-latest.jsonl");

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("keep", "ext", true, Platform::Universal, "1.0.0"),
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::from(vec![
            Ok(CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(true),
                platform: Platform::Universal,
                version: version("1.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-first".into(),
            }),
            Ok(CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(true),
                platform: Platform::Universal,
                version: version("2.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-second".into(),
            }),
        ])),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].hash, "sha256-first");
    assert_eq!(cached[0].version, version("1.0.0"));
}

#[test]
fn dedup_latest_prefers_the_first_record_seen_for_a_latest_key() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_dir = data_dir.join("cache");
    std::fs::create_dir_all(&cache_dir).unwrap();
    let cache_file = cache_dir.join("open-vsx-latest.jsonl");

    write_jsonl_cache(
        &cache_file,
        &[
            record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-cached"),
            record("other", "ext", true, Platform::Universal, "1.0.0", "sha256-other"),
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
            config("other", "ext", true, Platform::Universal, "1.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::from(vec![Ok(record(
            "keep",
            "ext",
            true,
            Platform::Universal,
            "2.0.0",
            "sha256-fetched",
        ))])),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(
        cached
            .iter()
            .find(|r| r.publisher == Publisher("keep".into()) && r.name == Name("ext".into()))
            .unwrap()
            .hash,
        "sha256-fetched"
    );
    assert_eq!(
        cached
            .iter()
            .find(|r| r.publisher == Publisher("other".into()) && r.name == Name("ext".into()))
            .unwrap()
            .hash,
        "sha256-other"
    );
}

#[test]
fn jsonl_cache_round_trip_preserves_records_and_skips_blank_lines() {
    let tmp = TempDir::new().unwrap();
    let path = tmp.path().join("cache.jsonl");
    let records = vec![
        record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-one"),
        record(
            "fresh",
            "ext",
            false,
            Platform::DarwinArm64,
            "2.0.0-insider",
            "sha256-two",
        ),
    ];

    write_jsonl_cache(&path, &records).unwrap();
    let mut contents = std::fs::read_to_string(&path).unwrap();
    contents.push_str("\n\n");
    std::fs::write(&path, contents).unwrap();

    let round_tripped = read_jsonl_cache(&path).unwrap();
    assert_eq!(round_tripped, records);
}

#[test]
fn jsonl_cache_handles_empty_whitespace_and_malformed_input() {
    let tmp = TempDir::new().unwrap();

    let empty = tmp.path().join("empty.jsonl");
    std::fs::write(&empty, "").unwrap();
    assert!(read_jsonl_cache(&empty).unwrap().is_empty());

    let whitespace = tmp.path().join("whitespace.jsonl");
    std::fs::write(&whitespace, " \n\t\n").unwrap();
    assert!(read_jsonl_cache(&whitespace).unwrap().is_empty());

    let malformed = tmp.path().join("malformed.jsonl");
    std::fs::write(&malformed, "{not-json}\n").unwrap();
    assert!(read_jsonl_cache(&malformed).is_err());

    let mixed = tmp.path().join("mixed.jsonl");
    std::fs::write(
        &mixed,
        format!(
            "{}\n{}\n{}\n",
            serde_json::to_string(&record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-one")).unwrap(),
            "{not-json}",
            serde_json::to_string(&record("fresh", "ext", false, Platform::DarwinArm64, "2.0.0", "sha256-two")).unwrap(),
        ),
    )
    .unwrap();
    assert!(read_jsonl_cache(&mixed).is_err());

    let unreadable = tmp.path().join("unreadable.jsonl");
    std::fs::create_dir(&unreadable).unwrap();
    assert!(read_jsonl_cache(&unreadable).is_err());
}

#[test]
fn pipeline_requests_only_cached_prereleases_without_release_counterparts() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_dir = data_dir.join("cache");
    std::fs::create_dir_all(&cache_dir).unwrap();
    let cache_file = cache_dir.join("open-vsx-latest.jsonl");

    write_jsonl_cache(
        &cache_file,
        &[
            CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: version("1.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-keep-pre".into(),
            },
            CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(true),
                platform: Platform::Universal,
                version: version("1.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-keep-release".into(),
            },
            CacheRecord {
                publisher: Publisher("need".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: version("2.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-need-pre".into(),
            },
            CacheRecord {
                publisher: Publisher("latest".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: version("3.0.0"),
                engine_version: engine("^1.0.0"),
                hash: "sha256-latest-pre".into(),
            },
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("latest", "ext", false, Platform::Universal, "3.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::new()),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let requested = marketplace.requested_release_ids.lock().unwrap().clone();
    let mut requested = requested;
    requested.sort();
    let mut expected = vec![
        (Publisher("latest".into()), Name("ext".into())),
        (Publisher("need".into()), Name("ext".into())),
    ];
    expected.sort();
    assert_eq!(requested, expected);
}

#[test]
fn pipeline_propagates_latest_fetch_failure_without_writing_latest_debug_files() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_file = data_dir.join("cache").join("open-vsx-latest.jsonl");

    let marketplace = FakeMarketplace {
        latest: MarketplaceFetchResult {
            configs: vec![],
            pages_failed: vec![],
            pages_fetched: vec![],
        },
        releases: vec![],
        latest_error: Some("boom latest".into()),
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::new()),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch latest configs for open-vsx"));
    assert!(!data_dir.join("debug").join("open-vsx-pages-failed.json").exists());
    assert!(!data_dir.join("debug").join("open-vsx-pages-fetched.json").exists());
    assert!(read_jsonl_cache(&cache_file).unwrap().is_empty());
}

#[test]
fn pipeline_propagates_release_fetch_failure_after_writing_latest_debug_files() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_file = data_dir.join("cache").join("open-vsx-latest.jsonl");

    let latest = MarketplaceFetchResult {
        configs: vec![config("keep", "ext", false, Platform::Universal, "1.0.0")],
        pages_failed: vec!["page-1-failed".into()],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: Some("boom release".into()),
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::new()),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch release configs"));
    assert!(read_jsonl_cache(&cache_file).unwrap().is_empty());
    assert!(std::fs::read_to_string(data_dir.join("debug").join("open-vsx-pages-failed.json"))
        .unwrap()
        .contains("page-1-failed"));
    assert!(std::fs::read_to_string(data_dir.join("debug").join("open-vsx-pages-fetched.json"))
        .unwrap()
        .contains("page-1"));
    assert!(std::fs::read_to_string(data_dir.join("debug").join("open-vsx-ids-pre-release-configs.json"))
        .unwrap()
        .contains("keep"));
}

#[test]
fn dedup_latest_keeps_first_stale_cached_record_before_later_same_latest_key_records() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_file = data_dir.join("cache").join("open-vsx-latest.jsonl");

    write_jsonl_cache(
        &cache_file,
        &[
            record("keep", "ext", false, Platform::Universal, "1.0.0", "sha256-stale"),
            record("keep", "ext", false, Platform::Universal, "2.0.0", "sha256-fresh"),
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![config("keep", "ext", false, Platform::Universal, "2.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::new()),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].hash, "sha256-stale");
}

#[test]
fn pipeline_dedupes_duplicate_prerelease_ids_and_ignores_cached_release_pairs() {
    let tmp = TempDir::new().unwrap();
    let data_dir = tmp.path().to_path_buf();
    let cache_file = data_dir.join("cache").join("open-vsx-latest.jsonl");

    write_jsonl_cache(
        &cache_file,
        &[
            record("skip", "ext", false, Platform::Universal, "1.0.0", "sha256-skip-pre"),
            record("skip", "ext", true, Platform::Universal, "1.0.0", "sha256-skip-release"),
            record("need", "ext", false, Platform::Universal, "2.0.0", "sha256-need-pre"),
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("dup", "ext", false, Platform::Universal, "3.0.0"),
            config("dup", "ext", false, Platform::Universal, "3.1.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace {
        latest,
        releases: vec![],
        latest_error: None,
        release_error: None,
        requested_release_ids: Mutex::new(Vec::new()),
    };
    let prefetcher = FakePrefetcher {
        responses: Mutex::new(VecDeque::new()),
    };
    let config = test_config(&data_dir);
    let pipeline = test_pipeline(&config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let mut requested = marketplace.requested_release_ids.lock().unwrap().clone();
    requested.sort();
    assert_eq!(
        requested,
        vec![
            (Publisher("dup".into()), Name("ext".into())),
            (Publisher("need".into()), Name("ext".into())),
        ]
    );
}
