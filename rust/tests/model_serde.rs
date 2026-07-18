mod support;

use nix_vscode_extensions_updater::config::AppConfig;
use nix_vscode_extensions_updater::model::{EngineVersionModifier, IsRelease, Platform, Version};
use nix_vscode_extensions_updater::prefetch::parse_prefetch_output;
use serde_json::json;
use support::{engine, version};

#[test]
fn compact_cache_record_serde() {
    let record = nix_vscode_extensions_updater::model::CacheRecord {
        publisher: nix_vscode_extensions_updater::model::Publisher("pub".into()),
        name: nix_vscode_extensions_updater::model::Name("ext".into()),
        is_release: IsRelease(true),
        platform: Platform::Universal,
        version: version("1.2.3"),
        engine_version: engine("^1.2.3"),
        hash: "sha256-abc".into(),
    };
    let json = serde_json::to_value(&record).unwrap();
    assert_eq!(json, json!({"p":"pub","n":"ext","r":1,"P":0,"v":"1.2.3","e":"^1.2.3","h":"sha256-abc"}));
}

#[test]
fn engine_version_parsing() {
    let parsed = engine(">=1.27.0-insider");
    assert_eq!(parsed.modifier, EngineVersionModifier::Gte);
    assert_eq!(parsed.version.to_string(), "1.27.0-insider");
}

#[test]
fn numeric_conversions() {
    assert_eq!(serde_json::to_value(Platform::DarwinArm64).unwrap(), json!(4));
    assert_eq!(serde_json::to_value(IsRelease(false)).unwrap(), json!(0));
    assert_eq!(serde_json::to_value(IsRelease(true)).unwrap(), json!(1));
}

#[test]
fn numeric_deserialization_rejects_invalid_values() {
    for value in [json!(-1), json!(5), json!("x"), json!(null)] {
        assert!(serde_json::from_value::<Platform>(value).is_err());
    }

    for value in [json!(-1), json!(2), json!("x"), json!(null)] {
        assert!(serde_json::from_value::<IsRelease>(value).is_err());
    }
}

#[test]
fn version_parsing_accepts_supported_forms() {
    for (input, expected) in [
        ("1.2.3", "1.2.3"),
        ("1.2.3-insider", "1.2.3-insider"),
        ("1.2.3-rc.1", "1.2.3-rc.1"),
    ] {
        assert_eq!(version(input).to_string(), expected);
    }

    for input in ["", " ", "1.2", "1.2.3.4", "v1.2.3", "1.2.x", "a.b.c"] {
        assert!(Version::parse(input).is_err());
    }
}

#[test]
fn engine_version_parsing_accepts_supported_forms_and_rejects_bad_inputs() {
    assert_eq!(engine("*").to_string(), "^0.0.0");
    assert_eq!(engine("^1.2.3").to_string(), "^1.2.3");
    assert_eq!(engine(">=1.2.3").to_string(), "^1.2.3");
    assert_eq!(engine("1.x.0").to_string(), "1.0.0");
    assert_eq!(engine(">=1.x.0").to_string(), "^1.0.0");

    for input in ["", " ", "^", ">=", "1.2", "^1.2", ">=1", "1.2.3.4", "1.x", "x.x"] {
        assert!(nix_vscode_extensions_updater::model::EngineVersion::parse(input).is_err());
    }
}

