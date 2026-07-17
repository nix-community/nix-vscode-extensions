use crate::model::{CacheRecord, ExtensionConfig};
use anyhow::Context;
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Write};
use std::path::Path;

pub fn cache_path(data_dir: &Path, site: &str) -> std::path::PathBuf {
    data_dir.join("cache").join(format!("{site}-latest.jsonl"))
}

pub fn debug_path(data_dir: &Path, site: &str, name: &str) -> std::path::PathBuf {
    data_dir.join("debug").join(format!("{site}-{name}.json"))
}

pub fn tmp_path(data_dir: &Path, kind: &str, site: &str) -> std::path::PathBuf {
    data_dir.join("tmp").join(kind).join(format!("{site}-latest.jsonl"))
}

pub fn ensure_empty_file(path: &Path) -> anyhow::Result<()> {
    if !path.exists() {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        File::create(path)?;
    }
    Ok(())
}

pub fn read_jsonl_cache(path: &Path) -> anyhow::Result<Vec<CacheRecord>> {
    ensure_empty_file(path)?;
    let file = File::open(path).with_context(|| format!("failed to open {}", path.display()))?;
    let reader = BufReader::new(file);
    let mut out = Vec::new();
    for line in reader.lines() {
        let line = line?;
        if line.trim().is_empty() {
            continue;
        }
        out.push(serde_json::from_str(&line)?);
    }
    Ok(out)
}

pub fn write_jsonl_cache(path: &Path, records: &[CacheRecord]) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = File::create(path)?;
    for record in records {
        writeln!(file, "{}", serde_json::to_string(record)?)?;
    }
    Ok(())
}

pub fn write_jsonl<T: serde::Serialize>(path: &Path, values: &[T]) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = File::create(path)?;
    for value in values {
        writeln!(file, "{}", serde_json::to_string(value)?)?;
    }
    Ok(())
}

pub fn write_json_pretty<T: serde::Serialize>(path: &Path, value: &T) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let file = File::create(path)?;
    serde_json::to_writer_pretty(file, value)?;
    Ok(())
}

pub fn records_from_configs(configs: &[ExtensionConfig]) -> Vec<CacheRecord> {
    configs
        .iter()
        .map(|config| CacheRecord {
            publisher: config.publisher.clone(),
            name: config.name.clone(),
            is_release: config.is_release,
            platform: config.platform,
            version: config.version.clone(),
            engine_version: config.engine_version.clone(),
            hash: String::new(),
        })
        .collect()
}

