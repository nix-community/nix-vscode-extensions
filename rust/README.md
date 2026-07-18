# Quick Start

This subtree exposes a flake dev shell and a default updater package.

From the repository root, enter the development shell:

```console
nix develop path:./rust
```

From inside `rust/`, enter the same shell with:

```console
nix develop .
```

Confirm the Rust toolchain is available on `PATH`:

```console
rust-analyzer --version
cargo --version
rustc --version
```

Run the updater from inside the shell:

```console
cargo run -- --config ../config.yaml
```

Run the Rust test suite from inside the shell:

```console
cargo test
```
