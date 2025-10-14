{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/674c2b09c59a220204350ced584cadaacee30038";
    nix-dev.url = "path:./nix-dev";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-dev,
      ...
    }:
    let
      inputsCombined = nix-dev.inputs // inputs;

      systemPlatform = {
        x86_64-linux = "linux-x64";
        aarch64-linux = "linux-arm64";
        x86_64-darwin = "darwin-x64";
        aarch64-darwin = "darwin-arm64";
      };

      systems = builtins.attrNames systemPlatform;
    in
    nix-dev.inputs.flake-parts.lib.mkFlake { inputs = inputsCombined; } {
      inherit systems;

      imports = [
        nix-dev.inputs.devshell.flakeModule
        nix-dev.inputs.treefmt-nix.flakeModule
        nix-dev.inputs.nix-unit.modules.flake.default
      ];

      flake =
        let
          vscode-marketplace = "vscode-marketplace";
          open-vsx = "open-vsx";

          platformUniversal = "universal";

          numberToPlatform =
            number:
            let
              numberStr = builtins.toString number;
            in
            {
              "0" = platformUniversal;
              "1" = systemPlatform.x86_64-linux;
              "2" = systemPlatform.aarch64-linux;
              "3" = systemPlatform.x86_64-darwin;
              "4" = systemPlatform.aarch64-darwin;
            }
            .${builtins.toString number} or (builtins.throw "Platform not recognized: ${numberStr}");

          numberToIsRelease =
            number:
            let
              numberStr = builtins.toString number;
            in
            {
              "0" = false;
              "1" = true;
            }
            .${builtins.toString number}
            or (builtins.throw "Value for `isRelease` not recognized: ${numberStr}");

          overlays = {
            default =
              final: prev:
              let
                pkgs = prev;
                inherit (pkgs) lib;
                system = final.stdenv.hostPlatform.system;
                platformCurrent = systemPlatform.${system};
                isCompatibleVersion =
                  vscodeVersion: engineVersion:
                  if lib.strings.hasPrefix "^" engineVersion then
                    lib.versionAtLeast vscodeVersion (lib.strings.removePrefix "^" engineVersion)
                  else
                    vscodeVersion == engineVersion;
                checkVSCodeVersion =
                  { doCheckVSCodeVersion, vscodeVersion }:
                  (x: if doCheckVSCodeVersion then isCompatibleVersion vscodeVersion x.engineVersion else true);
                loadGenerated =
                  {
                    onlyRelease ? false,
                    onlyUniversal ? false,
                    doCheckVSCodeVersion ? false,
                    vscodeVersion ? "*",
                    site,
                    pkgsWithFixes ? pkgs,
                  }:
                  let
                    filterCheck =
                      x:
                      (
                        x.platform == platformUniversal || (if !onlyUniversal then x.platform == platformCurrent else false)
                      )
                      && (if onlyRelease then x.isRelease else true)
                      && (checkVSCodeVersion { inherit doCheckVSCodeVersion vscodeVersion; } x);
                  in
                  lib.pipe site [
                    (x: ./data/cache/${site}${"-latest"}.json)
                    builtins.readFile
                    builtins.fromJSON
                    (map (
                      {
                        p,
                        n,
                        r,
                        P,
                        v,
                        e,
                        h,
                        ...
                      }:
                      {
                        publisher = p;
                        name = n;
                        isRelease = numberToIsRelease r;
                        platform = numberToPlatform P;
                        version = v;
                        engineVersion = e;
                        hash = h;
                      }
                    ))
                    (builtins.filter filterCheck)
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
                              platformSuffix = if platform == platformUniversal then "" else "targetPlatform=${platform}";
                            in
                            "https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${name}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?${platformSuffix}"
                          else
                            let
                              platformSuffix = if platform == platformUniversal then "" else "@${platform}";
                              platformInfix = if platform == platformUniversal then "" else "/${platform}";
                            in
                            "https://open-vsx.org/api/${publisher}/${name}${platformInfix}/${version}/file/${publisher}.${name}-${version}${platformSuffix}.vsix";
                      }
                    ))
                    (
                      x:
                      x
                      ++ builtins.filter filterCheck (
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
                        mkExtension = import ./nix/mkExtension.nix { inherit pkgs pkgsWithFixes system; };
                      in
                      map (
                        {
                          name,
                          publisher,
                          version,
                          hash,
                          url,
                          platform,
                          engineVersion,
                          isRelease,
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

                            # We use not only VS Code Markeplace but also Open VSX
                            # so we need to provide the URL for the extension
                            vsix = prev.fetchurl {
                              inherit url hash;
                              name = "${name}-${version}.zip";
                            };

                            inherit engineVersion platform isRelease;
                          };
                        in
                        {
                          inherit publisher name;
                          value = mkExtension extensionConfig;
                        }
                      )
                    )
                    # group by publisher
                    (builtins.groupBy ({ publisher, ... }: publisher))
                    (builtins.mapAttrs (
                      _:
                      builtins.foldl' (
                        acc:
                        { name, value, ... }:
                        acc
                        // (
                          let
                            valueValidated =
                              if !(lib.attrsets.isDerivation value) then
                                builtins.throw ''
                                  The extension '${value.vscodeExtPublisher}.${name}' has been removed on ${pkgs.system}.
                                  See '${./removed.nix}' for details.
                                ''
                              else
                                value;
                            # We have no reliable way to find the semantically latest version
                            # of an extension.

                            # Therefore, for an extension, we prioritize its versions
                            # and choose one with the highest priority.

                            # Here are the priorities (1 - highest) and properties:
                            # 1. pre-release platform-specific
                            # 2. pre-release universal
                            # 3. release platform-specific
                            # 4. release universal

                            # When there are no pre-release platform-specific versions,
                            # we choose a pre-release universal version etc.

                            # At this point, we process a list of objects (cache).

                            # There is at most one universal and at most one platform-specific version
                            # among any of pre-release and release versions.

                            # When we need the latest version,
                            # we keep an existing version in the accumulator attrset
                            # except for the case when a platform-specific version
                            # with the same `isRelease` is available.

                            valueSelected =
                              if acc ? ${name} then
                                if acc.${name}.passthru.isRelease == valueValidated.passthru.isRelease then
                                  valueValidated
                                else
                                  acc.${name}
                              else
                                valueValidated;
                          in
                          {
                            ${name} = valueSelected;
                          }
                        )
                      ) { }
                    ))
                  ];
                mkSet =
                  attrs@{
                    doCheckVSCodeVersion ? false,
                    vscodeVersion ? "*",
                    pkgsWithFixes ? pkgs,
                  }:
                  let
                    loadGenerated' = attrs': loadGenerated (attrs // attrs');
                  in
                  {
                    # See the documentation for `valueSelected` above.

                    # ---

                    # Below are priorities and corresponding combinations
                    # of properties that can appear in an attrset.
                    # For each extension, the attrset stores
                    # a version with the the highest priority.

                    # ---

                    # These attrsets contain pre-release and release
                    # universal and platform-specific versions.

                    # Priorities and properties:
                    # 1. pre-release platform-specific
                    # 2. pre-release universal
                    # 3. release platform-specific
                    # 4. release universal
                    vscode-marketplace = loadGenerated' { site = vscode-marketplace; };
                    open-vsx = loadGenerated' { site = open-vsx; };

                    # These attrsets contain only release
                    # universal and platform-specific versions.

                    # Priorities and properties:
                    # 1. release platform-specific
                    # 2. release universal
                    vscode-marketplace-release = loadGenerated' {
                      site = vscode-marketplace;
                      onlyRelease = true;
                    };
                    open-vsx-release = loadGenerated' {
                      site = open-vsx;
                      onlyRelease = true;
                    };

                    # These attrsets contain only pre-release and release
                    # universal versions.

                    # Priorities and properties:
                    # 1. pre-release universal
                    # 2. release universal
                    vscode-marketplace-universal = loadGenerated' {
                      site = vscode-marketplace;
                      onlyUniversal = true;
                    };
                    open-vsx-universal = loadGenerated' {
                      site = open-vsx;
                      onlyUniversal = true;
                    };

                    # These attrsets contain only release universal versions.

                    # Priorities and properties:
                    # 1. release universal
                    vscode-marketplace-release-universal = loadGenerated' {
                      site = vscode-marketplace;
                      onlyRelease = true;
                      onlyUniversal = true;
                    };
                    open-vsx-release-universal = loadGenerated' {
                      site = open-vsx;
                      onlyRelease = true;
                      onlyUniversal = true;
                    };
                  };

                nix-vscode-extensions =
                  (mkSet { })
                  // (
                    let
                      mkFun = closure@{ ... }: args: (mkSet (args // closure)) // { __argsCombined = args // closure; };
                      forVSCodeVersion =
                        vscodeVersion:
                        mkFun {
                          doCheckVSCodeVersion = true;
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
        // (nix-dev.inputs.flake-utils.lib.eachSystem systems (
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
                vscode-marketplace-universal
                open-vsx-universal
                vscode-marketplace-release-universal
                open-vsx-release-universal

                forVSCodeVersion
                usingFixesFrom
                ;
            };
          in
          {
            inherit extensions;
          }
        ));

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

          packages = {
            default = import ./nix/vscode-with-extensions.nix {
              inherit system nixpkgs resetLicense;
              nix-vscode-extensions = self;
            };
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
                "test: `allowAliases = false` and `checkMeta = true` work" = {
                  # https://github.com/nix-community/nix-vscode-extensions/issues/142
                  expr =
                    let
                      pkgs = import inputs.nixpkgs {
                        inherit system;

                        config = {
                          allowAliases = false;
                          checkMeta = true;
                        };

                        overlays = [ self.overlays.default ];
                      };
                      extensions = pkgs.nix-vscode-extensions;
                    in
                    (builtins.tryEval extensions.vscode-marketplace.b4dm4n.nixpkgs-fmt).success;
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
