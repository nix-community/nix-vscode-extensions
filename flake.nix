{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/ebe4301cbd8f81c4f8d3244b3632338bbeb6d49c";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      nix-dev = import ./nix-dev;
      inputsCombined = nix-dev.inputs // inputs;
    in
    nix-dev.inputs.flake-parts.lib.mkFlake { inputs = inputsCombined; } {
      systems = import flake-utils.inputs.systems;

      imports = [
        nix-dev.inputs.devshell.flakeModule
        nix-dev.inputs.treefmt-nix.flakeModule
        nix-dev.inputs.nix-unit.modules.flake.default
      ];

      flake =
        let
          vscode-marketplace = "vscode-marketplace";
          open-vsx = "open-vsx";
          universal = "universal";

          systemPlatform = {
            "aarch64-darwin" = "darwin-arm64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-linux" = "linux-x64";
            "x86_64-darwin" = "darwin-x64";
          };

          overlays = {
            default =
              final: prev:
              let
                pkgs = prev;
                inherit (pkgs) lib;
                currentPlatform = systemPlatform.${final.system};
                isCompatibleVersion =
                  vscodeVersion: engineVersion:
                  if lib.strings.hasPrefix "^" engineVersion then
                    lib.versionAtLeast vscodeVersion (lib.strings.removePrefix "^" engineVersion)
                  else
                    vscodeVersion == engineVersion;
                filterByPlatform =
                  {
                    checkVSCodeVersion,
                    # version of VSCode or VSCodium
                    vscodeVersion,
                  }:
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
                    pkgsWithFixes ? pkgs,
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
                        # TODO pass user's nixpkgs
                        mkExtension = import ./mkExtension.nix { inherit pkgs pkgsWithFixes; };
                      in
                      map (
                        {
                          name,
                          publisher,
                          version,
                          hash,
                          url,
                          engineVersion,
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

                            inherit engineVersion;
                          };
                        in
                        {
                          inherit name;
                          value = mkExtension extensionConfig;
                          inherit (extensionConfig.mktplcRef) publisher;
                        }
                      )
                    )
                    # group by publisher
                    (builtins.groupBy ({ publisher, ... }: publisher))
                    # platform-specific extensions will overwrite universal extensions
                    # due to the sorting order of platforms in the Haskell script
                    (builtins.mapAttrs (
                      _:
                      builtins.foldl' (
                        k:
                        { name, value, ... }:
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
                    pkgsWithFixes ? pkgs,
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

                nix-vscode-extensions =
                  (mkSet { })
                  // (
                    let
                      mkFun = closure@{ ... }: args: (mkSet (args // closure)) // { __argsCombined = args // closure; };
                      forVSCodeVersion =
                        vscodeVersion:
                        mkFun {
                          checkVSCodeVersion = true;
                          inherit vscodeVersion;
                        };
                      usingFixesFrom = pkgsWithFixes: mkFun { inherit pkgsWithFixes; };
                    in
                    {
                      forVSCodeVersion =
                        vscodeVersion:
                        let
                          attrPrev = forVSCodeVersion vscodeVersion { };
                        in
                        attrPrev
                        // {
                          usingFixesFrom = pkgsWithFixes: usingFixesFrom pkgsWithFixes attrPrev.__argsCombined;
                        };

                      usingFixesFrom =
                        pkgsWithFixes:
                        let
                          attrPrev = usingFixesFrom pkgsWithFixes { };
                        in
                        attrPrev
                        // {
                          forVSCodeVersion = vscodeVersion: forVSCodeVersion vscodeVersion attrPrev.__argsCombined;
                        };
                    }
                  );
              in
              nix-vscode-extensions // { inherit nix-vscode-extensions; };
          };

          templates = {
            default = {
              path = ./template;
              description = "VSCodium with extensions";
            };
          };
        in
        {
          inherit overlays templates;
        }
        // flake-utils.lib.eachDefaultSystem (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              # Uncomment to allow unfree extensions
              # config.allowUnfree = true;
              overlays = [ self.overlays.default ];
            };

            extensions = {
              inherit (pkgs)
                vscode-marketplace
                open-vsx
                vscode-marketplace-release
                open-vsx-release
                forVSCodeVersion
                usingFixesFrom
                ;
            };
          in
          {
            inherit extensions;
          }
        );

      perSystem =
        {
          self',
          system,
          lib,
          pkgs,
          inputs',
          ...
        }:
        let
          devshells.default = {
            commands = {
              tools = [
                {
                  expose = true;
                  packages = {
                    inherit (pkgs) nvfetcher;
                  };
                }
                {
                  prefix = "nix run .#";
                  packages = {
                    inherit (self'.packages) updateExtensions updateExtraExtensions;
                  };
                }
              ];
            };
          };

          mkShellApps = lib.mapAttrs (
            name: value:
            if !(lib.isDerivation value) && lib.isAttrs value then
              pkgs.writeShellApplication (value // { inherit name; })
            else
              value
          );

          haskell = import ./haskell;

          resetLicense =
            drv:
            drv.overrideAttrs (prev: {
              meta = prev.meta // {
                license = [ ];
              };
            });

          packages =
            {
              default =
                (pkgs.vscode-with-extensions.override {
                  # vscode = pkgs.vscodium;
                  vscode = resetLicense pkgs.vscode;
                  vscodeExtensions =
                    let
                      extensions = import inputs.nixpkgs {
                        inherit system;
                        # Uncomment to allow unfree extensions
                        # config.allowUnfree = true;
                        overlays = [ self.overlays.default ];
                      };
                    in
                    with extensions.vscode-marketplace;
                    [
                      golang.go
                      vlanguage.vscode-vlang
                      rust-lang.rust-analyzer
                      vadimcn.vscode-lldb
                      ms-dotnettools.vscode-dotnet-runtime
                      mkhl.direnv
                      jnoortheen.nix-ide
                      tamasfe.even-better-toml
                    ]
                    ++ (lib.lists.optionals (builtins.elem system lib.platforms.linux) [
                      # Exclusively for testing purpose
                      (resetLicense ms-vscode.cpptools)
                      # Local build hangs
                      # yzane.markdown-pdf
                    ]);
                }).overrideAttrs
                  (prev: {
                    meta = prev.meta // {
                      description = "VSCodium with a few extensions.";
                      longDescription = ''
                        This is a sample overridden VSCodium (a FOSS fork of VS Code) with a few extensions.
                        You can override this package and set `vscodeExtensions` to a list of extension
                        derivations, specifically those provided by this flake.
                        The [repository] offers approximately 40,000 extensions from the [Visual Studio Marketplace]
                        and an additional 4,500 from the [Open VSX Registry].
                        [repository]: https://github.com/nix-community/nix-vscode-extensions
                        [Visual Studio Marketplace]: https://marketplace.visualstudio.com/vscode
                        [Open VSX Registry]: https://open-vsx.org/
                      '';
                    };
                  });
            }
            // mkShellApps {
              updateExtensions = {
                text = ''${lib.meta.getExe haskell.outputs.packages.${system}.default} "$@"'';
                meta.description = "Update extensions";
              };
              updateExtraExtensions = {
                text = "${lib.meta.getExe pkgs.nvfetcher} -c extra-extensions.toml -o data/extra-extensions";
                meta.description = "Update extra extensions";
              };
            };

          legacyPackages.saveFromGC.ci.jobs =
            let
              mkSaveFromGC =
                attrs: import "${nix-dev.inputs.cache-nix-action}/saveFromGC.nix" ({ inherit pkgs; } // attrs);
              template = (import nix-dev.inputs.flake-compat { src = ./template; }).defaultNix;
            in
            {
              test =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputsCombined;
                  };
                  derivations = [ self'.packages.default ];
                }).saveFromGC;

              update =
                (mkSaveFromGC {
                  inputs = {
                    self.inputs = inputsCombined;
                    inherit haskell;
                  };
                  derivations = [
                    self'.packages.updateExtensions
                    self'.packages.updateExtraExtensions
                    self'.formatter
                  ];
                }).saveFromGC;

              test-template =
                (mkSaveFromGC {
                  inputs = {
                    self = template;
                    inherit template;
                  };
                  derivations = [ template.devShells.${system}.default ];
                }).saveFromGC;
            };

          nix-unit = {
            allowNetwork = true;

            inputs = {
              inherit (inputsCombined)
                nixpkgs
                flake-parts
                nix-unit
                flake-compat
                ;
            };

            tests =
              let
                inherit (self.extensions.${system}) vscode-marketplace;
              in
              {
                "test: ms-python.vscode-pylance fails if unfree" = {
                  expr =
                    # https://discourse.nixos.org/t/evaluating-possibly-nonfree-derivations/24835/2
                    (builtins.tryEval (builtins.unsafeDiscardStringContext vscode-marketplace.ms-python.vscode-pylance))
                    .success;
                  expected = false;
                };
                "test: ms-vscode.cpptools passes only on " = {
                  expr = (builtins.tryEval vscode-marketplace.ms-vscode.cpptools).success;
                  expected = builtins.elem system lib.platforms.linux;
                };
                "test: ms-python.vscode-pylance passes if not unfree" = {
                  expr = (builtins.tryEval (resetLicense vscode-marketplace.ms-python.vscode-pylance)).success;
                  expected = true;
                };
                "test: rust-lang.rust-analyzer passes" = {
                  expr = (builtins.tryEval vscode-marketplace.rust-lang.rust-analyzer).success;
                  expected = true;
                };
              };
          };

          treefmt = {
            flakeCheck = false;

            programs = {
              nixfmt.enable = true;
              prettier.enable = true;
            };

            settings.global.excludes = [
              "haskell/**"
              "data/**"
              # ".github/**"
              ".envrc"
              ".env"
              "LICENSE"
              # "README.md"
              "cabal.project"
              "extra-extensions.toml"
              ".markdownlint.jsonc"
            ];
          };
        in
        {
          inherit
            devshells
            packages
            legacyPackages
            nix-unit
            treefmt
            ;
        };
    };

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
      "https://hydra.iohk.io"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
    ];
  };
}
