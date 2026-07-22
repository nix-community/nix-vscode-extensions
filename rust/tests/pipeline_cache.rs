mod pipeline;

use nix_vscode_extensions_updater::cache::{read_jsonl_cache, tmp_path, write_jsonl_cache};
use nix_vscode_extensions_updater::marketplace::{parse_latest_response, MarketplaceFetchResult};
use nix_vscode_extensions_updater::model::{CacheRecord, IsRelease, Name, Platform, Publisher};
use nix_vscode_extensions_updater::pipeline::ShutdownSignal;
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use pipeline::support::{
    config, observed_platforms_for, record, test_pipeline, test_pipeline_with_shutdown,
    FakeMarketplace, FakePrefetcher, TestEnv,
};
use serde_json::json;
use std::collections::HashMap;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

fn prefetch_key(config: &nix_vscode_extensions_updater::model::ExtensionConfig) -> String {
    format!("{}.{}@{}", config.publisher.0, config.name.0, config.version.raw())
}

struct RecordingPrefetcher {
    records: HashMap<String, CacheRecord>,
    calls: Arc<Mutex<Vec<String>>>,
    shutdown: Option<(usize, Arc<ShutdownSignal>)>,
    seen: AtomicUsize,
}

impl RecordingPrefetcher {
    fn new(records: HashMap<String, CacheRecord>) -> Self {
        Self {
            records,
            calls: Arc::new(Mutex::new(Vec::new())),
            shutdown: None,
            seen: AtomicUsize::new(0),
        }
    }

    fn with_shutdown_after(mut self, call: usize, shutdown: Arc<ShutdownSignal>) -> Self {
        self.shutdown = Some((call, shutdown));
        self
    }

    fn calls(&self) -> Vec<String> {
        self.calls.lock().unwrap().clone()
    }
}

impl Prefetcher for RecordingPrefetcher {
    fn prefetch(
        &self,
        _target: nix_vscode_extensions_updater::model::Target,
        config: &nix_vscode_extensions_updater::model::ExtensionConfig,
        _timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        let key = prefetch_key(config);
        self.calls.lock().unwrap().push(key.clone());
        let seen = self.seen.fetch_add(1, Ordering::SeqCst) + 1;
        if let Some((shutdown_after, shutdown)) = &self.shutdown {
            if seen == *shutdown_after {
                shutdown.request();
            }
        }
        self.records
            .get(&key)
            .cloned()
            .ok_or_else(|| anyhow::anyhow!("missing prefetch response for {key}"))
    }
}

#[test]
fn pipeline_merges_and_keeps_retained_records() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    let retained = CacheRecord {
        publisher: Publisher("keep".into()),
        name: Name("old".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: pipeline::support::version("1.0.0"),
        engine_version: pipeline::support::engine("^1.0.0"),
        hash: "sha256-retained".into(),
    };
    write_jsonl_cache(&cache_file, &[retained.clone()]).unwrap();

    let latest_configs = vec![
            config("keep", "old", true, Platform::Universal, "1.1.0"),
            config("fresh", "ext", true, Platform::Universal, "2.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(CacheRecord {
        publisher: Publisher("fresh".into()),
        name: Name("ext".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: pipeline::support::version("2.0.0"),
        engine_version: pipeline::support::engine("^1.0.0"),
        hash: "sha256-fresh".into(),
    })]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 2);
    assert!(cached.iter().any(|r| r.hash == "sha256-retained"));
    assert!(cached.iter().any(|r| r.hash == "sha256-fresh"));
}

#[test]
fn dedup_latest_keeps_first_record_for_each_latest_key() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    let latest_configs = vec![
            config("keep", "ext", true, Platform::Universal, "1.0.0"),
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![
        Ok(CacheRecord {
            publisher: Publisher("keep".into()),
            name: Name("ext".into()),
            is_release: IsRelease(true),
            platform: Platform::Universal,
            version: pipeline::support::version("1.0.0"),
            engine_version: pipeline::support::engine("^1.0.0"),
            hash: "sha256-first".into(),
        }),
        Ok(CacheRecord {
            publisher: Publisher("keep".into()),
            name: Name("ext".into()),
            is_release: IsRelease(true),
            platform: Platform::Universal,
            version: pipeline::support::version("2.0.0"),
            engine_version: pipeline::support::engine("^1.0.0"),
            hash: "sha256-second".into(),
        }),
    ]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].hash, "sha256-first");
    assert_eq!(cached[0].version, pipeline::support::version("1.0.0"));
}

