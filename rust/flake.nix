{
  description = "Rust development shell for the nix-vscode-extensions updater";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/59682e0069f0ed0a452e2179a7f4c1f247027b9e";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { pkgs, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              rustc
              rust-analyzer
            ];
          };

          packages.default = pkgs.rustPlatform.buildRustPackage {
            pname = "nix-vscode-extensions-updater";
            version = "0.1.0";
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;
          };
        };
    };
}
