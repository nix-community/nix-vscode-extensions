{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3a05eebede89661660945da1f151959900903b6a";
    cache-nix-action = {
      url = "github:nix-community/cache-nix-action";
      flake = false;
    };
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.url = "github:nixos/nixpkgs/3a05eebede89661660945da1f151959900903b6a?dir=lib";
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
      url = "github:nix-community/nix-unit";
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
