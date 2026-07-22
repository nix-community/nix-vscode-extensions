{
  description = "Rust development shell for the nix-vscode-extensions updater";

  inputs = {
    crane.url = "github:ipetkov/crane";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
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
        {
          pkgs,
          self',
          ...
        }:
        {
          devShells.default = pkgs.mkShell {
            inputsFrom = [ self'.packages.default ];
            packages = with pkgs; [
              cargo
              rustc
              rust-analyzer
            ];
          };

          packages.default =
            let
              craneLib = inputs.crane.mkLib pkgs;
              src = pkgs.lib.fileset.toSource {
                root = ./.;
                fileset = pkgs.lib.fileset.unions [
                  (craneLib.fileset.commonCargoSources ./.)
                  ./tests
                ];
              };
              commonArgs = {
                pname = "nix-vscode-extensions-updater";
                version = "0.1.0";
                inherit src;
                strictDeps = true;
                cargoLock = ./Cargo.lock;
                meta.mainProgram = "nix-vscode-extensions-updater";
              };
              cargoArtifacts = craneLib.buildDepsOnly commonArgs;
            in
            craneLib.buildPackage (
              commonArgs
              // {
                inherit cargoArtifacts;
              }
            );
        };
    };
}
