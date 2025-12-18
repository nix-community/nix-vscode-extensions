# See the Removed extensions section in the README.md
{
  aarch64-darwin = [
    # https://github.com/nix-community/nix-vscode-extensions/issues/100
    # https://github.com/NixOS/nixpkgs/blob/e983b262e7336dba29e057ce76f67ecb9bd495b3/pkgs/applications/editors/vscode/extensions/ms-vscode.cpptools/default.nix#L55
    "ms-vscode.cpptools"

    # https://github.com/NixOS/nixpkgs/blob/cb04ce958b9a3156922c7f8dcac09264d679ede8/pkgs/applications/editors/vscode/extensions/yzane.markdown-pdf/default.nix#L6
    # https://github.com/NixOS/nixpkgs/blob/cb04ce958b9a3156922c7f8dcac09264d679ede8/pkgs/applications/networking/browsers/chromium/browser.nix#L115
    "yzane.markdown-pdf"
  ];
  x86_64-darwin = [
    "ms-vscode.cpptools"
    "yzane.markdown-pdf"
  ];
}
