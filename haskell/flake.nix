{
  description = "srid/haskell-template: Nix template for Haskell projects";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
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
        {
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
            # basePackages = pkgs.haskellPackages;

            # Packages to add on top of `basePackages`
            packages = {
              # Add source or Hackage overrides here
              # (Local packages are added automatically)
              /*
                aeson.source = "1.5.0.0" # Hackage version
                shower.source = inputs.shower; # Flake input
              */
            };

            # Add your package overrides here
            settings = {
              /*
                haskell-template = {
                  haddock = false;
                };
                aeson = {
                  check = false;
                };
              */
            };

            # Development shell configuration
            devShell = {
              hlsCheck.enable = false;
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
                # https://nixos.wiki/wiki/Packaging/Binaries
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
            };

          # Default shell.
          devShells.default = pkgs.mkShell {
            name = "updater";
            meta.description = "Haskell development environment";
            # See https://community.flake.parts/haskell-flake/devshell#composing-devshells
            inputsFrom = [
              config.haskellProjects.default.outputs.devShell
              config.treefmt.build.devShell
            ];
            packages = [ pkgs.hpack ];
          };
        };
    };
}
