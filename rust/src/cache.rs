use crate::model::{CacheRecord, ExtensionConfig};
use anyhow::Context;
use std::fs::{self, File, OpenOptions};
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
    read_jsonl(path)
}

pub fn read_tmp_fetched(path: &Path) -> anyhow::Result<Vec<CacheRecord>> {
    read_jsonl(path)
}

pub fn write_jsonl_cache(path: &Path, records: &[CacheRecord]) -> anyhow::Result<()> {
    rewrite_jsonl_atomic(path, records)
}

pub fn append_jsonl_record<T: serde::Serialize>(path: &Path, value: &T) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let mut file = OpenOptions::new().create(true).append(true).open(path)?;
    writeln!(file, "{}", serde_json::to_string(value)?)?;
    file.flush()?;
    file.sync_data()?;
    Ok(())
}

pub fn rewrite_jsonl_atomic<T: serde::Serialize>(path: &Path, values: &[T]) -> anyhow::Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)?;
    }
    let file_name = path
        .file_name()
        .and_then(|name| name.to_str())
        .unwrap_or("tmp.jsonl");
    let tmp_path = path.with_file_name(format!("{file_name}.tmp"));
    {
        let mut file = File::create(&tmp_path)?;
        for value in values {
            writeln!(file, "{}", serde_json::to_string(value)?)?;
        }
        file.flush()?;
        file.sync_data()?;
    }
    fs::rename(&tmp_path, path)?;
    Ok(())
}

fn read_jsonl<T: serde::de::DeserializeOwned>(path: &Path) -> anyhow::Result<Vec<T>> {
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
