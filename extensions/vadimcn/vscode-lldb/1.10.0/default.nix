# Credit to https://github.com/nix-community/nix-vscode-extensions/issues/52#issue-2129112776
{
  pkgs,
  lib,
  mktplcRef,
  vsix,
  buildVscodeMarketplaceExtension,
  ...
}:
buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;

  postInstall = lib.optionalString pkgs.stdenv.isLinux ''
    cd "$out/$installPrefix"
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./adapter/codelldb
    patchelf --add-rpath "${lib.makeLibraryPath [ pkgs.zlib ]}" ./lldb/lib/liblldb.so
  '';
}
