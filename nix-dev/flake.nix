{
  inputs = {
    nixpkgs_.url = "github:deemp/flakes?dir=source-flake/nixpkgs";
    nixpkgs.follows = "nixpkgs_/nixpkgs";
    codium.url = "github:deemp/flakes?dir=codium";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    devshell.url = "github:deemp/flakes?dir=devshell";
    drv-tools.url = "github:deemp/flakes?dir=drv-tools";
  };
  outputs = inputs: inputs.flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};
        inherit (inputs.codium.functions.${system}) mkCodium writeSettingsJSON;
        inherit (inputs.codium.configs.${system}) extensions settingsNix;
        inherit (inputs.devshell.functions.${system}) mkRunCommandsDir mkShell;
        inherit (inputs.drv-tools.functions.${system}) mkShellApps;
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
          commands = mkRunCommandsDir "nix-dev/" "ide" {
            inherit (packages) writeSettings updateExtensions;
            "codium ." = packages.codium;
          };
        };
      in
      {
        inherit packages devShells;
      });

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