#[test]
fn prefetch_output_parsing() {
    assert_eq!(parse_prefetch_output(r#"{"hash":"sha256-xyz"}"#).unwrap(), "sha256-xyz");
}

#[test]
fn config_artifact_prefetch_threads_defaults_to_metadata_fetch_threads_when_omitted() {
    let config: AppConfig = serde_yaml::from_str(
        r#"
open_vsx:
  metadata_fetch_threads: 7
vscode_marketplace:
  metadata_fetch_threads: 9
"#,
    )
    .unwrap();

    assert_eq!(config.open_vsx.artifact_prefetch_threads, None);
    assert_eq!(config.open_vsx.effective_artifact_prefetch_threads(), 7);
    assert_eq!(config.vscode_marketplace.artifact_prefetch_threads, None);
    assert_eq!(
        config.vscode_marketplace.effective_artifact_prefetch_threads(),
        9
    );
}

#[test]
fn config_artifact_prefetch_threads_deserializes_and_overrides_metadata_fetch_threads() {
    let config: AppConfig = serde_yaml::from_str(
        r#"
open_vsx:
  metadata_fetch_threads: 7
  artifact_prefetch_threads: 3
vscode_marketplace:
  metadata_fetch_threads: 9
  artifact_prefetch_threads: 4
"#,
    )
    .unwrap();

    assert_eq!(config.open_vsx.artifact_prefetch_threads, Some(3));
    assert_eq!(config.open_vsx.effective_artifact_prefetch_threads(), 3);
    assert_eq!(
        config.vscode_marketplace.artifact_prefetch_threads,
        Some(4)
    );
    assert_eq!(
        config.vscode_marketplace.effective_artifact_prefetch_threads(),
        4
    );
}

#[test]
fn config_metadata_fetch_threads_deserializes() {
    let config: AppConfig = serde_yaml::from_str(
        r#"
open_vsx:
  metadata_fetch_threads: 7
"#,
    )
    .unwrap();

    assert_eq!(config.open_vsx.metadata_fetch_threads, 7);
}

#[test]
fn config_rejects_legacy_thread_keys() {
    for legacy_key in ["fetchThreads", "prefetchThreads", "nThreads"] {
        let err = serde_yaml::from_str::<AppConfig>(&format!(
            r#"
open_vsx:
  {legacy_key}: 7
"#
        ))
        .unwrap_err();

        assert!(err.to_string().contains(&format!("unknown field `{legacy_key}`")));
    }
}

#[test]
fn config_snake_case_keys_deserialize() {
    let config: AppConfig = serde_yaml::from_str(
        r#"
collect_garbage: true
garbage_collector_delay: 10
program_timeout: 3600
log_severity: Info
data_dir: custom-data
queue_capacity: 512
request_response_timeout: 45
open_vsx:
  enable: true
  page_count: 10
  page_size: 1000
  metadata_fetch_threads: 50
  artifact_prefetch_threads: 20
vscode_marketplace:
  enable: false
  page_count: 100
  page_size: 1000
  metadata_fetch_threads: 30
"#,
    )
    .unwrap();

    assert!(config.collect_garbage);
    assert_eq!(config.garbage_collector_delay, 10);
    assert_eq!(config.program_timeout, 3600);
    assert_eq!(config.log_severity, nix_vscode_extensions_updater::config::LogSeverity::Info);
    assert_eq!(config.data_dir, std::path::PathBuf::from("custom-data"));
    assert_eq!(config.queue_capacity, 512);
    assert_eq!(config.request_response_timeout, 45);
    assert_eq!(config.open_vsx.page_count, 10);
    assert_eq!(config.open_vsx.page_size, 1000);
    assert_eq!(config.open_vsx.metadata_fetch_threads, 50);
    assert_eq!(config.open_vsx.artifact_prefetch_threads, Some(20));
    assert!(!config.vscode_marketplace.enable);
    assert_eq!(config.vscode_marketplace.page_count, 100);
}

#[test]
fn config_rejects_legacy_camel_case_keys() {
    for legacy_key in [
        "collectGarbage",
        "garbageCollectorDelay",
        "programTimeout",
        "logSeverity",
        "dataDir",
        "queueCapacity",
        "requestResponseTimeout",
        "openVSX",
        "vscodeMarketplace",
    ] {
        let yaml = if legacy_key == "openVSX" {
            "openVSX:\n  metadata_fetch_threads: 7\n".to_string()
        } else if legacy_key == "vscodeMarketplace" {
            "vscodeMarketplace:\n  metadata_fetch_threads: 7\n".to_string()
        } else {
            format!("{legacy_key}: 1\n")
        };

        let err = serde_yaml::from_str::<AppConfig>(&yaml).unwrap_err();
        assert!(err.to_string().contains(&format!("unknown field `{legacy_key}`")));
    }

    for legacy_key in ["pageSize", "metadataFetchThreads", "artifactPrefetchThreads"] {
        let err = serde_yaml::from_str::<AppConfig>(&format!(
            r#"
open_vsx:
  {legacy_key}: 7
"#
        ))
        .unwrap_err();

        assert!(err.to_string().contains(&format!("unknown field `{legacy_key}`")));
    }
}

#[test]
fn sample_config_yaml_uses_supported_snake_case_schema() {
    let config_path = concat!(env!("CARGO_MANIFEST_DIR"), "/../config.yaml");
    let yaml = std::fs::read_to_string(config_path).unwrap();
    let config: AppConfig = serde_yaml::from_str(&yaml).unwrap();

    assert!(config.collect_garbage);
    assert_eq!(config.garbage_collector_delay, 10);
    assert_eq!(config.program_timeout, 3600);
    assert_eq!(config.open_vsx.page_count, 10);
    assert_eq!(config.open_vsx.page_size, 1000);
    assert_eq!(config.open_vsx.metadata_fetch_threads, 50);
    assert_eq!(config.vscode_marketplace.page_count, 100);
    assert_eq!(config.vscode_marketplace.page_size, 1000);
}
