{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/674c2b09c59a220204350ced584cadaacee30038";
    cache-nix-action = {
      url = "github:nix-community/cache-nix-action/e2cf51da82e145785f5db595f553f7cbc2ca54df";
      flake = false;
    };
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.url = "github:nixos/nixpkgs/674c2b09c59a220204350ced584cadaacee30038?dir=lib";
    };
    devshell = {
      url = "github:deemp/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.inputs.systems.follows = "systems";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    nix-unit = {
      url = "github:nix-community/nix-unit/7a952131cbef9cb21953ae70ad09249541848f07";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = _: { };
}
