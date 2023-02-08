# Haskell

`VSCodium` with extensions and executables for `Haskell`.

## Prerequisites

- [flake.nix](./flake.nix) - extensively commented code
- [Prerequisites](https://github.com/deemp/flakes#prerequisites)
- [Haskell](https://github.com/deemp/flakes/blob/main/README/Haskell.md)

## Quick start

1. Install Nix - see [how](https://github.com/deemp/flakes/blob/main/README/InstallNix.md).

1. In a new terminal, run a devshell from the `hs` dir:

```console
cd hs
nix develop
cabal run
```

1. Optionally, run `VSCodium`

```console
nix run .#writeSettings
nix run .#codium .
```

### Configs

- [package.yaml] - used by `hpack` to generate a `.cabal`
- [.markdownlint.jsonc](./.markdownlint.jsonc) - for `markdownlint` from the extension `davidanson.vscode-markdownlint`
- [.ghcid](./.ghcid) - for [ghcid](https://github.com/ndmitchell/ghcid)
- [.envrc](./.envrc) - for [direnv](https://github.com/direnv/direnv)
- [fourmolu.yaml](./fourmolu.yaml) - for [fourmolu](https://github.com/fourmolu/fourmolu#configuration)

### Troubleshooting

- If `VSCodium` doesn't pick up the extensions, try to reboot your computer and start `VSCodium` again.
- See [troubleshooting](https://github.com/deemp/flakes/blob/main/README/Troubleshooting.md).