#[test]
fn dedup_latest_prefers_the_first_record_seen_for_a_latest_key() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    write_jsonl_cache(
        &cache_file,
        &[
            record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-cached"),
            record("other", "ext", true, Platform::Universal, "1.0.0", "sha256-other"),
        ],
    )
    .unwrap();

    let latest_configs = vec![
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
            config("other", "ext", true, Platform::Universal, "1.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "keep",
        "ext",
        true,
        Platform::Universal,
        "2.0.0",
        "sha256-fetched",
    ))]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);
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
fn pipeline_propagates_latest_fetch_failure_without_writing_latest_debug_files() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");
    let mut app_config = env.config.clone();
    app_config.n_retry = 0;
    app_config.retry_delay = 0;

    let marketplace = FakeMarketplace::new(MarketplaceFetchResult {
        configs: vec![],
        observed_platforms: observed_platforms_for(&[]),
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&app_config, &marketplace, &prefetcher);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch latest configs for open-vsx"));
    assert!(!env.debug_file("open-vsx", "pages-failed").exists());
    assert!(!env.debug_file("open-vsx", "pages-fetched").exists());
    assert!(read_jsonl_cache(&cache_file).unwrap().is_empty());
}

#[test]
fn pipeline_propagates_release_fetch_failure_after_writing_latest_debug_files() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");
    let mut app_config = env.config.clone();
    app_config.n_retry = 0;
    app_config.retry_delay = 0;

    let latest_configs = vec![config("keep", "ext", false, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec!["page-1-failed".into()],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest).with_release_error("boom release");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&app_config, &marketplace, &prefetcher);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch release configs"));
    assert!(read_jsonl_cache(&cache_file).unwrap().is_empty());
    assert!(std::fs::read_to_string(env.debug_file("open-vsx", "pages-failed"))
        .unwrap()
        .contains("page-1-failed"));
    assert!(std::fs::read_to_string(env.debug_file("open-vsx", "pages-fetched"))
        .unwrap()
        .contains("page-1"));
    assert!(std::fs::read_to_string(env.debug_file("open-vsx", "ids-pre-release-configs"))
        .unwrap()
        .contains("keep"));
}

#[test]
fn prerelease_debug_ids_only_include_latest_fetch_candidates() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    write_jsonl_cache(
        &cache_file,
        &[
            record("stale", "ext", false, Platform::Universal, "1.0.0", "sha256-stale-pre"),
            record("fresh", "ext", false, Platform::Universal, "2.0.0", "sha256-fresh-pre"),
        ],
    )
    .unwrap();

    let latest_configs = vec![config("fresh", "ext", false, Platform::Universal, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let debug_ids =
        std::fs::read_to_string(env.debug_file("open-vsx", "ids-pre-release-configs")).unwrap();
    assert!(debug_ids.contains("fresh"));
    assert!(!debug_ids.contains("stale"));
}

#[test]
fn dedup_latest_keeps_first_stale_cached_record_before_later_same_latest_key_records() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    write_jsonl_cache(
        &cache_file,
        &[
            record("keep", "ext", false, Platform::Universal, "1.0.0", "sha256-stale"),
            record("keep", "ext", false, Platform::Universal, "2.0.0", "sha256-fresh"),
        ],
    )
    .unwrap();

    let latest_configs = vec![config("keep", "ext", false, Platform::Universal, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].hash, "sha256-stale");
}

#[test]
fn open_vsx_skips_unobserved_universal_release_prefetch_and_writes_debug_output() {
    let env = TestEnv::new();
    let latest_configs = vec![config("need", "ext", false, Platform::LinuxX64, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let release_configs = vec![config("need", "ext", true, Platform::Universal, "1.9.0")];
    let marketplace = FakeMarketplace::new(latest)
        .with_release_configs(release_configs)
        .with_release_observed_platforms(observed_platforms_for(&[config(
            "need",
            "ext",
            true,
            Platform::LinuxX64,
            "1.9.0",
        )]));
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "need",
        "ext",
        false,
        Platform::LinuxX64,
        "2.0.0",
        "sha256-need-pre",
    ))]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched.len(), 1);
    assert_eq!(fetched[0].platform, Platform::LinuxX64);

    let skipped = std::fs::read_to_string(
        env.data_dir
            .join("debug")
            .join("open-vsx")
            .join("skipped-artifact-prefetches.jsonl"),
    )
    .unwrap();
    assert!(skipped.contains("\"P\":0"));
    assert!(skipped.contains("\"observed_platforms\":[1]"));
}

