mod support;

use nix_vscode_extensions_updater::marketplace::{parse_latest_response, parse_release_response};
use nix_vscode_extensions_updater::model::{IsRelease, Platform};
use serde_json::json;
use support::{assert_latest_fixture, assert_release_fixture, version};

#[test]
fn latest_response_parses_real_marketplace_payload() {
    assert_latest_fixture(
        include_str!("fixtures/vscode-adacore-ada-latest.json"),
        &[
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::DarwinArm64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::LinuxArm64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::LinuxX64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::DarwinX64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "24.0.6",
                Platform::Universal,
                true,
                "^1.83.1",
            ),
        ],
    );
}

#[test]
fn release_response_parses_real_marketplace_payload() {
    assert_release_fixture(
        include_str!("fixtures/vscode-adacore-ada-release.json"),
        &[
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::LinuxX64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::LinuxArm64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::DarwinX64,
                true,
                "^1.88.0",
            ),
            (
                "AdaCore",
                "ada",
                "2026.3.202607051",
                Platform::DarwinArm64,
                true,
                "^1.88.0",
            ),
        ],
    );
}

#[test]
fn latest_response_parses_rust_analyzer_fixture() {
    assert_latest_fixture(
        include_str!("fixtures/rust-lang-rust-analyzer-latest.json"),
        &[
            (
                "rust-lang",
                "rust-analyzer",
                "0.4.2977",
                Platform::LinuxX64,
                false,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.4.2977",
                Platform::LinuxArm64,
                false,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.4.2977",
                Platform::DarwinX64,
                false,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.4.2977",
                Platform::DarwinArm64,
                false,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.4.2977",
                Platform::Universal,
                false,
                "^1.93.0",
            ),
        ],
    );
}

#[test]
fn release_response_parses_rust_analyzer_fixture() {
    assert_release_fixture(
        include_str!("fixtures/rust-lang-rust-analyzer-release.json"),
        &[
            (
                "rust-lang",
                "rust-analyzer",
                "0.3.2971",
                Platform::Universal,
                true,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.3.2971",
                Platform::LinuxX64,
                true,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.3.2971",
                Platform::LinuxArm64,
                true,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.3.2971",
                Platform::DarwinX64,
                true,
                "^1.93.0",
            ),
            (
                "rust-lang",
                "rust-analyzer",
                "0.3.2971",
                Platform::DarwinArm64,
                true,
                "^1.93.0",
            ),
        ],
    );
}

#[test]
fn latest_response_parses_cpptools_fixture() {
    assert_latest_fixture(
        include_str!("fixtures/ms-vscode-cpptools-latest.json"),
        &[
            (
                "ms-vscode",
                "cpptools",
                "1.33.4",
                Platform::DarwinX64,
                false,
                "^1.77.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.33.4",
                Platform::LinuxArm64,
                false,
                "^1.77.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.33.4",
                Platform::LinuxX64,
                false,
                "^1.77.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.33.4",
                Platform::DarwinArm64,
                false,
                "^1.77.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.7.1",
                Platform::Universal,
                true,
                "^1.60.0",
            ),
        ],
    );
}

#[test]
fn release_response_parses_cpptools_fixture() {
    assert_release_fixture(
        include_str!("fixtures/ms-vscode-cpptools-release.json"),
        &[
            (
                "ms-vscode",
                "cpptools",
                "1.32.2",
                Platform::LinuxX64,
                true,
                "^1.67.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.32.2",
                Platform::LinuxArm64,
                true,
                "^1.67.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.32.2",
                Platform::DarwinX64,
                true,
                "^1.67.0",
            ),
            (
                "ms-vscode",
                "cpptools",
                "1.32.2",
                Platform::DarwinArm64,
                true,
                "^1.67.0",
            ),
        ],
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
fn marketplace_parsers_skip_unknown_platforms_and_keep_real_universals() {
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
                        },
                        {
                            "version": "1.2.5",
                            "targetPlatform": "universal",
                            "properties": [
                                {"key": "Microsoft.VisualStudio.Code.Engine", "value": "^1.0.0"}
                            ]
                        }
                    ]
                }
            ]
        }]
    });

    let parsed = parse_latest_response(&body.to_string()).unwrap();
    assert_eq!(parsed.len(), 2);
    assert_eq!(parsed[0].version, version("1.2.4-insider"));
    assert_eq!(parsed[0].platform, Platform::Universal);
    assert_eq!(parsed[0].is_release, IsRelease(false));
    assert_eq!(parsed[1].version, version("1.2.5"));
    assert_eq!(parsed[1].platform, Platform::Universal);
    assert_eq!(parsed[1].is_release, IsRelease(true));
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
