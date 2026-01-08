{
  system,
  nixpkgs,
  vscode-marketplace ? (import ./extensions.nix { inherit system nixpkgs; }).vscode-marketplace,
  lib ? nixpkgs.lib,
  resetLicense ? import ./resetLicense.nix,
  semver ? import ./semver.nix { inherit lib; },
  overlay ? import ./overlay.nix,
}:
semver.tests
// {
  "test: ms-python.vscode-pylance fails if unfree" = {
    expr =
      # https://discourse.nixos.org/t/evaluating-possibly-nonfree-derivations/24835/2
      (builtins.tryEval (builtins.unsafeDiscardStringContext vscode-marketplace.ms-python.vscode-pylance))
      .success;
    expected = false;
  };
  "test: ms-vscode.cpptools passes only on Linux" = {
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
        pkgs = import nixpkgs {
          inherit system;

          config = {
            allowAliases = false;
            checkMeta = true;
          };

          overlays = [ overlay ];
        };
        extensions = pkgs.nix-vscode-extensions;
      in
      (builtins.tryEval extensions.vscode-marketplace.b4dm4n.nixpkgs-fmt).success;
    expected = true;
  };
}