#[test]
fn open_vsx_prefetches_universal_prerelease_when_latest_observed_it() {
    let env = TestEnv::new();
    let latest_configs = vec![config("need", "ext", false, Platform::Universal, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "need",
        "ext",
        false,
        Platform::Universal,
        "2.0.0",
        "sha256-need-pre",
    ))]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched.len(), 1);
    assert_eq!(fetched[0].platform, Platform::Universal);
}

#[test]
fn open_vsx_prefetches_universal_release_when_release_lookup_observed_it() {
    let env = TestEnv::new();
    let latest_configs = vec![config("need", "ext", false, Platform::LinuxX64, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest).with_release_configs(vec![config(
        "need",
        "ext",
        true,
        Platform::Universal,
        "1.9.0",
    )]);
    let prefetcher = FakePrefetcher::new(vec![
        Ok(record(
            "need",
            "ext",
            false,
            Platform::LinuxX64,
            "2.0.0",
            "sha256-need-pre",
        )),
        Ok(record(
            "need",
            "ext",
            true,
            Platform::Universal,
            "1.9.0",
            "sha256-need-release",
        )),
    ]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched.len(), 2);
    assert!(fetched.iter().any(|record| {
        record.is_release.0 && record.platform == Platform::Universal && record.hash == "sha256-need-release"
    }));
}

#[test]
fn open_vsx_prefetches_platform_specific_variant_when_observed() {
    let env = TestEnv::new();
    let latest_configs = vec![config("need", "ext", true, Platform::LinuxX64, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "need",
        "ext",
        true,
        Platform::LinuxX64,
        "2.0.0",
        "sha256-need-linux",
    ))]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched.len(), 1);
    assert_eq!(fetched[0].platform, Platform::LinuxX64);
}

#[test]
fn open_vsx_unknown_platform_entries_do_not_become_universal_prefetch_candidates() {
    let env = TestEnv::new();
    let body = json!({
        "results": [{
            "extensions": [{
                "flags": "public",
                "extensionName": "sample",
                "publisher": {"publisherName": "alice"},
                "versions": [{
                    "version": "1.2.3",
                    "targetPlatform": "fancy-os",
                    "properties": [
                        {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                    ]
                }]
            }]
        }]
    });
    let latest_configs = parse_latest_response(&body.to_string()).unwrap();
    assert!(latest_configs.is_empty());

    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert!(fetched.is_empty());
}

#[test]
fn interrupted_run_checkpoints_progress_and_next_run_resumes_without_refetching_completed_records() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.artifact_prefetch_threads = Some(1);
    let latest_configs = vec![
        config("one", "ext", true, Platform::Universal, "1.0.0"),
        config("two", "ext", true, Platform::Universal, "2.0.0"),
    ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let shutdown = Arc::new(ShutdownSignal::new());
    let first_prefetcher = RecordingPrefetcher::new(HashMap::from([
        (
            "one.ext@1.0.0".to_string(),
            record("one", "ext", true, Platform::Universal, "1.0.0", "sha256-one"),
        ),
        (
            "two.ext@2.0.0".to_string(),
            record("two", "ext", true, Platform::Universal, "2.0.0", "sha256-two"),
        ),
    ]))
    .with_shutdown_after(1, shutdown.clone());
    let marketplace = FakeMarketplace::new(latest.clone());
    let first_run = test_pipeline_with_shutdown(
        &app_config,
        &marketplace,
        &first_prefetcher,
        shutdown.as_ref(),
    )
    .run();
    assert!(first_run.unwrap_err().to_string().contains("interrupted by shutdown signal"));

    let fetched_tmp = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched_tmp.len(), 1);
    assert_eq!(fetched_tmp[0].publisher.0, "one");

    let checkpointed_cache = read_jsonl_cache(&env.cache_file("open-vsx")).unwrap();
    assert_eq!(checkpointed_cache.len(), 1);
    assert_eq!(checkpointed_cache[0].publisher.0, "one");

    let second_prefetcher = RecordingPrefetcher::new(HashMap::from([(
        "two.ext@2.0.0".to_string(),
        record("two", "ext", true, Platform::Universal, "2.0.0", "sha256-two"),
    )]));
    let second_marketplace = FakeMarketplace::new(latest);
    test_pipeline(
        &app_config,
        &second_marketplace,
        &second_prefetcher,
    )
    .run()
    .unwrap();

    assert_eq!(second_prefetcher.calls(), vec!["two.ext@2.0.0".to_string()]);
    let merged = read_jsonl_cache(&env.cache_file("open-vsx")).unwrap();
    assert_eq!(merged.len(), 2);
    assert!(merged.iter().any(|record| record.publisher.0 == "one"));
    assert!(merged.iter().any(|record| record.publisher.0 == "two"));
}

