{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/def3da69945bbe338c373fddad5a1bb49cf199ce";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      ...
    }:
    let
      flake-compat = import (
        builtins.fetchGit {
          url = "https://github.com/deemp/flake-compat";
          rev = "7f5e675bc0baf8640e3f587f7ba241fea5b122bd";
        }
      );

      nix-dev =
        (flake-compat {
          src = ./.;
          root = "nix-dev";
        }).defaultNix;

      inputsCombined = nix-dev.inputs // inputs;

      systemPlatform = import ./nix/systemPlatform.nix;

      systems = builtins.attrNames systemPlatform;
    in
    inputsCombined.flake-parts.lib.mkFlake { inputs = inputsCombined; } {
      inherit systems;

      imports = [
        inputsCombined.devshell.flakeModule
        inputsCombined.treefmt-nix.flakeModule
      ];

      flake =
        let
          overlays.default = import ./nix/overlay.nix;

          templates = {
            default = {
              path = ./template;
              description = "VSCodium with extensions";
            };
          };
        in
        {
          inherit overlays templates;
        }
        // (inputsCombined.flake-utils.lib.eachSystem systems (system: {
          extensions = import ./nix/extensions.nix {
            inherit system nixpkgs;
          };
        }));

      perSystem =
        {
          self',
          system,
          lib,
          pkgs,
          inputs',
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

          haskell = import ./haskell;

          packages = {
            default = import ./nix/vscode-with-extensions.nix {
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

          legacyPackages.saveFromGC.ci.jobs =
            let
              mkSaveFromGC =
                attrs: import "${inputsCombined.cache-nix-action}/saveFromGC.nix" ({ inherit pkgs; } // attrs);
              template = (flake-compat { src = ./template; }).defaultNix;
            in
            {
              test =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputsCombined;
                  };
                  derivations = [ self'.packages.default ];
                }).saveFromGC;

              update =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputsCombined;
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
        in
        {
          inherit
            devshells
            packages
            legacyPackages
            treefmt
            ;
          checks = nix-dev.outputs.checks.${system};
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
