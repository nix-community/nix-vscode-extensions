# Original implementation: https://github.com/NixOS/nixpkgs/blob/1e76ade8ef2a87d0484312f69aefa3fdad3d022d/pkgs/applications/editors/vscode/extensions/tecosaur.latex-utilities/default.nix
{
  lib,
  jq,
  moreutils,
  texlivePackages,
  vscode-utils,
  
  mktplcRef,
  vsix,
  ...
}:

vscode-utils.buildVscodeMarketplaceExtension rec {
  inherit mktplcRef vsix;

  nativeBuildInputs = [
    jq
    moreutils
  ];

  buildInputs = [ texlivePackages.texcount ];

  postInstall = ''
    cd "$out/$installPrefix"
    echo -n ${mktplcRef.version} > VERSION
    jq '.contributes.configuration.properties."latex-utilities.countWord.path".default = "${texlivePackages.texcount}/bin/texcount"' package.json | sponge package.json
  '';

  meta = {
    description = "Add-on to the Visual Studio Code extension LaTeX Workshop";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=tecosaur.latex-utilities";
    homepage = "https://github.com/tecosaur/LaTeX-Utilities";
    changelog = "https://marketplace.visualstudio.com/items/tecosaur.latex-utilities/changelog";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jeancaspar ];
  };
}
