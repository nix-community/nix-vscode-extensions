mod pipeline;

use nix_vscode_extensions_updater::logging::Level;
use nix_vscode_extensions_updater::marketplace::{MarketplaceFetchResult, ReleaseLookupFailure};
use nix_vscode_extensions_updater::model::{Name, Platform, Publisher};
use pipeline::support::{
    config, record, test_pipeline, test_pipeline_with_logger, FakeMarketplace, FakePrefetcher,
    TestEnv, TestLogger,
};

#[test]
fn pipeline_requests_only_latest_prereleases_for_release_lookup() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    nix_vscode_extensions_updater::cache::write_jsonl_cache(
        &cache_file,
        &[
            pipeline::support::record(
                "keep",
                "ext",
                false,
                Platform::Universal,
                "1.0.0",
                "sha256-keep-pre",
            ),
            pipeline::support::record(
                "keep",
                "ext",
                true,
                Platform::Universal,
                "1.0.0",
                "sha256-keep-release",
            ),
            pipeline::support::record(
                "need",
                "ext",
                false,
                Platform::Universal,
                "2.0.0",
                "sha256-need-pre",
            ),
            pipeline::support::record(
                "latest",
                "ext",
                false,
                Platform::Universal,
                "3.0.0",
                "sha256-latest-pre",
            ),
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

    let mut requested = marketplace.requested_release_ids.lock().unwrap().clone();
    requested.sort();
    let mut expected = vec![(Publisher("latest".into()), Name("ext".into()))];
    expected.sort();
    assert_eq!(requested, expected);
}

#[test]
fn pipeline_dedupes_duplicate_latest_prerelease_ids_and_ignores_cached_release_pairs() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    nix_vscode_extensions_updater::cache::write_jsonl_cache(
        &cache_file,
        &[
            record("skip", "ext", false, Platform::Universal, "1.0.0", "sha256-skip-pre"),
            record(
                "skip",
                "ext",
                true,
                Platform::Universal,
                "1.0.0",
                "sha256-skip-release",
            ),
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
        vec![(Publisher("dup".into()), Name("ext".into()))]
    );
}

#[test]
fn release_config_partial_failures_are_preserved_and_logged() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![config("need", "ext", false, Platform::Universal, "1.0.0")],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest).with_release_failures(vec![
        ReleaseLookupFailure {
            publisher: Publisher("need".into()),
            name: Name("ext".into()),
            error: "boom release lookup".into(),
        },
    ]);
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
