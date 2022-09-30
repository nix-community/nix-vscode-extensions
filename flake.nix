{
  description = "VSCode and OpenVSX Extensions Collection For Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
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
                  --marketplace "''${NAME:-"VSCode Marketplace"}"
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
        devShell = pkgs.mkShell {
          shellHook = ''
            # nvfetch
            export DENO_DIR="$(pwd)/.deno"
            export FIRST_BLOCK=1
            export THREADS=0
            export ACTION_ID=1
            export OUT_DIR=tmp/out

            export TARGET=vscode-marketplace
            # export TARGET=open-vsx
            if [[ $TARGET = vscode-marketplace ]]; then
              export NAME="VSCode Marketplace"
              export BLOCK_SIZE=10
              export BLOCK_LIMIT=200
              export APPROX_EXTENSIONS=45000
              export ALLOW_NET=marketplace.visualstudio.com
            else
              export NAME="Open VSX"
              export BLOCK_SIZE=10
              export BLOCK_LIMIT=20
              export APPROX_EXTENSIONS=3000
              export ALLOW_NET=open-vsx.org
            fi
          '';
          nativeBuildInputs = with pkgs; [
            deno
            nvfetcher
            poetry
          ];
          buildInputs = [ ];
        };
        packages = extensions // { inherit scripts; };
        overlays.default = final: prev: {
          vscode-marketplace = extensions;
        };
      });
}
