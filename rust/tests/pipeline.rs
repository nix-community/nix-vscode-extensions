mod support;

use nix_vscode_extensions_updater::logging::Level;
use nix_vscode_extensions_updater::cache::{read_jsonl_cache, write_jsonl_cache};
use nix_vscode_extensions_updater::marketplace::{MarketplaceFetchResult, ReleaseLookupFailure};
use nix_vscode_extensions_updater::model::{CacheRecord, IsRelease, Name, Platform, Publisher};
use support::{
    config, record, test_pipeline, test_pipeline_with_logger, FakeMarketplace, FakePrefetcher,
    TestEnv, TestLogger,
};

#[test]
fn pipeline_merges_and_keeps_retained_records() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    let retained = CacheRecord {
        publisher: Publisher("keep".into()),
        name: Name("old".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: support::version("1.0.0"),
        engine_version: support::engine("^1.0.0"),
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
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(CacheRecord {
        publisher: Publisher("fresh".into()),
        name: Name("ext".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: support::version("2.0.0"),
        engine_version: support::engine("^1.0.0"),
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

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("keep", "ext", true, Platform::Universal, "1.0.0"),
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
        ],
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
            version: support::version("1.0.0"),
            engine_version: support::engine("^1.0.0"),
            hash: "sha256-first".into(),
        }),
        Ok(CacheRecord {
            publisher: Publisher("keep".into()),
            name: Name("ext".into()),
            is_release: IsRelease(true),
            platform: Platform::Universal,
            version: support::version("2.0.0"),
            engine_version: support::engine("^1.0.0"),
            hash: "sha256-second".into(),
        }),
    ]);
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);
    pipeline.run().unwrap();

    let cached = read_jsonl_cache(&cache_file).unwrap();
    assert_eq!(cached.len(), 1);
    assert_eq!(cached[0].hash, "sha256-first");
    assert_eq!(cached[0].version, support::version("1.0.0"));
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

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("keep", "ext", true, Platform::Universal, "2.0.0"),
            config("other", "ext", true, Platform::Universal, "1.0.0"),
        ],
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
fn pipeline_requests_only_cached_prereleases_without_release_counterparts() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    write_jsonl_cache(
        &cache_file,
        &[
            CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: support::version("1.0.0"),
                engine_version: support::engine("^1.0.0"),
                hash: "sha256-keep-pre".into(),
            },
            CacheRecord {
                publisher: Publisher("keep".into()),
                name: Name("ext".into()),
                is_release: IsRelease(true),
                platform: Platform::Universal,
                version: support::version("1.0.0"),
                engine_version: support::engine("^1.0.0"),
                hash: "sha256-keep-release".into(),
            },
            CacheRecord {
                publisher: Publisher("need".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: support::version("2.0.0"),
                engine_version: support::engine("^1.0.0"),
                hash: "sha256-need-pre".into(),
            },
            CacheRecord {
                publisher: Publisher("latest".into()),
                name: Name("ext".into()),
                is_release: IsRelease(false),
                platform: Platform::Universal,
                version: support::version("3.0.0"),
                engine_version: support::engine("^1.0.0"),
                hash: "sha256-latest-pre".into(),
            },
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![config("latest", "ext", false, Platform::Universal, "3.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);
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
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    let marketplace = FakeMarketplace::new(MarketplaceFetchResult {
        configs: vec![],
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

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

    let latest = MarketplaceFetchResult {
        configs: vec![config("keep", "ext", false, Platform::Universal, "1.0.0")],
        pages_failed: vec!["page-1-failed".into()],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest).with_release_error("boom release");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

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

    let latest = MarketplaceFetchResult {
        configs: vec![config("keep", "ext", false, Platform::Universal, "2.0.0")],
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
fn pipeline_dedupes_duplicate_prerelease_ids_and_ignores_cached_release_pairs() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

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
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let pipeline = test_pipeline(&env.config, &marketplace, &prefetcher);

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

#[test]
fn pipeline_logs_stage_boundaries_and_summaries() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![config("fresh", "ext", true, Platform::Universal, "2.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "fresh",
        "ext",
        true,
        Platform::Universal,
        "2.0.0",
        "sha256-fresh",
    ))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    assert!(messages.iter().any(|message| message.contains("[run] Starting extension updater run")));
    assert!(messages.iter().any(|message| message.contains("[open-vsx] Target start")));
    assert!(messages.iter().any(|message| message.contains("[open-vsx] Latest-page fetch start")));
    assert!(messages.iter().any(|message| message.contains("[open-vsx] Prefetch start")));
    assert!(messages.iter().any(|message| message.contains("[open-vsx] Cache write finish: merged cache count=1")));
    assert!(messages.iter().any(|message| message.contains("[open-vsx] Latest configs fetched count: 1")));
    assert!(messages.iter().any(|message| message.contains("[run] Finished extension updater run")));
}

#[test]
fn vscode_marketplace_target_skips_open_vsx_prerelease_release_fetch_logging() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.enable = false;
    app_config.vscode_marketplace.enable = true;
    let latest = MarketplaceFetchResult {
        configs: vec![config("fresh", "ext", true, Platform::Universal, "2.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "fresh",
        "ext",
        true,
        Platform::Universal,
        "2.0.0",
        "sha256-fresh",
    ))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    assert!(messages
        .iter()
        .any(|message| message.contains("[vscode-marketplace] Target start")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[vscode-marketplace] Latest-page fetch start")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[vscode-marketplace] Prefetch start")));
    assert!(!messages
        .iter()
        .any(|message| message.contains("Open VSX prerelease candidate")));
    assert!(!messages
        .iter()
        .any(|message| message.contains("Release-config fetch")));
}

#[test]
fn zero_work_target_still_logs_prefetch_and_cache_lifecycle() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Processed (0/0) extensions")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Prefetch finish: fetched records=0 failed records=0")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Cache write finish: merged cache count=0")));
}

#[test]
fn release_config_partial_failures_are_preserved_and_logged() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![config("need", "ext", false, Platform::Universal, "1.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest)
        .with_release_failures(vec![ReleaseLookupFailure {
            publisher: Publisher("need".into()),
            name: Name("ext".into()),
            error: "boom release lookup".into(),
        }]);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "need",
        "ext",
        false,
        Platform::Universal,
        "1.0.0",
        "sha256-need-pre",
    ))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let entries = logger.entries();
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Info
            && entry
                .message
                .contains("[open-vsx] Release lookups failed for 1 extensions")
    }));
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Debug
            && entry
                .message
                .contains("[open-vsx] Release lookup failure: need.ext error=boom release lookup")
    }));
}

