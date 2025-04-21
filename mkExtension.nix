# Each `${publisher}.${name}` MUST provide a function `{ mktplcRef, vsix } -> Derivation`
# Each Derivation MUST be produced via overridable `buildVscodeMarketplaceExtension` (see below)

# Custom fixes are loaded via `mkExtensionLocal`

{ pkgs, pkgsWithFixes }:
let
  inherit (pkgs) lib;

  buildVscodeMarketplaceExtension = lib.customisation.makeOverridable pkgs.vscode-utils.buildVscodeMarketplaceExtension;
  buildVscodeExtension = lib.customisation.makeOverridable pkgs.vscode-utils.buildVscodeExtension;

  # We don't modify callPackage because extensions
  # may use its original version
  pkgs' = pkgs // {
    vscode-utils = pkgs.vscode-utils // {
      inherit buildVscodeMarketplaceExtension buildVscodeExtension;
    };
  };

  applyMkExtension = builtins.mapAttrs (
    publisher:
    builtins.mapAttrs (
      name: f:
      { mktplcRef, vsix }@extensionConfig:
      f (
        extensionConfig
        // {
          pkgs = pkgs';
          inherit lib;
          inherit (pkgs'.vscode-utils) buildVscodeMarketplaceExtension;
        }
      )
    )
  );

  mkExtensionLocal = applyMkExtension (import ./extensions);

  extensionsRemoved = (import ./removed.nix).${pkgs.system} or [ ];

  callPackage = pkgs.beam.beamLib.callPackageWith pkgs';

  # TODO find a cleaner way to get the store path of nixpkgs from given pkgs
  pathNixpkgs = lib.trivial.pipe pkgsWithFixes.hello.inputDerivation._derivation_original_args [
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
    {
      mktplcRef,
      vsix,
      engineVersion,
    }@extensionConfig:
    let
      mkExtension = (
        (self.${mktplcRef.publisher} or { }).${mktplcRef.name} or (
          if builtins.elem "${mktplcRef.publisher}.${mktplcRef.name}" extensionsRemoved then
            # In `flake.nix`, there is a check whether the result is a derivation.
            _: { vscodeExtPublisher = mktplcRef.publisher; }
          else
            buildVscodeMarketplaceExtension
        )
      );
    in
    (mkExtension { inherit mktplcRef vsix; }).overrideAttrs (prev: {
      passthru = prev.passthru // extensionConfig;
    });
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  mkExtensionNixpkgs
  mkExtensionLocal
  { __functor = chooseMkExtension; }
]
