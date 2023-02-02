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

        loadGenerated = set:
          with builtins;
          with pkgs; let
            generated = import ./data/generated/${set}.nix {
              inherit fetchurl fetchFromGitHub;
              fetchgit = fetchGit;
            };

            groupedByPublisher = groupBy (e: e.publisher) (attrValues generated);
            pkgDefinition = {
              open-vsx = e:
                with e;
                with vscode-utils; {
                  inherit name;
                  value = buildVscodeMarketplaceExtension {
                    vsix = src;
                    mktplcRef = {
                      inherit version;
                      publisher = publisher;
                      name = name;
                    };
                    meta = with lib; {
                      inherit changelog downloadPage homepage;
                      license = licenses.${license};
                    };
                  };
                };
              vscode-marketplace = e:
                with e;
                with vscode-utils; {
                  inherit name;
                  value = buildVscodeMarketplaceExtension {
                    vsix = src;
                    mktplcRef = {
                      inherit version;
                      publisher = publisher;
                      name = name;
                    };
                  };
                };
            };
          in
            mapAttrs (_: val: listToAttrs (map pkgDefinition.${set} val)) groupedByPublisher;

        extensions = {
          vscode-marketplace = loadGenerated "vscode-marketplace";
          open-vsx = loadGenerated "open-vsx";
        };

        vscodiumWithExtensions = let
          inherit (pkgs) vscode-with-extensions vscodium;
          vscodium_ = vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = builtins.attrValues {
              inherit (extensions.vscode-marketplace.golang) go;
              inherit (extensions.vscode-marketplace.vlanguage) vscode-vlang;
            };
          };
        in
          vscodium_
          // {
            meta =
              (builtins.removeAttrs vscodium_.meta ["description"])
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
