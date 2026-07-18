mod pipeline;

use nix_vscode_extensions_updater::logging::Level;
use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::Platform;
use pipeline::support::{
    config, observed_platforms_for, record, test_pipeline_with_logger, FakeMarketplace,
    FakePrefetcher, TestEnv, TestLogger,
};

#[test]
fn retry_logs_exhaustion_for_latest_fetch() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.n_retry = 1;
    app_config.retry_delay = 0;
    let marketplace = FakeMarketplace::new(MarketplaceFetchResult {
        configs: vec![],
        observed_platforms: observed_platforms_for(&[]),
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    let err = pipeline.run().unwrap_err();
    assert!(err
        .to_string()
        .contains("failed to fetch latest configs for open-vsx"));

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
        observed_platforms: observed_platforms_for(&[]),
        pages_failed: vec![],
        pages_fetched: vec![],
    })
    .with_latest_error("boom latest");
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    let err = pipeline.run().unwrap_err();
    assert!(err
        .to_string()
        .contains("failed to fetch latest configs for open-vsx"));

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
    let latest_configs = vec![config("need", "ext", false, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
