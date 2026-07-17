use crate::cache::{
    cache_path, debug_path, ensure_empty_file, read_jsonl_cache, tmp_path, write_json_pretty,
    write_jsonl, write_jsonl_cache,
};
use crate::config::AppConfig;
use crate::logging::{Level, Logger};
use crate::marketplace::MarketplaceClient;
use crate::model::{CacheRecord, ExtensionConfig, Name, Publisher, Target};
use crate::prefetch::Prefetcher;
use anyhow::Context;
use std::collections::{HashMap, HashSet};

pub struct Pipeline<'a, M, P, L> {
    pub config: &'a AppConfig,
    pub marketplace: &'a M,
    pub prefetcher: &'a P,
    pub logger: &'a L,
}

impl<'a, M, P, L> Pipeline<'a, M, P, L>
where
    M: MarketplaceClient,
    P: Prefetcher,
    L: Logger,
{
    pub fn run(&self) -> anyhow::Result<()> {
        self.ensure_dirs()?;
        for target in self.config.enabled_targets() {
            self.run_target(target)?;
        }
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
        ensure_empty_file(&cache_file)?;
        let cached = read_jsonl_cache(&cache_file)?;

        self.logger.log(Level::Info, &format!("[{site}] start"));
        let latest = self.fetch_latest(target.clone())?;
        let release = if matches!(target, Target::OpenVsx) {
            let ids = prerelease_ids(&latest.configs, &cached);
            write_jsonl(&debug_path(&self.config.data_dir, site, "ids-pre-release-configs"), &ids)?;
            self.marketplace
                .fetch_release_configs(target.clone(), &ids)
                .context("failed to fetch release configs")?
        } else {
            Vec::new()
        };

        let mut fetched = latest.configs;
        fetched.extend(release);
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

        let mut fetched_records = Vec::new();
        let mut failed_records = Vec::new();
        for config in &fetched_not_cached {
            match self
                .prefetcher
                .prefetch(target.clone(), config, self.config.request_response_timeout)
            {
                Ok(record) => fetched_records.push(record),
                Err(err) => {
                    failed_records.push(config.clone());
                    self.logger
                        .log(Level::Error, &format!("[{site}] prefetch failed: {err:#}"));
                }
            }
        }

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
        write_jsonl_cache(&cache_file, &merged)?;

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

        self.logger.log(Level::Info, &format!("[{site}] processed {}", fetched_not_cached.len()));
        self.logger.log(Level::Info, &format!("[{site}] failed {}", failed_records.len()));
        self.logger.log(Level::Info, &format!("[{site}] finish"));
        Ok(())
    }

    fn fetch_latest(&self, target: Target) -> anyhow::Result<crate::marketplace::MarketplaceFetchResult> {
        let site = site_name(&target);
        let site_cfg = match target {
            Target::VscodeMarketplace => &self.config.vscode_marketplace,
            Target::OpenVsx => &self.config.open_vsx,
        };
        let result = self
            .marketplace
            .fetch_latest(target, site_cfg)
            .with_context(|| format!("failed to fetch latest configs for {site}"))?;
        write_json_pretty(
            &debug_path(&self.config.data_dir, site, "pages-failed"),
            &result.pages_failed,
        )?;
        write_json_pretty(
            &debug_path(&self.config.data_dir, site, "pages-fetched"),
            &result.pages_fetched,
        )?;
        Ok(result)
    }
}

fn site_name(target: &Target) -> &'static str {
    match target {
        Target::VscodeMarketplace => "vscode-marketplace",
        Target::OpenVsx => "open-vsx",
    }
}

fn prerelease_ids(latest: &[ExtensionConfig], cached: &[CacheRecord]) -> Vec<(Publisher, Name)> {
    let mut ids = HashSet::new();
    for config in latest.iter().filter(|config| !config.is_release.0) {
        ids.insert((config.publisher.clone(), config.name.clone()));
    }
    let cached_pre = cached
        .iter()
        .filter(|record| !record.is_release.0)
        .map(|record| (record.publisher.clone(), record.name.clone()))
        .collect::<HashSet<_>>();
    let cached_release = cached
        .iter()
        .filter(|record| record.is_release.0)
        .map(|record| (record.publisher.clone(), record.name.clone()))
        .collect::<HashSet<_>>();
    ids.extend(cached_pre.difference(&cached_release).cloned());
    ids.into_iter().collect()
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
