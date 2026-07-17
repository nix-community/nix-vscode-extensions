mod support;

use nix_vscode_extensions_updater::model::Platform;
use nix_vscode_extensions_updater::model::Target;
use nix_vscode_extensions_updater::prefetch::{NixPrefetcher, PrefetchCommandOutput};
use std::io;
use support::config;

#[test]
fn prefetch_reports_spawn_failures_with_context() {
    let config = config("broken", "ext", true, Platform::LinuxX64, "2.0.0");

    let err = NixPrefetcher::prefetch_with_output(
        Target::OpenVsx,
        &config,
        Err(io::Error::new(io::ErrorKind::NotFound, "missing nix")),
    )
    .unwrap_err();

    let message = err.to_string();
    assert!(message.contains("failed to spawn nix"));
    assert_prefetch_context(&message);
}

#[test]
fn prefetch_reports_non_zero_exit_with_context() {
    let config = config("broken", "ext", true, Platform::LinuxX64, "2.0.0");

    let err = NixPrefetcher::prefetch_with_output(
        Target::OpenVsx,
        &config,
        Ok(PrefetchCommandOutput {
            status_code: Some(17),
            stdout: Vec::new(),
            stderr: b"prefetch exploded".to_vec(),
        }),
    )
    .unwrap_err();

    let message = err.to_string();
    assert!(message.contains("exited with status 17"));
    assert!(message.contains("stderr=prefetch exploded"));
    assert_prefetch_context(&message);
}

#[test]
fn prefetch_reports_stderr_on_success_with_context() {
    let config = config("broken", "ext", true, Platform::LinuxX64, "2.0.0");

    let err = NixPrefetcher::prefetch_with_output(
        Target::OpenVsx,
        &config,
        Ok(PrefetchCommandOutput {
            status_code: Some(0),
            stdout: br#"{"hash":"sha256-ok"}"#.to_vec(),
            stderr: b"warning output".to_vec(),
        }),
    )
    .unwrap_err();

    let message = err.to_string();
    assert!(message.contains("produced stderr"));
    assert!(message.contains("stderr=warning output"));
    assert_prefetch_context(&message);
}

#[test]
fn prefetch_reports_invalid_json_with_context() {
    let config = config("broken", "ext", true, Platform::LinuxX64, "2.0.0");

    let err = NixPrefetcher::prefetch_with_output(
        Target::OpenVsx,
        &config,
        Ok(PrefetchCommandOutput {
            status_code: Some(0),
            stdout: b"not-json".to_vec(),
            stderr: Vec::new(),
        }),
    )
    .unwrap_err();

    let message = format!("{err:#}");
    assert!(message.contains("invalid prefetch json"));
    assert!(message.contains("stdout=not-json"));
    assert_prefetch_context(&message);
}

#[test]
fn prefetch_reports_missing_hash_with_context() {
    let config = config("broken", "ext", true, Platform::LinuxX64, "2.0.0");

    let err = NixPrefetcher::prefetch_with_output(
        Target::OpenVsx,
        &config,
        Ok(PrefetchCommandOutput {
            status_code: Some(0),
            stdout: br#"{"hash":"   "}"#.to_vec(),
            stderr: Vec::new(),
        }),
    )
    .unwrap_err();

    let message = err.to_string();
    assert!(message.contains("missing hash in prefetch output"));
    assert_prefetch_context(&message);
}

fn assert_prefetch_context(message: &str) {
    assert!(message.contains("extension=broken.ext"));
    assert!(message.contains("version=2.0.0"));
    assert!(message.contains("platform=linux-x64"));
    assert!(message.contains("target=open-vsx"));
    assert!(message.contains("url=https://open-vsx.org/api/broken/ext/linux-x64/2.0.0/file/broken-2.0.0@linux-x64.vsix"));
}
