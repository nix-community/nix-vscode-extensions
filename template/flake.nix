{
  inputs = {
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    flake-utils.follows = "nix-vscode-extensions/flake-utils";
    nixpkgs.follows = "nix-vscode-extensions/nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ inputs.nix-vscode-extensions.overlays.default ];
        };

        inherit (pkgs) vscode-with-extensions vscodium;

        packages.default = vscode-with-extensions.override {
          vscode = vscodium;
          vscodeExtensions = [
            pkgs.vscode-marketplace.golang.go
            pkgs.open-vsx-release.rust-lang.rust-analyzer
            # unfree
            pkgs.vscode-marketplace.ms-python.vscode-pylance
          ];
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ packages.default ];
          shellHook = ''
            printf "VSCodium with extensions:\n"
            codium --list-extensions
          '';
        };
      in
      {
        inherit packages devShells;
      }
    );
}
