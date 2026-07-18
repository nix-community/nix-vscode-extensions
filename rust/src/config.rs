use crate::model::Target;
use anyhow::Context;
use serde::Deserialize;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SiteConfig {
    #[serde(default = "default_page_size", rename = "pageSize")]
    pub page_size: usize,
    #[serde(default = "default_page_count", rename = "pageCount")]
    pub page_count: usize,
    #[serde(default = "default_metadata_fetch_threads", rename = "metadataFetchThreads")]
    pub metadata_fetch_threads: usize,
    #[serde(default, rename = "artifactPrefetchThreads")]
    pub artifact_prefetch_threads: Option<usize>,
    #[serde(default = "default_true")]
    pub enable: bool,
}

fn default_page_size() -> usize {
    1000
}

fn default_page_count() -> usize {
    10
}

fn default_metadata_fetch_threads() -> usize {
    30
}

fn default_true() -> bool {
    true
}

impl Default for SiteConfig {
    fn default() -> Self {
        Self {
            page_size: default_page_size(),
            page_count: default_page_count(),
            metadata_fetch_threads: default_metadata_fetch_threads(),
            artifact_prefetch_threads: None,
            enable: true,
        }
    }
}

impl SiteConfig {
    pub fn effective_artifact_prefetch_threads(&self) -> usize {
        self.artifact_prefetch_threads
            .unwrap_or(self.metadata_fetch_threads)
    }
}

#[derive(Clone, Debug, Deserialize)]
pub struct AppConfig {
    #[serde(default = "default_processed_logger_delay", rename = "processedLoggerDelay")]
    pub processed_logger_delay: u64,
    #[serde(default = "default_garbage_collector_delay", rename = "garbageCollectorDelay")]
    pub garbage_collector_delay: u64,
    #[serde(default, rename = "collectGarbage")]
    pub collect_garbage: bool,
    #[serde(default = "default_program_timeout", rename = "programTimeout")]
    pub program_timeout: u64,
    #[serde(default = "default_retry_delay", rename = "retryDelay")]
    pub retry_delay: u64,
    #[serde(default = "default_n_retry", rename = "nRetry")]
    pub n_retry: u32,
    #[serde(default = "default_log_severity", rename = "logSeverity")]
    pub log_severity: LogSeverity,
    #[serde(default = "default_data_dir", rename = "dataDir")]
    pub data_dir: PathBuf,
    #[serde(default = "default_queue_capacity", rename = "queueCapacity")]
    pub queue_capacity: usize,
    #[serde(default = "default_request_timeout", rename = "requestResponseTimeout")]
    pub request_response_timeout: u64,
    #[serde(default, rename = "openVSX")]
    pub open_vsx: SiteConfig,
    #[serde(default, rename = "vscodeMarketplace")]
    pub vscode_marketplace: SiteConfig,
}

fn default_processed_logger_delay() -> u64 {
    2
}
fn default_garbage_collector_delay() -> u64 {
    30
}
fn default_program_timeout() -> u64 {
    900
}
fn default_retry_delay() -> u64 {
    20
}
fn default_n_retry() -> u32 {
    3
}
fn default_log_severity() -> LogSeverity {
    LogSeverity::Info
}
fn default_data_dir() -> PathBuf {
    PathBuf::from("data")
}
fn default_queue_capacity() -> usize {
    200
}
fn default_request_timeout() -> u64 {
    100
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            processed_logger_delay: default_processed_logger_delay(),
            garbage_collector_delay: default_garbage_collector_delay(),
            collect_garbage: false,
            program_timeout: default_program_timeout(),
            retry_delay: default_retry_delay(),
            n_retry: default_n_retry(),
            log_severity: default_log_severity(),
            data_dir: default_data_dir(),
            queue_capacity: default_queue_capacity(),
            request_response_timeout: default_request_timeout(),
            open_vsx: SiteConfig::default(),
            vscode_marketplace: SiteConfig {
                page_size: 1000,
                page_count: 100,
                metadata_fetch_threads: 100,
                artifact_prefetch_threads: None,
                enable: true,
            },
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Ord, PartialOrd, Deserialize)]
pub enum LogSeverity {
    Debug,
    Info,
    Warning,
    Error,
}

impl AppConfig {
    pub fn load(path: Option<&Path>) -> anyhow::Result<Self> {
        match path {
            None => Ok(Self::default()),
            Some(path) => {
                let text = std::fs::read_to_string(path)
                    .with_context(|| format!("failed to read config file at {}", path.display()))?;
                let mut config: AppConfig = serde_yaml::from_str(&text)
                    .with_context(|| format!("failed to parse config file at {}", path.display()))?;
                let defaults = AppConfig::default();
                if config.data_dir.as_os_str().is_empty() {
                    config.data_dir = defaults.data_dir;
                }
                Ok(config)
            }
        }
    }

    pub fn enabled_targets(&self) -> Vec<Target> {
        let mut targets = Vec::new();
        if self.vscode_marketplace.enable {
            targets.push(Target::VscodeMarketplace);
        }
        if self.open_vsx.enable {
            targets.push(Target::OpenVsx);
        }
        targets
    }
}
