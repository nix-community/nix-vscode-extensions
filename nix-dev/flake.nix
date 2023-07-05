{
  inputs.flakes.url = "github:deemp/flakes";
  outputs = inputs:
    let
      inputs_ =
        let flakes = inputs.flakes.flakes; in
        {
          inherit (flakes.source-flake) nixpkgs flake-utils;
          inherit (flakes) drv-tools devshell codium;
        };

      outputs = outputs_ { } // { inputs = inputs_; outputs = outputs_; };

      outputs_ =
        inputs__:
        let inputs = inputs_ // inputs__; in
        inputs.flake-utils.lib.eachDefaultSystem
          (system:
          let
            pkgs = inputs.nixpkgs.legacyPackages.${system};
            inherit (inputs.codium.lib.${system}) mkCodium writeSettingsJSON extensions settingsNix;
            inherit (inputs.devshell.lib.${system}) mkRunCommandsDir mkShell;
            inherit (inputs.drv-tools.lib.${system}) mkShellApps;
            packages = {
              codium = mkCodium {
                extensions = {
                  inherit (extensions) nix misc markdown github;
                };
              };
              writeSettings = writeSettingsJSON {
                inherit (settingsNix)
                  nix-ide markdown-all-in-one git gitlens todo-tree
                  markdown-language-features files workbench editor
                  errorlens
                  ;
              };
            } //
            (mkShellApps {
              updateExtensions = {
                text = ''nix run hs/#updateExtensions'';
                description = "Update extensions data";
              };
            });

            devShells.default = mkShell {
              commands = mkRunCommandsDir "nix-dev/" "ide"
                {
                  "codium ." = packages.codium;
                  inherit (packages) writeSettings;
                }
              ++ mkRunCommandsDir "nix-dev/" "scripts" {
                inherit (packages) updateExtensions;
              };
            };
          in
          {
            inherit packages devShells;
          });
    in
    outputs;

  nixConfig = {
    extra-trusted-substituters = [
      "https://haskell-language-server.cachix.org"
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
      "https://deemp.cachix.org"
    ];
    extra-trusted-public-keys = [
      "haskell-language-server.cachix.org-1:juFfHrwkOxqIOZShtC4YC1uT1bBcq2RSvC7OMKx0Nz8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "deemp.cachix.org-1:9shDxyR2ANqEPQEEYDL/xIOnoPwxHot21L5fiZnFL18="
    ];
  };
}
