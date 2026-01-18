# The result of this function is an attrset where
# each `${publisher}.${name}` maps to a function `{ mktplcRef, vsix } -> (Derivation | { publisher })`
# Each Derivation is produced via the overridable `buildVscodeMarketplaceExtension` function (defined below).
# The `{ publisher }` attrset is provided for compatibility with `groupBy`.

# Custom fixes are loaded via `mkExtensionLocal`.

{
  pkgs,
  pkgsWithFixes,
  system,
}:
let
  inherit (pkgs) lib;

  makeOverridable =
    f: args:
    lib.customisation.makeOverridable f (
      if builtins.isFunction args then
        let
          x = args (f x);
        in
        x
      else
        args
    );

  buildVscodeMarketplaceExtension = makeOverridable pkgs.vscode-utils.buildVscodeMarketplaceExtension;

  buildVscodeExtension = makeOverridable pkgs.vscode-utils.buildVscodeExtension;

  # We don't modify callPackage because extensions
  # may use its original version
  pkgs' = pkgs // {
    vscode-utils = pkgs.vscode-utils // {
      inherit buildVscodeMarketplaceExtension buildVscodeExtension;
    };
  };

  applyMkExtension = builtins.mapAttrs (
    publisher: builtins.mapAttrs (name: f: { mktplcRef, vsix }@extensionConfig: f extensionConfig)
  );

  mkExtensionLocal = applyMkExtension (import ../extensions { pkgs = pkgs'; });

  extensionsRemoved = (import ./removed.nix).${system} or [ ];

  # Similar to callPackageWith/callPackage, but without makeOverridable.
  #
  # In `nixpkgs`, `pkgs.lib.callPackageWith` uses `pkgs.lib.makeOverridable`.
  # We need `callPackageWith` to use a custom `makeOverridable`
  # to handle the case when in an expression for an extension in `nixpkgs`,
  # `pkgs.vscode-utils.buildVscodeMarketplaceExtension`
  # takes a function, not an attrset.
  #
  # Adapted from
  # https://github.com/NixOS/nixpkgs/blob/b044ad6e5e92e70d7a7723864b0ab7a6c25bafda/pkgs/development/beam-modules/lib.nix#L9
  callPackageWith =
    autoArgs: fn: args:
    let
      f = if lib.isFunction fn then fn else import fn;
      auto = builtins.intersectAttrs (lib.functionArgs f) autoArgs;
    in
    f (auto // args);

  callPackage = callPackageWith pkgs';

  # TODO find a cleaner way to get the store path of nixpkgs from given pkgs
  pathNixpkgs =
    if pkgsWithFixes ? outPath then
      pkgsWithFixes.outPath
    else
      lib.trivial.pipe pkgsWithFixes.hello.inputDerivation._derivation_original_args [
        builtins.tail
        builtins.head
        builtins.dirOf
        builtins.dirOf
        builtins.dirOf
        builtins.dirOf
      ];

  extensionsNixpkgs = callPackage (
    pathNixpkgs + "/pkgs/applications/editors/vscode/extensions/default.nix"
  ) { config.allowAliases = false; };

  extensionsProblematic = [
    # Problem:
    # Some arguments of the function that produces a derivation
    # are provided in the `let .. in` expression before the call to that function

    # TODO make a PR to nixpkgs to simplify overriding for these extensions
    "anweber.vscode-httpyac"
    "chenglou92.rescript-vscode"
    # Wait for https://github.com/NixOS/nixpkgs/pull/383013 to be merged
    "vadimcn.vscode-lldb"
    "rust-lang.rust-analyzer"

    # In Nixpkgs, these packages are constructed
    # using the `buildVscodeExtension` function.
    #
    # Their expressions don't provide any meaningful fixes.
    #
    # Find all such extensions:
    # https://github.com/search?q=repo%3ANixOS%2Fnixpkgs%20buildVscodeExtension&type=code
    "eamodio.gitlens"
    "google.gemini-cli-vscode-ide-companion"
    "kilocode.kilo-code"
    "ms-vscode.js-debug-companion"
    "ms-vscode.vscode-js-profile-table"
    "prettier.prettier-vscode"
    "rooveterinaryinc.roo-cline"
    "vscode-icons-team.vscode-icons"
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

          path = pathNixpkgs + "/pkgs/applications/editors/vscode/extensions/${subPath}";

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
          buildVscodeMarketplaceExtension (
            extensionConfig // (if extension' ? meta then { meta = extension'.meta; } else { })
          )
        else
          (extension'.override
            or (abort "The extension '${publisher}.${name}' doesn't have an 'override' attribute.")
          )
            extensionConfig
    )
  ) extensionsNixpkgs;

  chooseMkExtension =
    self:
    {
      mktplcRef,
      vsix,
      engineVersion,
      platform,
      isRelease,
    }@extensionConfig:
    let
      mkExtension =
        (self.${mktplcRef.publisher} or { }).${mktplcRef.name} or (
          if builtins.elem "${mktplcRef.publisher}.${mktplcRef.name}" extensionsRemoved then
            # In `./nix/overlay.nix`, there is a check whether the result is a derivation.
            _: { vscodeExtPublisher = mktplcRef.publisher; }
          else
            buildVscodeMarketplaceExtension
        );

      extension = (mkExtension { inherit mktplcRef vsix; }) // {
        passthru = extensionConfig;
      };
    in
    extension;
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  mkExtensionNixpkgs
  mkExtensionLocal
  { __functor = chooseMkExtension; }
]
