mod pipeline;

use nix_vscode_extensions_updater::cache::{read_jsonl_cache, tmp_path};
use nix_vscode_extensions_updater::marketplace::MarketplaceFetchResult;
use nix_vscode_extensions_updater::model::{CacheRecord, ExtensionConfig, Platform, Target};
use nix_vscode_extensions_updater::prefetch::Prefetcher;
use pipeline::support::{
    assert_has_line, assert_line_prefix, assert_no_line, capture_pipeline_logs, config,
    count_lines, find_line, info_lines, observed_platforms_for, record, FakeMarketplace,
    FakePrefetcher, TestEnv,
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
    let latest_configs = vec![config("fresh", "ext", true, Platform::Universal, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
    let (logs, result) = capture_pipeline_logs(&env.config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_has_line(&lines, "[ START  ] [run] Starting extension updater run");
    assert_has_line(&lines, "[ START  ] [open-vsx] Target start");
    assert_has_line(&lines, "[ START  ] [open-vsx] Latest-page fetch start");
    assert_has_line(&lines, "[ START  ] [open-vsx] Prefetch start");
    assert_has_line(&lines, "[ FINISH ] [open-vsx] Cache write finish: merged cache count=1");
    assert_has_line(&lines, "[  INFO  ] [open-vsx] Latest configs fetched count: 1");
    assert_has_line(&lines, "[ FINISH ] [run] Finished extension updater run");
}

#[test]
fn vscode_marketplace_target_skips_open_vsx_prerelease_release_fetch_logging() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.enable = false;
    app_config.vscode_marketplace.enable = true;
    let latest_configs = vec![config("fresh", "ext", true, Platform::Universal, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
    let (logs, result) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_has_line(&lines, "[vscode-marketplace] Target start");
    assert_has_line(&lines, "[vscode-marketplace] Latest-page fetch start");
    assert_has_line(&lines, "[vscode-marketplace] Prefetch start");
    assert_no_line(&lines, "Open VSX prerelease candidate");
    assert_no_line(&lines, "Release-config fetch");
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

    let latest_configs = vec![
            config("fresh", "ext", false, Platform::Universal, "2.0.0"),
            config("fresh", "ext", false, Platform::Universal, "2.1.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let (logs, result) = capture_pipeline_logs(&env.config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_has_line(
        &lines,
        "[open-vsx] Open VSX prerelease candidates from latest: count=1",
    );
    assert_has_line(
        &lines,
        "[open-vsx] Open VSX prerelease candidate count from latest: 1",
    );
    assert_no_line(&lines, "cached_without_release");
    assert_no_line(&lines, "combined_unique_ids");
}

#[test]
fn zero_work_target_still_logs_prefetch_and_cache_lifecycle() {
    let env = TestEnv::new();
    let latest = MarketplaceFetchResult {
        configs: vec![],
        observed_platforms: observed_platforms_for(&[]),
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(Vec::new());
    let (logs, result) = capture_pipeline_logs(&env.config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_has_line(&lines, "[open-vsx] Processed (0/0) extensions failures=0");
    assert_has_line(
        &lines,
        "[open-vsx] Prefetch finish: fetched records=0 failed records=0",
    );
    assert_has_line(&lines, "[open-vsx] Cache write finish: merged cache count=0");
}

#[test]
fn prefetch_failures_log_context() {
    let env = TestEnv::new();
    let mut debug_config = env.config.clone();
    debug_config.log_severity = nix_vscode_extensions_updater::config::LogSeverity::Debug;
    let latest_configs = vec![config("broken", "ext", true, Platform::LinuxX64, "2.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = FakePrefetcher::new(vec![Err(anyhow::anyhow!("stderr exploded"))]);
    let (logs, result) = capture_pipeline_logs(&debug_config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    let start = find_line(&lines, "[open-vsx] Prefetch start extension=broken.ext");
    assert!(start.contains("extension=broken.ext"));
    assert!(start.contains("version=2.0.0"));
    assert!(start.contains("platform=linux-x64"));
    assert!(start.contains("target=open-vsx"));
    assert!(start.contains(
        "url=https://open-vsx.org/api/broken/ext/linux-x64/2.0.0/file/broken.ext-2.0.0@linux-x64.vsix"
    ));
    let failure = find_line(&lines, "[open-vsx] Prefetch failed extension=broken.ext");
    assert!(failure.contains("extension=broken.ext"));
    assert!(failure.contains("version=2.0.0"));
    assert!(failure.contains("platform=linux-x64"));
    assert!(failure.contains("target=open-vsx"));
    assert!(failure.contains(
        "url=https://open-vsx.org/api/broken/ext/linux-x64/2.0.0/file/broken.ext-2.0.0@linux-x64.vsix"
    ));
}

#[test]
fn prefetch_success_logs_at_info() {
    let env = TestEnv::new();
    let latest_configs = vec![config("ok", "ext", true, Platform::Universal, "1.0.0")];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
    let mut debug_config = env.config.clone();
    debug_config.log_severity = nix_vscode_extensions_updater::config::LogSeverity::Debug;
    let (logs, result) = capture_pipeline_logs(&debug_config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_line_prefix(&lines, "DEBUG", "[open-vsx] Prefetch start extension=ok.ext");
    assert_line_prefix(&lines, "INFO", "[open-vsx] Prefetch success extension=ok.ext");
    assert_eq!(
        info_lines(&lines)
            .into_iter()
            .filter(|line| line.contains("Prefetch success"))
            .count(),
        1
    );
}

#[test]
fn progress_logging_emits_updates_and_failure_counts() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.processed_logger_delay = 0;
    let latest_configs = vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
    let (logs, result) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    result.unwrap();

    let lines = logs.lines();
    assert_has_line(&lines, "[open-vsx] Processed (1/2) extensions failures=0");
    assert_has_line(&lines, "[open-vsx] Processed (2/2) extensions failures=1");
}

#[test]
fn prefetch_runs_concurrently_with_a_bounded_cap() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.artifact_prefetch_threads = Some(2);
    let latest_configs = vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
            config("three", "ext", true, Platform::Universal, "1.0.0"),
            config("four", "ext", true, Platform::Universal, "1.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
        pages_failed: vec![],
        pages_fetched: vec!["page-1".into()],
    };
    let marketplace = FakeMarketplace::new(latest);
    let prefetcher = Arc::new(TrackingPrefetcher::new());
    let (logs, result) = capture_pipeline_logs(&app_config, &marketplace, prefetcher.as_ref());
    result.unwrap();

    assert_eq!(prefetcher.max_active(), 2);
    let lines = logs.lines();
    assert_has_line(
        &lines,
        "[open-vsx] Prefetch finish: fetched records=4 failed records=0",
    );
}

#[test]
fn concurrent_prefetch_collects_successes_and_failures_once_each() {
    let env = TestEnv::new();
    let mut app_config = env.config.clone();
    app_config.open_vsx.artifact_prefetch_threads = Some(2);
    let latest_configs = vec![
            config("one", "ext", true, Platform::Universal, "1.0.0"),
            config("two", "ext", true, Platform::Universal, "1.0.0"),
            config("three", "ext", true, Platform::Universal, "1.0.0"),
        ];
    let latest = MarketplaceFetchResult {
        observed_platforms: observed_platforms_for(&latest_configs),
        configs: latest_configs,
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
    let (logs, result) = capture_pipeline_logs(&app_config, &marketplace, &prefetcher);
    result.unwrap();
    assert_eq!(count_lines(&logs.lines(), "Prefetch failed"), 1);

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
