{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    flake-compat,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        extensions = self.overlays.default null system;

        vscodium-with-extensions = let
          package = pkgs.vscode-with-extensions.override {
            vscode = pkgs.vscodium;
            vscodeExtensions = with self.extensions.vscode-marketplace; [
              golang.go
              vlanguage.vscode-vlang
            ];
          };
          package' =
            package
            // {
              meta =
                (removeAttrs package.meta ["description"])
                // {
                  longDescription = lib.mdDoc ''
                    This is a sample overridden VSCodium (FOSS fork of VS Code) with a couple extensions.
                    You can override this package and set `vscodeExtensions` to a list of extension
                    derivations, namely those provided by this flake.

                    The [repository] provides about 40K extensions from [Visual Studio Marketplace]
                    and another ~3K from [Open VSX Registry].

                    [repository]: https://github.com/nix-community/nix-vscode-extensions
                    [Visual Studio Marketplace]: https://marketplace.visualstudio.com/vscode
                    [Open VSX Registry]: https://open-vsx.org/
                  '';
                };
            };
        in
          package';
      in {
        packages = {
          inherit vscodium-with-extensions;
        };
        inherit extensions;
      }
    )
    // {
      overlays = {
        default = _: prev: let
          inherit (prev) lib;
          utils = prev.vscode-utils;
          loadGenerated = path:
            lib.pipe path [
              (path:
                import path {
                  inherit (prev) fetchgit fetchurl fetchFromGitHub;
                })
              (lib.mapAttrsToList (_: extension: {
                inherit (extension) name;
                value = utils.buildVscodeMarketplaceExtension {
                  vsix = extension.src;
                  mktplcRef = {
                    inherit (extension) name publisher version;
                  };
                };
              }))
              (builtins.groupBy ({value, ...}: value.vscodeExtPublisher))
              (builtins.mapAttrs (_: lib.listToAttrs))
            ];
        in {
          vscode-marketplace = loadGenerated ./data/generated/vscode-marketplace.nix;
          open-vsx = loadGenerated ./data/generated/open-vsx.nix;
        };
      };
    }
    // {
      templates = {
        default = {
          path = ./template;
          description = "VSCodium with extensions";
        };
      };
    };
}
