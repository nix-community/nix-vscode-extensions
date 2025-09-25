{
  description = "srid/haskell-template: Nix template for Haskell projects";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/a1f79a1770d05af18111fbbe2a3ab2c42c0f6cd0";
    nixpkgs-lib.url = "github:nixos/nixpkgs/a1f79a1770d05af18111fbbe2a3ab2c42c0f6cd0?dir=lib";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    devshell = {
      url = "github:deemp/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.inputs.systems.follows = "systems";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.devshell.flakeModule
      ];
      perSystem =
        {
          self',
          system,
          lib,
          config,
          pkgs,
          ...
        }:
        let
          ghcVersion = "910";
          haskellPackages = pkgs.haskell.packages."ghc${ghcVersion}";
          devTools =
            let
              wrapTool =
                pkgsName: pname: flags:
                let
                  pkg = pkgs.${pkgsName};
                in
                pkgs.symlinkJoin {
                  name = pname;
                  paths = [ pkg ];
                  meta = pkg.meta;
                  version = pkg.version;
                  buildInputs = [ pkgs.makeWrapper ];
                  postBuild = ''
                    wrapProgram $out/bin/${pname} \
                      --add-flags "${flags}"
                  '';
                };
            in
            {
              cabal = wrapTool "cabal-install" "cabal" "-v0";
              inherit (pkgs) hpack;
              ghc = builtins.head (
                builtins.filter (
                  x: pkgs.lib.attrsets.isDerivation x && pkgs.lib.strings.hasPrefix "ghc-" x.name
                ) config.haskellProjects.default.outputs.devShell.nativeBuildInputs
              );
              inherit (haskellPackages) haskell-language-server;
            };

          # Our only Haskell project. You can have multiple projects, but this template
          # has only one.
          # See https://github.com/srid/haskell-flake/blob/master/example/flake.nix
          haskellProjects.default = {
            # To avoid unnecessary rebuilds, we filter projectRoot:
            # https://community.flake.parts/haskell-flake/local#rebuild
            projectRoot = builtins.toString (
              lib.fileset.toSource {
                root = ./.;
                fileset = lib.fileset.unions [
                  ./app
                  ./src
                  ./updater.cabal
                  ./LICENSE
                  ./README.md
                  ./CHANGELOG.md
                ];
              }
            );

            # The base package set (this value is the default)
            basePackages = haskellPackages.override {
              overrides =
                self: super:
                let
                  jailbreakUnbreak =
                    pkg:
                    pkgs.haskell.lib.doJailbreak (
                      pkg.overrideAttrs (_: {
                        meta = { };
                      })
                    );
                  packageFromHackage =
                    pkg: ver: sha256:
                    super.callHackageDirect { inherit pkg ver sha256; } { };
                in
                {
                  # co-log-concurrent = jailbreakUnbreak super.co-log-concurrent;
                  # with-utf8 = super.with-utf8_1_1_0_0;
                  tls = packageFromHackage "tls" "1.9.0" "sha256-WpzhvGh6AUdWEKMit2PcpmCo1R28wyTlJY/r5503zL8=";
                };
            };

            settings =
              let
                default = {
                  haddock = false;
                  check = false;
                };
              in
              {
                crypton = default;
                tls = default;
                http-client-tls = default;
              };

            # Development shell configuration
            devShell = {
              hlsCheck.enable = false;
              hoogle = false;
              tools = hp: {
                cabal-install = null;
                hlint = null;
                haskell-language-server = null;
                ghcid = null;
              };
            };

            # What should haskell-flake add to flake outputs?
            autoWire = [
              "packages"
              "apps"
              "checks"
            ]; # Wire all but the devShell
          };

          # Auto formatters. This also adds a flake check to ensure that the
          # source tree was auto formatted.
          treefmt.config = {
            projectRootFile = "flake.nix";
            programs.fourmolu.enable = true;
            programs.nixfmt-rfc-style.enable = true;
            programs.hlint.enable = true;
          };

          # Default package & app.
          packages.default =
            let
              updater = pkgs.haskell.lib.justStaticExecutables self'.packages.updater;
              updaterBin = "$out/bin/${updater.meta.mainProgram}";
            in
            pkgs.stdenv.mkDerivation {
              name = updater.name;
              phases = [ "installPhase" ];
              installPhase =
                # https://sandervanderburg.blogspot.com/2015/10/deploying-prebuilt-binary-software-with.html
                # https://wiki.nixos.org/wiki/Packaging/Binaries
                # https://github.com/NixOS/patchelf
                ''
                  mkdir -p $out/bin
                  cp -p ${lib.getExe updater} $out/bin
                  chmod +rw ${updaterBin}
                  patchelf \
                    --set-interpreter "$(cat $${pkgs.stdenv.cc}/nix-support/dynamic-linker)" \
                    --add-needed libgcc_s.so.1 ${updaterBin} \
                    --set-rpath "$(patchelf --print-rpath ${updaterBin})":${lib.makeLibraryPath [ pkgs.gcc.cc.lib ]} \
                    ${updaterBin}
                '';
              meta.mainProgram = "updater";
            };

          # Default shell.
          devshells.default = {
            commands = {
              tools = [
                {
                  expose = true;
                  packages = devTools;
                }
              ];
            };
          };
        in
        {
          inherit
            devshells
            treefmt
            packages
            haskellProjects
            ;
        };
    };
}