#[test]
fn resumed_records_outside_current_target_set_are_discarded() {
    let env = TestEnv::new();
    let latest_configs = vec![config("keep", "ext", true, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    write_jsonl_cache(
        &tmp_path(&env.data_dir, "fetched", "open-vsx"),
        &[
            record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-keep"),
            record("drop", "ext", true, Platform::Universal, "1.0.0", "sha256-drop"),
        ],
    )
    .unwrap();

    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    test_pipeline(&env.config, &marketplace, &prefetcher).run().unwrap();

    let resumed = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(resumed.len(), 1);
    assert_eq!(resumed[0].publisher.0, "keep");
}

#[test]
fn older_than_cache_resumed_records_are_dropped_before_resume() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");
    write_jsonl_cache(
        &cache_file,
        &[record(
            "keep",
            "ext",
            true,
            Platform::Universal,
            "2.0.0",
            "sha256-cached",
        )],
    )
    .unwrap();
    write_jsonl_cache(
        &tmp_path(&env.data_dir, "fetched", "open-vsx"),
        &[record(
            "keep",
            "ext",
            true,
            Platform::Universal,
            "1.0.0",
            "sha256-stale",
        )],
    )
    .unwrap();

    let latest_configs = vec![config("keep", "ext", true, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let prefetcher = RecordingPrefetcher::new(HashMap::from([(
        "keep.ext@1.0.0".to_string(),
        record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-refetched"),
    )]));
    let marketplace = FakeMarketplace::new(latest);
    test_pipeline(&env.config, &marketplace, &prefetcher).run().unwrap();

    assert_eq!(prefetcher.calls(), vec!["keep.ext@1.0.0".to_string()]);
    assert!(read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx"))
        .unwrap()
        .is_empty());
    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].version, pipeline::support::version("2.0.0"));
}

#[test]
fn older_than_cache_newly_fetched_records_are_dropped() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");
    write_jsonl_cache(
        &cache_file,
        &[record(
            "keep",
            "ext",
            true,
            Platform::Universal,
            "2.0.0",
            "sha256-cached",
        )],
    )
    .unwrap();

    let latest_configs = vec![config("keep", "ext", true, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let prefetcher = RecordingPrefetcher::new(HashMap::from([(
        "keep.ext@1.0.0".to_string(),
        record("keep", "ext", true, Platform::Universal, "1.0.0", "sha256-stale"),
    )]));
    let marketplace = FakeMarketplace::new(latest);
    test_pipeline(&env.config, &marketplace, &prefetcher).run().unwrap();

    assert_eq!(prefetcher.calls(), vec!["keep.ext@1.0.0".to_string()]);
    assert!(read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx"))
        .unwrap()
        .is_empty());
    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].version, pipeline::support::version("2.0.0"));
}

#[test]
fn failed_tmp_records_do_not_suppress_retries() {
    let env = TestEnv::new();
    let failed_tmp = tmp_path(&env.data_dir, "failed", "open-vsx");
    std::fs::create_dir_all(failed_tmp.parent().unwrap()).unwrap();
    std::fs::write(
        &failed_tmp,
        format!(
            "{}\n",
            serde_json::to_string(&config("retry", "ext", true, Platform::Universal, "1.0.0")).unwrap()
        ),
    )
    .unwrap();
    let latest_configs = vec![config("retry", "ext", true, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let prefetcher = RecordingPrefetcher::new(HashMap::from([(
        "retry.ext@1.0.0".to_string(),
        record("retry", "ext", true, Platform::Universal, "1.0.0", "sha256-retry"),
    )]));
    let marketplace = FakeMarketplace::new(latest);
    test_pipeline(&env.config, &marketplace, &prefetcher).run().unwrap();

    assert_eq!(prefetcher.calls(), vec!["retry.ext@1.0.0".to_string()]);
    let cached = read_jsonl_cache(&env.cache_file("open-vsx")).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].publisher.0, "retry");
}
