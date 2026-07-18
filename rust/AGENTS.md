# Rust Updater Instructions

- This subtree contains the updater crate.
- Use `cargo test` for verification and `cargo fmt` only when formatting is required by the task.
- Keep the updater behavior aligned with the repo contract: JSONL caches, compact record keys, and the existing Nix-facing semantics.
- Prefer small, focused Rust changes and keep crate-local docs/tests in sync with code changes.
- Avoid introducing extra runtime dependencies unless they directly support the updater pipeline.
- Use the flake dev shell for Rust work: `nix develop .` inside `rust/`, or `nix develop path:./rust` from the repository root.
