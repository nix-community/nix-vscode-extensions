final: prev:
let
  vscode-marketplace = "vscode-marketplace";

  open-vsx = "open-vsx";

  platformUniversal = "universal";

  systemPlatform = import ./systemPlatform.nix;

  numberToPlatform =
    number:
    let
      numberStr = builtins.toString number;
    in
    {
      "0" = platformUniversal;
      "1" = systemPlatform.x86_64-linux;
      "2" = systemPlatform.aarch64-linux;
      "3" = systemPlatform.x86_64-darwin;
      "4" = systemPlatform.aarch64-darwin;
    }
    .${builtins.toString number} or (builtins.throw "Platform not recognized: ${numberStr}");

  numberToIsRelease =
    number:
    let
      numberStr = builtins.toString number;
    in
    {
      "0" = false;
      "1" = true;
    }
    .${builtins.toString number}
    or (builtins.throw "Value for `isRelease` not recognized: ${numberStr}");

  pkgs = prev;
  inherit (pkgs) lib;
  system = final.stdenv.hostPlatform.system;
  platformCurrent = systemPlatform.${system};
  inherit (import ./semver.nix { inherit pkgs; }) compareSemVer;

  isCompatibleVersion =
    vscodeVersion: engineVersion:
    if lib.strings.hasPrefix "^" engineVersion then
      compareSemVer vscodeVersion (lib.strings.removePrefix "^" engineVersion) >= 0
    else
      compareSemVer vscodeVersion engineVersion == 0;
  checkVSCodeVersion =
    { doCheckVSCodeVersion, vscodeVersion }:
    (x: if doCheckVSCodeVersion then isCompatibleVersion vscodeVersion x.engineVersion else true);
  loadGenerated =
    {
      onlyRelease ? false,
      onlyUniversal ? false,
      doCheckVSCodeVersion ? false,
      vscodeVersion ? "*",
      site,
      pkgsWithFixes ? pkgs,
    }:
    let
      filterCheck =
        x:
        (
          x.platform == platformUniversal || (if !onlyUniversal then x.platform == platformCurrent else false)
        )
        && (if onlyRelease then x.isRelease else true)
        && (checkVSCodeVersion { inherit doCheckVSCodeVersion vscodeVersion; } x);
    in
    lib.pipe site [
      (x: ../data/cache/${site}${"-latest"}.json)
      builtins.readFile
      builtins.fromJSON
      (map (
        {
          p,
          n,
          r,
          P,
          v,
          e,
          h,
          ...
        }:
        {
          publisher = p;
          name = n;
          isRelease = numberToIsRelease r;
          platform = numberToPlatform P;
          version = v;
          engineVersion = e;
          hash = h;
        }
      ))
      (builtins.filter filterCheck)
      (map (
        extension@{
          name,
          publisher,
          version,
          platform,
          ...
        }:
        extension
        // {
          url =
            if site == vscode-marketplace then
              let
                platformSuffix = if platform == platformUniversal then "" else "targetPlatform=${platform}";
              in
              "https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${name}/${version}/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?${platformSuffix}"
            else
              let
                platformSuffix = if platform == platformUniversal then "" else "@${platform}";
                platformInfix = if platform == platformUniversal then "" else "/${platform}";
              in
              "https://open-vsx.org/api/${publisher}/${name}${platformInfix}/${version}/file/${publisher}.${name}-${version}${platformSuffix}.vsix";
        }
      ))
      (
        x:
        x
        ++ builtins.filter filterCheck (
          pkgs.lib.attrsets.mapAttrsToList
            (name: value: {
              url = value.src.url;
              hash = value.src.outputHash;
              inherit (value)
                publisher
                name
                version
                platform
                engineVersion
                ;
            })
            (
              # append extra extensions fetched from elsewhere to overwrite site extensions
              import ../data/extra-extensions/generated.nix {
                inherit (pkgs)
                  fetchgit
                  fetchurl
                  fetchFromGitHub
                  dockerTools
                  ;
              }
            )
        )
      )
      # lowercase all names and publishers
      (map (
        extension@{ name, publisher, ... }:
        extension
        // {
          name = lib.toLower name;
          publisher = lib.toLower publisher;
        }
      ))
      (
        let
          # keep outside of map to improve performance
          # TODO pass user's nixpkgs
          mkExtension = import ./mkExtension.nix { inherit pkgs pkgsWithFixes system; };
        in
        map (
          {
            name,
            publisher,
            version,
            hash,
            url,
            platform,
            engineVersion,
            isRelease,
            ...
          }:
          let
            extensionConfig = {
              mktplcRef = {
                inherit
                  name
                  publisher
                  version
                  hash
                  ;
              };

              # We use not only VS Code Markeplace but also Open VSX
              # so we need to provide the URL for the extension
              vsix = prev.fetchurl {
                inherit url hash;
                name =
                  let
                    dummy_ext = pkgs.vscode-utils.buildVscodeExtension {
                      pname = "";
                      version = "";
                      src = "";
                      vscodeExtUniqueId = "";
                      vscodeExtPublisher = "";
                      vscodeExtName = "";
                    };
                    dummy_deps = builtins.map (x: x.name) dummy_ext.nativeBuildInputs;
                    is_vsix = builtins.elem "unpack-vsix-setup-hook" dummy_deps;
                    file_extension = if is_vsix then "vsix" else "zip";
                  in
                  "${name}-${version}.${file_extension}";
              };

              inherit engineVersion platform isRelease;
            };
          in
          {
            inherit publisher name;
            value = mkExtension extensionConfig;
          }
        )
      )
      # group by publisher
      (builtins.groupBy ({ publisher, ... }: publisher))
      (builtins.mapAttrs (
        _:
        builtins.foldl' (
          acc:
          { name, value, ... }:
          acc
          // (
            let
              valueValidated =
                if !(lib.attrsets.isDerivation value) then
                  builtins.throw ''
                    The extension '${value.vscodeExtPublisher}.${name}' has been removed on ${pkgs.system}.
                    See '${./removed.nix}' for details.
                  ''
                else
                  value;
              # We have no reliable way to find the semantically latest version
              # of an extension.

              # Therefore, for an extension, we prioritize its versions
              # and choose one with the highest priority.

              # Here are the priorities (1 - highest) and properties:
              # 1. pre-release platform-specific
              # 2. pre-release universal
              # 3. release platform-specific
              # 4. release universal

              # When there are no pre-release platform-specific versions,
              # we choose a pre-release universal version etc.

              # At this point, we process a list of objects (cache).

              # There is at most one universal and at most one platform-specific version
              # among any of pre-release and release versions.

              # When we need the latest version,
              # we keep an existing version in the accumulator attrset
              # except for the case when a platform-specific version
              # with the same `isRelease` is available.

              valueSelected =
                if acc ? ${name} then
                  if acc.${name}.passthru.isRelease == valueValidated.passthru.isRelease then
                    valueValidated
                  else
                    acc.${name}
                else
                  valueValidated;
            in
            {
              ${name} = valueSelected;
            }
          )
        ) { }
      ))
    ];
  mkSet =
    attrs@{
      doCheckVSCodeVersion ? false,
      vscodeVersion ? "*",
      pkgsWithFixes ? pkgs,
    }:
    let
      loadGenerated' = attrs': loadGenerated (attrs // attrs');
    in
    {
      # See the documentation for `valueSelected` above.

      # ---

      # Below are priorities and corresponding combinations
      # of properties that can appear in an attrset.
      # For each extension, the attrset stores
      # a version with the the highest priority.

      # ---

      # These attrsets contain pre-release and release
      # universal and platform-specific versions.

      # Priorities and properties:
      # 1. pre-release platform-specific
      # 2. pre-release universal
      # 3. release platform-specific
      # 4. release universal
      vscode-marketplace = loadGenerated' { site = vscode-marketplace; };
      open-vsx = loadGenerated' { site = open-vsx; };

      # These attrsets contain only release
      # universal and platform-specific versions.

      # Priorities and properties:
      # 1. release platform-specific
      # 2. release universal
      vscode-marketplace-release = loadGenerated' {
        site = vscode-marketplace;
        onlyRelease = true;
      };
      open-vsx-release = loadGenerated' {
        site = open-vsx;
        onlyRelease = true;
      };

      # These attrsets contain only pre-release and release
      # universal versions.

      # Priorities and properties:
      # 1. pre-release universal
      # 2. release universal
      vscode-marketplace-universal = loadGenerated' {
        site = vscode-marketplace;
        onlyUniversal = true;
      };
      open-vsx-universal = loadGenerated' {
        site = open-vsx;
        onlyUniversal = true;
      };

      # These attrsets contain only release universal versions.

      # Priorities and properties:
      # 1. release universal
      vscode-marketplace-release-universal = loadGenerated' {
        site = vscode-marketplace;
        onlyRelease = true;
        onlyUniversal = true;
      };
      open-vsx-release-universal = loadGenerated' {
        site = open-vsx;
        onlyRelease = true;
        onlyUniversal = true;
      };
    };

  nix-vscode-extensions =
    (mkSet { })
    // (
      let
        mkFun = closure@{ ... }: args: (mkSet (args // closure)) // { __argsCombined = args // closure; };
        forVSCodeVersion =
          vscodeVersion:
          mkFun {
            doCheckVSCodeVersion = true;
            inherit vscodeVersion;
          };
        usingFixesFrom = pkgsWithFixes: mkFun { inherit pkgsWithFixes; };
      in
      {
        forVSCodeVersion =
          vscodeVersion:
          let
            attrPrev = forVSCodeVersion vscodeVersion { };
          in
          attrPrev
          // {
            usingFixesFrom = pkgsWithFixes: usingFixesFrom pkgsWithFixes attrPrev.__argsCombined;
          };

        usingFixesFrom =
          pkgsWithFixes:
          let
            attrPrev = usingFixesFrom pkgsWithFixes { };
          in
          attrPrev
          // {
            forVSCodeVersion = vscodeVersion: forVSCodeVersion vscodeVersion attrPrev.__argsCombined;
          };
      }
    );
in
nix-vscode-extensions // { inherit nix-vscode-extensions; }
