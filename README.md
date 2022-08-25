# Nix VSCode Marketplace

At the time of writing this,
[searching `nixpkgs` yields 209 VSCode extensions.][nixpkgs-query]
However, the VSCode marketplace contains more than 50,000 extensions.

This flake includes all extensions from OpenVSX, and the 10k most downloaded
extensions from the VSCode Marketplace.

I've setup a GitHub action to update all extensions daily.

## How To Use

Add the flake as an input to your flake.

Then, you can directly use the extensions that this package exports. Or you can
use the overlay.

## Contribution

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
