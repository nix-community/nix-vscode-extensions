{
  inputs = {
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/c43d9089df96cf8aca157762ed0e2ddca9fcd71e";
    flake-utils.follows = "nix-vscode-extensions/flake-utils";
    nixpkgs.follows = "nix-vscode-extensions/nixpkgs";
  };

  outputs = inputs:
    inputs.flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          extensions = inputs.nix-vscode-extensions.extensions.${system};
          inherit (pkgs) vscode-with-extensions vscodium;

          packages.codium =
            vscode-with-extensions.override {
              vscode = vscodium;
              vscodeExtensions = [
                extensions.vscode-marketplace.golang.go
                extensions.open-vsx-release.rust-lang.rust-analyzer
              ];
            };
          devShells.default = pkgs.mkShell {
            buildInputs = [ packages.codium ];
            shellHook = ''
              printf "VSCodium with extensions:\n"
              codium --list-extensions
            '';
          };
        in
        {
          inherit packages devShells;
        });
}

