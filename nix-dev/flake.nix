{
  inputs = {
    flakes.url = "github:deemp/flakes";
    nixpkgs.url = "github:nixos/nixpkgs/23ff7d9dc4f3d553939e7bfe0d2667198f993536";
  };
  outputs =
    inputs:
    let
      flakes = inputs.flakes;
    in
    flakes.makeFlake {
      inputs = {
        inherit (flakes.all)
          drv-tools
          devshell
          codium
          workflows
          flakes-tools
          ;
        inherit flakes;
        haskell = import ../haskell;
        inherit (inputs) nixpkgs;
      };
      perSystem =
        { inputs, system }:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inherit (inputs.codium.lib.${system})
            mkCodium
            writeSettingsJSON
            extensionsCommon
            settingsCommonNix
            ;
          inherit (inputs.devshell.lib.${system}) mkRunCommandsDir mkShell mkCommands;
          inherit (inputs.drv-tools.lib.${system}) mkShellApps getExe;
          inherit (inputs.workflows.lib.${system})
            writeWorkflow
            nixCI
            os
            run
            expr
            names
            steps
            ;
          inherit (inputs.flakes-tools.lib.${system}) mkFlakesTools;

          packages =
            let
              scripts = (
                mkShellApps {
                  updateExtensions = {
                    text = getExe inputs.haskell.packages.${system}.default;
                    description = "Update extensions";
                  };
                  updateExtraExtensions = {
                    text = "${getExe pkgs.nvfetcher} -c extra-extensions.toml -o data/extra-extensions";
                    description = "Update extra extensions";
                  };
                }
              );
            in
            scripts
            // {
              codium = mkCodium { extensions = extensionsCommon; };
              writeSettings = writeSettingsJSON settingsCommonNix;
              inherit
                (mkFlakesTools {
                  dirs = [ "template" ];
                  root = ../.;
                })
                updateLocks
                ;
              inherit
                (mkFlakesTools {
                  dirs = [
                    "."
                    "template"
                    "nix-dev"
                    "haskell"
                  ];
                  root = ../.;
                })
                format
                saveFlakes
                ;

              writeWorkflows = writeWorkflow "ci" (nixCI {
                jobArgs = {
                  cacheNixArgs = {
                    gcEnabledLinux = true;
                    gcMaxStoreSizeLinux = 7500000000;
                    purgeEnabled = true;
                    purgeByCreatedTime = true;
                    purgeMaxAge = 86400;
                    debug = true;
                    keyJob = "update";
                    files = [
                      "**/flake.nix"
                      "**/flake.lock"
                      "haskell/**/*"
                    ];
                    keyOS = expr names.runner.os;
                  };
                  dir = "nix-dev/";
                  doCommit = false;
                  strategy = { };
                  runsOn = os.ubuntu-22;
                  steps =
                    { dir, stepsAttrs }:
                    [
                      {
                        name = "Update extensions";
                        env.CONFIG = ".github/config.yaml";
                        run = run.nixScript {
                          inherit dir;
                          name = scripts.updateExtensions.pname;
                        };
                      }
                      {
                        name = "Update extra extensions";
                        run = run.nixScript {
                          inherit dir;
                          name = scripts.updateExtraExtensions.pname;
                        };
                      }
                      {
                        name = "Commit and push changes";
                        run = run.commit {
                          messages = [
                            (steps.updateLocks { }).name
                            stepsAttrs."Update extensions".name
                            stepsAttrs."Update extra extensions".name
                          ];
                        };
                      }
                      {
                        name = "Check template VSCodium";
                        run = ''
                          nix profile install template/
                          nix run template/ -- --list-extensions
                        '';
                      }
                    ];
                };
              });
            };

          tools = [ pkgs.nvfetcher ];

          devShells.default = mkShell {
            packages = tools;
            commands =
              mkRunCommandsDir "nix-dev/" "ide" {
                "codium ." = packages.codium;
                inherit (packages) writeSettings;
              }
              ++ mkRunCommandsDir "nix-dev/" "scripts" {
                inherit (packages) updateExtensions updateExtraExtensions;
              }
              ++ mkRunCommandsDir "nix-dev/" "infra" { inherit (packages) writeWorkflows updateLocks; }
              ++ mkCommands "tools" tools;
          };
        in
        {
          inherit packages devShells;
        };
    };

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
      "https://deemp.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "deemp.cachix.org-1:9shDxyR2ANqEPQEEYDL/xIOnoPwxHot21L5fiZnFL18="
    ];
  };
}
