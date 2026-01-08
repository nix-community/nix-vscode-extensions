{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/def3da69945bbe338c373fddad5a1bb49cf199ce";
    cache-nix-action = {
      url = "github:nix-community/cache-nix-action/e2cf51da82e145785f5db595f553f7cbc2ca54df";
      flake = false;
    };
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    };
    devshell = {
      url = "github:deemp/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    parent = {
      url = "path:../";
      flake = false;
    };
  };
  outputs =
    inputs@{ nixpkgs, ... }:
    let
      parent = inputs.parent.outPath;
      systemPlatform = import "${parent}/nix/systemPlatform.nix";
      systems = builtins.attrNames systemPlatform;
      overlay = import "${parent}/nix/overlay.nix";
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      inherit systems;

      imports = [
        inputs.nix-unit.modules.flake.default
      ];

      perSystem =
        {
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          nix-unit = {
            inputs = {
              inherit (inputs)
                nixpkgs
                flake-parts
                nix-unit
                parent
                ;
              "flake-parts/nixpkgs-lib" = inputs.flake-parts.inputs.nixpkgs-lib;
            };

            tests = import "${parent}/nix/tests.nix" {
              inherit system nixpkgs overlay;
            };
          };
        };
    };
}
