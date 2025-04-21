# Original implementation: https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/editors/vscode/extensions/ms-vsliveshare.vsliveshare
{
  pkgs,
  mktplcRef,
  vsix,
  buildVscodeMarketplaceExtension,
  ...
}:
buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;

  # Similar to https://github.com/NixOS/nixpkgs/blob/6f5808c6534d514751d6de0e20aae83f45d9f798/pkgs/applications/editors/vscode/extensions/ms-vsliveshare.vsliveshare/default.nix#L15-L18
  # Not sure it's necessary
  postPatch = ''
    substituteInPlace vendor.js \
      --replace-fail '"xsel"' '"${pkgs.xsel}/bin/xsel"'
  '';
}
