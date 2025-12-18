{ pkgs }:
let
  inherit (pkgs) lib;

  # Compare two pre-release identifiers
  comparePreReleaseIdentifiers = id1: id2:
    let
      isNum1 = builtins.match "[0-9]+" id1 != null;
      isNum2 = builtins.match "[0-9]+" id2 != null;
    in
      if isNum1 && isNum2 then
        lib.compare (builtins.fromJSON id1) (builtins.fromJSON id2)
      else if !isNum1 && !isNum2 then
        lib.compare id1 id2
      else
        # Numeric identifiers always have lower precedence than non-numeric identifiers.
        if isNum1 then -1 else 1;

  # Compare two prerelease strings (e.g., "alpha.1" vs "alpha.beta")
  comparePrerelease = pre1: pre2:
    if pre1 == null && pre2 == null then 0
    else if pre1 == null then 1  # pre1 (no prerelease) > pre2 (prerelease)
    else if pre2 == null then -1 # pre1 (prerelease) < pre2 (no prerelease)
    else
      lib.compareLists comparePreReleaseIdentifiers (lib.splitString "." pre1) (lib.splitString "." pre2);

  # Compare two SemVer strings
  compareSemVer = v1: v2:
    let
      parse = v:
        let
          # This is based on the official SemVer regex [1], adopted for Nix Regex compatibility (no `?:`, no `\d`).
          #
          # [1]: https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
          m = builtins.match "^(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\\+([0-9a-zA-Z-]+(\\.[0-9a-zA-Z-]+)*))?$" v;
        in
          if m == null then builtins.throw "Invalid SemVer: ${v}"
          else {
            major = builtins.fromJSON (builtins.elemAt m 0);
            minor = builtins.fromJSON (builtins.elemAt m 1);
            patch = builtins.fromJSON (builtins.elemAt m 2);
            prerelease = builtins.elemAt m 4;
            # Build metadata is ignored for determining precedence.
          };

      s1 = parse v1;
      s2 = parse v2;

      cMajor = lib.compare s1.major s2.major;
      cMinor = lib.compare s1.minor s2.minor;
      cPatch = lib.compare s1.patch s2.patch;
    in
      if cMajor != 0 then cMajor
      else if cMinor != 0 then cMinor
      else if cPatch != 0 then cPatch
      else comparePrerelease s1.prerelease s2.prerelease;

  tests = {
    "test: semver equal" = {
      expr = compareSemVer "1.0.0" "1.0.0";
      expected = 0;
    };
    "test: semver greater major" = {
      expr = compareSemVer "2.0.0" "1.0.0";
      expected = 1;
    };
    "test: semver less major" = {
      expr = compareSemVer "1.0.0" "2.0.0";
      expected = -1;
    };
    "test: semver greater minor" = {
      expr = compareSemVer "1.2.0" "1.1.0";
      expected = 1;
    };
    "test: semver less minor" = {
      expr = compareSemVer "1.1.0" "1.2.0";
      expected = -1;
    };
    "test: semver greater patch" = {
      expr = compareSemVer "1.0.2" "1.0.1";
      expected = 1;
    };
    "test: semver less patch" = {
      expr = compareSemVer "1.0.1" "1.0.2";
      expected = -1;
    };
    "test: semver prerelease" = {
      expr = compareSemVer "1.0.0-alpha" "1.0.0";
      expected = -1;
    };
    "test: semver prerelease numeric" = {
      expr = compareSemVer "1.106.0-20251103" "1.106.0";
      expected = -1;
    };
    "test: semver prerelease non-numeric greater than numeric" = {
      expr = compareSemVer "1.106.0-20251103" "1.106.0-beta";
      expected = -1;
    };
    "test: semver prerelease numeric greater" = {
      expr = compareSemVer "1.107.0-20251103" "1.106.0";
      expected = 1;
    };
    "test: semver 1.0.0-alpha < 1.0.0-alpha.1" = {
      expr = compareSemVer "1.0.0-alpha" "1.0.0-alpha.1";
      expected = -1;
    };
    "test: semver 1.0.0-alpha.1 < 1.0.0-alpha.beta" = {
      expr = compareSemVer "1.0.0-alpha.1" "1.0.0-alpha.beta";
      expected = -1;
    };
    "test: semver 1.0.0-alpha.beta < 1.0.0-beta" = {
      expr = compareSemVer "1.0.0-alpha.beta" "1.0.0-beta";
      expected = -1;
    };
    "test: semver 1.0.0-beta < 1.0.0-beta.2" = {
      expr = compareSemVer "1.0.0-beta" "1.0.0-beta.2";
      expected = -1;
    };
    "test: semver 1.0.0-beta.2 < 1.0.0-beta.11" = {
      expr = compareSemVer "1.0.0-beta.2" "1.0.0-beta.11";
      expected = -1;
    };
    "test: semver 1.0.0-beta.11 < 1.0.0-rc.1" = {
      expr = compareSemVer "1.0.0-beta.11" "1.0.0-rc.1";
      expected = -1;
    };
    "test: semver 1.0.0-rc.1 < 1.0.0" = {
      expr = compareSemVer "1.0.0-rc.1" "1.0.0";
      expected = -1;
    };
    "test: semver build metadata ignored" = {
      expr = compareSemVer "1.0.0+001" "1.0.0+20130313144700";
      expected = 0;
    };
  };
in
{
  inherit compareSemVer tests;
}
