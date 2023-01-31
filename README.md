# Nix VSCode Extensions

At the time of writing this, searching `nixpkgs` yields around **200** `VS Code` extensions. However, the `VS Code Marketplace` contains more than **40,000** extensions!

This flake provides the Nix expressions for the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VSCode Marketplace](https://marketplace.visualstudio.com/vscode). A `GitHub Action` updates the extensions daily.

That said, you can now use a different set of extensions for `VS Code` (or `VSCodium`) in each of your projects. Moreover, you can share your flakes and cache them so that other people don't need to install these extensions manually!

## Note

- Extension names and publishers are lowercased
- If an extension's publisher or name aren't valid nix identifiers, you may access them by quoting the attribute names like `vscode-marketplace."4"."2"`
- You may search the repo to find out at what commit a given extension was available

## Template

This template shows how you can get a `VSCodium` with a couple of extensions. Try it:

```console
nix flake new vscodium-project -t github:nix-community/nix-vscode-extensions
cd vscodium-project
git init && git add .
nix develop
```

This will print the extensions available in `VSCodium`.
Run `codium .` or `nix run .#codium .` to start `VSCodium` in the current directory.

## Usage

### With flakes

Add the following to your `flake.nix` (see [Flakes](https://nixos.wiki/wiki/Flakes)).

```nix
inputs.nix-vscode-extensions = {
  url = "github:nix-community/nix-vscode-extensions";
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

Alternatively, use the overlay (see `overlays.default` in [flake.nix](./flake.nix)).

### Without flakes

This repo provides a `default.nix`, so you can use [niv](https://github.com/nmattia/niv) or `fetchGit` with an appropriate `rev`.

```nix
(import (builtins.fetchGit {
  url = "https://github.com/nix-community/nix-vscode-extensions";
  ref = "refs/heads/master";
  rev = "13378a0b6026e8b52ccb881454b43201cbe005b4";
})).extensions.x86_64-linux.vscode-marketplace.golang.go
```

Alternatively, you may use an overlay (see `overlays.default` in [flake.nix](./flake.nix)).

## Contribute

1. See the [issues](https://github.com/nix-community/nix-vscode-extensions/issues)

1. (Optionally) Install [direnv](https://direnv.net/), e.g., via `nix profile install nixpkgs#direnv`.

1. Start a devshell. When prompted about `extra-trusted-substituters` answer `y`. This is to use binary caches.

  ```console
  nix develop nix-dev/
  ```

1. (Optionally) Start `VSCodium` with necessary extensions

   ```console
   nix run nix-dev/#writeSettingsJson
   nix run nix-dev/#codium
   ```

## Troubleshooting

- If `VSCodium` doesn't pick the extensions, try rebooting your computer and starting `VSCodium` again.
- See [troubleshooting](https://github.com/deemp/flakes/blob/main/README/Troubleshooting.md).
