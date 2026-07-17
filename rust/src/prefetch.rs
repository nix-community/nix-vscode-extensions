use crate::model::{CacheRecord, ExtensionConfig, Target};
use anyhow::{anyhow, Context};
use serde::Deserialize;
use std::process::Command;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PrefetchLogContext {
    pub extension_id: String,
    pub version: String,
    pub platform: String,
    pub target: String,
    pub url: String,
}

pub trait Prefetcher: Send + Sync {
    fn prefetch(
        &self,
        target: Target,
        config: &ExtensionConfig,
        timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord>;
}

pub struct NixPrefetcher;

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PrefetchCommandOutput {
    pub status_code: Option<i32>,
    pub stdout: Vec<u8>,
    pub stderr: Vec<u8>,
}

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

    fn classify_output(
        context: &PrefetchLogContext,
        config: &ExtensionConfig,
        output: PrefetchCommandOutput,
    ) -> anyhow::Result<CacheRecord> {
        if output.status_code != Some(0) {
            return Err(anyhow!(
                "nix store prefetch-file exited with status {} for {} stderr={}",
                output
                    .status_code
                    .map_or_else(|| "signal".to_string(), |code| code.to_string()),
                context.render(),
                String::from_utf8_lossy(&output.stderr).trim()
            ));
        }
        if !output.stderr.is_empty() {
            return Err(anyhow!(
                "nix store prefetch-file produced stderr for {} stderr={}",
                context.render(),
                String::from_utf8_lossy(&output.stderr).trim()
            ));
        }
        let response: PrefetchResponse = serde_json::from_slice(&output.stdout).with_context(|| {
            format!(
                "invalid prefetch json for {} stdout={}",
                context.render(),
                String::from_utf8_lossy(&output.stdout).trim()
            )
        })?;
        if response.hash.trim().is_empty() {
            return Err(anyhow!("missing hash in prefetch output for {}", context.render()));
        }
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

    #[doc(hidden)]
    pub fn prefetch_with_output(
        target: Target,
        config: &ExtensionConfig,
        output: std::io::Result<PrefetchCommandOutput>,
    ) -> anyhow::Result<CacheRecord> {
        let context = PrefetchLogContext::new(target, config);
        let output =
            output.with_context(|| format!("failed to spawn nix for {}", context.render()))?;
        Self::classify_output(&context, config, output)
    }
}

impl PrefetchLogContext {
    pub fn new(target: Target, config: &ExtensionConfig) -> Self {
        Self {
            extension_id: format!("{}.{}", config.publisher.0, config.name.0),
            version: config.version.raw().to_string(),
            platform: config.platform.to_string(),
            target: target.to_string(),
            url: NixPrefetcher::url(target, config),
        }
    }

    pub fn render(&self) -> String {
        format!(
            "extension={} version={} platform={} target={} url={}",
            self.extension_id, self.version, self.platform, self.target, self.url
        )
    }
}

impl Prefetcher for NixPrefetcher {
    fn prefetch(
        &self,
        target: Target,
        config: &ExtensionConfig,
        timeout_seconds: u64,
    ) -> anyhow::Result<CacheRecord> {
        let context = PrefetchLogContext::new(target.clone(), config);
        let output = Command::new("nix")
            .args([
                "store",
                "prefetch-file",
                "--timeout",
                &timeout_seconds.to_string(),
                "--json",
                &context.url,
                "--name",
                &format!(
                    "{}-{}-{}",
                    context.extension_id, context.version, context.platform
                ),
            ])
            .output()
            .map(|output| PrefetchCommandOutput {
                status_code: output.status.code(),
                stdout: output.stdout,
                stderr: output.stderr,
            });

        Self::prefetch_with_output(target, config, output)
    }
}

pub fn parse_prefetch_output(output: &str) -> anyhow::Result<String> {
    let response: PrefetchResponse = serde_json::from_str(output)?;
    Ok(response.hash)
}
