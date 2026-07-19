use crate::cache::{
    cache_path, debug_path, read_jsonl_cache, tmp_path, write_json_pretty, write_jsonl,
    write_jsonl_cache,
};
use crate::config::{AppConfig, SiteConfig};
use crate::logging::{lifecycle_field, Lifecycle};
use crate::marketplace::{
    MarketplaceClient, MarketplaceFetchResult, ObservedPlatformMap, ReleaseConfigFetchResult,
    ReleaseLookupFailure,
};
use crate::model::{CacheRecord, ExtensionConfig, Name, Platform, Publisher, Target};
use crate::prefetch::{is_expected_missing_artifact_error, PrefetchLogContext, Prefetcher};
use anyhow::Context;
use rayon::prelude::*;
use rayon::ThreadPoolBuilder;
use serde::Serialize;
use std::collections::{HashMap, HashSet};
use std::sync::Mutex;
use std::thread;
use std::time::{Duration, Instant};
use tracing::dispatcher::Dispatch;

pub struct Pipeline<'a, M, P> {
    pub config: &'a AppConfig,
    pub marketplace: &'a M,
    pub prefetcher: &'a P,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct StageCounts {
    latest_prerelease_count: usize,
    latest_config_count: usize,
    fetched_not_cached_count: usize,
    cached_present_and_fetched_count: usize,
    cached_not_fetched_count: usize,
    fetched_record_count: usize,
    failed_record_count: usize,
    merged_cache_count: usize,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
struct SkippedOpenVsxPrefetch {
    config: ExtensionConfig,
    observed_platforms: Vec<Platform>,
}

struct ProgressTracker<'a> {
    site: &'a str,
    delay: Duration,
    total: usize,
    processed: usize,
    failures: usize,
    last_log: Option<Instant>,
}

impl<'a> ProgressTracker<'a> {
    fn new(site: &'a str, delay_seconds: u64, total: usize) -> Self {
        Self {
            site,
            delay: Duration::from_secs(delay_seconds),
            total,
            processed: 0,
            failures: 0,
            last_log: None,
        }
    }

    fn record(&mut self, failed: bool) {
        self.processed += 1;
        if failed {
            self.failures += 1;
        }
        let now = Instant::now();
        let should_log = self
            .last_log
            .map(|last| now.duration_since(last) >= self.delay)
            .unwrap_or(true);
        if should_log {
            self.log();
            self.last_log = Some(now);
        }
    }

    fn finish(&mut self) {
        self.log();
        self.last_log = Some(Instant::now());
    }

    fn log(&self) {
        if self.failures > 0 {
            tracing::warn!(
                stage = self.site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!("Processed ({}/{}) extensions", self.processed, self.total),
                failures = self.failures,
            );
        } else {
            tracing::info!(
                stage = self.site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!("Processed ({}/{}) extensions", self.processed, self.total),
                failures = self.failures,
            );
        }
    }
}

