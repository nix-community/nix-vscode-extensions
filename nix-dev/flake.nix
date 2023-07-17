{
  inputs.flakes.url = "github:deemp/flakes";
  outputs = inputs:
    let
      inputs_ =
        let flakes = inputs.flakes.flakes; in
        {
          inherit (flakes.source-flake) nixpkgs flake-utils;
          inherit (flakes) drv-tools devshell codium workflows flakes-tools;
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
            inherit (inputs.devshell.lib.${system}) mkRunCommandsDir mkShell;
            inherit (inputs.drv-tools.lib.${system}) mkShellApps withDescription;
            inherit (inputs.workflows.lib.${system}) writeWorkflow nixCI os run;

            packages = {
              codium = mkCodium { extensions = extensionsCommon; };
              writeSettings = writeSettingsJSON settingsCommonNix;
              updateExtensions = withDescription inputs.haskell.packages.${system}.updateExtensions (x: ''Update extensions.'');
              writeWorkflows = writeWorkflow "ci" (nixCI {
                strategy.matrix.os = [ os.ubuntu-22 ];
                cacheNixArgs = {
                  linuxMaxStoreSize = 5000000000;
                  macosGCEnabled = false;
                  keyJob = "update";
                  files = [ "**/flake.nix" "**/flake.lock" "haskell/**/*" ];
                };
                dir = "nix-dev/";
                doRemoveCacheProfiles = false;
                doPushToCachix = false;
                doUpdateLocks = false;
                doFormat = false;
                steps = dir: [
                  (
                    let name = "Update extensions"; in
                    {
                      inherit name;
                      env.CONFIG = ".github/config.yaml";
                      run = run.nixScript { inherit dir; name = "updateExtensions"; commitMessage = name; };
                    }
                  )
                  {
                    name = "Commit and push changes.";
                    run = ''
                      git add .
                      git commit --allow-empty -m "action: update extensions"
                      git push
                    '';
                  }
                ];
              });
            };

            devShells.default = mkShell {
              commands =
                mkRunCommandsDir "nix-dev/" "ide" { "codium ." = packages.codium; inherit (packages) writeSettings; }
                ++ mkRunCommandsDir "nix-dev/" "scripts" { inherit (packages) updateExtensions; }
                ++ mkRunCommandsDir "nix-dev/" "infra" { inherit (packages) writeWorkflows; };
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
