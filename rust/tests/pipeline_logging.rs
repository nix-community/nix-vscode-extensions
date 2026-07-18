mod pipeline;

use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::Platform;
use pipeline::assertions::log_messages;
use pipeline::support::{
    config, record, test_pipeline_with_logger, FakeMarketplace, FakePrefetcher, TestEnv,
    TestLogger,
};

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
    assert!(messages
        .iter()
        .any(|message| message.contains("[run] Starting extension updater run")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Target start")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Latest-page fetch start")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Prefetch start")));
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Cache write finish: merged cache count=1")
    }));
    assert!(messages
        .iter()
        .any(|message| message.contains("[open-vsx] Latest configs fetched count: 1")));
    assert!(messages
        .iter()
        .any(|message| message.contains("[run] Finished extension updater run")));
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
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Prefetch finish: fetched records=0 failed records=0")
    }));
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Cache write finish: merged cache count=0")
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
    assert!(failure.contains(
        "url=https://open-vsx.org/api/broken/ext/linux-x64/2.0.0/file/broken.ext-2.0.0@linux-x64.vsix"
    ));
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
        entry.level == nix_vscode_extensions_updater::logging::Level::Debug
            && entry
                .message
                .contains("[open-vsx] Prefetch success: extension=ok.ext")
    }));
    assert!(!entries.iter().any(|entry| {
        entry.level == nix_vscode_extensions_updater::logging::Level::Info
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
        Ok(record(
            "one",
            "ext",
            true,
            Platform::Universal,
            "1.0.0",
            "sha256-one",
        )),
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
