# Each ${publisher}.${name} MUST provide a function { mktplcRef, vsix } -> Derivation
# Each Derivation MUST be produced via overridable buildVscodeMarketplaceExtension

# Write custom fixes in mkExtensionLocal

{ pkgs }:
let
  inherit (pkgs) lib;

  buildVscodeMarketplaceExtension = lib.customisation.makeOverridable pkgs.vscode-utils.buildVscodeMarketplaceExtension;
  buildVscodeExtension = lib.customisation.makeOverridable pkgs.vscode-utils.buildVscodeExtension;

  applyMkExtension = builtins.mapAttrs (
    publisher:
    builtins.mapAttrs (
      name: f:
      (
        { mktplcRef, vsix }@extensionConfig:
        buildVscodeMarketplaceExtension (extensionConfig // f extensionConfig)
      )
    )
  );

  mkExtensionLocal = applyMkExtension {
    # Write your fixes here

    # Each ${publisher}.${name} MUST provide a function { mktplcRef, vsix } -> Attrset
    # Each Attrset must be a valid argument of buildVscodeMarketplaceExtension (see above)

    # Use mkExtensionNixpkgs to override extensions from nixpkgs.
    #
    # Example:
    #
    # ```nix
    # foo.bar = { mktplcRef, vsix }@arg: (mkExtensionNixpkgs.foo.bar arg).override { postInstall = "..."; };
    # ```

    # Credit to https://github.com/nix-community/nix-vscode-extensions/issues/52#issue-2129112776
    vadimcn.vscode-lldb = _: {
      postInstall = lib.optionalString pkgs.stdenv.isLinux ''
        cd "$out/$installPrefix"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./adapter/codelldb
        patchelf --add-rpath "${lib.makeLibraryPath [ pkgs.zlib ]}" ./lldb/lib/liblldb.so
      '';
    };

    ms-dotnettools.vscode-dotnet-runtime = _: {
      postPatch = ''
        chmod +x "$PWD/dist/install scripts/dotnet-install.sh"
      '';
    };

    ms-vsliveshare.vsliveshare = _: {
      # Similar to https://github.com/NixOS/nixpkgs/blob/6f5808c6534d514751d6de0e20aae83f45d9f798/pkgs/applications/editors/vscode/extensions/ms-vsliveshare.vsliveshare/default.nix#L15-L18
      # Not sure it's necessary
      postPatch = ''
        substituteInPlace vendor.js \
          --replace-fail '"xsel"' '"${pkgs.xsel}/bin/xsel"'
      '';
    };
  };

  extensionsRemoved = (import ./removed.nix).${pkgs.system} or [ ];

  # We don't modify callPackage because extensions
  # may use its original version
  pkgs' = pkgs // {
    vscode-utils = pkgs.vscode-utils // {
      inherit buildVscodeMarketplaceExtension buildVscodeExtension;
    };
  };

  callPackage = pkgs.beam.beamLib.callPackageWith pkgs';

  # TODO find a cleaner way to get the store path of nixpkgs from given pkgs
  pathNixpkgs = lib.trivial.pipe pkgs.hello.inputDerivation._derivation_original_args [
    builtins.tail
    builtins.head
    builtins.dirOf
    builtins.dirOf
    builtins.dirOf
    builtins.dirOf
  ];

  extensionsNixpkgs =
    callPackage "${pathNixpkgs}/pkgs/applications/editors/vscode/extensions/default.nix"
      { config.allowAliases = false; };

  extensionsProblematic =
    # Some arguments of the function that produces a derivation
    # are provided in the `let .. in` expression before the call to that function

    # TODO make a PR to nixpkgs to simplify overriding for these extensions
    [
      "anweber.vscode-httpyac"
      "chenglou92.rescript-vscode"
      # Wait for https://github.com/NixOS/nixpkgs/pull/383013 to be merged
      "vadimcn.vscode-lldb"
      "rust-lang.rust-analyzer"
    ]
    ++
    # Have old fixes
    [
      # Doesn't build due to the patch
      # https://github.com/NixOS/nixpkgs/tree/a3cd526f08839bd963e7d106b7869694b0579a94/pkgs/applications/editors/vscode/extensions/hashicorp.terraform
      # TODO newer fix
      "hashicorp.terraform"
    ];

  pathSpecial = {
    ms-ceintl = "language-packs.nix";
    wakatime = "WakaTime.vscode-wakatime";
  };

  mkExtensionNixpkgs = builtins.mapAttrs (
    publisher:
    builtins.mapAttrs (
      name: extension:
      let
        extensionId = "${publisher}.${name}";
      in
      if builtins.elem extensionId extensionsRemoved then
        _: { vscodeExtPublisher = publisher; }
      else
        let
          subPath = pathSpecial.${publisher} or extensionId;

          path = "${pathNixpkgs}/pkgs/applications/editors/vscode/extensions/${subPath}";

          extension' =
            if builtins.pathExists path then
              let
                extension'' = callPackage path { };
              in
              if publisher == "ms-ceintl" then extension''.${name} else extension''
            else
              extension;
        in
        { mktplcRef, vsix }@extensionConfig:
        if builtins.elem extensionId extensionsProblematic then
          buildVscodeMarketplaceExtension extensionConfig
        else
          (extension'.override or (abort "${publisher}.${name}")) extensionConfig
    )
  ) extensionsNixpkgs;

  chooseMkExtension =
    self:
    { mktplcRef, vsix }@extensionConfig:
    let
      mkExtension = (
        (self.${mktplcRef.publisher} or { }).${mktplcRef.name} or (
          if builtins.elem "${mktplcRef.publisher}.${mktplcRef.name}" extensionsRemoved then
            _: { vscodeExtPublisher = mktplcRef.publisher; }
          else
            buildVscodeMarketplaceExtension
        )
      );
    in
    (mkExtension extensionConfig).overrideAttrs (prev: {
      passthru = prev.passthru // extensionConfig;
    });
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  mkExtensionNixpkgs
  mkExtensionLocal
  { __functor = chooseMkExtension; }
]
