mod pipeline;

use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::Platform;
use pipeline::support::{
    assert_line_prefix, assert_no_line, capture_pipeline_logs, config, count_lines,
    observed_platforms_for, record, FakeMarketplace, FakePrefetcher, TestEnv,
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
    app_config.log_severity = nix_vscode_extensions_updater::config::LogSeverity::Debug;
    let (logs, err) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    let err = err.unwrap_err();
    assert!(err
        .to_string()
        .contains("failed to fetch latest configs for open-vsx"));

    let lines = logs.lines();
    assert_line_prefix(&lines, "DEBUG", "[open-vsx] latest-page fetch attempt 1/2 start");
    assert_line_prefix(
        &lines,
        "ERROR",
        "[open-vsx] latest-page fetch attempt 1/2 failed; retrying in 0s: boom latest",
    );
    assert_line_prefix(
        &lines,
        "ERROR",
        "[open-vsx] latest-page fetch exhausted after 2/2 attempts: boom latest",
    );
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
    app_config.log_severity = nix_vscode_extensions_updater::config::LogSeverity::Debug;
    let (logs, err) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    let err = err.unwrap_err();
    assert!(err
        .to_string()
        .contains("failed to fetch latest configs for open-vsx"));

    let lines = logs.lines();
    assert_eq!(count_lines(&lines, "latest-page fetch attempt 1/1 start"), 1);
    assert_no_line(&lines, "retrying in 0s");
    assert_line_prefix(
        &lines,
        "ERROR",
        "[open-vsx] latest-page fetch exhausted after 1/1 attempts: boom latest",
    );
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
    app_config.log_severity = nix_vscode_extensions_updater::config::LogSeverity::Debug;
    let (logs, result) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_line_prefix(
        &lines,
        "ERROR",
        "[open-vsx] release-config fetch attempt 1/2 failed; retrying in 0s: transient release failure",
    );
    assert_line_prefix(
        &lines,
        "INFO ",
        "[open-vsx] release-config fetch recovered on attempt 2/2",
    );
}
