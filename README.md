# Nix VSCode Marketplace

At the time of writing this, searching `nixpkgs` yields 233 VS Code extensions
However, the VS Code marketplace contains more than 40,000 extensions.

This flake includes the majority of available extensions from [Open VSX](https://open-vsx.org/) and [VSCode Marketplace](https://marketplace.visualstudio.com/vscode).

A GitHub action updates the extensions daily.

## How To Use

Try a [template](https://github.com/br4ch1st0chr0n3/flakes#vscodium)

## Contribution

1. Select `TARGET` in `flake.nix`

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
