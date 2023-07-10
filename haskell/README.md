# Haskell

## Prerequisites

- [flake.nix](./flake.nix) - extensively commented code
- [Prerequisites](https://github.com/deemp/flakes#prerequisites)
- [Haskell](https://github.com/deemp/flakes/blob/main/README/Haskell.md)

## Quick start

1. Install Nix - see [how](https://github.com/deemp/flakes/blob/main/README/InstallNix.md).

1. In a new terminal, run a devshell from the `hs` dir. When prompted about `extra-trusted-substituters` answer `y`. This is to use binary caches.

    ```console
    cd hs
    nix develop
    ```

1. (Optionally) Edit the [config](./config.yaml).

1. Run the app.

    ```console
    set -a
    source .env
    cabal run
    ```

1. The fetched extensions will be in [data](./data).

1. (Optionally) Run `VSCodium`.

    ```console
    nix run .#writeSettings
    nix run .#codium .
    ```

1. (Optionally) Open a `.hs` file and hover over a function. Wait until HLS gives the type info.

### Configs

- [package.yaml] - used by `hpack` to generate a `.cabal`
- [.markdownlint.jsonc](./.markdownlint.jsonc) - for `markdownlint` from the extension `davidanson.vscode-markdownlint`
- [.ghcid](./.ghcid) - for [ghcid](https://github.com/ndmitchell/ghcid)
- [.envrc](./.envrc) - for [direnv](https://github.com/direnv/direnv)
- [fourmolu.yaml](./fourmolu.yaml) - for [fourmolu](https://github.com/fourmolu/fourmolu#configuration)

### Troubleshooting

- If `VSCodium` doesn't pick up the extensions, try to reboot your computer and start `VSCodium` again.
- See [troubleshooting](https://github.com/deemp/flakes/blob/main/README/Troubleshooting.md).
