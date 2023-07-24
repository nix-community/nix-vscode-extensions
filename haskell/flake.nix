{
  outputs = inputs:
    let flakes = (import ../nix-dev).outputs.inputs.flakes; in
    flakes.makeFlake {
      inputs = { inherit (flakes.all) nixpkgs drv-tools devshell codium haskell-tools; };
      perSystem = { inputs, system }:
        let
          # We're going to make some dev tools for our Haskell package
          # See NixOS wiki for more info - https://nixos.wiki/wiki/Haskell

          # First, we import stuff
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          inherit (inputs.codium.lib.${system}) writeSettingsJSON mkCodium;
          inherit (inputs.codium.lib.${system}) extensions settingsNix;
          inherit (inputs.devshell.lib.${system}) mkCommands mkShell mkRunCommands;
          inherit (inputs.haskell-tools.lib.${system}) toolsGHC;
          inherit (inputs.drv-tools.lib.${system}) mkShellApp;

          # Next, set the desired GHC version
          ghcVersion_ = "928";

          # and the name of the package
          myPackageName = "nix-managed";

          # And the binaries. 
          # In our case, the Haskell app will call the `hello` command
          myPackageDepsBin = [ pkgs.jq pkgs.nix ];

          # --- shells ---

          # First of all, we need to prepare the haskellPackages attrset
          # So, we define the overrides - https://nixos.wiki/wiki/Haskell#Overrides
          # This is to supply the necessary libraries and executables to our packages
          # Sometimes, we need to fix the broken packages - https://gutier.io/post/development-fixing-broken-haskell-packages-nixpkgs/
          # That's why, inherit several helper functions
          # Note that overriding the packages from haskellPackages will require their rebuilds
          # So, override as few packages as possible and consider making a PR when haskellPackages.somePackage doesn't build

          inherit (pkgs.haskell.lib)
            # override deps of a package
            # see what can be overriden - https://github.com/NixOS/nixpkgs/blob/0ba44a03f620806a2558a699dba143e6cf9858db/pkgs/development/haskell-modules/generic-builder.nix#L13
            overrideCabal
            ;

          # Here's our override
          override = {
            overrides = self: super: {
              co-log-concurrent = overrideCabal (super.co-log-concurrent) (_: { broken = false; });
              myPackage = overrideCabal
                (super.callCabal2nix myPackageName ./. { })
                (_: {
                  # these deps will be in haskellPackages.myPackage.getCabalDeps.librarySystemDepends
                  executableSystemDepends = myPackageDepsBin ++ (super.executableSystemDepends or [ ]);
                });
            };
          };

          # We supply it to a helper function that will give us haskell tools for given 
          # compiler version, override, packages we're going to develop, and their binary runtime dependencies

          # Our devShells should only be aware of the dev dependencies of the Haskell packages that we're going to develop
          # So, we need to supply all Haskell packages that we'd like to develop so that they're excluded from the dev dependencies
          # More specifically, if we're developing Haskell packages A and B and A depends on B, we need to supply both A and B
          # This will prevent nix from building B as a dev dependency of A

          inherit (toolsGHC {
            version = ghcVersion_; inherit override;
            packages = (ps: [ ps.myPackage ]);
            runtimeDependencies = myPackageDepsBin;
          })
            hls cabal implicit-hie justStaticExecutable
            ghcid callCabal2nix haskellPackages hpack;

          updateExtensions = justStaticExecutable {
            package = haskellPackages.myPackage;
            runtimeDependencies = myPackageDepsBin;
          };

          tools = [
            ghcid
            hpack
            implicit-hie
            cabal
            hls
            pkgs.jq
          ];

          packages = {
            # And compose VSCodium with dev tools and HLS
            codium = mkCodium {
              extensions = { inherit (extensions) nix haskell misc github markdown; };
              runtimeDependencies = tools;
            };

            # a script to write .vscode/settings.json
            writeSettings = writeSettingsJSON {
              inherit (settingsNix) haskell todo-tree files editor gitlens
                git nix-ide workbench markdown-all-in-one markdown-language-features;
            };

            inherit updateExtensions;
          };

          devShells = {
            default = mkShell {
              packages = tools;
              commands = mkCommands "tools" tools ++
                mkRunCommands "ide" {
                  "codium ." = packages.codium;
                  inherit (packages) writeSettings;
                };
            };
          };
        in
        {
          inherit packages devShells;
        };
    };
  nixConfig = {
    extra-substituters = [
      "https://haskell-language-server.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.iog.io"
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
