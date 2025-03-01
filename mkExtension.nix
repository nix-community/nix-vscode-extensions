# Each ${publisher}.${name} MUST provide a function { mktplcRef, vsix } -> Derivation
# Each Derivation MUST be produced via overridable buildVscodeMarketplaceExtension

# Write custom fixes in mkExtensionLocal

{ pkgs, nixpkgs }:
let
  inherit (pkgs) lib;

  mkExtension = lib.customisation.makeOverridable pkgs.vscode-utils.buildVscodeMarketplaceExtension;

  pkgs' = lib.attrsets.recursiveUpdate pkgs {
    vscode-utils.buildVscodeMarketplaceExtension = mkExtension;
  };

  mkExtensionLocal = applyMkExtension {
    # Write your fixes here

    # Each ${publisher}.${name} MUST provide a function { mktplcRef, vsix } -> Attrset
    # Each Attrset must be a valid argument of mkExtension (see above)

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

  applyMkExtension = builtins.mapAttrs (
    publisher:
    builtins.mapAttrs (
      name: f: ({ mktplcRef, vsix }@extensionConfig: mkExtension (extensionConfig // f extensionConfig))
    )
  );

  mkExtensionNixpkgs =
    # apply fixes from nixpkgs
    let
      # TODO PR to nixpkgs to allow overriding mktplcRef and vsix
      haveFixesNonOverridable = [
        "anweber.vscode-httpyac"
        "chenglou92.rescript-vscode"
        # Wait for https://github.com/NixOS/nixpkgs/pull/383013 to be merged
        "vadimcn.vscode-lldb"
        "rust-lang.rust-analyzer"
      ];

      # extensions with fixes
      # where mktplcRef and vsix are overridable
      haveFixesOverridable = [
        # from the directory https://github.com/NixOS/nixpkgs/tree/555702214240ef048370f6c2fe27674ec73da765/pkgs/applications/editors/vscode/extensions
        "asciidoctor.asciidoctor-vscode"
        "azdavis.millet"
        "b4dm4n.vscode-nixpkgs-fmt"
        "betterthantomorrow.calva"
        "charliermarsh.ruff"
        "chrischinchilla.vscode-pandoc"
        "contextmapper.context-mapper-vscode-extension"
        "eugleo.magic-racket"
        "foxundermoon.shell-format"
        "hashicorp.terraform"
        "jackmacwindows.craftos-pc"
        "jebbs.plantuml"
        "kamadorueda.alejandra"
        "ms-dotnettools.csdevkit"
        "ms-dotnettools.csharp"
        "ms-python.python"
        "ms-python.vscode-pylance"
        "ms-toolsai.jupyter"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.vscode-remote-extensionpack"
        "ms-vscode.cpptools"
        "ms-vsliveshare.vsliveshare"
        "myriad-dreamin.tinymist"
        "reditorsupport.r"
        "sourcery.sourcery"
        "sumneko.lua"
        "tekumara.typos-vscode"
        "timonwong.shellcheck"
        "visualjj.visualjj"
        "yzane.markdown-pdf"

        # from https://github.com/NixOS/nixpkgs/blob/555702214240ef048370f6c2fe27674ec73da765/pkgs/applications/editors/vscode/extensions/default.nix
        "continue.continue"
        "devsense.phptools-vscode"
        "kddejong.vscode-cfn-lint"
        "ms-dotnettools.vscodeintellicode-csharp"
        "uloco.theme-bluloco-light"
        "valentjn.vscode-ltex"
        "zxh404.vscode-proto3"
      ];

      extensionsNixpkgsPath = "${nixpkgs}/pkgs/applications/editors/vscode/extensions/default.nix";
      callPackage = pkgs.beam.beamLib.callPackageWith pkgs';
      extensionsNixpkgs = callPackage extensionsNixpkgsPath { };

      fixed = lib.trivial.pipe haveFixesOverridable [
        (builtins.map (
          fullName:
          let
            fullNameList = lib.strings.splitString "." fullName;
            publisher = lib.lists.head fullNameList;
            name = lib.lists.last fullNameList;
          in
          {
            inherit publisher name fullName;
          }
        ))
        (builtins.filter (
          {
            publisher,
            name,
            fullName,
          }:
          (extensionsNixpkgs.${publisher} or { }).${name} or { } != { }
        ))
        (builtins.map (
          {
            publisher,
            name,
            fullName,
          }:
          let
            path = "${nixpkgs}/pkgs/applications/editors/vscode/extensions/${fullName}";
            extension =
              if builtins.pathExists path then callPackage path { } else extensionsNixpkgs.${publisher}.${name};
          in
          {
            ${publisher}.${name} = { mktplcRef, vsix }@extensionConfig: extension.override extensionConfig;
          }
        ))
        (builtins.foldl' lib.attrsets.recursiveUpdate { })
      ];
    in
    fixed;

  chooseMkExtension =
    self:
    { mktplcRef, vsix }@extensionConfig:
    ((self.${mktplcRef.publisher} or { }).${mktplcRef.name} or mkExtension) extensionConfig;
in
builtins.foldl' lib.attrsets.recursiveUpdate { } [
  mkExtensionNixpkgs
  mkExtensionLocal
  { __functor = chooseMkExtension; }
]
