{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    my-codium.url = "github:deemp/flakes?dir=codium";
    flake-utils_.url = "github:deemp/flakes?dir=source-flake/flake-utils";
    flake-utils.follows = "flake-utils_/flake-utils";
    vscode-extensions_.url = "github:deemp/flakes?dir=source-flake/vscode-extensions";
    vscode-extensions.follows = "vscode-extensions_/vscode-extensions";
    my-devshell.url = "github:deemp/flakes?dir=devshell";
  };
  outputs =
    { self
    , my-codium
    , flake-utils
    , vscode-extensions
    , my-devshell
    , nixpkgs
    , ...
    }: flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (my-codium.functions.${system}) mkCodium writeSettingsJSON;
        inherit (my-codium.configs.${system}) extensions settingsNix;
        devshell = my-devshell.devshell.${system};
        inherit (my-devshell.functions.${system}) mkCommands;
        codium = mkCodium {
          extensions = {
            inherit (extensions) nix misc markdown github;
          };
        };
        writeSettings = writeSettingsJSON {
          inherit (settingsNix)
            nix-ide markdown-all-in-one git gitlens todo-tree
            markdown-language-features
            ;
        };
        tools = [
          codium
          writeSettings
          pkgs.deno
          pkgs.nvfetcher
          pkgs.poetry
        ];
        scripts =
          let poetryInstall = "if [[ ! -d .venv ]]; then poetry install; fi"; in
          {
            nvfetch = pkgs.writeShellApplication {
              name = "nvfetch";
              runtimeInputs = [ pkgs.poetry ];
              text = ''
                ${poetryInstall}
                poetry run python -m scripts.nvfetch \
                  --target "$TARGET" --first-block "''${FIRST_BLOCK:-1}" \
                  --block-size "''${BLOCK_SIZE:-1}" --block-limit "''${BLOCK_LIMIT:-1}" \
                  --threads "''${THREADS:-0}" --action-id "''${ACTION_ID:-1}"
              '';
            };
            combine = pkgs.writeShellApplication {
              name = "combine";
              text = ''
                ${poetryInstall}
                poetry run python -m scripts.combine \
                  --target "$TARGET" --out-dir "''${OUT_DIR:-./}"
              '';
              runtimeInputs = [ pkgs.poetry ];
            };
            generateConfigs = pkgs.writeShellApplication {
              name = "generate-configs";
              text = ''     
                ${poetryInstall}
                poetry run python -m scripts.generate-configs \
                  --target "''${TARGET:-vscode-marketplace}" \
                  --approx-extensions "''${APPROX_EXTENSIONS:-10000}" \
                  --block-limit "''${BLOCK_LIMIT:-1}" \
                  --block-size "''${BLOCK_SIZE:-1}" \
                  --marketplace "''${NAME:-"VSCode Marketplace"}" \
                  --max-attempts "''${MAX_ATTEMPTS:-3}" \
                  --retry-wait-minutes "''${RETRY_WAIT_MINUTES:-10}" \
                  --timeout-minutes "''${TIMEOUT_MINUTES:-10}"
              '';
              runtimeInputs = [ pkgs.poetry ];
            };
            updateExtensions = pkgs.writeShellApplication {
              name = "update-extensions";
              text = ''
                mkdir -p nvfetch
                export DENO_DIR=.deno && nix run nixpkgs#deno -- run \
                  --allow-write --allow-net="$ALLOW_NET" \
                  --no-prompt updater/index.ts "$TARGET" \
                  nvfetch/"$TARGET".toml
              '';
            };
          };
      in
      {
        packages = scripts;
        devShells.default = devshell.mkShell
          {
            packages = tools;
            bash = {
              extra = ''
                # nvfetch
                export DENO_DIR="$(pwd)/.deno"
                export FIRST_BLOCK=1
                export THREADS=0
                export ACTION_ID=1
                export OUT_DIR=tmp/out

                # export TARGET=vscode-marketplace
                export TARGET=open-vsx
                if [[ $TARGET = vscode-marketplace ]]; then
                  export NAME="VSCode Marketplace"
                  export BLOCK_SIZE=10
                  export BLOCK_LIMIT=200
                  export APPROX_EXTENSIONS=45000
                  export ALLOW_NET=marketplace.visualstudio.com
                  export MAX_ATTEMPTS=6
                  export RETRY_WAIT_MINUTES=61
                  export TIMEOUT_MINUTES=360
                else
                  export NAME="Open VSX"
                  export BLOCK_SIZE=10
                  export BLOCK_LIMIT=20
                  export APPROX_EXTENSIONS=3000
                  export ALLOW_NET=open-vsx.org
                  export MAX_ATTEMPTS=6
                  export RETRY_WAIT_MINUTES=61
                  export TIMEOUT_MINUTES=360
                fi
              '';
            };
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
