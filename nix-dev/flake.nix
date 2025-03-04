{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/3a05eebede89661660945da1f151959900903b6a";
    cache-nix-action = {
      url = "github:nix-community/cache-nix-action";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.devshell.follows = "devshell";
      inputs.flake-parts.follows = "flake-parts";
      inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell = {
      url = "github:deemp/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.inputs.systems.follows = "systems";
    };
  };
  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.devshell.flakeModule ];
      perSystem =
        {
          self',
          pkgs,
          lib,
          system,
          ...
        }:
        let
          haskell = import ../haskell;

          mkShellApps = lib.mapAttrs (
            name: value:
            if !(lib.isDerivation value) && lib.isAttrs value then
              pkgs.writeShellApplication (value // { inherit name; })
            else
              value
          );

          packages = mkShellApps {
            updateExtensions = {
              text = "${haskell.outputs.packages.${system}.default} /# $@";
              meta.description = "Update extensions";
            };

            updateExtraExtensions = {
              text = "${lib.meta.getExe pkgs.nvfetcher} -c extra-extensions.toml -o data/extra-extensions";
              meta.description = "Update extra extensions";
            };
          };

          devshells.default = {
            commands = {
              tools = [
                {
                  expose = true;
                  packages = {
                    inherit (pkgs) nvfetcher;
                  };
                }
                {
                  prefix = "nix run nix-dev/#";
                  packages = {
                    inherit (self'.packages) updateExtensions updateExtraExtensions;
                  };
                }
              ];
            };
          };
        in
        {
          inherit packages devshells;
        };
    };

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
