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
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs) lib;
        utils = pkgs.vscode-utils;

        loadGenerated = path:
          lib.pipe path [
            (path:
              import path {
                inherit (pkgs) fetchgit fetchurl fetchFromGitHub;
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

        extensions = {
          vscode-marketplace = loadGenerated ./data/generated/vscode-marketplace.nix;
          open-vsx = loadGenerated ./data/generated/open-vsx.nix;
        };

        vscodiumWithExtensions = let
          inherit (pkgs) vscode-with-extensions vscodium;
          vscodium' = vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = builtins.attrValues {
              inherit (extensions.vscode-marketplace.golang) go;
              inherit (extensions.vscode-marketplace.vlanguage) vscode-vlang;
            };
          };
        in
          vscodium'
          // {
            meta =
              (builtins.removeAttrs vscodium'.meta ["description"])
              // {
                longDescription = ''
                  This is a sample `VSCodium` (= `VS Code` without proprietary stuff) with a couple of extensions.

                  The [repo](https://github.com/nix-community/nix-vscode-extensions) provides
                  `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
                '';
              };
          };
      in {
        packages = {
          inherit vscodiumWithExtensions;
        };
        inherit extensions;
      }
    )
    // {
      overlays.default = final: prev: {
        vscode-extensions = self.extensions.${prev.system};
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
