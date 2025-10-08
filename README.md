# Nix expressions for VS Code Extensions

As of October 2, 2025, the [nixpkgs](https://github.com/NixOS/nixpkgs) repository contains **456** [VS Code](https://code.visualstudio.com/) extensions. This is a small fraction of the nearly **80,000** extensions available on the [VS Code Marketplace](https://marketplace.visualstudio.com/vscode). In addition, many of the extensions in `nixpkgs` are outdated.

This flake provides Nix expressions for the latest pre-release and release versions of the majority of available extensions from the [VS Code Marketplace](https://marketplace.visualstudio.com/vscode) and the [Open VSX Registry](https://open-vsx.org/). A [GitHub Action](https://github.com/features/actions) updates these extensions daily.

## Important

### Don't abuse this flake

We have a permission from MS to use a crawler on their API (see the [discussion](https://github.com/NixOS/nixpkgs/issues/208456)).

Don't abuse this flake!

### nix4vscode

Check [nix4vscode](https://github.com/nix-community/nix4vscode) (and contribute!) if you need more extension versions.

## Prerequisites

### Read NixOS wiki

Read the [VS Code page](https://wiki.nixos.org/wiki/Visual_Studio_Code) on the NixOS wiki.

### (Optional) Enable flakes and experimental commands

- Read about [Nix flakes](https://wiki.nixos.org/wiki/Flakes).
- [Set them up](https://wiki.nixos.org/wiki/Flakes#Setup).
- Enable the [`nix-command`](https://nix.dev/manual/nix/2.31/contributing/experimental-features#xp-feature-nix-command) option to use [`nix repl`](https://nix.dev/manual/nix/2.31/command-ref/new-cli/nix3-repl) (see [Explore](#explore)) and other experimental commands. This option should already be enabled if you followed the setup instructions for flakes.

### (Optional) Allow unfree packages

See [Unfree extensions](#unfree-extensions).

### (Optional) Enter the repository directory

Clone this repository and enter its directory.

```console
git clone https://github.com/nix-community/nix-vscode-extensions
cd nix-vscode-extensions
```

### (Optional) Start REPL

See [nix repl](https://nix.dev/manual/nix/2.31/command-ref/new-cli/nix3-repl.html).

```console
nix repl
```

### (Optional) Get your system

```console
system="$(nix-instantiate --eval --expr "builtins.currentSystem")"
```

On my system:

```console
printf "$system"
"x86_64-linux"
```

> [!NOTE]
> You can use the value that you got on your machine instead of `builtins.currentSystem` in instructions below.

## History

You can search for an extension in the repository history:

- Get commits containing the extension: `git log -S '"copilot"' --oneline data/cache/vscode-marketplace-latest.json`
- Select a commit, e.g.: `0910d1e`
- Search in that commit: `git grep '"copilot"' 0910d1e -- data/cache/vscode-marketplace-latest.json`

## Example

The [`./nix/vscode-with-extensions.nix`](./nix/vscode-with-extensions.nix) provides an example of [vscode-with-extensions](https://github.com/NixOS/nixpkgs/blob/674c2b09c59a220204350ced584cadaacee30038/pkgs/applications/editors/vscode/with-extensions.nix).

This package is `VS Code` with a couple of extensions.

Run `VS Code` and list installed extensions.

### List extensions with flakes

```console
nix run github:nix-community/nix-vscode-extensions/fd5c5549692ff4d2dbee1ab7eea19adc2f97baeb#default -- --list-extensions
```

<!-- 
TODO

### List extensions without flakes

1. [Enter the repository directory](#optional-enter-the-repository-directory).
2. [Get your system](#optional-get-your-system).
3. List extensions, including already installed on your system (???):

    ```console
    nix-shell -A "packages.$system.default" --run 'code --list-extensions'
    ``` 
-->

## Template

This repository has a flake [template](template/flake.nix).

This template provides a [VSCodium](https://github.com/VSCodium/vscodium) with a couple of extensions.

1. Create a flake from the template (see [nix flake new](https://nixos.org/manual/nix/2.31/command-ref/new-cli/nix3-flake-new.html)).

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

If you use [NixOS](https://nixos.org/), [Home Manager](https://nix-community.github.io/home-manager/), or similar:

1. If you use flakes, add `nix-vscode-extensions` to your flake inputs (see [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L16)).

   ```nix
   inputs.nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/fd5c5549692ff4d2dbee1ab7eea19adc2f97baeb";
   outputs = inputs@{ nix-vscode-extensions, ... }: ...
   ```

1. If you don't use flakes, import the `nix-vscode-extensions` repository.

   ```nix
   let
     nix-vscode-extensions = import (
       builtins.fetchGit {
         url = "https://github.com/nix-community/nix-vscode-extensions";
         ref = "refs/heads/master";
         rev = "fd5c5549692ff4d2dbee1ab7eea19adc2f97baeb";
       }
     );
   in
   ```

1. Add the `nix-vscode-extensions.overlays.default` to `nixpkgs` overlays (see [Get `extensions` via the overlay](#get-extensions-via-the-overlay), [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L48)).

1. (Optional) Allow unfree packages (see [Unfree extensions](#unfree-extensions)).

1. Use `pkgs.nix-vscode-extensions.vscode-marketplace`, `pkgs.nix-vscode-extensions.open-vsx` and others (see [The `extensions` attrset](#the-extensions-attrset), [Explore](#explore), [example](https://github.com/maurerf/nix-darwin-config/blob/0f88b77e712f14e3da72ec0b640e206a37da7afe/flake.nix#L131)).

> [!NOTE]
> See [With-expressions](https://nix.dev/manual/nix/2.31/language/syntax#with-expressions).
>
> In `with A; with B;`, the attributes of `B` shadow the attributes of `A`.
>
> Keep in mind this property of `with` when writing `with vscode-marketplace; with vscode-marketplace-release;`.

## Get `extensions`

### Prerequisites

- [Start REPL](#optional-start-repl)

### Get `nixpkgs`

#### Get `nixpkgs` with flakes

```console
nix-repl> nixpkgs = builtins.getFlake github:NixOS/nixpkgs/674c2b09c59a220204350ced584cadaacee30038
```

#### Get `nixpkgs` without flakes

```console
nix-repl> nixpkgs = (import (builtins.fetchGit {
            url = "https://github.com/NixOS/nixpkgs";
            ref = "refs/heads/master";
            rev = "674c2b09c59a220204350ced584cadaacee30038";
          }))
```

### Get `nix-vscode-extensions`

#### Get `nix-vscode-extensions` with flakes

```console
nix-repl> nix-vscode-extensions = builtins.getFlake github:nix-community/nix-vscode-extensions/fd5c5549692ff4d2dbee1ab7eea19adc2f97baeb
```

#### Get `nix-vscode-extensions` without flakes

```console
nix-repl> nix-vscode-extensions = (import (builtins.fetchGit {
            url = "https://github.com/nix-community/nix-vscode-extensions";
            ref = "refs/heads/master";
            rev = "fd5c5549692ff4d2dbee1ab7eea19adc2f97baeb";
          }))
```

### Get `extensions` via the overlay

```console
nix-repl> extensions = (import nixpkgs { system = builtins.currentSystem; config.allowUnfree = true; overlays = [ nix-vscode-extensions.overlays.default ]; }).nix-vscode-extensions
```

### Get `extensions` from `nix-vscode-extensions`

```console
nix-repl> extensions = nix-vscode-extensions.extensions.${builtins.currentSystem}
```

## Extensions

### Platforms

We provide attrsets that contain both universal and platform-specific extensions.

We use a reasonable mapping between the sites target platforms and Nix-supported platforms (see `systemPlatform` in [flake.nix](./flake.nix), [issue](https://github.com/nix-community/nix-vscode-extensions/issues/20)).

### The `extensions` attrset

> [!NOTE]
> Here, `*` stands for a sequence of zero or more characters.

The [Get `extensions`](#get-extensions) section explains how to get the `extensions` attrset.

This attrset contains several attributes described in the sections [Extension attrsets](#extension-attrsets) and [Functions that produce extension attrsets](#functions-that-produce-extension-attrsets).

### Extension attrsets

We have no reliable way to choose the semantically latest cached version of an extension (see [cache files](#cache-files)).

Therefore, we used the following method:

1. We chose properties of extension versions that may predict whether a version is the latest one:
   - whether a version is pre-release or release;
   - whether a version is universal or platform-specific.
1. We prioritized all combinations of property values.
1. We created several attrsets of extensions with constraints on possible combinations of property values.
1. We named attrsets to show additional constraints. E.g., `vscode-marketplace*` attrsets contain only extensions from the `VS Code Marketplace`.
1. In each attrset, for each extension whose versions could be in that attrset, we provided a single highest-priority version of that extension.

The next sections show permitted property combinations and their priorities in corresponding attrsets.

#### `vscode-marketplace` and `open-vsx`

1. pre-release platform-specific
2. pre-release universal
3. release platform-specific
4. release universal

#### `vscode-marketplace-release` and `open-vsx-release`

1. release platform-specific
2. release universal

#### `vscode-marketplace-universal` and `open-vsx-universal`

1. pre-release universal
2. release universal

#### `vscode-marketplace-release-universal` and `open-vsx-release-universal`

1. release universal

### Functions that produce extension attrsets

#### `forVSCodeVersion`

`forVSCodeVersion version` produces an attrset similar to `extensions` (see [The `extensions` attrset](#the-extensions-attrset)) but containing only the extensions [compatible](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#visual-studio-code-compatibility) with the `version` version of `VS Code` (see [Versions compatible with a given version of VS Code](#versions-compatible-with-a-given-version-of-vs-code)).

You should replace `version` with your `VS Code` or `VSCodium` version.

#### `usingFixesFrom`

`usingFixesFrom nixpkgsWithFixes` produces an attrset where particular extensions have fixes specified in the supplied `nixpkgsWithFixes` (see `mkExtensionNixpkgs` in [mkExtension.nix](#mkextensionnix), [Versions with fixes from particular `nixpkgs`](#versions-with-fixes-from-particular-nixpkgs), [Use fixes from `nixpkgs`](#use-fixes-from-nixpkgs)).

- The supplied `nixpkgsWithFixes` can be any version of `nixpkgs` (see [Get `nixpkgs`](#get-nixpkgs)).
- The supplied `nixpkgsWithFixes` is used only to look up the fixes in its source code and is independent of the `nixpkgs` that you apply the overlay to.

The top-level `vscode-marketplace*` and `open-vsx*` attributes are constructed using fixes from `nixpkgs` that you apply the overlay to (if you [get `extensions` via the overlay](#get-extensions-via-the-overlay)) or `nixpkgs` from the `nix-vscode-extensions` repository (if you [get `extensions` from `nix-vscode-extensions`](#get-extensions-from-nix-vscode-extensions)).

### Extension identifiers

- Extension publishers and names are lowercased only in Nix.
  - They're not lowercased in `.json` [cache files](#cache-files).
- Access an extension in the format `<attrset>.<publisher>.<name>`, where `<attrset>` is `vscode-marketplace`, `open-vsx`, etc. (see [Explore](#explore)).
- If an extension publisher or name aren't valid Nix identifiers, quote them like `<attrset>."4"."2"`.

### Missing extensions

- Some previously available extensions may be unavailable in newer versions of this flake.
  - An extension is missing if it doesn't appear during a particular workflow run in a `VS Code Marketplace` or an `Open VSX` response about the full set of available extensions (see [discussion](https://github.com/nix-community/nix-vscode-extensions/issues/16#issuecomment-1441025955)).
  - We let missing extensions remain in [cache files](#cache-files) and plan to purge missing extensions periodically (see [#139](https://github.com/nix-community/nix-vscode-extensions/issues/139)).

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

### Prerequisites

- [Get `extensions`](#get-extensions)

> [!NOTE]
> Press the `Tab` button (denoted as `<TAB>` below) to see attrset attributes.

### Explore `extensions`

```console
nix-repl> extensions.<TAB>
extensions.forVSCodeVersion                      extensions.vscode-marketplace
extensions.open-vsx                              extensions.vscode-marketplace-release
extensions.open-vsx-release                      extensions.vscode-marketplace-release-universal
extensions.open-vsx-release-universal            extensions.vscode-marketplace-universal
extensions.open-vsx-universal
extensions.usingFixesFrom
```

### Explore `vscode-marketplace` and `open-vsx`

See [`vscode-marketplace` and `open-vsx`](#vscode-marketplace-and-open-vsx).

```console
nix-repl> extensions.vscode-marketplace.rust-lang.rust-analyzer.version
"0.4.2638"
```

```console
nix-repl> extensions.vscode-marketplace.vadimcn.vscode-lldb.version
"1.11.0"
```

### Explore `vscode-marketplace-release` and `open-vsx-release`

See [`vscode-marketplace-release` and `open-vsx-release`](#vscode-marketplace-release-and-open-vsx-release).

```console
nix-repl> extensions.vscode-marketplace-release.rust-lang.rust-analyzer.version
"0.3.2593"
```

```console
nix-repl> extensions.vscode-marketplace-release.vadimcn.vscode-lldb.version
"1.11.0"
```

### Explore `vscode-marketplace-universal` and `open-vsx-universal`

See [`vscode-marketplace-universal` and `open-vsx-universal`](#vscode-marketplace-universal-and-open-vsx-universal).

```console
nix-repl> extensions.vscode-marketplace-universal.rust-lang.rust-analyzer.version
"0.4.1067"
```

```console
nix-repl> extensions.vscode-marketplace-universal.vadimcn.vscode-lldb.version
"1.11.6"
```

### Explore `vscode-marketplace-release-universal` and `open-vsx-release-universal`

See [`vscode-marketplace-release-universal` and `open-vsx-release-universal`](#vscode-marketplace-release-universal-and-open-vsx-release-universal).

```console
nix-repl> extensions.vscode-marketplace-release-universal.vadimcn.vscode-lldb.version
"1.11.6"
```

### Versions compatible with a given version of VS Code

See [`forVSCodeVersion`](#forvscodeversion).

```console
nix-repl> extensionsCompatible = extensions.forVSCodeVersion "1.78.2"
```

The `extensionsCompatible` attrset contains some of the [the `extensions` attrset](#the-extensions-attrset) attributes.

### Versions with fixes from particular `nixpkgs`

Some extensions require non-trivial fixes ([example](https://github.com/nix-community/nix-vscode-extensions/issues/69)).

These fixes may be available in a particular version of `nixpkgs`.

These fixes are read from the source code of that `nixpkgs` version (see `mkExtensionNixpkgs` in [mkExtension.nix](#mkextensionnix)).

#### Use fixes from `nixpkgs`

[Get `extensions`](#get-extensions).

In this case, we use the same version of `nixpkgs` that was used to get `extensions`.
You can use any other version instead.

```console
nix-repl> extensionsFixed = extensions.usingFixesFrom nixpkgs
```

The `extensionsFixed` attrset contains some of the [the `extensions` attrset](#the-extensions-attrset) attributes.

### Removed extensions

Some extensions are unavailable or don't work on particular platforms.

These extensions are disabled via [removed.nix](./removed.nix).

## Config

See:

- [`./config.yaml`](./config.yaml)

<!-- TODO provide command to print config -->

## Cache

### Cache files

See:

- [`./data/cache`](./data/cache)
- [`./data/cache/open-vsx-latest.json`](./data/cache/open-vsx-latest.json)
- [`./data/cache/vscode-marketplace-latest.json`](./data/cache/vscode-marketplace-latest.json)

### Cache object example

```json
{
  "p": "haskell",
  "n": "haskell",
  "r": 0,
  "s": 0,
  "v": "2.7.0",
  "e": "^1.102.0",
  "m": 2,
  "h": "sha256-rkQw8A2irw1AcUCnEffG5BNPuQQF9dfjiRHHXPdK/zU="
}
```

### Intermediate Nix representation

| JSON key | Nix attrname    | Description                                                                                                                                      |
| -------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `p`      | `publisher`     | extension publisher                                                                                                                              |
| `n`      | `name`          | extension name                                                                                                                                   |
| `r`      | `isRelease`     | whether it's a release extension version                                                                                                         |
| `P`      | `platform`      | extension platform                                                                                                                               |
| `v`      | `version`       | extension version                                                                                                                                |
| `e`      | `engineVersion` | engine version (minimal compatible VSCode version)                                                                                               |
| `m`      | N/A             | [missing times](../README.md#missing-extensions)                                                                                                 |
| `h`      | `hash`          | extension `.vsix` hash obtained via [nix store prefetch-file](https://nix.dev/manual/nix/2.31/command-ref/new-cli/nix3-store-prefetch-file.html) |

### Values

In the [./flake.nix](./flake.nix):

- `numberToPlatform` converts `s` to `platform`;
- `numberToIsRelease` converts `r` to `isRelease`.

### Nix

### `mkExtension.nix`

[`./nix/mkExtension.nix`](./nix/mkExtension.nix) provides a function to build an extension from an extension config.

## Contribute

### Issues

Resolve [issues](https://github.com/nix-community/nix-vscode-extensions/issues).

### Pull requests

Make [pull requests](https://github.com/nix-community/nix-vscode-extensions/pulls).

### README

- Fix links.
- Write new sections.
- Update commit hashes used in examples if they're too old.
- Enhance the text.

### Extra extensions

The [extra-extensions.toml](extra-extensions.toml) file contains a list of extensions to be fetched from sites other than `VS Code Marketplace` and `Open VSX`.
These extensions replace ones fetched from `VS Code Marketplace` and `Open VSX`.
Add necessary extensions there, preferrably, for all supported platforms (see [Extensions](#extensions)).
[nvfetcher](https://github.com/berberman/nvfetcher) will fetch the latest release versions of these extensions and write configs to [generated.nix](data/extra-extensions/generated.nix).

### Special extensions

Certain extensions require special treatment.

Provide functions to build such extension in the [extensions](extensions) directory (see [extensions/default.nix](./extensions/default.nix)).

Optionally, create and link issues explaining chosen functions.

Each extension, including [Extra extensions](#extra-extensions), is built via one of the functions in [mkExtension.nix](#mkextensionnix).

These functions don't modify the license of ([unfree](https://wiki.nixos.org/wiki/Unfree_software)) extensions from `nixpkgs`.

#### Build problems

- Extension with multiple extensions in a zipfile ([issue](https://github.com/nix-community/nix-vscode-extensions/issues/31))
- Platform-specific extensions ([comment](https://github.com/nix-community/nix-vscode-extensions/issues/20#issuecomment-1543679655))

### Haskell script

See the [./haskell/README.md](./haskell/README.md#quick-start).

## Troubleshooting

- If `Nix`-provided `VSCodium` doesn't pick up the extensions:
  - Close other instances of `Nix`-provided `VSCodium` and start `VSCodium` again.
  - Try to reboot your computer and start `VSCodium` again.