#[test]
fn prefetch_failures_log_context() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![config("broken", "ext", true, Platform::LinuxX64, "2.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Err(anyhow::anyhow!("stderr exploded"))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    let failure = messages
        .iter()
        .find(|message| message.contains("[open-vsx] Prefetch failed:"))
        .unwrap();
    assert!(failure.contains("extension=broken.ext"));
    assert!(failure.contains("version=2.0.0"));
    assert!(failure.contains("platform=linux-x64"));
    assert!(failure.contains("target=open-vsx"));
    assert!(failure.contains("url=https://open-vsx.org/api/broken/ext/linux-x64/2.0.0/file/broken.ext-2.0.0@linux-x64.vsix"));
}

#[test]
fn prefetch_success_logs_at_debug_only() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![config("ok", "ext", true, Platform::Universal, "1.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "ok",
        "ext",
        true,
        Platform::Universal,
        "1.0.0",
        "sha256-ok",
    ))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let entries = logger.entries();
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Debug
            && entry
                .message
                .contains("[open-vsx] Prefetch success: extension=ok.ext")
    }));
    assert!(!entries.iter().any(|entry| {
        entry.level == Level::Info
            && entry
                .message
                .contains("[open-vsx] Prefetch success: extension=ok.ext")
    }));
}

#[test]
fn progress_logging_emits_updates_and_failure_counts() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.processed_logger_delay = 0;
    let latest = MarketplaceFetchResult {
        configs: vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![
        Ok(record("one", "ext", true, Platform::Universal, "1.0.0", "sha256-one")),
        Err(anyhow::anyhow!("boom prefetch")),
    ]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Processed (1/2) extensions")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Processed (2/2) extensions, failures=1")));
}

