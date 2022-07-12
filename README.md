# Nix VSCode Marketplace

[Searcing `nixpkgs` yields 206 VSCode extensions at the time of writing this.][nixpkgs-query] However, the VSCode marketplace contains more than 50,000 extensions.

This flake includes the most popular 5,000 VSCode extensions at the time of writing.

## How this works

I wrote a small program to auto-generate the definitions for the extensions. However, the program needs to download the extension files to compute their `SHA256`. That's why I could not include the full extension set, as it would take ages to download the files for all of them.

Also, the program now requires me to run it manually. I'm open to help with making it an automatic job that runs in the cloud.

[nixpkgs-query]: https://search.nixos.org/packages?channel=unstable&from=0&size=50&sort=relevance&type=packages&query=vscode