{
  description = "srid/haskell-template: Nix template for Haskell projects";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    haskell-flake.url = "github:srid/haskell-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    fourmolu-nix.url = "github:jedimahdi/fourmolu-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.haskell-flake.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.fourmolu-nix.flakeModule
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

            programs.fourmolu = {
              enable = true;
              package = config.fourmolu.wrapper;
            };
            programs.nixfmt-rfc-style.enable = true;
            programs.cabal-fmt.enable = true;
            programs.hlint.enable = true;
          };

          fourmolu.settings = {
            indentation = 2;
            comma-style = "leading";
            record-brace-space = true;
            indent-wheres = true;
            import-export-style = "diff-friendly";
            respectful = true;
            haddock-style = "multi-line";
            newlines-between-decls = 1;
            extensions = [ "ImportQualifiedPost" ];
          };

          # Default package & app.
          packages.default = self'.packages.updater;
          apps.default = self'.apps.updater;

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
