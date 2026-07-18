mod pipeline;

use nix_vscode_extensions_updater::cache::{read_jsonl_cache, tmp_path};
use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::{CacheRecord, ExtensionConfig, Platform, Target};
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use pipeline::assertions::log_messages;
use pipeline::support::{
    config, record, test_pipeline_with_logger, FakeMarketplace, FakePrefetcher, TestEnv,
    TestLogger,
};
use std::collections::HashMap;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::Arc;
use std::thread;
use std::time::Duration;

struct TrackingPrefetcher {
    active: AtomicUsize,
    max_active: AtomicUsize,
}

impl TrackingPrefetcher {
    fn new() -> Self {
        Self {
            active: AtomicUsize::new(0),
            max_active: AtomicUsize::new(0),
        }
    }

    fn max_active(&self) -> usize {
        self.max_active.load(Ordering::SeqCst)
    }
}

impl Prefetcher for TrackingPrefetcher {
    fn prefetch(
        &self,
        _target: Target,
        config: &ExtensionConfig,
        _timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        let active = self.active.fetch_add(1, Ordering::SeqCst) + 1;
        let _ = self
            .max_active
            .fetch_update(Ordering::SeqCst, Ordering::SeqCst, |current| {
                (active > current).then_some(active)
            });
        thread::sleep(Duration::from_millis(40));
        self.active.fetch_sub(1, Ordering::SeqCst);
        Ok(record(
            &config.publisher.0,
            &config.name.0,
            config.is_release.0,
            config.platform,
            config.version.raw(),
            &format!("sha256-{}", config.version.raw()),
        ))
    }
}

struct KeyedPrefetcher {
    results: HashMap<String, anyhow::Result<CacheRecord>>,
}

impl KeyedPrefetcher {
    fn new(results: HashMap<String, anyhow::Result<CacheRecord>>) -> Self {
        Self { results }
    }
}

impl Prefetcher for KeyedPrefetcher {
    fn prefetch(
        &self,
        _target: Target,
        config: &ExtensionConfig,
        _timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        match self.results.get(&format!("{}.{}", config.publisher.0, config.name.0)) {
            Some(Ok(record)) => Ok(record.clone()),
            Some(Err(err)) => Err(anyhow::anyhow!(err.to_string())),
            None => panic!("missing keyed prefetch response"),
        }
    }
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
fn open_vsx_prerelease_logging_reports_latest_only_counts() {
    let env = TestEnv::new();
    let cache_file = env.cache_file("open-vsx");

    nix_vscode_extensions_updater::cache::write_jsonl_cache(
        &cache_file,
        &[
            record("stale", "ext", false, Platform::Universal, "1.0.0", "sha256-stale-pre"),
            record("paired", "ext", false, Platform::Universal, "1.0.0", "sha256-paired-pre"),
            record(
                "paired",
                "ext",
                true,
                Platform::Universal,
                "1.0.0",
                "sha256-paired-release",
            ),
        ],
    )
    .unwrap();

    let latest = MarketplaceFetchResult {
        configs: vec![
            config("fresh", "ext", false, Platform::Universal, "2.0.0"),
            config("fresh", "ext", false, Platform::Universal, "2.1.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&env.config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let messages = log_messages(&logger);
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Open VSX prerelease candidates from latest: count=1")
    }));
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Open VSX prerelease candidate count from latest: 1")
    }));
    assert!(!messages
        .iter()
        .any(|message| message.contains("cached_without_release")));
    assert!(!messages.iter().any(|message| message.contains("combined_unique_ids")));
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

#[test]
fn prefetch_runs_concurrently_with_a_bounded_cap() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.artifact_prefetch_threads = Some(2);
    let latest = MarketplaceFetchResult {
        configs: vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
            config("three", "ext", true, Platform::Universal, "1.0.0"),
            config("four", "ext", true, Platform::Universal, "1.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = Arc::new(TrackingPrefetcher::new());
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, prefetcher.as_ref(), &logger);

    pipeline.run().unwrap();

    assert_eq!(prefetcher.max_active(), 2);
    let messages = log_messages(&logger);
    assert!(messages.iter().any(|message| {
        message.contains("[open-vsx] Prefetch finish: fetched records=4 failed records=0")
    }));
}

#[test]
fn concurrent_prefetch_collects_successes_and_failures_once_each() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.artifact_prefetch_threads = Some(2);
    let latest = MarketplaceFetchResult {
        configs: vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
            config("three", "ext", true, Platform::Universal, "1.0.0"),
        ],
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = KeyedPrefetcher::new(HashMap::from([
        (
            "one.ext".to_string(),
            Ok(record(
                "one",
                "ext",
                true,
                Platform::Universal,
                "1.0.0",
                "sha256-one",
            )),
        ),
        ("two.ext".to_string(), Err(anyhow::anyhow!("boom two"))),
        (
            "three.ext".to_string(),
            Ok(record(
                "three",
                "ext",
                true,
                Platform::Universal,
                "1.0.0",
                "sha256-three",
            )),
        ),
    ]));
    let logger = TestLogger::new();
    let pipeline = test_pipeline_with_logger(&app_config, &marketplace, &prefetcher, &logger);

    pipeline.run().unwrap();

    let fetched = read_jsonl_cache(&tmp_path(&env.data_dir, "fetched", "open-vsx")).unwrap();
    assert_eq!(fetched.len(), 2);
    assert!(fetched.iter().any(|record| record.publisher.0 == "one"));
    assert!(fetched.iter().any(|record| record.publisher.0 == "three"));

    let failed_text =
        std::fs::read_to_string(tmp_path(&env.data_dir, "failed", "open-vsx")).unwrap();
    let failed: Vec<ExtensionConfig> = failed_text
        .lines()
        .filter(|line| !line.is_empty())
        .map(|line| serde_json::from_str(line).unwrap())
        .collect();
    assert_eq!(failed.len(), 1);
    assert_eq!(failed[0].publisher.0, "two");
}
