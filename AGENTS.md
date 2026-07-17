# Repo Instructions

- Treat this repo as a mixed Nix + Rust workspace.
- Prefer `rg` for searches and `apply_patch` for edits.
- Do not overwrite unrelated user changes; leave dirty files alone unless the task explicitly targets them.
- Keep changes ASCII unless the file already uses Unicode.
- For Rust work, validate with `cargo test` from `rust/`.
- For Nix wiring, prefer minimal, explicit changes and keep cache/layout migrations consistent across docs, CI, and overlays.
- Keep tracked cache/data format changes intentional; rename consumers and artifacts together.

## Commits

- Use Conventional Commits.
- Use exactly one scope per commit.
- Allowed scopes are:
- `readme` for `README.md`
- `agents` for `AGENTS.md`
- `nix` for `nix/`, `flake.nix`, and `default.nix`
- `extensions` for tracked files under `extensions/`
- `github` for tracked files under `.github/`
- `vscode` for tracked files under `.vscode/`
- `rust` for tracked files under `rust/`
- Mixed-area commits are not allowed. A commit must touch files from exactly one mapped scope.
- Include a body that explains the change.
- Include a `Co-authored-by: <assistant/provider name> <current model name> <model-specific no-reply email>` line.