#[test]
fn retry_logs_exhaustion_for_latest_fetch() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.n_retry = 1;
    app_config.retry_delay = 0;
    let marketplace = FakeMarketplace::new(MarketplaceFetchResult {
        configs: vec![],
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch latest configs for open-vsx"));

    let entries = logger.entries();
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Debug
            && entry
                .message
                .contains("[open-vsx] latest-page fetch attempt 1/2 start")
    }));
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Error
            && entry
                .message
                .contains("[open-vsx] latest-page fetch attempt 1/2 failed; retrying in 0s: boom latest")
    }));
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Error
            && entry
                .message
                .contains("[open-vsx] latest-page fetch exhausted after 2/2 attempts: boom latest")
    }));
}

#[test]
fn retry_with_zero_retries_exhausts_immediately() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.n_retry = 0;
    app_config.retry_delay = 0;
    let marketplace = FakeMarketplace::new(MarketplaceFetchResult {
        configs: vec![],
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    let err = pipeline.run().unwrap_err();
    assert!(err.to_string().contains("failed to fetch latest configs for open-vsx"));

    let entries = logger.entries();
    assert_eq!(
        entries
            .iter()
            .filter(|entry| {
                entry.level == Level::Debug
                    && entry
                        .message
                        .contains("[open-vsx] latest-page fetch attempt 1/1 start")
            })
            .count(),
        1
    );
    assert!(!entries
        .iter()
        .any(|entry| entry.message.contains("retrying in 0s")));
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Error
            && entry
                .message
                .contains("[open-vsx] latest-page fetch exhausted after 1/1 attempts: boom latest")
    }));
}

#[test]
fn retry_logs_recovery_for_release_fetch() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.n_retry = 1;
    app_config.retry_delay = 0;
    let latest = MarketplaceFetchResult {
        configs: vec![config("need", "ext", false, Platform::Universal, "1.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest).fail_release_attempts(1);
    let prefetcher = FakePrefetcher::new(vec![Ok(record(
        "need",
        "ext",
        false,
        Platform::Universal,
        "1.0.0",
        "sha256-need-pre",
    ))]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let entries = logger.entries();
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Error
            && entry.message.contains(
                "[open-vsx] release-config fetch attempt 1/2 failed; retrying in 0s: transient release failure"
            )
    }));
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Info
            && entry
                .message
                .contains("[open-vsx] release-config fetch recovered on attempt 2/2")
    }));
}

#[test]
fn release_config_partial_success_summary_logs_exact_counts() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![
            config("one", "ext", false, Platform::Universal, "1.0.0"),
            config("two", "ext", false, Platform::Universal, "1.0.0"),
            config("three", "ext", false, Platform::Universal, "1.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest)
        .with_release_configs(vec![config(
            "one",
            "ext",
            true,
            Platform::Universal,
            "1.0.0",
        )])
        .with_release_failures(vec![
            ReleaseLookupFailure {
                publisher: Publisher("two".into()),
                name: Name("ext".into()),
                error: "boom two".into(),
            },
            ReleaseLookupFailure {
                publisher: Publisher("three".into()),
                name: Name("ext".into()),
                error: "boom three".into(),
            },
        ]);
    let prefetcher = FakePrefetcher::new(vec![
        Ok(record(
            "one",
            "ext",
            false,
            Platform::Universal,
            "1.0.0",
            "sha256-one-pre",
        )),
        Ok(record(
            "two",
            "ext",
            false,
            Platform::Universal,
            "1.0.0",
            "sha256-two-pre",
        )),
        Ok(record(
            "three",
            "ext",
            false,
            Platform::Universal,
            "1.0.0",
            "sha256-three-pre",
        )),
        Ok(record(
            "one",
            "ext",
            true,
            Platform::Universal,
            "1.0.0",
            "sha256-one-release",
        )),
    ]);
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let entries = logger.entries();
    assert!(entries.iter().any(|entry| {
        entry.level == Level::Info
            && entry.message.contains(
                "[open-vsx] Release-config fetch finish: attempted_ids=3 succeeded_responses=1 failed_responses=2 parsed_configs=1"
            )
    }));
}

fn log_messages(logger: &TestLogger) -> Vec<String> {
    logger.entries().into_iter().map(|entry| entry.message).collect()
}
