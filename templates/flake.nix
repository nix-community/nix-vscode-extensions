{
  inputs = {
    nixpkgs_.url = "github:deemp/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    nix-vscode-extensions.url = "github:deemp/nix-vscode-extensions";
  };

  outputs =
    { self
    , flake-utils
    , nixpkgs
    , nix-vscode-extensions
    , ...
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        extensions = nix-vscode-extensions.packages.${system};
        codium =
          let
            inherit (pkgs) vscode-with-extensions vscodium;
            someExtensions = builtins.attrValues {
              inherit (extensions.vscode.golang) go;
              inherit (extensions.vscode.vlanguage) vscode-vlang;
            };
          in
          (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = someExtensions;
          });
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [ codium ];
          shellHook = ''
            printf "VSCodium with extensions:\n"
            codium --list-extensions
          '';
        };
      });

  nixConfig = {
    extra-substituters = [
      "https://haskell-language-server.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.iog.io"
      "https://deemp.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "deemp.cachix.org-1:9shDxyR2ANqEPQEEYDL/xIOnoPwxHot21L5fiZnFL18="
    ];
  };
}

