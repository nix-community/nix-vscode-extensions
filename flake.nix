{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) eachDefaultSystem;
    in
    {
      overlays = {
        default = final: prev:
          let
            utils = nixpkgs.legacyPackages.${final.system}.vscode-utils;
            loadGenerated = path:
              lib.pipe path [
                (path_: builtins.fromJSON (builtins.readFile path_))
                (builtins.map (extension@{ name, publisher, version, sha256, url, ... }:
                  {
                    inherit name;
                    value = utils.buildVscodeMarketplaceExtension {
                      vsix = prev.fetchurl {
                        inherit url sha256;
                        name = "${name}-${version}.zip";
                      };
                      mktplcRef = {
                        inherit name version publisher;
                      };
                    };
                  }))
                (builtins.groupBy ({ value, ... }: value.vscodeExtPublisher))
                (builtins.mapAttrs (_: lib.listToAttrs))
              ];
          in
          {
            vscode-marketplace = loadGenerated ./data/cache/vscode-marketplace.json;
            open-vsx = loadGenerated ./data/cache/open-vsx.json;
          };
      };
      templates = {
        vscodium-with-extensions = {
          path = ./template;
          description = "VSCodium with extensions";
        };
      };
    }
    // (eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        extensions = self.overlays.default pkgs pkgs;

        packages = {
          vscodium-with-extensions = pkgs.lib.attrsets.recursiveUpdate
            (pkgs.vscode-with-extensions.override
              {
                vscode = pkgs.vscodium;
                vscodeExtensions = with self.extensions.${system}.vscode-marketplace; [
                  golang.go
                  vlanguage.vscode-vlang
                ];
              }
            )
            {
              meta = rec {
                longDescription = lib.mdDoc ''
                  This is a sample overridden VSCodium (FOSS fork of VS Code) with a couple extensions.
                  You can override this package and set `vscodeExtensions` to a list of extension
                  derivations, namely those provided by this flake.

                  The [repository] provides ~40K extensions from [Visual Studio Marketplace]
                  and another ~3K from [Open VSX Registry].

                  [repository]: https://github.com/nix-community/nix-vscode-extensions
                  [Visual Studio Marketplace]: https://marketplace.visualstudio.com/vscode
                  [Open VSX Registry]: https://open-vsx.org/
                '';
              };
            };
        };
        formatter = pkgs.writeScriptBin "fmt" "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt flake.nix nix-dev/flake.nix";
      }));
}
