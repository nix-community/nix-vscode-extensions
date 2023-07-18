{
  inputs.flakes.url = "github:deemp/flakes";
  outputs = inputs:
    let
      inputs_ =
        let flakes = inputs.flakes.flakes; in
        {
          inherit (flakes.source-flake) nixpkgs flake-utils;
          inherit (flakes) drv-tools devshell codium workflows flakes-tools;
          inherit flakes;
          haskell = import ../haskell;
        };

      outputs = outputs_ { } // { inputs = inputs_; outputs = outputs_; };

      outputs_ =
        inputs__:
        let inputs = inputs_ // inputs__; in
        inputs.flake-utils.lib.eachDefaultSystem
          (system:
          let
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            inherit (inputs.codium.lib.${system}) mkCodium writeSettingsJSON extensionsCommon settingsCommonNix;
            inherit (inputs.devshell.lib.${system}) mkRunCommandsDir mkShell mkCommands;
            inherit (inputs.drv-tools.lib.${system}) mkShellApps withDescription getExe;
            inherit (inputs.workflows.lib.${system}) writeWorkflow nixCI os run expr names;
            inherit (inputs.flakes-tools.lib.${system}) mkFlakesTools;

            packages =
              let scripts =
                (mkShellApps {
                  updateExtensions = {
                    text = getExe inputs.haskell.packages.${system}.updateExtensions;
                    description = "Update extensions";
                  };
                  updateExtraExtensions = {
                    text = "${getExe pkgs.nvfetcher} -c extra-extensions.toml -o data/extra-extensions";
                    description = "Update extra extensions";
                  };
                });
              in
              scripts //
              {
                codium = mkCodium { extensions = extensionsCommon; };
                writeSettings = writeSettingsJSON settingsCommonNix;
                inherit (mkFlakesTools { dirs = [ "template" ]; root = ../.; }) updateLocks;
                inherit (mkFlakesTools { dirs = [ "." "template" "nix-dev" "haskell" ]; root = ../.; }) format;

                writeWorkflows = writeWorkflow "ci" (nixCI {
                  cacheNixArgs = {
                    linuxMaxStoreSize = 5000000000;
                    macosGCEnabled = false;
                    keyJob = "update";
                    files = [ "**/flake.nix" "**/flake.lock" "haskell/**/*" ];
                    keyOS = expr names.runner.os;
                  };
                  dir = "nix-dev/";
                  doRemoveCacheProfiles = false;
                  doPushToCachix = false;
                  doUpdateLocks = true;
                  updateLocksArgs = { doGitPull = false; doCommit = false; };
                  doFormat = true;
                  strategy = { };
                  runsOn = os.ubuntu-22;
                  steps = dir: [
                    (
                      let name = "Check template VSCodium"; in
                      {
                        inherit name;
                        run = "${run.nixScript { dir = "template/"; name = ""; doInstall = false; }} -- --list-extensions";
                      }
                    )
                    (
                      let name = "Update extensions"; in
                      {
                        inherit name;
                        env.CONFIG = ".github/config.yaml";
                        run = run.nixScript { inherit dir; name = scripts.updateExtensions.pname; commitArgs.commitMessage = name; };
                      }
                    )
                    (
                      let name = "Update extra extensions"; in
                      {
                        inherit name;
                        run = run.nixScript { inherit dir; name = scripts.updateExtraExtensions.pname; commitArgs.commitMessage = name; };
                      }
                    )
                    {
                      name = "Commit and push changes";
                      run = run.commit { commitMessages = [ "Update flake locks" "Update extensions" "Update extra extensions" ]; };
                    }
                  ];
                });
              };

            tools = [ pkgs.nvfetcher ];

            devShells.default = mkShell {
              packages = tools;
              commands =
                mkRunCommandsDir "nix-dev/" "ide" { "codium ." = packages.codium; inherit (packages) writeSettings; }
                ++ mkRunCommandsDir "nix-dev/" "scripts" { inherit (packages) updateExtensions updateExtraExtensions; }
                ++ mkRunCommandsDir "nix-dev/" "infra" { inherit (packages) writeWorkflows updateLocks; }
                ++ mkCommands "tools" tools;
            };
          in
          {
            inherit packages devShells;
          });
    in
    outputs;

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
