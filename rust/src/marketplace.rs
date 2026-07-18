use crate::config::SiteConfig;
use crate::model::{
    EngineVersion, ExtensionConfig, IsRelease, Name, ObservedVersionKey, Platform, Publisher,
    Target, Version,
};
use anyhow::{anyhow, Context};
use rayon::prelude::*;
use reqwest::blocking::Client;
use serde_json::Value;
use std::collections::{BTreeMap, BTreeSet};
use std::time::Duration;

pub type ObservedPlatformMap = BTreeMap<ObservedVersionKey, BTreeSet<Platform>>;

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct MarketplaceFetchResult {
    pub configs: Vec<ExtensionConfig>,
    pub observed_platforms: ObservedPlatformMap,
    pub pages_failed: Vec<String>,
    pub pages_fetched: Vec<String>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReleaseLookupFailure {
    pub publisher: Publisher,
    pub name: Name,
    pub error: String,
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct ReleaseConfigFetchResult {
    pub configs: Vec<ExtensionConfig>,
    pub observed_platforms: ObservedPlatformMap,
    pub failures: Vec<ReleaseLookupFailure>,
}

pub trait MarketplaceClient {
    fn fetch_latest(&self, target: Target, site: &SiteConfig) -> anyhow::Result<MarketplaceFetchResult>;
    fn fetch_release_configs(
        &self,
        target: Target,
        ids: &[(Publisher, Name)],
    ) -> anyhow::Result<ReleaseConfigFetchResult>;
}

pub struct HttpMarketplaceClient {
    client: Client,
}

impl HttpMarketplaceClient {
    pub fn new(timeout_seconds: u64) -> anyhow::Result<Self> {
        Ok(Self {
            client: Client::builder()
                .timeout(Duration::from_secs(timeout_seconds))
                .build()?,
        })
    }

    fn api_url(target: &Target) -> &'static str {
        match target {
            Target::VscodeMarketplace => "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery",
            Target::OpenVsx => "https://open-vsx.org/vscode/gallery/extensionquery",
        }
    }

    fn request_body(page_number: usize, page_size: usize, target: &Target) -> Value {
        let flags = match target {
            Target::VscodeMarketplace => 0x10 | 0x20 | 0x10000,
            Target::OpenVsx => 0x10 | 0x20 | 0x200,
        };
        serde_json::json!({
            "filters": [{
                "criteria": [
                    {"filterType": 8, "value": "Microsoft.VisualStudio.Code"},
                    {"filterType": 12, "value": "4096"}
                ],
                "pageNumber": page_number,
                "pageSize": page_size,
                "sortBy": 2,
                "sortOrder": 2
            }],
            "assetTypes": [],
            "flags": flags
        })
    }

    fn fetch_page(&self, target: &Target, page_number: usize, page_size: usize) -> anyhow::Result<String> {
        let response = self
            .client
            .post(Self::api_url(target))
            .header("content-type", "application/json")
            .header("accept", "application/json; api-version=6.1-preview.1")
            .header("accept-encoding", "gzip")
            .json(&Self::request_body(page_number, page_size, target))
            .send()
            .with_context(|| format!("failed to fetch page {page_number}"))?
            .error_for_status()
            .with_context(|| format!("bad status for page {page_number}"))?;
        response.text().context("failed to read page body")
    }

    fn fetch_one_release(&self, target: &Target, publisher: &Publisher, name: &Name) -> anyhow::Result<String> {
        let response = self
            .client
            .post(Self::api_url(target))
            .header("content-type", "application/json")
            .header("accept", "application/json; api-version=6.1-preview.1")
            .header("accept-encoding", "gzip")
            .json(&serde_json::json!({
                "filters": [{
                    "criteria": [
                        {"filterType": 8, "value": "Microsoft.VisualStudio.Code"},
                        {"filterType": 7, "value": format!("{}.{}", publisher.0, name.0)},
                        {"filterType": 12, "value": "4096"}
                    ],
                    "pageNumber": 1,
                    "pageSize": 1,
                    "sortBy": 0,
                    "sortOrder": 0
                }],
                "assetTypes": [],
                "flags": 0x10 | 0x20
            }))
            .send()
            .with_context(|| format!("failed to fetch release for {}.{}", publisher.0, name.0))?
            .error_for_status()
            .context("bad release status")?;
        response.text().context("failed to read release body")
    }
}

impl MarketplaceClient for HttpMarketplaceClient {
    fn fetch_latest(&self, target: Target, site: &SiteConfig) -> anyhow::Result<MarketplaceFetchResult> {
        let pool = rayon::ThreadPoolBuilder::new()
            .num_threads(site.metadata_fetch_threads)
            .build()?;
        let results = pool.install(|| {
            (1..=site.page_count)
                .into_par_iter()
                .map(|page_number| match self.fetch_page(&target, page_number, site.page_size) {
                    Ok(body) => Ok((page_number, body)),
                    Err(err) => Err(format!("{err:#}")),
                })
                .collect::<Vec<_>>()
        });
        let mut pages_failed = Vec::new();
        let mut pages_fetched = Vec::new();
        let mut configs = Vec::new();
        let mut observed_platforms = ObservedPlatformMap::new();
        for result in results {
            match result {
                Ok((_, body)) => {
                    pages_fetched.push(body.clone());
                    let parsed = parse_latest_response_with_observed(&body)?;
                    configs.extend(parsed.configs);
                    merge_observed_platforms(&mut observed_platforms, parsed.observed_platforms);
                }
                Err(err) => pages_failed.push(err),
            }
        }
        Ok(MarketplaceFetchResult {
            configs,
            observed_platforms,
            pages_failed,
            pages_fetched,
        })
    }

    fn fetch_release_configs(
        &self,
        target: Target,
        ids: &[(Publisher, Name)],
    ) -> anyhow::Result<ReleaseConfigFetchResult> {
        let pool = rayon::ThreadPoolBuilder::new().num_threads(ids.len().max(1)).build()?;
        let results = pool.install(|| {
            ids.par_iter()
                .map(|(publisher, name)| match self.fetch_one_release(&target, publisher, name) {
                    Ok(body) => Ok(((publisher.clone(), name.clone()), body)),
                    Err(err) => Err(ReleaseLookupFailure {
                        publisher: publisher.clone(),
                        name: name.clone(),
                        error: format!("{err:#}"),
                    }),
                })
                .collect::<Vec<_>>()
        });
        let mut configs = Vec::new();
        let mut observed_platforms = ObservedPlatformMap::new();
        let mut failures = Vec::new();
        for result in results {
            match result {
                Ok((_, body)) => {
                    let parsed = parse_release_response_with_observed(&body)?;
                    configs.extend(parsed.configs);
                    merge_observed_platforms(&mut observed_platforms, parsed.observed_platforms);
                }
                Err(err) => failures.push(err),
            }
        }
        Ok(ReleaseConfigFetchResult {
            configs,
            observed_platforms,
            failures,
        })
    }
}

pub fn parse_latest_response(body: &str) -> anyhow::Result<Vec<ExtensionConfig>> {
    Ok(parse_latest_response_with_observed(body)?.configs)
}

pub fn parse_release_response(body: &str) -> anyhow::Result<Vec<ExtensionConfig>> {
    Ok(parse_release_response_with_observed(body)?.configs)
}

fn parse_latest_response_with_observed(body: &str) -> anyhow::Result<MarketplaceFetchResult> {
    let value: Value = serde_json::from_str(body)?;
    let mut out = Vec::new();
    let mut observed_platforms = ObservedPlatformMap::new();
    let extensions = value
        .pointer("/results/0/extensions")
        .and_then(Value::as_array)
        .ok_or_else(|| anyhow!("missing extensions"))?;
    for ext in extensions {
        if !flags_allowed(ext) {
            continue;
        }
        let name = Name(ext.get("extensionName").and_then(Value::as_str).unwrap_or_default().to_string());
        let publisher = Publisher(
            ext.pointer("/publisher/publisherName")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string(),
        );
        let versions = ext.get("versions").and_then(Value::as_array).cloned().unwrap_or_default();
        for version_value in versions {
            if let Some(cfg) = parse_version_object(&version_value, &publisher, &name)? {
                note_observed_platform(&mut observed_platforms, &cfg);
                out.push(cfg);
            }
        }
    }
    Ok(MarketplaceFetchResult {
        configs: out,
        observed_platforms,
        pages_failed: Vec::new(),
        pages_fetched: Vec::new(),
    })
}

fn parse_release_response_with_observed(body: &str) -> anyhow::Result<ReleaseConfigFetchResult> {
    let value: Value = serde_json::from_str(body)?;
    let mut out = Vec::new();
    let mut observed_platforms = ObservedPlatformMap::new();
    let extensions = value
        .pointer("/results/0/extensions")
        .and_then(Value::as_array)
        .ok_or_else(|| anyhow!("missing extensions"))?;
    for ext in extensions {
        if !flags_allowed(ext) {
            continue;
        }
        let name = Name(ext.get("extensionName").and_then(Value::as_str).unwrap_or_default().to_string());
        let publisher = Publisher(
            ext.pointer("/publisher/publisherName")
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string(),
        );
        let versions = ext.get("versions").and_then(Value::as_array).cloned().unwrap_or_default();
        let mut per_platform = BTreeMap::<Platform, ExtensionConfig>::new();
        for version_value in versions {
            if let Some(cfg) = parse_version_object(&version_value, &publisher, &name)? {
                if cfg.is_release.0 {
                    note_observed_platform(&mut observed_platforms, &cfg);
                    per_platform.entry(cfg.platform).or_insert(cfg);
                }
            }
        }
        out.extend(per_platform.into_values());
    }
    Ok(ReleaseConfigFetchResult {
        configs: out,
        observed_platforms,
        failures: Vec::new(),
    })
}

fn flags_allowed(ext: &Value) -> bool {
    ext.get("flags")
        .and_then(Value::as_str)
        .map(|flags| {
            flags
                .split(", ")
                .filter(|s| !s.is_empty())
                .all(|flag| matches!(flag, "public" | "preview" | "validated" | "verified" | "trial"))
        })
        .unwrap_or(true)
}

fn parse_version_object(version: &Value, publisher: &Publisher, name: &Name) -> anyhow::Result<Option<ExtensionConfig>> {
    let version_value = match version.get("version").and_then(Value::as_str) {
        Some(version) => Version::parse(version).map_err(anyhow::Error::msg)?,
        None => return Ok(None),
    };
    let platform = match version.get("targetPlatform").and_then(Value::as_str) {
        Some("linux-x64") => Platform::LinuxX64,
        Some("linux-arm64") => Platform::LinuxArm64,
        Some("darwin-x64") => Platform::DarwinX64,
        Some("darwin-arm64") => Platform::DarwinArm64,
        Some(_) | None => Platform::Universal,
    };
    let properties = version
        .get("properties")
        .and_then(Value::as_array)
        .cloned()
        .unwrap_or_default();
    let engine_version = properties
        .iter()
        .find(|prop| prop.get("key").and_then(Value::as_str) == Some("Microsoft.VisualStudio.Code.Engine"))
        .and_then(|prop| prop.get("value"))
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow!("missing engine version"))?;
    let is_release = !properties
        .iter()
        .any(|prop| prop.get("key").and_then(Value::as_str) == Some("Microsoft.VisualStudio.Code.PreRelease"));
    Ok(Some(ExtensionConfig {
        publisher: publisher.clone(),
        name: name.clone(),
        is_release: IsRelease(is_release),
        platform,
        version: version_value,
        engine_version: EngineVersion::parse(engine_version).map_err(anyhow::Error::msg)?,
    }))
}

fn note_observed_platform(observed_platforms: &mut ObservedPlatformMap, config: &ExtensionConfig) {
    observed_platforms
        .entry(config.observed_version_key())
        .or_default()
        .insert(config.platform);
}

fn merge_observed_platforms(target: &mut ObservedPlatformMap, source: ObservedPlatformMap) {
    for (key, platforms) in source {
        target.entry(key).or_default().extend(platforms);
    }
}

#[allow(dead_code)]
fn _dedup_ids(ids: &[(Publisher, Name)]) -> Vec<(Publisher, Name)> {
    let mut set = BTreeSet::new();
    ids.iter().cloned().filter(|id| set.insert(id.clone())).collect()
}
