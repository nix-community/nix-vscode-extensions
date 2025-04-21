# Original implementation: https://github.com/NixOS/nixpkgs/blob/4f48368f11e7329735ab76d890f18f8d4be3f60f/pkgs/applications/editors/vscode/extensions/sumneko.lua/default.nix
{
  pkgs,
  mktplcRef,
  vsix,
  buildVscodeMarketplaceExtension,
  ...
}:
buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;

  patches = [ ./remove-chmod.patch ];

  postInstall = ''
    ln -sf ${pkgs.lua-language-server}/bin/lua-language-server \
      $out/$installPrefix/server/bin/lua-language-server
  '';
}
