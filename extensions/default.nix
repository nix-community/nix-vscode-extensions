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

  vadimcn.vscode-lldb =
    config@{
      mktplcRef,
      pkgs,
      lib,
      ...
    }:
    if lib.versionAtLeast mktplcRef.version "1.11.0" then
      # https://github.com/NixOS/nixpkgs/pull/383013
      pkgs.callPackage ./vadimcn/vscode-lldb/latest config
    else
      import ./vadimcn/vscode-lldb/1.10.0 config;

  ms-dotnettools.vscode-dotnet-runtime = import ./ms-dotnettools/vscode-dotnet-runtime/latest;

  ms-vsliveshare.vsliveshare = import ./ms-vsliveshare/vsliveshare/latest;

  sumneko.lua = import ./sumneko/lua/latest;
}
