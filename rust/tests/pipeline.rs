mod support;

use nix_vscode_extensions_updater::cache::{read_jsonl_cache, write_jsonl_cache};
use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::{CacheRecord, IsRelease, Name, Platform, Publisher};
use support::{config, record, test_pipeline, FakeMarketplace, FakePrefetcher, TestEnv};

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
