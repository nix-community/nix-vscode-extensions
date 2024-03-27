{ pkgs }: extensions:
let
  inherit (pkgs.lib.attrsets) hasAttrByPath recursiveUpdate getAttrFromPath setAttrByPath mapAttrsToList;
  modifyAttrByPath = path: f: attrs: if hasAttrByPath path attrs then recursiveUpdate attrs (setAttrByPath path (f (getAttrFromPath path extensions))) else attrs;
  overrideAttrsByPath = path: f: attrs: modifyAttrByPath path (x: x.overrideAttrs f) attrs;
  mkModifyAttrs = attrs: pkgs.lib.lists.flatten (mapAttrsToList (publisher: mapAttrsToList (name: f: overrideAttrsByPath [ publisher name ] f)) attrs);
  updateExtensions = attrs: pkgs.lib.trivial.pipe extensions (mkModifyAttrs attrs);
in
updateExtensions {
  # https://github.com/nix-community/nix-vscode-extensions/issues/31
  asf.apache-netbeans-java = _: { sourceRoot = "extension"; };
  ms-vscode.cmake-tools = _: { sourceRoot = "extension"; };
  ms-dotnettools.csdevkit = _: { sourceRoot = "extension"; };
}
