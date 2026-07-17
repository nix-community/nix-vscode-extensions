# Repo Instructions

- Treat this repo as a mixed Nix + Rust workspace.
- Prefer `rg` for searches and `apply_patch` for edits.
- Do not overwrite unrelated user changes; leave dirty files alone unless the task explicitly targets them.
- Keep changes ASCII unless the file already uses Unicode.
- For Rust work, validate with `cargo test` from `rust/`.
- For Nix wiring, prefer minimal, explicit changes and keep cache/layout migrations consistent across docs, CI, and overlays.
- Keep tracked cache/data format changes intentional; rename consumers and artifacts together.