impl<'a, M, P> Pipeline<'a, M, P>
where
    M: MarketplaceClient,
    P: Prefetcher + Sync,
{
    pub fn run(&self) -> anyhow::Result<()> {
        self.ensure_dirs()?;
        let enabled_targets = self.config.enabled_targets();
        tracing::info!(
            stage = "run",
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Starting extension updater run"
        );
        tracing::info!(
            stage = "run",
            lifecycle = lifecycle_field(Lifecycle::Info),
            summary = %format!(
                "Config summary: data_dir={} targets={} processed_logger_delay={}s n_retry={} retry_delay={}s program_timeout={}s request_response_timeout={}s queue_capacity={}",
                self.config.data_dir.display(),
                enabled_targets
                    .iter()
                    .map(ToString::to_string)
                    .collect::<Vec<_>>()
                    .join(","),
                self.config.processed_logger_delay,
                self.config.n_retry,
                self.config.retry_delay,
                self.config.program_timeout,
                self.config.request_response_timeout,
                self.config.queue_capacity
            )
        );

        for target in enabled_targets {
            self.run_target(target)?;
        }

        tracing::info!(
            stage = "run",
            lifecycle = lifecycle_field(Lifecycle::Finish),
            summary = "Finished extension updater run"
        );
        Ok(())
    }

    fn ensure_dirs(&self) -> anyhow::Result<()> {
        let root = &self.config.data_dir;
        std::fs::create_dir_all(root.join("cache"))?;
        std::fs::create_dir_all(root.join("debug"))?;
        std::fs::create_dir_all(root.join("tmp").join("fetched"))?;
        std::fs::create_dir_all(root.join("tmp").join("failed"))?;
        Ok(())
    }

    fn run_target(&self, target: Target) -> anyhow::Result<()> {
        let site = site_name(&target);
        let cache_file = cache_path(&self.config.data_dir, site);
        let cached = read_jsonl_cache(&cache_file)?;

        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Target start"
        );
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Info),
            summary = %format!("Cached record count before work: {}", cached.len())
        );

        let latest = self.fetch_latest(target.clone())?;
        let latest_prerelease_ids = prerelease_ids_from_latest(&latest.configs);

        let release = if matches!(target, Target::OpenVsx) {
            let ids = latest_prerelease_ids.iter().cloned().collect::<Vec<_>>();
            tracing::info!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!(
                    "Open VSX prerelease candidates from latest: count={}",
                    latest_prerelease_ids.len(),
                )
            );
            write_jsonl(&debug_path(&self.config.data_dir, site, "ids-pre-release-configs"), &ids)?;
            self.fetch_release_configs(target.clone(), &ids)?
        } else {
            ReleaseConfigFetchResult::default()
        };

        let latest_config_count = latest.configs.len();
        let mut fetched = latest.configs;
        fetched.extend(release.configs);
        dedup_extension_configs(&mut fetched);
        let observed_platforms = merge_observed_platform_maps(latest.observed_platforms, release.observed_platforms);
        let (fetched, skipped_prefetch_configs) = if matches!(target, Target::OpenVsx) {
            filter_open_vsx_prefetch_configs(fetched, &observed_platforms)
        } else {
            (fetched, Vec::new())
        };

        if matches!(target, Target::OpenVsx) {
            write_jsonl(
                &self
                    .config
                    .data_dir
                    .join("debug")
                    .join(site)
                    .join("skipped-artifact-prefetches.jsonl"),
                &skipped_prefetch_configs,
            )?;
        }

        let cache_by_full: HashMap<_, _> = cached.iter().map(|r| (r.key_full(), r.clone())).collect();
        let fetched_by_full: HashMap<_, _> =
            fetched.iter().map(|c| (c.key_full(), c.clone())).collect();

        let cached_present_and_fetched: Vec<_> = cached
            .iter()
            .filter(|record| fetched_by_full.contains_key(&record.key_full()))
            .cloned()
            .collect();
        let cached_not_fetched: Vec<_> = cached
            .iter()
            .filter(|record| !fetched_by_full.contains_key(&record.key_full()))
            .cloned()
            .collect();
        let fetched_not_cached: Vec<_> = fetched
            .iter()
            .filter(|config| !cache_by_full.contains_key(&config.key_full()))
            .cloned()
            .collect();

        write_jsonl(
            &debug_path(&self.config.data_dir, site, "info-present-and-fetched"),
            &cached_present_and_fetched,
        )?;
        write_jsonl(
            &debug_path(&self.config.data_dir, site, "configs-fetched-not-cached"),
            &fetched_not_cached,
        )?;

        let (fetched_records, failed_records) =
            self.prefetch_missing(target.clone(), site, site_config(self.config, &target), &fetched_not_cached);

        write_jsonl(
            &tmp_path(&self.config.data_dir, "fetched", site),
            &fetched_records,
        )?;
        write_jsonl(
            &tmp_path(&self.config.data_dir, "failed", site),
            &failed_records,
        )?;

        let mut merged = Vec::new();
        merged.extend(fetched_records.clone());
        merged.extend(cached_not_fetched.clone());
        merged.extend(cached_present_and_fetched.clone());
        merged = dedup_latest(merged);
        merged.sort_by(|a, b| {
            a.publisher
                .0
                .cmp(&b.publisher.0)
                .then(a.name.0.cmp(&b.name.0))
                .then(a.is_release.cmp(&b.is_release))
                .then(a.platform.cmp(&b.platform))
                .then(a.version.cmp(&b.version))
        });

        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Cache write start"
        );
        write_jsonl_cache(&cache_file, &merged)?;
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Finish),
            summary = %format!("Cache write finish: merged cache count={}", merged.len())
        );

        write_jsonl(
            &debug_path(&self.config.data_dir, site, "cached-not-updated"),
            &cached_not_fetched,
        )?;
        write_jsonl(
            &debug_path(&self.config.data_dir, site, "updated-not-cached"),
            &fetched_records,
        )?;
        write_jsonl(
            &debug_path(&self.config.data_dir, site, "cached-and-updated"),
            &cached_present_and_fetched,
        )?;

        let counts = StageCounts {
            latest_prerelease_count: latest_prerelease_ids.len(),
            latest_config_count,
            fetched_not_cached_count: fetched_not_cached.len(),
            cached_present_and_fetched_count: cached_present_and_fetched.len(),
            cached_not_fetched_count: cached_not_fetched.len(),
            fetched_record_count: fetched_records.len(),
            failed_record_count: failed_records.len(),
            merged_cache_count: merged.len(),
        };
        self.log_target_summary(&target, site, counts);
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Finish),
            summary = "Target finish"
        );
        Ok(())
    }

    fn prefetch_missing(
        &self,
        target: Target,
        site: &str,
        site_config: &SiteConfig,
        fetched_not_cached: &[ExtensionConfig],
    ) -> (Vec<CacheRecord>, Vec<ExtensionConfig>) {
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Prefetch start"
        );
        let progress = Mutex::new(ProgressTracker::new(
            site,
            self.config.processed_logger_delay,
            fetched_not_cached.len(),
        ));
        let dispatch = current_dispatch();
        let pool = ThreadPoolBuilder::new()
            .num_threads(site_config.effective_artifact_prefetch_threads())
            .build()
            .expect("prefetch thread pool should build");
        let results = pool.install(|| {
            fetched_not_cached
                .par_iter()
                .map(|config| {
                    tracing::dispatcher::with_default(&dispatch, || {
                        let context = PrefetchLogContext::new(target.clone(), config);
                        tracing::debug!(
                            stage = site,
                            lifecycle = lifecycle_field(Lifecycle::Info),
                            summary = "Prefetch start",
                            extension = %context.extension_id,
                            version = %context.version,
                            platform = %context.platform,
                            target = %context.target,
                            url = %context.url,
                        );
                        let result = self
                            .prefetcher
                            .prefetch(target.clone(), config, self.config.request_response_timeout);
                        match result {
                            Ok(record) => {
                                tracing::info!(
                                    stage = site,
                                    lifecycle = lifecycle_field(Lifecycle::Info),
                                    summary = "Prefetch success",
                                    extension = %context.extension_id,
                                    version = %context.version,
                                    platform = %context.platform,
                                    target = %context.target,
                                    url = %context.url,
                                );
                                progress.lock().unwrap().record(false);
                                Ok(record)
                            }
                            Err(err) => {
                                if is_expected_missing_artifact_error(&err) {
                                    tracing::warn!(
                                        stage = site,
                                        lifecycle = lifecycle_field(Lifecycle::Info),
                                        summary = "Prefetch failed",
                                        extension = %context.extension_id,
                                        version = %context.version,
                                        platform = %context.platform,
                                        target = %context.target,
                                        url = %context.url,
                                        error = %format!("{err:#}"),
                                    );
                                } else {
                                    tracing::error!(
                                        stage = site,
                                        lifecycle = lifecycle_field(Lifecycle::Info),
                                        summary = "Prefetch failed",
                                        extension = %context.extension_id,
                                        version = %context.version,
                                        platform = %context.platform,
                                        target = %context.target,
                                        url = %context.url,
                                        error = %format!("{err:#}"),
                                    );
                                }
                                progress.lock().unwrap().record(true);
                                Err(config.clone())
                            }
                        }
                    })
                })
                .collect::<Vec<_>>()
        });
        let mut fetched_records = Vec::new();
        let mut failed_records = Vec::new();
        for result in results {
            match result {
                Ok(record) => fetched_records.push(record),
                Err(config) => failed_records.push(config),
            }
        }
        progress.lock().unwrap().finish();
        if failed_records.is_empty() {
            tracing::info!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Finish),
                summary = %format!(
                    "Prefetch finish: fetched records={} failed records={}",
                    fetched_records.len(),
                    failed_records.len()
                )
            );
        } else {
            tracing::warn!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Finish),
                summary = %format!(
                    "Prefetch finish: fetched records={} failed records={}",
                    fetched_records.len(),
                    failed_records.len()
                )
            );
        }
        (fetched_records, failed_records)
    }

    fn fetch_latest(&self, target: Target) -> anyhow::Result<MarketplaceFetchResult> {
        let site = site_name(&target);
        let site_cfg = site_config(self.config, &target);
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Latest-page fetch start"
        );
        let result = self
            .retry(site, "latest-page fetch", || self.marketplace.fetch_latest(target.clone(), site_cfg))
            .with_context(|| format!("failed to fetch latest configs for {site}"))?;
        write_json_pretty(
            &debug_path(&self.config.data_dir, site, "pages-failed"),
            &result.pages_failed,
        )?;
        write_json_pretty(
            &debug_path(&self.config.data_dir, site, "pages-fetched"),
            &result.pages_fetched,
        )?;
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Finish),
            summary = %format!(
                "Latest-page fetch finish: requested_pages={} page_size={} metadata_fetch_threads={} succeeded_pages={} failed_pages={} latest_configs={}",
                site_cfg.page_count,
                site_cfg.page_size,
                site_cfg.metadata_fetch_threads,
                result.pages_fetched.len(),
                result.pages_failed.len(),
                result.configs.len()
            )
        );
        Ok(result)
    }

    fn fetch_release_configs(
        &self,
        target: Target,
        ids: &[(Publisher, Name)],
    ) -> anyhow::Result<ReleaseConfigFetchResult> {
        let site = site_name(&target);
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Start),
            summary = "Release-config fetch start"
        );
        let result = self
            .retry(site, "release-config fetch", || {
                self.marketplace.fetch_release_configs(target.clone(), ids)
            })
            .context("failed to fetch release configs")?;
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Finish),
            summary = %format!(
                "Release-config fetch finish: attempted_ids={} succeeded_responses={} failed_responses={} parsed_configs={}",
                ids.len(),
                ids.len().saturating_sub(result.failures.len()),
                result.failures.len(),
                result.configs.len()
            )
        );
        if !result.failures.is_empty() {
            tracing::warn!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!("Release lookups failed for {} extensions", result.failures.len())
            );
            for failure in &result.failures {
                self.log_release_failure(site, failure);
            }
        }
        Ok(result)
    }

    fn log_release_failure(&self, site: &str, failure: &ReleaseLookupFailure) {
        tracing::warn!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Info),
            summary = "Release lookup failure",
            extension = %format!("{}.{}", failure.publisher, failure.name),
            error = %failure.error,
        );
    }

    fn log_target_summary(&self, target: &Target, site: &str, counts: StageCounts) {
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Info),
            summary = %format!("Latest configs fetched count: {}", counts.latest_config_count)
        );
        if matches!(target, Target::OpenVsx) {
            tracing::info!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!(
                    "Open VSX prerelease candidate count from latest: {}",
                    counts.latest_prerelease_count
                )
            );
        }
        tracing::info!(
            stage = site,
            lifecycle = lifecycle_field(Lifecycle::Info),
            summary = %format!(
                "Fetched-not-cached={} cached-present-and-fetched={} cached-not-fetched={}",
                counts.fetched_not_cached_count,
                counts.cached_present_and_fetched_count,
                counts.cached_not_fetched_count
            )
        );
        if counts.failed_record_count == 0 {
            tracing::info!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!(
                    "Fetched records count={} failed records count={} merged cache count={}",
                    counts.fetched_record_count, counts.failed_record_count, counts.merged_cache_count
                )
            );
        } else {
            tracing::warn!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!(
                    "Fetched records count={} failed records count={} merged cache count={}",
                    counts.fetched_record_count, counts.failed_record_count, counts.merged_cache_count
                )
            );
        }
    }

    fn retry<T, F>(&self, site: &str, phase: &str, mut op: F) -> anyhow::Result<T>
    where
        F: FnMut() -> anyhow::Result<T>,
    {
        let total_attempts = self.config.n_retry + 1;
        for attempt in 1..=total_attempts {
            tracing::debug!(
                stage = site,
                lifecycle = lifecycle_field(Lifecycle::Info),
                summary = %format!("{phase} attempt {attempt}/{total_attempts} start"),
                phase = phase,
                attempt = attempt,
                total_attempts = total_attempts,
            );
            match op() {
                Ok(value) => {
                    if attempt > 1 {
                        tracing::info!(
                            stage = site,
                            lifecycle = lifecycle_field(Lifecycle::Info),
                            summary = %format!("{phase} recovered on attempt {attempt}/{total_attempts}"),
                            phase = phase,
                            attempt = attempt,
                            total_attempts = total_attempts,
                        );
                    }
                    return Ok(value);
                }
                Err(err) if attempt < total_attempts => {
                    tracing::error!(
                        stage = site,
                        lifecycle = lifecycle_field(Lifecycle::Info),
                        summary = %format!(
                            "{phase} attempt {attempt}/{total_attempts} failed; retrying in {}s: {err:#}",
                            self.config.retry_delay
                        ),
                        phase = phase,
                        attempt = attempt,
                        total_attempts = total_attempts,
                        retry_delay_s = self.config.retry_delay,
                        error = %format!("{err:#}"),
                    );
                    thread::sleep(Duration::from_secs(self.config.retry_delay));
                }
                Err(err) => {
                    tracing::error!(
                        stage = site,
                        lifecycle = lifecycle_field(Lifecycle::Info),
                        summary = %format!(
                            "{phase} exhausted after {attempt}/{total_attempts} attempts: {err:#}"
                        ),
                        phase = phase,
                        attempt = attempt,
                        total_attempts = total_attempts,
                        error = %format!("{err:#}"),
                    );
                    return Err(err);
                }
            }
        }
        unreachable!("retry loop must return")
    }
}

