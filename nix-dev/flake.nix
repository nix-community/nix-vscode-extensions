{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    my-codium.url = "github:deemp/flakes?dir=codium";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    vscode-extensions_.url = "github:deemp/flakes?dir=source-flake/vscode-extensions";
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
        inherit (pkgs.lib.attrsets) mapAttrsToList recursiveUpdate mapAttrs;
        inherit (drv-tools.functions.${system}) mkShellApps concatMapStringsNewline;

        codium = mkCodium {
          extensions = {
            inherit (extensions) nix misc markdown github;
          };
        };
        writeSettings = writeSettingsJSON {
          inherit (settingsNix)
            nix-ide markdown-all-in-one git gitlens todo-tree
            markdown-language-features files editor workbench
            ;
        };
        tools = [
          codium
          writeSettings
          pkgs.deno
          pkgs.nvfetcher
          pkgs.poetry
        ];
        env = isTargetOpenVSX: mapAttrs (name: builtins.toString)
          ({
            DENO_DIR = "$PWD/.deno";
            FIRST_BLOCK = 1;
            THREADS = 0;
            ACTION_ID = 1;
            OUT_DIR = "tmp/out";
          } // (if isTargetOpenVSX then {
            TARGET = "open-vsx";
            NAME = "Open VSX";
            BLOCK_SIZE = 10;
            BLOCK_LIMIT = 20;
            APPROX_EXTENSIONS = 3000;
            ALLOW_NET = "open-vsx.org";
            MAX_ATTEMPTS = 6;
            RETRY_WAIT_MINUTES = 61;
            TIMEOUT_MINUTES = 360;
          } else {
            TARGET = "vscode-marketplace";
            NAME = "VSCode Marketplace";
            BLOCK_SIZE = 10;
            BLOCK_LIMIT = 230;
            APPROX_EXTENSIONS = 45000;
            ALLOW_NET = "marketplace.visualstudio.com";
            MAX_ATTEMPTS = 6;
            RETRY_WAIT_MINUTES = 61;
            TIMEOUT_MINUTES = 360;
          }));
        scripts =
          let poetryInstall = "if [[ ! -d .venv ]]; then poetry install; fi"; in
          mkShellApps (
            mapAttrs (name: value: value // { text = concatMapStringsNewline (x: value.text (env x)) [ true false ]; })
              {
                nvfetch = {
                  runtimeInputs = [ pkgs.poetry ];
                  text = _: with _; ''
                    ${poetryInstall}
                    poetry run python -m scripts.nvfetch \
                      --target "${TARGET}" \
                      --first-block "${FIRST_BLOCK}" \
                      --block-size "${BLOCK_SIZE}" \
                      --block-limit "${BLOCK_LIMIT}" \
                      --threads "${THREADS}" \
                      --action-id "${ACTION_ID}"
                  '';
                };
                combine = {
                  text = _: with _; ''
                    ${poetryInstall}
                    poetry run python -m scripts.combine \
                      --target "${TARGET}" \
                      --out-dir "${OUT_DIR}"
                  '';
                  runtimeInputs = [ pkgs.poetry ];
                };
                generateConfigs = {
                  text = _: with _; ''     
                    ${poetryInstall}
                    poetry run python -m scripts.generate-configs \
                      --target "${TARGET}" \
                      --approx-extensions "${APPROX_EXTENSIONS}" \
                      --block-limit "${BLOCK_LIMIT}" \
                      --block-size "${BLOCK_SIZE}" \
                      --marketplace "${NAME}" \
                      --max-attempts "${MAX_ATTEMPTS}" \
                      --retry-wait-minutes "${RETRY_WAIT_MINUTES}" \
                      --timeout-minutes "${TIMEOUT_MINUTES}"
                  '';
                  runtimeInputs = [ pkgs.poetry ];
                };
                updateExtensions = {
                  text = _: with _; ''
                    mkdir -p nvfetch
                    export DENO_DIR=${DENO_DIR} && nix run nixpkgs#deno -- run \
                      --allow-write \ 
                      --allow-net="${ALLOW_NET}" \
                      --no-prompt \
                      updater/index.ts "${TARGET}" \
                      nvfetch/"${TARGET}".toml
                  '';
                };
              });
      in
      {
        packages = scripts;
        devShells.default = devshell.mkShell {
          packages = tools;
          commands = mkCommands "ide" tools;
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
