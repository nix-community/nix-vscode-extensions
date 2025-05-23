# Nix expressions for VS Code Extensions

At the time of writing this, `nixpkgs` contains **271** `VS Code` extensions. This is a small fraction of the more than **40,000** extensions in the `VS Code Marketplace`! In addition, many of the extensions in `nixpkgs` are significantly out-of-date.

This flake provides Nix expressions for the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VS Code Marketplace](https://marketplace.visualstudio.com/vscode). A `GitHub Action` updates the extensions daily.

That said, you can now use a different set of extensions for `VS Code`/`VSCodium` in each of your projects. Moreover, you can share your flakes and cache them so that other people don't need to install these extensions manually!

## Note

### API crawler

- We have a permission from MS to use a crawler on their API (see the [discussion](https://github.com/NixOS/nixpkgs/issues/208456)). Don't abuse this flake!

### nix4vscode

- Check [nix4vscode](https://github.com/nix-community/nix4vscode) (and contribute!) if you need a more individual approach to extensions.

### Prerequisites

- [VS Code](https://wiki.nixos.org/wiki/Visual_Studio_Code) page on the NixOS wiki.
- (Optional) [Flakes](https://wiki.nixos.org/wiki/Flakes).

## History

You can search for an extension in the repository history:

- Get commits containing the extension: `git log -S '"copilot"' --oneline data/cache/vscode-marketplace-latest.json`
- Select a commit, e.g.: `0910d1e`
- Search in that commit: `git grep '"copilot"' 0910d1e -- data/cache/vscode-marketplace-latest.json`

## Example

The [flake.nix](./flake.nix) provides an example (`packages.${builtins.currentSystem}.default`) of [vscode-with-extensions](https://github.com/NixOS/nixpkgs/blob/81b9a5f9d1f7f87619df26a4eaf48bf6dec8c82c/pkgs/applications/editors/vscode/with-extensions.nix).

This package is `VS Code` with a couple of extensions.

Run `VS Code` and list installed extensions.

```console
nix run github:nix-community/nix-vscode-extensions/00e11463876a04a77fb97ba50c015ab9e5bee90d# -- --list-extensions
```

## Template

This repository has a flake [template](template/flake.nix).

This template provides a [VSCodium](https://github.com/VSCodium/vscodium) with a couple of extensions.

1. Create a flake from the template (see [nix flake new](https://nixos.org/manual/nix/latest/command-ref/new-cli/nix3-flake-new.html)).

   ```console
   nix flake new vscodium-project -t github:nix-community/nix-vscode-extensions
   cd vscodium-project
   git init && git add .
   ```

1. Run `VSCodium`.

   ```console
   nix run .# .
   ```

1. Alternatively, start a devShell and run `VSCodium`. A `shellHook` will print extensions available in the `VSCodium`.

   ```console
   nix develop .#vscodium
   codium .
   ```

In case of problems see [Troubleshooting](#troubleshooting).

## Overlay

See [Overlays](https://wiki.nixos.org/wiki/Overlays#Using_overlays).

If you use NixOS, Home Manager, or similar:

1. If you use flakes, add `nix-vscode-extensions` to your flake inputs (see [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L16)).

   ```nix
   inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/00e11463876a04a77fb97ba50c015ab9e5bee90d";
   outputs = inputs@{ nix-vscode-extensions, ... }: ...
   ```

1. If you don't use flakes, import the `nix-vscode-extensions` repository.

   ```nix
   let
     nix-vscode-extensions = import (
       builtins.fetchGit {
         url = "https://github.com/nix-community/nix-vscode-extensions";
         ref = "refs/heads/master";
         rev = "00e11463876a04a77fb97ba50c015ab9e5bee90d";
       }
     );
   in
   ```

1. Add the `nix-vscode-extensions.overlays.default` to `nixpkgs` overlays (see [Get `extensions` via the overlay](#get-extensions-via-the-overlay), [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L48)).

1. (Optional) Allow unfree packages (see [Unfree extensions](#unfree-extensions)).

1. Use `pkgs.nix-vscode-extensions.vscode-marketplace`, `pkgs.nix-vscode-extensions.open-vsx` and others (see [`extensions` attrsets](#extensions-attrsets), [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L131)).

> [!NOTE]
> See [With-expressions](https://nix.dev/manual/nix/latest/language/syntax#with-expressions).
>
> In `with A; with B;`, the attributes of `B` shadow the attributes of `A`.
>
> Keep in mind this property of `with` when writing `with vscode-marketplace; with vscode-marketplace-release;`.

## Get `extensions`

### Start REPL

See [nix repl](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-repl.html).

```console
nix repl
```

### Get your system

```console
nix-repl> builtins.currentSystem
```

Output on my machine:

```console
x86_64-linux
```

### Get `nixpkgs`

#### Get `nixpkgs` with flakes

```console
nix-repl> nixpkgs = builtins.getFlake github:nixos/nixpkgs/ebe4301cbd8f81c4f8d3244b3632338bbeb6d49c
```

#### Get `nixpkgs` without flakes

```console
nix-repl> nixpkgs = (import (builtins.fetchGit {
            url = "https://github.com/NixOS/nixpkgs";
            ref = "refs/heads/master";
            rev = "ebe4301cbd8f81c4f8d3244b3632338bbeb6d49c";
          }))
```

### Get `nix-vscode-extensions`

#### Get `nix-vscode-extensions` with flakes

```console
nix-repl> nix-vscode-extensions = builtins.getFlake github:nix-community/nix-vscode-extensions/00e11463876a04a77fb97ba50c015ab9e5bee90d
```

#### Get `nix-vscode-extensions` without flakes

```console
nix-repl> nix-vscode-extensions = (import (builtins.fetchGit {
            url = "https://github.com/nix-community/nix-vscode-extensions";
            ref = "refs/heads/master";
            rev = "00e11463876a04a77fb97ba50c015ab9e5bee90d";
          }))
```

### Get `extensions` via the overlay

```console
nix-repl> extensions = import nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; overlays = [ nix-vscode-extensions.overlays.default ]; }
```

If you want `extensions` to have only [`extensions` attrsets](#extensions-attrsets), get `extensions` as follows:

```console
nix-repl> extensions = (import nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; overlays = [ nix-vscode-extensions.overlays.default ]; }).nix-vscode-extensions
```

### Get `extensions` from `nix-vscode-extensions`

```console
nix-repl> extensions = nix-vscode-extensions.extensions.x86_64-linux
```

## Extensions

### Platforms

We provide attrsets that contain both universal and platform-specific extensions.

We use a reasonable mapping between the sites target platforms and Nix-supported platforms (see `systemPlatform` in [flake.nix](./flake.nix), [issue](https://github.com/nix-community/nix-vscode-extensions/issues/20)).

### `extensions` attrsets

The [Get `extensions`](#get-extensions) section explains how to get the `extensions` attrset.

This attrset contains the following attributes:

- `vscode-marketplace` and `open-vsx` contain the latest versions of extensions, including pre-release ones. Such pre-release versions expire in some time. That's why, there are `*-release` attrsets.
- `vscode-marketplace-release` and `open-vsx-release` contain the release versions of extensions (see [Release extensions](#release-extensions)).
- `forVSCodeVersion` - `forVSCodeVersion "1.78.2"` produces an attrset containing only the extensions [compatible](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#visual-studio-code-compatibility) with the `"1.78.2"` version of `VS Code` (see [Versions compatible with a given version of VS Code](#versions-compatible-with-a-given-version-of-vs-code)).
  - You may supply the actual version of your `VS Code` instead of `"1.78.2"`.
- `usingFixesFrom` - `usingFixesFrom nixpkgsWithFixes` produces an attrset where particular extensions have fixes specified in the supplied `nixpkgsWithFixes` (see `mkExtensionNixpkgs` in [mkExtension.nix](./mkExtension.nix), [Versions with fixes from particular `nixpkgs`](#versions-with-fixes-from-particular-nixpkgs)).
  - The supplied `nixpkgsWithFixes` can be any version of `nixpkgs` (see [Get `nixpkgs`](#get-nixpkgs)).
  - The supplied `nixpkgsWithFixes` is used only to look up the fixes in its source code and is independent of the `nixpkgs` that you apply the overlay to.
- The top-level `vscode-marketplace*` and `open-vsx*` attributes are constructed using fixes from `nixpkgs` that you apply the overlay to (if you [get `extensions` via the overlay](#get-extensions-via-the-overlay)) or `nixpkgs` from the `nix-vscode-extensions` repository (if you [get `extensions` from `nix-vscode-extensions`](#get-extensions-from-nix-vscode-extensions)).

### Extension identifiers

- Extension publishers and names are lowercased only in Nix.
  - They're not lowercased in `.json` cache files such as [data/cache/open-vsx-latest.json](./data/cache/open-vsx-latest.json).
- Access an extension in the format `<attrset>.<publisher>.<name>`, where `<attrset>` is `vscode-marketplace`, `open-vsx`, etc. (see [Explore](#explore)).
- If an extension publisher or name aren't valid Nix identifiers, quote them like `<attrset>."4"."2"`.

### Missing extensions

- Some previously available extensions may be unavailable in newer versions of this flake.
  - An extension is missing if it doesn't appear during a particular workflow run in a `VS Code Marketplace` or an `Open VSX` response about the full set of available extensions ([discussion](https://github.com/nix-community/nix-vscode-extensions/issues/16#issuecomment-1441025955)).
  - We let missing extensions remain in cache files (see [data/cache](./data/cache)) at most `maxMissingTimes` (specified in [.github/config.yaml](.github/config.yaml)).

### Extension packs

- We don't automatically handle extension packs. You should look up extensions in a pack and explicitly write all necessary extensions.

### Unfree extensions

- We use derivations and code from `nixpkgs` for some extensions (see [Versions with fixes from particular `nixpkgs`](#versions-with-fixes-from-particular-nixpkgs)).
- Unfree extensions from `nixpkgs` stay unfree here (see [Unfree software](https://wiki.nixos.org/wiki/Unfree_software), [Special extensions](#special-extensions)).
- If you want to use unfree extensions, try one of the following ways:

  - [Installing unfree packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree).
  - [Global configuration](https://nixos.org/manual/nixpkgs/stable/#chap-packageconfig) - [Example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L45).
  - Set `config.allowUnfree = true` when constructing `pkgs`.

    ```nix
    pkgs = import nixpkgs {
      system = builtins.currentSystem;
      config.allowUnfree = true;
      overlays = [ overlays.default ];
    }
    ```

  - Override the license of a particular extension.

    ```nix
    let
      resetLicense =
        drv:
        drv.overrideAttrs (prev: {
          meta = prev.meta // {
            license = [ ];
          };
        });
    in
    resetLicense <publisher>.<name>
    ```

## Explore

[Start REPL](#start-repl).

> [!NOTE]
> Press the `Tab` button (denoted as `<TAB>` below) to see attrset attributes.

### Explore `extensions`

```console
nix-repl> extensions.<TAB>
extensions.forVSCodeVersion            extensions.usingFixesFrom
extensions.open-vsx                    extensions.vscode-marketplace
extensions.open-vsx-release            extensions.vscode-marketplace-release
```

### Latest versions

```console
nix-repl> extensions.vscode-marketplace.rust-lang.rust-analyzer
«derivation /nix/store/v2dyb61zg6faalpcz4faf6dd0ckgbcsp-vscode-extension-rust-lang-rust-analyzer-0.4.2434.drv»
```

### Release versions

```console
nix-repl> extensions.vscode-marketplace-release.rust-lang.rust-analyzer
«derivation /nix/store/5xhr4a3j62awpnsd9l0llq2yn9q4gb6r-vscode-extension-rust-lang-rust-analyzer-0.3.2433.drv»
```

### Versions compatible with a given version of VS Code

```console
nix-repl> extensionsCompatible = extensions.forVSCodeVersion "1.78.2"
```

The `extensionsCompatible` attrset contains some of the [`extensions` attrsets](#extensions-attrsets).

### Versions with fixes from particular `nixpkgs`

Some extensions require non-trivial fixes ([example](https://github.com/nix-community/nix-vscode-extensions/issues/69)).

These fixes may be available in a particular version of `nixpkgs`.

These fixes are read from the source code of that `nixpkgs` version (see `mkExtensionNixpkgs` in [mkExtension.nix](./mkExtension.nix)).

#### Use fixes from `nixpkgs`

[Get `extensions`](#get-extensions).

In this case, we use the same version of `nixpkgs` that was used to get `extensions`.
You can use any other version instead.

```console
nix-repl> extensionsFixed = extensions.usingFixesFrom nixpkgs
```

The `extensionsFixed` attrset contains some of the [`extensions` attrsets](#extensions-attrsets).

### Removed extensions

Some extensions are unavailable or don't work on particular platforms.

These extensions are disabled via [removed.nix](./removed.nix).

## Contribute

### Issues

Resolve [issues](https://github.com/nix-community/nix-vscode-extensions/issues).

### README

- Fix links.
- Write new sections.
- Update commit hashes used in examples if they're too old.
- Enhance text.

### Release extensions

The [config](.github/config.yaml) contains several extensions.
We cache the information about the latest **release** versions of these extensions (see [Extensions](#extensions)).

You can add new extensions to the config and make a Pull Request.
Use the original extension publisher and name, e.g. `GitHub` and `copilot`.

### Extra extensions

The [extra-extensions.toml](extra-extensions.toml) file contains a list of extensions to be fetched from sites other than `VS Code Marketplace` and `Open VSX`.
These extensions replace ones fetched from `VS Code Marketplace` and `Open VSX`.
Add necessary extensions there, preferrably, for all supported platforms (see [Extensions](#extensions)).
[nvfetcher](https://github.com/berberman/nvfetcher) will fetch the latest release versions of these extensions and write configs to [generated.nix](data/extra-extensions/generated.nix).

### Special extensions

Certain extensions require special treatment.

Provide functions to build such extension in the [extensions](extensions) directory (see [extensions/default.nix](./extensions/default.nix)).

Optionally, create and link issues explaining chosen functions.

Each extension, including [Extra extensions](#extra-extensions), is built via one of the functions in [mkExtension.nix](mkExtension.nix).

These functions don't modify the license of ([unfree](https://wiki.nixos.org/wiki/Unfree_software)) extensions from `nixpkgs`.

#### Build problems

- Extension with multiple extensions in a zipfile ([issue](https://github.com/nix-community/nix-vscode-extensions/issues/31))
- Platform-specific extensions ([comment](https://github.com/nix-community/nix-vscode-extensions/issues/20#issuecomment-1543679655))

### Main flake

1. (Optionally) [Install](https://direnv.net/#basic-installation), e.g., via `nix profile install nixpkgs#direnv`.

1. Run a devshell. When prompted about `extra-trusted-substituters` answer `y`. This is to use binary caches.

   ```console
   nix develop nix-dev/
   ```

1. (Optionally) Start `VSCodium` with necessary extensions and tools.

   ```console
   nix run nix-dev/#codium .
   ```

### Haskell script

1. See the [README](./haskell/README.md).

1. Set the environment.

   ```console
   set -a
   source .env
   ```

1. Run the script.

   ```console
   nix run haskell/#updateExtensions
   ```

### Pull requests

Pull requests are welcome!

## Troubleshooting

- If `Nix`-provided `VSCodium` doesn't pick up the extensions:
  - Close other instances of `Nix`-provided `VSCodium` and start `VSCodium` again.
  - Try to reboot your computer and start `VSCodium` again.
