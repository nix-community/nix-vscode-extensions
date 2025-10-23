{ pkgs }:
let
  inherit (pkgs) callPackage lib;
in
{
  # Each extension may have several fixes that depend on the extension version.
  #
  # Fixes MUST be provided in the subdirectories of the ./extensions directory.
  #
  # A fix that works for versions up to `<version>`
  # of the extension `<name>` published by `<publisher>`
  # MUST be in the directory `./extensions/<publisher>/<name>/<version>`
  #
  # Each `${publisher}.${name}` in this file (`extensions/default.nix`) MUST provide
  # a function that produces an extension derivation.
  #
  # ```
  # { pkgs, lib, mktplcRef, vsix, buildVscodeMarketplaceExtension } -> Derivation
  # ```
  #
  # You may use less available attributes available in the function argument attrset.
  #
  # ```
  # { mktplcRef, ... } -> Derivation
  # ```

  ms-vsliveshare.vsliveshare = callPackage ./ms-vsliveshare/vsliveshare/latest;

  rust-lang.rust-analyzer = callPackage ./rust-lang/rust-analyzer/latest;

  sumneko.lua = callPackage ./sumneko/lua/latest;

  vadimcn.vscode-lldb =
    config@{ mktplcRef, ... }:
    let
      lowestSupportedVersion = "1.11.7";
    in
    if lib.versionAtLeast mktplcRef.version lowestSupportedVersion then
      # https://github.com/nix-community/nix-vscode-extensions/pull/151
      callPackage ./vadimcn/vscode-lldb/latest config
    else
      throw ''
        The version `${mktplcRef.version}` of `vadimcn.vscode-lldb` is unsupported.
         
        Only versions greater or equal to `${lowestSupportedVersion}` are supported.

        Try `extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace-universal.vadimcn.vscode-lldb`
        or  `extensions.${pkgs.stdenv.hostPlatform.system}.open-vsx-universal.vadimcn.vscode-lldb`.
      '';
}
