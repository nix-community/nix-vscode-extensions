mod support;

use nix_vscode_extensions_updater::marketplace::{parse_latest_response, parse_release_response};
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
fn latest_response_parses_real_marketplace_payload() {
    let latest = parse_latest_response(include_str!("fixtures/vscode-adacore-ada-latest.json")).unwrap();
    assert_eq!(latest.len(), 6);
    assert_eq!(
        latest
            .iter()
            .map(|config| {
                (
                    config.publisher.0.as_str(),
                    config.name.0.as_str(),
                    config.version.to_string(),
                    config.platform,
                    config.is_release.0,
                    config.engine_version.to_string(),
                )
            })
            .collect::<Vec<_>>(),
        vec![
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::DarwinArm64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::LinuxArm64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::Universal, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::LinuxX64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::DarwinX64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "24.0.6".to_string(), Platform::Universal, true, "^1.83.1".to_string()),
        ]
    );
}

#[test]
fn release_response_parses_real_marketplace_payload() {
    let release = parse_release_response(include_str!("fixtures/vscode-adacore-ada-release.json")).unwrap();
    assert_eq!(release.len(), 5);
    assert_eq!(
        release
            .iter()
            .map(|config| {
                (
                    config.publisher.0.as_str(),
                    config.name.0.as_str(),
                    config.version.to_string(),
                    config.platform,
                    config.is_release.0,
                    config.engine_version.to_string(),
                )
            })
            .collect::<Vec<_>>(),
        vec![
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::Universal, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::LinuxX64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::LinuxArm64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::DarwinX64, true, "^1.88.0".to_string()),
            ("AdaCore", "ada", "2026.3.202607051".to_string(), Platform::DarwinArm64, true, "^1.88.0".to_string()),
        ]
    );
}

#[test]
fn marketplace_parsers_filter_flags() {
    let body = json!({
        "results": [{
            "extensions": [
                {
                    "flags": "public, validated",
                    "extensionName": "keep",
                    "publisher": {"publisherName": "alice"},
                    "versions": [{
                        "version": "1.2.3",
                        "properties": [
                            {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                        ]
                    }]
                },
                {
                    "flags": "public, private",
                    "extensionName": "drop",
                    "publisher": {"publisherName": "alice"},
                    "versions": [{
                        "version": "1.2.3",
                        "properties": [
                            {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                        ]
                    }]
                },
                {
                    "flags": "public, verified",
                    "extensionName": "keep-too",
                    "publisher": {"publisherName": "alice"},
                    "versions": [{
                        "version": "1.2.3",
                        "properties": [
                            {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                        ]
                    }]
                }
            ]
        }]
    });

    let parsed = parse_latest_response(&body.to_string()).unwrap();
    assert_eq!(parsed.len(), 2);
    assert_eq!(parsed[0].publisher.0, "alice");
    assert_eq!(parsed[0].name.0, "keep");
    assert_eq!(parsed[0].version, version("1.2.3"));
    assert_eq!(parsed[0].is_release, IsRelease(true));
    assert_eq!(parsed[1].name.0, "keep-too");
}

#[test]
fn marketplace_parsers_reject_missing_engine_versions() {
    let body = json!({
        "results": [{
            "extensions": [{
                "flags": "public",
                "extensionName": "missing-engine",
                "publisher": {"publisherName": "alice"},
                "versions": [{
                    "version": "1.2.3",
                    "properties": []
                }]
            }]
        }]
    });

    let err = parse_latest_response(&body.to_string()).unwrap_err();
    assert!(err.to_string().contains("missing engine version"));
}

#[test]
fn marketplace_parsers_handle_prerelease_and_unknown_platforms() {
    let body = json!({
        "results": [{
            "extensions": [
                {
                    "flags": "public",
                    "extensionName": "sample",
                    "publisher": {"publisherName": "alice"},
                    "versions": [
                        {
                            "version": "1.2.3",
                            "targetPlatform": "fancy-os",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                            ]
                        },
                        {
                            "version": "1.2.4-insider",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"},
                                {"key": "Microsoft.VisualStudio.Code.PreRelease", "value": "true"}
                            ]
                        }
                    ]
                }
            ]
        }]
    });

    let parsed = parse_latest_response(&body.to_string()).unwrap();
    assert_eq!(parsed.len(), 2);
    assert_eq!(parsed[0].platform, Platform::Universal);
    assert_eq!(parsed[0].is_release, IsRelease(true));
    assert_eq!(parsed[1].platform, Platform::Universal);
    assert_eq!(parsed[1].is_release, IsRelease(false));
}

#[test]
fn release_parser_keeps_first_release_per_platform() {
    let body = json!({
        "results": [{
            "extensions": [
                {
                    "flags": "public",
                    "extensionName": "sample",
                    "publisher": {"publisherName": "alice"},
                    "versions": [
                        {
                            "version": "1.2.3",
                            "targetPlatform": "linux-x64",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                            ]
                        },
                        {
                            "version": "1.2.4",
                            "targetPlatform": "linux-x64",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                            ]
                        },
                        {
                            "version": "1.2.5-insider",
                            "targetPlatform": "linux-x64",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"},
                                {"key": "Microsoft.VisualStudio.Code.PreRelease", "value": "true"}
                            ]
                        }
                    ]
                }
            ]
        }]
    });

    let parsed = parse_release_response(&body.to_string()).unwrap();
    assert_eq!(parsed.len(), 1);
    assert_eq!(parsed[0].version, version("1.2.3"));
    assert_eq!(parsed[0].platform, Platform::LinuxX64);
    assert_eq!(parsed[0].is_release, IsRelease(true));
}
