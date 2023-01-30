# Nix VSCode Extensions

At the time of writing this, searching `nixpkgs` yields around **200** `VS Code` extensions. However, the `VS Code Marketplace` contains more than **40,000** extensions!

This flake provides the Nix expressions for the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VSCode Marketplace](https://marketplace.visualstudio.com/vscode). A `GitHub Action` updates the extensions daily.

That said, you can now use a different set of extensions for `VS Code` (or `VSCodium`) in each of your projects. Moreover, you can share your flakes so that other people don't need to install these extensions manually!

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

nix-repl> inputs.nix-vscode-extensions.extensions.x86_64-linux.vscode.golang.go
«derivation /nix/store/ldx15dnxwd1sa3gb2lvs1rl4v0f5cq11-vscode-extension-golang-Go-0.37.1.drv»

nix-repl> inputs.nix-vscode-extensions.extensions.x86_64-linux.open-vsx.golang.go
«derivation /nix/store/sq3bm44dl8k1g1mm2daqix3ayjn289j2-vscode-extension-golang-Go-0.37.1.drv»
```

The [template](./template/flake.nix) demonstrates how to use the extensions with `VSCodium`.

### Without flakes

This repo provides a `default.nix`, so you can use [niv](https://github.com/nmattia/niv) or `fetchGit` with an appropriate `rev`.

```nix
(import (builtins.fetchGit {
  url = "https://github.com/nix-community/nix-vscode-extensions";
  ref = "refs/heads/master";
  rev = "ed701255dd9d4ae1aa12ab7f82d05bd3a85580b5";
})).extensions.x86_64-linux.vscode.golang.go
```

### Note

- Extension names and publishers are lowercased
- If an extension's name or publisher start not with a letter, you may access them by quoting the attribute names like vscode."2strangeextension"."3strangepublisher"

## Template

This template shows how you can get a `VSCodium` with a couple of extensions. Try it:

```console
nix flake new vscodium-project -t github:nix-community/nix-vscode-extensions
cd vscodium-project
git init && git add .
nix develop
```

This will print the extensions available in `VSCodium`. Run `codium .` to start `VSCodium`.

## Troubleshooting

If `VSCodium` doesn't pick the extensions, try rebooting your computer and try again.

## Contribute

1. (Optionally) Start `VSCodium` with necessary extensions

   ```console
   nix develop nix-dev/
   write-settings-json
   codium .
   ```

1. Select `TARGET` in `nix-dev/flake.nix`, e.g., `open-vsx`. Comment out another target like so: `# export TARGET=vscode-marketplace`.

1. Export variables

    ```console
    nix develop nix-dev/
    ```

1. Run scripts in this environment

    ```console
    nix run nix-dev/#generateConfigs
    ```

Improvement on any part of this project is welcome. These are possible areas of
improvement that I have in mind:

- License information is only included with OpenVSX extensions. This is because
I could not obtain license information from the official VSCode Marketplace API.
The official API is not documented at all, so I'm not sure if I can get license
information out of it or not.
- The Nix expressions that converts the output of Nvfetcher to package
definitions is not the most pretty Nix expressions ever.
- The GitHub action is not great either. I'm sure it can be way better, but I'm
not particularly good with actions (this is my first one ever).
