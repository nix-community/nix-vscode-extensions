{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      inherit (nixpkgs) lib;
      inherit (flake-utils.lib) eachDefaultSystem;
      vscode-marketplace = "vscode-marketplace";
      open-vsx = "open-vsx";
      universal = "universal";

      systemPlatform = {
        "aarch64-darwin" = "darwin-arm64";
        "x86_64-linux" = "linux-x64";
        "aarch64-linux" = "linux-arm64";
        "x86_64-darwin" = "darwin-x64";
      };
    in
    {
      overlays = {
        default = final: prev:
          let
            utils = nixpkgs.legacyPackages.${final.system}.vscode-utils;
            currentPlatform = systemPlatform.${final.system};
            loadGenerated = site:
              lib.pipe site [
                (x: ./data/cache/${site}.json)
                __readFile
                __fromJSON
                (__filter (x: x.platform == universal || x.platform == currentPlatform))
                (map (extension@{ name, publisher, version, sha256, platform, ... }:
                  {
                    inherit name platform;
                    value = utils.buildVscodeMarketplaceExtension {
                      vsix = prev.fetchurl {
                        inherit sha256;
                        url =
                          if site == vscode-marketplace then
                            let platform' = if platform == universal then "" else "targetPlatform=${platform}"; in
                            "https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${name}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?${platform'}"
                          else
                            let platform' = if platform == universal then "" else "@${platform}"; in
                            "https://open-vsx.org/api/${publisher}/${name}/${version}/file/${publisher}.${name}-${version}${platform'}.vsix";
                        name = "${name}-${version}.zip";
                      };
                      mktplcRef = {
                        inherit name version publisher;
                      };
                    };
                  }))
                (map (x: builtins.removeAttrs x [ "platform" ]))
                (__groupBy ({ value, ... }: value.vscodeExtPublisher))
                # platform-specific extensions will overwrite the universal extensions
                # due to the sorting order of platforms in the Haskell script
                (__mapAttrs (_: __foldl' (k: { name, value }: k // { ${name} = value; }) { }))
              ];
          in
          {
            vscode-marketplace = loadGenerated vscode-marketplace;
            open-vsx = loadGenerated open-vsx;
          };
      };
      templates = {
        vscodium-with-extensions = {
          path = ./template;
          description = "VSCodium with extensions";
        };
      };
    }
    // (eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        extensions = self.overlays.default pkgs pkgs;
        packages = {
          vscodium-with-extensions = pkgs.lib.trivial.pipe
            (pkgs.vscode-with-extensions.override
              {
                vscode = pkgs.vscodium;
                vscodeExtensions = with self.extensions.${system}.vscode-marketplace; [
                  golang.go
                  vlanguage.vscode-vlang
                  rust-lang.rust-analyzer
                ];
              }
            )
            [
              (x: pkgs.lib.attrsets.recursiveUpdate x
                {
                  meta = rec {
                    longDescription = ''
                      This is a sample overridden VSCodium (FOSS fork of VS Code) with a couple extensions.
                      You can override this package and set `vscodeExtensions` to a list of extension
                      derivations, namely those provided by this flake.

                      The [repository] provides ~40K extensions from [Visual Studio Marketplace]
                      and another ~3K from [Open VSX Registry].

                      [repository]: https://github.com/nix-community/nix-vscode-extensions
                      [Visual Studio Marketplace]: https://marketplace.visualstudio.com/vscode
                      [Open VSX Registry]: https://open-vsx.org/
                    '';
                  };
                })
              (x: x // { meta = builtins.removeAttrs x.meta [ "description" ]; })
            ];
        };
        formatter = pkgs.writeScriptBin
          "fmt"
          "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt flake.nix nix-dev/flake.nix";
      }));
}
