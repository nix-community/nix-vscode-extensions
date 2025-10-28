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

  vadimcn.vscode-lldb = callPackage ./vadimcn/vscode-lldb/latest;
}