fn current_dispatch() -> Dispatch {
    tracing::dispatcher::get_default(|dispatch| dispatch.clone())
}

fn site_config<'a>(config: &'a AppConfig, target: &Target) -> &'a SiteConfig {
    match target {
        Target::VscodeMarketplace => &config.vscode_marketplace,
        Target::OpenVsx => &config.open_vsx,
    }
}

fn site_name(target: &Target) -> &'static str {
    match target {
        Target::VscodeMarketplace => "vscode-marketplace",
        Target::OpenVsx => "open-vsx",
    }
}

fn prerelease_ids_from_latest(latest: &[ExtensionConfig]) -> HashSet<(Publisher, Name)> {
    latest
        .iter()
        .filter(|config| !config.is_release.0)
        .map(|config| (config.publisher.clone(), config.name.clone()))
        .collect()
}

fn dedup_extension_configs(configs: &mut Vec<ExtensionConfig>) {
    let mut seen = HashSet::new();
    configs.retain(|config| seen.insert(config.key_full()));
}

fn dedup_latest(records: Vec<CacheRecord>) -> Vec<CacheRecord> {
    let mut seen = HashSet::new();
    let mut out = Vec::new();
    for record in records {
        if seen.insert(record.key_latest()) {
            out.push(record);
        }
    }
    out
}

fn merge_observed_platform_maps(
    latest: ObservedPlatformMap,
    release: ObservedPlatformMap,
) -> ObservedPlatformMap {
    let mut merged = latest;
    for (key, platforms) in release {
        merged.entry(key).or_default().extend(platforms);
    }
    merged
}

fn filter_open_vsx_prefetch_configs(
    configs: Vec<ExtensionConfig>,
    observed_platforms: &ObservedPlatformMap,
) -> (Vec<ExtensionConfig>, Vec<SkippedOpenVsxPrefetch>) {
    let mut kept = Vec::new();
    let mut skipped = Vec::new();

    for config in configs {
        let observed = observed_platforms.get(&config.observed_version_key());
        let allowed = observed
            .map(|platforms| platforms.contains(&config.platform))
            .unwrap_or(false);

        if allowed {
            kept.push(config);
        } else {
            skipped.push(SkippedOpenVsxPrefetch {
                config,
                observed_platforms: observed
                    .map(|platforms| platforms.iter().copied().collect())
                    .unwrap_or_default(),
            });
        }
    }

    (kept, skipped)
}
