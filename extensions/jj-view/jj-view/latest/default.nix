{
  lib,
  pkgs,
  stdenv,
  vscode-utils,

  mktplcRef,
  vsix,

  ...
}:
vscode-utils.buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;
}
// lib.optionalAttrs stdenv.hostPlatform.isLinux {
  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  buildInputs = [
    stdenv.cc.cc.lib
    pkgs.musl
  ];

  # Remove Android binaries before autoPatchelf scans native modules on Linux.
  preFixup = ''
    rm -rf "$out/share/vscode/extensions/${mktplcRef.publisher}.${mktplcRef.name}/dist/node_modules/@parcel/watcher-android-arm64"
  '';
}
