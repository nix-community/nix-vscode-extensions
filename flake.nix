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
      nix-dev = import ./nix-dev;

      inputsCombined = nix-dev.inputs // inputs;

      systemPlatform = {
        x86_64-linux = "linux-x64";
        aarch64-linux = "linux-arm64";
        x86_64-darwin = "darwin-x64";
        aarch64-darwin = "darwin-arm64";
      };

      systems = builtins.attrNames systemPlatform;
    in
    nix-dev.inputs.flake-parts.lib.mkFlake { inputs = inputsCombined; } {
      inherit systems;

      imports = [
        nix-dev.inputs.devshell.flakeModule
        nix-dev.inputs.treefmt-nix.flakeModule
        nix-dev.inputs.nix-unit.modules.flake.default
      ];

      flake =
        let
          overlays = {
            default = import ./nix/overlay.nix { inherit systemPlatform; };
          };

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
        // (nix-dev.inputs.flake-utils.lib.eachSystem systems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              # Uncomment to allow unfree extensions
              # config.allowUnfree = true;
              overlays = [ self.overlays.default ];
            };

            extensions = {
              inherit (pkgs)
                vscode-marketplace
                open-vsx
                vscode-marketplace-release
                open-vsx-release
                vscode-marketplace-universal
                open-vsx-universal
                vscode-marketplace-release-universal
                open-vsx-release-universal

                forVSCodeVersion
                usingFixesFrom
                ;
            };
          in
          {
            inherit extensions;
          }
        ));

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
            commands = {
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

          resetLicense =
            drv:
            drv.overrideAttrs (prev: {
              meta = prev.meta // {
                license = [ ];
              };
            });

          packages = {
            default = import ./nix/vscode-with-extensions.nix {
              inherit system nixpkgs resetLicense;
              nix-vscode-extensions = self;
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
                attrs: import "${nix-dev.inputs.cache-nix-action}/saveFromGC.nix" ({ inherit pkgs; } // attrs);
              template = (import nix-dev.inputs.flake-compat { src = ./template; }).defaultNix;
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

          nix-unit = {
            allowNetwork = true;

            inputs = {
              inherit (inputsCombined)
                nixpkgs
                flake-parts
                nix-unit
                flake-compat
                ;
            };

            tests =
              let
                inherit (self.extensions.${system}) vscode-marketplace;
                semver = import ./nix/semver.nix { inherit pkgs; };
              in
              semver.tests
              // {
                "test: ms-python.vscode-pylance fails if unfree" = {
                  expr =
                    # https://discourse.nixos.org/t/evaluating-possibly-nonfree-derivations/24835/2
                    (builtins.tryEval (builtins.unsafeDiscardStringContext vscode-marketplace.ms-python.vscode-pylance))
                    .success;
                  expected = false;
                };
                "test: ms-vscode.cpptools passes only on " = {
                  expr = (builtins.tryEval vscode-marketplace.ms-vscode.cpptools).success;
                  expected = builtins.elem system lib.platforms.linux;
                };
                "test: ms-python.vscode-pylance passes if not unfree" = {
                  expr = (builtins.tryEval (resetLicense vscode-marketplace.ms-python.vscode-pylance)).success;
                  expected = true;
                };
                "test: rust-lang.rust-analyzer passes" = {
                  expr = (builtins.tryEval vscode-marketplace.rust-lang.rust-analyzer).success;
                  expected = true;
                };
                "test: `allowAliases = false` and `checkMeta = true` work" = {
                  # https://github.com/nix-community/nix-vscode-extensions/issues/142
                  expr =
                    let
                      pkgs = import inputs.nixpkgs {
                        inherit system;

                        config = {
                          allowAliases = false;
                          checkMeta = true;
                        };

                        overlays = [ self.overlays.default ];
                      };
                      extensions = pkgs.nix-vscode-extensions;
                    in
                    (builtins.tryEval extensions.vscode-marketplace.b4dm4n.nixpkgs-fmt).success;
                  expected = true;
                };
              };
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
            nix-unit
            treefmt
            ;
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
