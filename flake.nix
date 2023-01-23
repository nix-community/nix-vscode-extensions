{
  description = "
    `VS Code` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    See the attributes `extensions.\${system}.vscode` and `extensions.\${system}.open-vsx` for other extensions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dbc68fa4bb132d990945d39801b0d7f2ba15b08f";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }: flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs { inherit system; };

        loadGenerated = set:
          with builtins; with pkgs; let
            generated = import ./generated/${set}/generated.nix {
              inherit fetchurl fetchFromGitHub;
              fetchgit = fetchGit;
            };

            groupedByPublisher = (groupBy (e: e.publisher) (attrValues generated));
            pkgDefinition = {
              open-vsx = e: with e; with vscode-utils; {
                inherit name;
                value = buildVscodeMarketplaceExtension {
                  vsix = src;
                  mktplcRef = {
                    inherit version;
                    publisher = marketplacePublisher;
                    name = marketplaceName;
                  };
                  meta = with lib; {
                    inherit changelog downloadPage homepage;
                    license = licenses.${license};
                  };
                };
              };
              vscode-marketplace = e: with e; with vscode-utils; {
                inherit name;
                value = buildVscodeMarketplaceExtension {
                  vsix = src;
                  mktplcRef = {
                    inherit version;
                    publisher = marketplacePublisher;
                    name = marketplaceName;
                  };
                };
              };
            };
          in
          mapAttrs (_: val: listToAttrs (map pkgDefinition.${set} val)) groupedByPublisher;

        extensions = {
          vscode = loadGenerated "vscode-marketplace";
          open-vsx = loadGenerated "open-vsx";
        };

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

        # test
        vscodium-with-extensions =
          let inherit (pkgs) vscode-with-extensions vscodium;
          in
          (vscode-with-extensions.override {
            vscode = vscodium;
            vscodeExtensions = builtins.attrValues {
              inherit (extensions.vscode.golang) go;
              inherit (extensions.vscode.vlanguage) vscode-vlang;
            };
          });
      in
      {
        devShell = pkgs.mkShell {
          shellHook = ''
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

            printf "\nVSCodium with extensions:\n"
            codium --list-extensions
          '';
          buildInputs = [
            pkgs.deno
            pkgs.nvfetcher
            pkgs.poetry
            vscodium-with-extensions
          ];
        };
        packages = { inherit scripts vscodium-with-extensions; };
        inherit extensions;
        overlays.default = final: prev: {
          vscode-extensions = extensions;
        };
      }
    ) // {
    templates = {
      default = {
        path = ./template;
        description = "VSCodium with extensions";
      };
    };
  };
}
