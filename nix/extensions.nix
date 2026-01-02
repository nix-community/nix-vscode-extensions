{
  system,
  nixpkgs,
  overlay ? import ./overlay.nix,
}:
let
  pkgs = import nixpkgs {
    inherit system;
    # Uncomment to allow unfree extensions
    # config.allowUnfree = true;
    overlays = [ overlay ];
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
extensions
