# Haskell

## Quick start

1. Install `Nix` ([link](https://nixos.org/download/)).

1. Install `direnv` ([link](https://direnv.net/#basic-installation)).

1. In a new terminal, allow `direnv` to run the devshell.
   When prompted about `extra-trusted-substituters` answer `y`.
   This is to use binary caches.

    ```console
    cd haskell
    direnv allow
    ```

1. (Optionally) Edit the [config](./config.yaml) (see [./src/Config.hs](./src/Configs.hs) for all available options).

1. Run the updater.

    ```console
    cabal run updater -- --config config.yaml
    ```

1. The fetched extensions will be in [data](./data).

## Keys of objects in the cache

Example:

```json
{"p":"0-don","n":"code-collector","r":1,"s":0,"v":"0.0.54","e":"^1.80.0","m":2,"h":"sha256-tBfwL+zl8etRp3xPkXYJn9OrX/s2o4F957bRLJR7xT8="}
```

- `p` - extension publisher
- `n` - extension name
- `r` - whether it's a release version
  - `0` means `true`
  - `1` means `false`
- `s` - extension platform ("s" is from "system")
  - `0` means `universal` (platform)
  - `1` means `linux-x64` (platform) or `x86_64-linux` (system)
  - `2` means `linux-arm64` (platform) or `aarch64-linux` (system)
  - `3` means `darwin-x64` (platform) or `x86_64-darwin` (system)
  - `4` means `darwin-arm64` (platform) or `aarch64-darwin` (system)
- `v` - extension version
- `e` - engine version (minimal compatible VSCode version)
- `m` - missing times
- `h` - hash

## Requests

### VSCode Marketplace

- [filterType](https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L88)

- [flags](https://github.com/microsoft/vscode/blob/b4c1eaa7c86d5daa45f6a41e255e70ae3cb03326/src/vs/platform/extensionManagement/common/extensionGalleryManifestService.ts#L158)

### OpenVSX

- [filterType](https://github.com/eclipse/openvsx/blob/0b5b657529f0784f7bc901fae39afc8df25a4389/server/src/main/java/org/eclipse/openvsx/adapter/ExtensionQueryParam.java#L90)

- [flags](https://github.com/eclipse/openvsx/blob/d02ca60957c0281671fd7e1cad0ebb147e14aa21/server/src/main/java/org/eclipse/openvsx/adapter/ExtensionQueryParam.java#L26)

### Example

Run sample requests and see results in the [./tmp](./tmp/) directory.
  
```console
bash requests.sh
```

### Configs

- [package.yaml] - used by `hpack` to generate a `.cabal`
- [.markdownlint.jsonc](./.markdownlint.jsonc) - for `markdownlint` from the extension `davidanson.vscode-markdownlint`
- [.envrc](./.envrc) - for [direnv](https://github.com/direnv/direnv)
- [fourmolu.yaml](./fourmolu.yaml) - for [fourmolu](https://github.com/fourmolu/fourmolu#configuration)
