use crate::cache::{
    cache_path, debug_path, read_jsonl_cache, tmp_path, write_json_pretty, write_jsonl,
    write_jsonl_cache,
};
use crate::config::{AppConfig, SiteConfig};
use crate::logging::{stage, Level, Logger};
use crate::marketplace::{
    MarketplaceClient, MarketplaceFetchResult, ReleaseConfigFetchResult, ReleaseLookupFailure,
};
use crate::model::{CacheRecord, ExtensionConfig, Name, Publisher, Target};
use crate::prefetch::{PrefetchLogContext, Prefetcher};
use anyhow::Context;
use rayon::prelude::*;
use rayon::ThreadPoolBuilder;
use std::collections::{HashMap, HashSet};
use std::sync::Mutex;
use std::thread;
use std::time::{Duration, Instant};

pub struct Pipeline<'a, M, P, L> {
    pub config: &'a AppConfig,
    pub marketplace: &'a M,
    pub prefetcher: &'a P,
    pub logger: &'a L,
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

struct ProgressTracker<'a, L> {
    logger: &'a L,
    site: &'a str,
    delay: Duration,
    total: usize,
    processed: usize,
    failures: usize,
    last_log: Option<Instant>,
}

impl<'a, L> ProgressTracker<'a, L>
where
    L: Logger,
{
    fn new(logger: &'a L, site: &'a str, delay_seconds: u64, total: usize) -> Self {
        Self {
            logger,
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
        let failure_suffix = if self.failures == 0 {
            String::new()
        } else {
            format!(", failures={}", self.failures)
        };
        self.logger.log(
            Level::Info,
            &stage(
                self.site,
                &format!(
                    "Processed ({}/{}) extensions{}",
                    self.processed, self.total, failure_suffix
                ),
            ),
        );
    }
}

impl<'a, M, P, L> Pipeline<'a, M, P, L>
where
    M: MarketplaceClient,
    P: Prefetcher + Sync,
    L: Logger + Sync,
{
    pub fn run(&self) -> anyhow::Result<()> {
        self.ensure_dirs()?;
        let enabled_targets = self.config.enabled_targets();
        self.logger
            .log(Level::Info, &stage("run", "Starting extension updater run"));
        self.logger.log(
            Level::Info,
            &stage(
                "run",
                &format!(
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
                ),
            ),
        );

        for target in enabled_targets {
            self.run_target(target)?;
        }

        self.logger
            .log(Level::Info, &stage("run", "Finished extension updater run"));
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

        self.logger.log(Level::Info, &stage(site, "Target start"));
        self.logger.log(
            Level::Info,
            &stage(site, &format!("Cached record count before work: {}", cached.len())),
        );

        let latest = self.fetch_latest(target.clone())?;
        let latest_prerelease_ids = prerelease_ids_from_latest(&latest.configs);

        let release = if matches!(target, Target::OpenVsx) {
            let ids = latest_prerelease_ids.iter().cloned().collect::<Vec<_>>();
            self.logger.log(
                Level::Info,
                &stage(
                    site,
                    &format!(
                        "Open VSX prerelease candidates from latest: count={}",
                        latest_prerelease_ids.len(),
                    ),
                ),
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

        self.logger.log(Level::Info, &stage(site, "Cache write start"));
        write_jsonl_cache(&cache_file, &merged)?;
        self.logger.log(
            Level::Info,
            &stage(site, &format!("Cache write finish: merged cache count={}", merged.len())),
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
        self.logger.log(Level::Info, &stage(site, "Target finish"));
        Ok(())
    }

    fn prefetch_missing(
        &self,
        target: Target,
        site: &str,
        site_config: &SiteConfig,
        fetched_not_cached: &[ExtensionConfig],
    ) -> (Vec<CacheRecord>, Vec<ExtensionConfig>) {
        self.logger.log(Level::Info, &stage(site, "Prefetch start"));
        let progress = Mutex::new(ProgressTracker::new(
            self.logger,
            site,
            self.config.processed_logger_delay,
            fetched_not_cached.len(),
        ));
        let pool = ThreadPoolBuilder::new()
            .num_threads(site_config.effective_artifact_prefetch_threads())
            .build()
            .expect("prefetch thread pool should build");
        let results = pool.install(|| {
            fetched_not_cached
                .par_iter()
                .map(|config| {
                    let context = PrefetchLogContext::new(target.clone(), config);
                    let result = self
                        .prefetcher
                        .prefetch(target.clone(), config, self.config.request_response_timeout);
                    match result {
                        Ok(record) => {
                            self.logger.log(
                                Level::Debug,
                                &stage(site, &format!("Prefetch success: {}", context.render())),
                            );
                            progress.lock().unwrap().record(false);
                            Ok(record)
                        }
                        Err(err) => {
                            self.logger.log(
                                Level::Error,
                                &stage(site, &format!("Prefetch failed: {} error={err:#}", context.render())),
                            );
                            progress.lock().unwrap().record(true);
                            Err(config.clone())
                        }
                    }
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
        self.logger.log(
            Level::Info,
            &stage(
                site,
                &format!(
                    "Prefetch finish: fetched records={} failed records={}",
                    fetched_records.len(),
                    failed_records.len()
                ),
            ),
        );
        (fetched_records, failed_records)
    }

    fn fetch_latest(&self, target: Target) -> anyhow::Result<MarketplaceFetchResult> {
        let site = site_name(&target);
        let site_cfg = site_config(self.config, &target);
        self.logger.log(Level::Info, &stage(site, "Latest-page fetch start"));
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
        self.logger.log(
            Level::Info,
            &stage(
                site,
                &format!(
                    "Latest-page fetch finish: requested_pages={} page_size={} metadata_fetch_threads={} succeeded_pages={} failed_pages={} latest_configs={}",
                    site_cfg.page_count,
                    site_cfg.page_size,
                    site_cfg.metadata_fetch_threads,
                    result.pages_fetched.len(),
                    result.pages_failed.len(),
                    result.configs.len()
                ),
            ),
        );
        Ok(result)
    }

    fn fetch_release_configs(
        &self,
        target: Target,
        ids: &[(Publisher, Name)],
    ) -> anyhow::Result<ReleaseConfigFetchResult> {
        let site = site_name(&target);
        self.logger.log(Level::Info, &stage(site, "Release-config fetch start"));
        let result = self
            .retry(site, "release-config fetch", || {
                self.marketplace.fetch_release_configs(target.clone(), ids)
            })
            .context("failed to fetch release configs")?;
        self.logger.log(
            Level::Info,
            &stage(
                site,
                &format!(
                    "Release-config fetch finish: attempted_ids={} succeeded_responses={} failed_responses={} parsed_configs={}",
                    ids.len(),
                    ids.len().saturating_sub(result.failures.len()),
                    result.failures.len(),
                    result.configs.len()
                ),
            ),
        );
        if !result.failures.is_empty() {
            self.logger.log(
                Level::Info,
                &stage(
                    site,
                    &format!("Release lookups failed for {} extensions", result.failures.len()),
                ),
            );
            for failure in &result.failures {
                self.log_release_failure(site, failure);
            }
        }
        Ok(result)
    }

    fn log_release_failure(&self, site: &str, failure: &ReleaseLookupFailure) {
        self.logger.log(
            Level::Debug,
            &stage(
                site,
                &format!(
                    "Release lookup failure: {}.{} error={}",
                    failure.publisher, failure.name, failure.error
                ),
            ),
        );
    }

    fn log_target_summary(&self, target: &Target, site: &str, counts: StageCounts) {
        self.logger.log(
            Level::Info,
            &stage(site, &format!("Latest configs fetched count: {}", counts.latest_config_count)),
        );
        if matches!(target, Target::OpenVsx) {
            self.logger.log(
                Level::Info,
                &stage(
                    site,
                    &format!(
                        "Open VSX prerelease candidate count from latest: {}",
                        counts.latest_prerelease_count
                    ),
                ),
            );
        }
        self.logger.log(
            Level::Info,
            &stage(
                site,
                &format!(
                    "Fetched-not-cached={} cached-present-and-fetched={} cached-not-fetched={}",
                    counts.fetched_not_cached_count,
                    counts.cached_present_and_fetched_count,
                    counts.cached_not_fetched_count
                ),
            ),
        );
        self.logger.log(
            Level::Info,
            &stage(
                site,
                &format!(
                    "Fetched records count={} failed records count={} merged cache count={}",
                    counts.fetched_record_count, counts.failed_record_count, counts.merged_cache_count
                ),
            ),
        );
    }

    fn retry<T, F>(&self, site: &str, phase: &str, mut op: F) -> anyhow::Result<T>
    where
        F: FnMut() -> anyhow::Result<T>,
    {
        let total_attempts = self.config.n_retry + 1;
        for attempt in 1..=total_attempts {
            self.logger.log(
                Level::Debug,
                &stage(site, &format!("{phase} attempt {attempt}/{total_attempts} start")),
            );
            match op() {
                Ok(value) => {
                    if attempt > 1 {
                        self.logger.log(
                            Level::Info,
                            &stage(site, &format!("{phase} recovered on attempt {attempt}/{total_attempts}")),
                        );
                    }
                    return Ok(value);
                }
                Err(err) if attempt < total_attempts => {
                    self.logger.log(
                        Level::Error,
                        &stage(
                            site,
                            &format!(
                                "{phase} attempt {attempt}/{total_attempts} failed; retrying in {}s: {err:#}",
                                self.config.retry_delay
                            ),
                        ),
                    );
                    thread::sleep(Duration::from_secs(self.config.retry_delay));
                }
                Err(err) => {
                    self.logger.log(
                        Level::Error,
                        &stage(
                            site,
                            &format!("{phase} exhausted after {attempt}/{total_attempts} attempts: {err:#}"),
                        ),
                    );
                    return Err(err);
                }
            }
        }
        unreachable!("retry loop must return")
    }
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
