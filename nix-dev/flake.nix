{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    my-codium.url = "github:deemp/flakes?dir=codium";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    vscode-extensions_.url = "github:deemp/flakes?dir=source-flake/nix-vscode-extensions";
    vscode-extensions.follows = "vscode-extensions_/vscode-extensions";
    my-devshell.url = "github:deemp/flakes?dir=devshell";
    drv-tools.url = "github:deemp/flakes?dir=drv-tools";
  };
  outputs =
    { self
    , my-codium
    , flake-utils
    , vscode-extensions
    , my-devshell
    , nixpkgs
    , drv-tools
    , ...
    }: flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (my-codium.functions.${system}) mkCodium writeSettingsJSON;
        inherit (my-codium.configs.${system}) extensions settingsNix;
        devshell = my-devshell.devshell.${system};
        inherit (my-devshell.functions.${system}) mkCommands;
        inherit (drv-tools.functions.${system}) mkShellApps concatMapStringsNewline;
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
        tools = [
          pkgs.deno
        ];

        env = isTargetOpenVSX:
          builtins.mapAttrs (_: toString)
            ({
              DENO_DIR = "$(pwd)/.deno";
            } // (
              if isTargetOpenVSX then {
                TARGET = "vscode-marketplace";
                NAME = "VSCode Marketplace";
                ALLOW_NET = "marketplace.visualstudio.com";
              } else {
                TARGET = "open-vsx";
                NAME = "Open VSX";
                ALLOW_NET = "open-vsx.org";
              }
            ));
        scripts = mkShellApps
          {
            updateExtensions = {
              text = ''
                ${concatMapStringsNewline
                  (x: with (env x); ''
                    export DENO_DIR="${DENO_DIR}"
                    ${pkgs.deno}/bin/deno run \
                      --allow-write \
                      --allow-net="${ALLOW_NET}" \
                      --no-prompt \
                      updater/index.ts "${TARGET}" \
                      data/new/"${TARGET}".yaml''
                  ) [ true false ]}  
                nix run hs/#updateData
                rm -rf data/new
              '';
            };
          };
      in
      {
        packages = {
          inherit codium writeSettings;
        } // scripts;
        devShells.default = devshell.mkShell {
          packages = tools;
          commands = (mkCommands "tools" tools) ++ [
            {
              category = "ide";
              name = "nix run nix-dev/#writeSettings";
              help = writeSettings.meta.description;
            }
            {
              category = "ide";
              name = "nix run nix-dev/#codium .";
              help = codium.meta.description;
            }
          ];
        };
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
