{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    flake-utils.url = "github:numtide/flake-utils";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/13378a0b6026e8b52ccb881454b43201cbe005b4";
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

        extensions = nix-vscode-extensions.extensions.${system};
        codium =
          let
            inherit (pkgs) vscode-with-extensions vscodium;
            someExtensions = builtins.attrValues {
              inherit (extensions.vscode-marketplace.golang) go;
              inherit (extensions.vscode-marketplace.vlanguage) vscode-vlang;
            };
          in
          (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = someExtensions;
          });
      in
      {
        packages = {
          inherit codium;
        };
        devShells.default = pkgs.mkShell {
          buildInputs = [ codium ];
          shellHook = ''
            printf "VSCodium with extensions:\n"
            codium --list-extensions
          '';
        };
      });
}

