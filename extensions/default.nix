{
  # Each extension may have several fixes that depend on the extension version.
  # 
  # Fixes MUST be provided in the subdirectories of the ./extensions directory.
  # 
  # A fix that works for versions up to `<version>` 
  # of the extension `<name>` published by `<publisher>` 
  # MUST be in the directory `./extensions/<publisher>/<name>/<version>`
  # 
  # You may create a `default.nix` in that directory for convenience.
  # 
  # Each `${publisher}.${name}` in this file (`default.nix`) MUST provide a function .
  # 
  # ```
  # { pkgs, lib, mkExtensionNixpkgs, mkExtensionNixpkgs, mktplcRef, vsix, ... } -> Attrset
  # ```
  # 
  # You may omit unused fields and provide `{ ... } -> Attrset`.
  # 
  # Each `Attrset` MUST be a valid argument of `buildVscodeMarketplaceExtension` (see the `mkExtension.nix` file).
  # 
  # Use `mkExtensionNixpkgs` to override extensions from `nixpkgs`.
  #
  # Example of a fix:
  #
  # ```nix
  # { mktplcRef, vsix, ... }@arg: (mkExtensionNixpkgs.foo.bar { inherit mktplcRef vsix; } ).override { postInstall = "..."; };
  # ```

  vadimcn.vscode-lldb = import ./vadimcn/vscode-lldb/latest;

  ms-dotnettools.vscode-dotnet-runtime = import ./ms-dotnettools/vscode-dotnet-runtime/latest;

  ms-vsliveshare.vsliveshare = import ./ms-vsliveshare/vsliveshare/latest;

  # Fixed variant of https://github.com/NixOS/nixpkgs/blob/4f48368f11e7329735ab76d890f18f8d4be3f60f/pkgs/applications/editors/vscode/extensions/sumneko.lua/default.nix
  sumneko.lua = import ./sumneko/lua/latest;
}
