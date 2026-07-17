use crate::model::{CacheRecord, ExtensionConfig, Target};
use anyhow::{anyhow, Context};
use serde::Deserialize;
use std::process::Command;

pub trait Prefetcher: Send + Sync {
    fn prefetch(
        &self,
        target: Target,
        config: &ExtensionConfig,
        timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord>;
}

pub struct NixPrefetcher;

#[derive(Debug, Deserialize)]
struct PrefetchResponse {
    hash: String,
}

impl NixPrefetcher {
    fn url(target: Target, config: &ExtensionConfig) -> String {
        match target {
            Target::VscodeMarketplace => {
                let suffix = if config.platform == crate::model::Platform::Universal {
                    String::new()
                } else {
                    format!("targetPlatform={}", config.platform)
                };
                format!(
                    "https://{}.gallery.vsassets.io/_apis/public/gallery/publisher/{}/extension/{}/{}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?{}",
                    config.publisher.0,
                    config.publisher.0,
                    config.name.0,
                    config.version.raw(),
                    suffix
                )
            }
            Target::OpenVsx => {
                let platform_infix = if config.platform == crate::model::Platform::Universal {
                    String::new()
                } else {
                    format!("/{}", config.platform)
                };
                let platform_suffix = if config.platform == crate::model::Platform::Universal {
                    String::new()
                } else {
                    format!("@{}", config.platform)
                };
                format!(
                    "https://open-vsx.org/api/{}/{name}{platform_infix}/{version}/file/{}-{version}{platform_suffix}.vsix",
                    config.publisher.0,
                    config.publisher.0,
                    name = config.name.0,
                    version = config.version.raw(),
                    platform_infix = platform_infix,
                    platform_suffix = platform_suffix,
                )
            }
        }
    }
}

impl Prefetcher for NixPrefetcher {
    fn prefetch(
        &self,
        target: Target,
        config: &ExtensionConfig,
        timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        let ext_name = format!("{}.{}", config.publisher.0, config.name.0);
        let output = Command::new("nix")
            .args([
                "store",
                "prefetch-file",
                "--timeout",
                &timeout_seconds.to_string(),
                "--json",
                &Self::url(target, config),
                "--name",
                &format!("{ext_name}-{}-{}", config.version.raw(), config.platform),
            ])
            .output()
            .with_context(|| format!("failed to start prefetch for {ext_name}"))?;

        if !output.status.success() || !output.stderr.is_empty() {
            return Err(anyhow!(
                "prefetch failed for {ext_name}: {}",
                String::from_utf8_lossy(&output.stderr)
            ));
        }
        let response: PrefetchResponse = serde_json::from_slice(&output.stdout)?;
        Ok(CacheRecord {
            publisher: config.publisher.clone(),
            name: config.name.clone(),
            is_release: config.is_release,
            platform: config.platform,
            version: config.version.clone(),
            engine_version: config.engine_version.clone(),
            hash: response.hash,
        })
    }
}

pub fn parse_prefetch_output(output: &str) -> anyhow::Result<String> {
    let response: PrefetchResponse = serde_json::from_str(output)?;
    Ok(response.hash)
}
