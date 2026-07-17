mod support;

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
