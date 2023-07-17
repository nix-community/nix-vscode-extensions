{ pkgs, platforms }:
let
  # merge parts of an extension config
  mergeParts =
    common@{ name, version, publisher, engineVersion }:
    platformSpecific@{ url, sha256, platform }:
    common // platformSpecific;
  # generate a config for each platform-specific part
  genConfigs = args:
    let
      common = builtins.elemAt args 0;
      platformSpecific = builtins.elemAt args 1;
    in
    map (mergeParts common) platformSpecific;
  # supported sites platforms
  genConfigsList = x: pkgs.lib.lists.flatten (map genConfigs x);
in
genConfigsList
  [
  ] ++ (import ./codelldb.nix) {
  inherit pkgs;
  inherit platforms;
}
