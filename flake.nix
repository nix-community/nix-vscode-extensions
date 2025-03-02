{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
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
        default =
          final: prev:
          let
            pkgs = prev;
            currentPlatform = systemPlatform.${final.system};
            isCompatibleVersion =
              vscodeVersion: engineVersion:
              if lib.strings.hasPrefix "^" engineVersion then
                lib.versionAtLeast vscodeVersion (lib.strings.removePrefix "^" engineVersion)
              else
                vscodeVersion == engineVersion;
            # version of VSCode or VSCodium
            filterByPlatform =
              { checkVSCodeVersion, vscodeVersion }:
              (builtins.filter (
                x:
                (x.platform == universal || x.platform == currentPlatform)
                && (if checkVSCodeVersion then (isCompatibleVersion vscodeVersion x.engineVersion) else true)
              ));
            loadGenerated =
              {
                needLatest ? true,
                checkVSCodeVersion ? false,
                vscodeVersion ? "*",
                site,
              }:
              lib.pipe site [
                (x: ./data/cache/${site}${if needLatest then "-latest" else "-release"}.json)
                builtins.readFile
                builtins.fromJSON
                (filterByPlatform { inherit checkVSCodeVersion vscodeVersion; })
                (map (
                  extension@{
                    name,
                    publisher,
                    version,
                    platform,
                    ...
                  }:
                  extension
                  // {
                    url =
                      if site == vscode-marketplace then
                        let
                          platformSuffix = if platform == universal then "" else "targetPlatform=${platform}";
                        in
                        "https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${name}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?${platformSuffix}"
                      else
                        let
                          platformSuffix = if platform == universal then "" else "@${platform}";
                          platformInfix = if platform == universal then "" else "/${platform}";
                        in
                        "https://open-vsx.org/api/${publisher}/${name}${platformInfix}/${version}/file/${publisher}.${name}-${version}${platformSuffix}.vsix";
                  }
                ))
                (
                  x:
                  builtins.map (ext: ext // { hash = ext.sha256; }) x
                  ++ filterByPlatform { inherit checkVSCodeVersion vscodeVersion; } (
                    pkgs.lib.attrsets.mapAttrsToList
                      (name: value: {
                        url = value.src.url;
                        hash = value.src.outputHash;
                        inherit (value)
                          publisher
                          name
                          version
                          platform
                          engineVersion
                          ;
                      })
                      (
                        # append extra extensions fetched from elsewhere to overwrite site extensions
                        import ./data/extra-extensions/generated.nix {
                          inherit (pkgs)
                            fetchgit
                            fetchurl
                            fetchFromGitHub
                            dockerTools
                            ;
                        }
                      )
                  )
                )
                # lowercase all names and publishers
                (map (
                  extension@{ name, publisher, ... }:
                  extension
                  // {
                    name = lib.toLower name;
                    publisher = lib.toLower publisher;
                  }
                ))
                (
                  let
                    # keep outside of map to improve performance
                    mkExtension = import ./mkExtension.nix { inherit pkgs nixpkgs; };
                  in
                  map (
                    {
                      name,
                      publisher,
                      version,
                      hash,
                      url,
                      ...
                    }:
                    let
                      extensionConfig = {
                        mktplcRef = {
                          inherit
                            name
                            publisher
                            version
                            hash
                            ;
                        };

                        # We use not only VSCode Markeplace but also Open VSX
                        # so we need to provide the URL for the extension
                        vsix = prev.fetchurl {
                          inherit url hash;
                          name = "${name}-${version}.zip";
                        };
                      };
                    in
                    {
                      inherit name;
                      value = mkExtension extensionConfig;
                    }
                  )
                )
                # group by publisher
                (builtins.groupBy ({ value, ... }: value.vscodeExtPublisher))
                # platform-specific extensions will overwrite universal extensions
                # due to the sorting order of platforms in the Haskell script
                (builtins.mapAttrs (
                  _:
                  builtins.foldl' (
                    k:
                    { name, value }:
                    k
                    // {
                      ${name} =
                        if !(lib.attrsets.isDerivation value) then
                          builtins.throw ''
                            The extension '${value.vscodeExtPublisher}.${name}' has been removed on ${pkgs.system}.
                            See '${./removed.nix}' for details.
                          ''
                        else
                          value;
                    }
                  ) { }
                ))
              ];
            mkSet =
              attrs@{
                checkVSCodeVersion ? false,
                vscodeVersion ? "*",
              }:
              {
                vscode-marketplace = loadGenerated (attrs // { site = vscode-marketplace; });
                open-vsx = loadGenerated (attrs // { site = open-vsx; });
                vscode-marketplace-release = loadGenerated (
                  attrs
                  // {
                    needLatest = false;
                    site = vscode-marketplace;
                  }
                );
                open-vsx-release = loadGenerated (
                  attrs
                  // {
                    needLatest = false;
                    site = open-vsx;
                  }
                );
              };
            res = (mkSet { }) // {
              forVSCodeVersion =
                vscodeVersion:
                mkSet {
                  checkVSCodeVersion = true;
                  inherit vscodeVersion;
                };
            };
          in
          res;
      };
      templates = {
        default = {
          path = ./template;
          description = "VSCodium with extensions";
        };
      };
    }
    // (eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        extensions = import nixpkgs {
          inherit system;
          # Uncomment to allow unfree extensions
          # config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        };
        packages = {
          default =
            pkgs.lib.trivial.pipe
              (pkgs.vscode-with-extensions.override {
                vscode = pkgs.vscodium;
                vscodeExtensions = with self.extensions.${system}.vscode-marketplace; [
                  golang.go
                  vlanguage.vscode-vlang
                  rust-lang.rust-analyzer
                  vadimcn.vscode-lldb
                ];
              })
              [
                (
                  x:
                  pkgs.lib.attrsets.recursiveUpdate x {
                    meta = {
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
                  }
                )
                (x: x // { meta = builtins.removeAttrs x.meta [ "description" ]; })
              ];
        };
        formatter = pkgs.nixfmt-rfc-style;
      }
    ));
}
