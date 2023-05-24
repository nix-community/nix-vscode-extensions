# Nix expressions for VS Code Extensions

At the time of writing this, searching `nixpkgs` yields around **200** `VS Code` extensions. However, the `VS Code Marketplace` contains more than **40,000** extensions!

This flake provides the Nix expressions for the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VS Code Marketplace](https://marketplace.visualstudio.com/vscode). A `GitHub Action` updates the extensions daily.

That said, you can now use a different set of extensions for `VS Code` (or `VSCodium`) in each of your projects. Moreover, you can share your flakes and cache them so that other people don't need to install these extensions manually!

## Note

- Extension names and publishers are lowercased.
- If an extension's publisher or name aren't valid Nix identifiers, you may access them by quoting the attribute names like `vscode-marketplace."4"."2"`.
- You may search the repo to find out at what commit a given extension was available.
- We have a permission from MS to use a crawler on their API in this case (see the [discussion](https://github.com/NixOS/nixpkgs/issues/208456)). Please, don't abuse this flake!

## Template

A template shows how you can get a [VSCodium](https://github.com/VSCodium/vscodium) with a couple of extensions. Try it:

```console
nix flake new vscodium-project -t github:nix-community/nix-vscode-extensions
cd vscodium-project
git init && git add .
nix develop
```

This will print the extensions available in `VSCodium`.

Run `codium .` or `nix run .#codium .` to start `VSCodium` in the current directory.

In case of problems see [Troubleshooting](#troubleshooting).

## Example

There's a sample package `vscodium-with-extensions` with a couple of extensions that you can try.

```console
nix run github:nix-community/nix-vscode-extensions#vscodium-with-extensions -- --list-extensions
```

## Usage

### Extensions

We provide extensions attrsets that contain both universal and platform-specific extensions.
We provide a [reasonable](https://github.com/nix-community/nix-vscode-extensions/issues/20) mapping between the sites target platforms and Nix-supported platforms.

There are several attrsets

- `vscode-marketplace` and `open-vsx` contain the latest versions of extensions, including pre-release ones. Such pre-release versions expire in some time. That's why, there are `-release` attrsets.
- `vscode-marketplace-release` and `open-vsx-release` contain the release versions of extensions manually listed in the [config](hs/config.json).
- `forVSCodeVersion "4.228.1"` allows to leave only the extensions [compatible](https://code.visualstudio.com/api/working-with-extensions/publishing-extension#visual-studio-code-compatibility) with the `"4.228.1"` version of `VS Code`.
  - You may supply the actual version of your `VS Code` instead of `"4.228.1"`.

### With flakes

Add the following to your `flake.nix` (see [Flakes](https://nixos.wiki/wiki/Flakes)).

```nix
inputs = {
  nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
};
```

Now, you can explore the extensions in `nix repl`:

```sh
$ nix repl
nix-repl> :lf .
Added 10 variables.

nix-repl> inputs.nix-vscode-extensions.extensions.x86_64-linux.vscode-marketplace.golang.go
«derivation /nix/store/ldx15dnxwd1sa3gb2lvs1rl4v0f5cq11-vscode-extension-golang-Go-0.37.1.drv»

nix-repl> inputs.nix-vscode-extensions.extensions.x86_64-linux.open-vsx.golang.go
«derivation /nix/store/sq3bm44dl8k1g1mm2daqix3ayjn289j2-vscode-extension-golang-Go-0.37.1.drv»
```

Alternatively, use an overlay (see `overlays.default` in [flake.nix](./flake.nix)).

### Without flakes

This repo provides a `default.nix`, so you can use, e.g.

```nix
(import (builtins.fetchGit {
  url = "https://github.com/nix-community/nix-vscode-extensions";
  ref = "refs/heads/master";
  rev = "a1980daf16eb0d8acfb6e17953d3945bfdac9a4d";
})).extensions.x86_64-linux.vscode-marketplace.golang.go
```

Alternatively, you may use an overlay (see `overlays.default` in [flake.nix](./flake.nix)).

## Contribute

### Release extensions

The [config](hs/config.json) contains several extensions.
We cache the information about the latest release versions of these extensions (see [Extensions](#extensions)).
If you'd like to use release versions of an extension, please, add that extension to the config and make a PR.

### Main flake

1. See the [issues](https://github.com/nix-community/nix-vscode-extensions/issues)

1. (Optionally) Install [direnv](https://direnv.net/), e.g., via `nix profile install nixpkgs#direnv`.

1. Run a devshell. When prompted about `extra-trusted-substituters` answer `y`. This is to use binary caches.

    ```console
    nix develop nix-dev/
    ```

1. (Optionally) Start `VSCodium` with necessary extensions and tools

    ```console
    nix run nix-dev/#writeSettingsJson
    nix run nix-dev/#codium .
    ```

### Haskell script

1. See the [hs/README.md](./hs/README.md)

1. Get the environment.

    ```console
    set -a
    source .env
    ```

1. Run the script.

    ```console
    nix run hs/#updateExtensions
    ```

## Troubleshooting

- If `VSCodium` doesn't pick up the extensions, try to reboot your computer and start `VSCodium` again.
- See [troubleshooting](https://github.com/deemp/flakes/blob/main/README/Troubleshooting.md).
