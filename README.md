# Nix VSCode Marketplace

At the time of writing this, searching `nixpkgs` yields around **200** VS Code extensions.
However, the VS Code marketplace contains more than **40,000** extensions!

This flake provides the Nix expressions for the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VSCode Marketplace](https://marketplace.visualstudio.com/vscode).

A GitHub action updates the extensions daily.

## Usage

### With flakes

Add the following to your `flake.nix` (see [Flakes](https://nixos.wiki/wiki/Flakes)).

```nix
inputs.nix-vscode-extensions = {
  url = "github:nix-community/nix-vscode-extensions";
};
```

Now, you can access the extensions from `VS Code Marketplace` and `Open VSX Registry`.

- `nix-vscode-extensions.packages.${system}.vscode.golang.go`
- `nix-vscode-extensions.packages.${system}.open-vsx.golang.go`

### Without flakes

This repo provides a `default.nix`, so you can use [niv](https://github.com/nmattia/niv) or `fetchGit` with an appropriate `rev`.

```nix
(import (builtins.fetchGit {
  url = "https://github.com/nix-community/nix-vscode-extensions";
  ref = "refs/heads/master";
  rev = "e5b6acfc794790e2c258853c34731c98a90d823d";
})).packages.x86_64-linux.vscode.golang.go
```

## Template

Try a template:

```console
nix flake new vscodium-project -t github:nix-community/nix-vscode-extensions#vscodium-with-extensions
cd vscodium-project
git init && git add .
nix develop
```

This will print the extensions available in `VSCodium`. Run `codium .` to start `VSCodium`.

## Troubleshooting

If `VSCodium` doesn't pick the extensions, try rebooting your computer and try again.

## Contribute

1. (Optional) Start `VSCodium` with necessary extensions

   ```console
   nix develop nix-dev/
   write-settings-json
   codium .
   ```

1. Select `TARGET` in `flake.nix`, e.g., `open-vsx`. Comment out another target like so: `# export TARGET=vscode-marketplace`.

1. Export variables

    ```console
    nix develop
    ```

1. Run scripts in this environment

    ```console
    nix run .#scripts.generateConfigs
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
