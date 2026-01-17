{
  description = "
    `VS Code Marketplace` (~40K) and `Open VSX` (~3K) extensions as `Nix` expressions.
    Learn more in the flake [repo](https://github.com/nix-community/nix-vscode-extensions).
  ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/def3da69945bbe338c373fddad5a1bb49cf199ce";
  };

  outputs =
    { nixpkgs, ... }:
    let
      flake-compat = import ./nix/flake-compat.nix;

      nix-dev =
        (flake-compat {
          src = ./.;
          root = "nix-dev";
        }).defaultNix;

      systemPlatform = import ./nix/systemPlatform.nix;

      overlay = import ./nix/overlay.nix;
    in
    {
      extensions = builtins.mapAttrs (
        system: _:
        import ./nix/extensions.nix {
          inherit system nixpkgs overlay;
        }
      ) systemPlatform;

      inherit (nix-dev) devShells checks formatter;

      overlays.default = overlay;

      templates = {
        default = {
          path = ./template;
          description = "VSCodium with extensions";
        };
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
