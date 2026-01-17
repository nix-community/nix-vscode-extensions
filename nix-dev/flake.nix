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
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        {
          inputs',
          pkgs,
          system,
          self',
          lib,
          ...
        }:
        let
          devshells.default = {
            commandGroups = {
              tools = [
                {
                  expose = true;
                  packages = {
                    inherit (pkgs) nvfetcher;
                  };
                }
                {
                  prefix = "nix run .#";
                  packages = {
                    inherit (self'.packages) updateExtensions updateExtraExtensions;
                  };
                }
              ];
            };
          };

          mkShellApps = lib.mapAttrs (
            name: value:
            if !(lib.isDerivation value) && lib.isAttrs value then
              pkgs.writeShellApplication (value // { inherit name; })
            else
              value
          );

          haskell = import ../haskell;

          packages = {
            default = import ../nix/vscode-with-extensions.nix {
              inherit system nixpkgs;
            };
          }
          // mkShellApps {
            updateExtensions = {
              text = ''${lib.meta.getExe haskell.outputs.packages.${system}.default} "$@"'';
              meta.description = "Update extensions";
            };
            updateExtraExtensions = {
              text = "${lib.meta.getExe pkgs.nvfetcher} -c extra-extensions.toml -o data/extra-extensions";
              meta.description = "Update extra extensions";
            };
          };

          flake-compat = import ../nix/flake-compat.nix;

          legacyPackages.saveFromGC.ci.jobs =
            let
              mkSaveFromGC =
                attrs: import "${inputs.cache-nix-action}/saveFromGC.nix" ({ inherit pkgs; } // attrs);
              template = (flake-compat { src = ../template; }).defaultNix;
            in
            {
              test =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputs;
                  };
                  derivations = [ self'.packages.default ];
                }).saveFromGC;

              update =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputs;
                    inherit haskell;
                  };
                  derivations = [
                    self'.packages.updateExtensions
                    self'.packages.updateExtraExtensions
                    self'.formatter
                  ];
                }).saveFromGC;

              test-template =
                (mkSaveFromGC {
                  inputs = {
                    self = template;
                    inherit template;
                  };
                  derivations = [ template.devShells.${system}.default ];
                }).saveFromGC;
            };

          treefmt = {
            flakeCheck = false;

            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
            };

            settings.global.excludes = [
              "haskell/**"
              "data/**"
              # ".github/**"
              ".envrc"
              ".env"
              "LICENSE"
              # "README.md"
              "cabal.project"
              "extra-extensions.toml"
              ".markdownlint.jsonc"
            ];
          };

          nix-unit = {
            inputs = {
              inherit (inputs)
                nixpkgs
                flake-parts
                nix-unit
                parent
                devshell
                treefmt-nix
                ;
              "flake-parts/nixpkgs-lib" = inputs.flake-parts.inputs.nixpkgs-lib;
            };

            tests = import "${parent}/nix/tests.nix" {
              inherit system nixpkgs overlay;
            };
          };
        in
        {
          inherit
            devshells
            legacyPackages
            nix-unit
            packages
            treefmt
            ;
        };
    };
}
