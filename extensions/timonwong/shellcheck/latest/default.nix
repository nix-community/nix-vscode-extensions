# Based on https://github.com/NixOS/nixpkgs/blob/36ff9aed23df5b20e3c9ff89ab311d5b8eba7a12/pkgs/applications/editors/vscode/extensions/timonwong.shellcheck/default.nix
#
# The `jq` filter there (L22) assumes `contributes.configuration` is an object.
# This holds for 0.40.1 but not for 0.46.1, where it's an array of sections.
{
  jq,
  lib,
  moreutils,
  shellcheck,
  vscode-utils,

  mktplcRef,
  vsix,

  ...
}:
vscode-utils.buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;

  nativeBuildInputs = [
    jq
    moreutils
  ];

  # `contributes.configuration` is an object in older versions
  # and an array of sections in newer versions (e.g., 0.46.1).
  postInstall = ''
    cd "$out/$installPrefix"
    jq --arg path "${lib.getExe shellcheck}" '
      def setDefault:
        if (.properties // {}) | has("shellcheck.executablePath")
        then .properties."shellcheck.executablePath".default = $path
        else .
        end;
      .contributes.configuration |= (if type == "array" then map(setDefault) else setDefault end)
    ' package.json | sponge package.json
  '';

  meta = {
    description = "Integrates ShellCheck into VS Code, a linter for Shell scripts";
    downloadPage = "https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck";
    homepage = "https://github.com/vscode-shellcheck/vscode-shellcheck";
    license = lib.licenses.mit;
  };
}
