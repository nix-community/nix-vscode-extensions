{
  system,
  nixpkgs,
  nix-vscode-extensions,
  resetLicense,
}:
let
  pkgs = nixpkgs.legacyPackages.${system};
  lib = pkgs.lib;
in
pkgs.vscode-with-extensions.override {
  # vscode = pkgs.vscodium;
  vscode = resetLicense pkgs.vscode;
  vscodeExtensions =
    let
      extensions = import nixpkgs {
        inherit system;
        # Uncomment to allow unfree extensions
        # config.allowUnfree = true;
        overlays = [ nix-vscode-extensions.overlays.default ];
      };
    in
    (with extensions.vscode-marketplace; [
      golang.go
      vlanguage.vscode-vlang
      rust-lang.rust-analyzer
      ms-dotnettools.vscode-dotnet-runtime
      mkhl.direnv
      jnoortheen.nix-ide
      tamasfe.even-better-toml
    ])
    ++ (lib.lists.optionals (builtins.elem system lib.platforms.linux) (
      with extensions.vscode-marketplace;
      [
        # Exclusively for testing purpose
        (resetLicense ms-vscode.cpptools)
        # on aarch64-linux, triggers the error:
        # build input /nix/store/194yri6cyqad6yvbhpqp5wswsppnsi7x-jq-1.8.1-dev does not exist
        # yzane.markdown-pdf
      ]
    ))
    ++ (with extensions.vscode-marketplace-universal; [
      # TODO make v1.11.6 build
      # vadimcn.vscode-lldb
    ]);
}
