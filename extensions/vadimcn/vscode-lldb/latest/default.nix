# Based on https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vscode/extensions/vadimcn.vscode-lldb/default.nix
{
  callPackage,
  cargo,
  cmake,
  fetchFromGitHub,
  lib,
  llvmPackages_19,
  makeRustPlatform,
  makeWrapper,
  nodejs,
  python3,
  rustc,
  stdenv,
  unzip,

  mktplcRef,

  ...
}:
assert lib.versionAtLeast python3.version "3.5";
let
  extFullName = "${mktplcRef.publisher}.${mktplcRef.name}";

  # If you want to add a new version and hashes, run `nix repl` and load the `nixpkgs` flake.

  # nix-repl> :lf nixpkgs
  # nix-repl> pkgs = legacyPackages.${builtins.currentSystem}

  # Get the hash of a source code in a release (https://github.com/vadimcn/codelldb/releases)
  #
  # nix-repl> rev = "<version>"
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = ""; }
  # nix-repl> :b src
  #
  # Write here the hash that you `got:`.
  #
  # Write the hash from above here.
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = "<hash>" ; }
  #
  # nix-repl> :b pkgs.rustPlatform.buildRustPackage { cargoHash = ""; name = "dummy"; inherit src; useFetchCargoVendor = true; }
  #
  # Write here the hash that you `got:`.
  #
  # nix-repl> :b pkgs.buildNpmPackage { npmDepsHash = ""; name = "dummy"; inherit src; dontNpmBuild = true; }
  #
  # Write here the hash that you `got:`.
  supportedVersions = {
    "1.12.3" = {
      hash = "sha256-McyL5M6BMomk1nYWmwQKYhejLTYfgTJy8nVPsVH1iOA=";
      cargoHash = "sha256-fuUTLdavMiYfpyxctXes2GJCsNZd5g1d4B/v+W/Rnu8=";
      npmDepsHash = "sha256-TCeIBrlsNuphW2gVsX97+Wu1lOG5gDwS7559YA1d10M=";
    };
    "1.12.2" = {
      hash = "sha256-7//+y02rfDloeNADpoM8tist7fPstBZ2Eqt4dM5dCaE=";
      cargoHash = "sha256-fuUTLdavMiYfpyxctXes2GJCsNZd5g1d4B/v+W/Rnu8=";
      npmDepsHash = "sha256-TCeIBrlsNuphW2gVsX97+Wu1lOG5gDwS7559YA1d10M=";
    };
    "1.11.0" = {
      hash = "sha256-BzLKRs1fbLN4XSltnxPsgUG7ZJSMz/yJ/jQDZ9OTVxY=";
      cargoHash = "sha256-cLmL+QnFh2HwS2FcKTmGYI1NsrGV7MLWf3UBhNzBo0g=";
      npmDepsHash = "sha256-JRLXPsru+4cJe/WInYSr57+Js7mohL1CMR9LLCXORDg=";
    };
  };
in
assert lib.asserts.assertMsg (supportedVersions ? ${mktplcRef.version}) ''
  The version `${mktplcRef.version}` of `${extFullName}` is not supported.

  Only the versions `${lib.concatStringsSep "`, `" (builtins.attrNames supportedVersions)}` are supported.

  Try `extensions.${stdenv.hostPlatform.system}.vscode-marketplace-universal.${extFullName}`
  or  `extensions.${stdenv.hostPlatform.system}.open-vsx-universal.${extFullName}`.
'';
let
  inherit (mktplcRef) publisher version;
  pname = mktplcRef.name;

  vscodeExtUniqueId = "${publisher}.${pname}";
  vscodeExtPublisher = publisher;
  vscodeExtName = pname;

  inherit (supportedVersions.${version}) hash cargoHash npmDepsHash;

  src = fetchFromGitHub {
    owner = "vadimcn";
    repo = "codelldb";
    rev = "v${version}";
    hash = hash;
  };

  lldb = llvmPackages_19.lldb;
  stdenv = llvmPackages_19.libcxxStdenv;

  adapter = (
    callPackage ./adapter.nix {
      # The adapter is meant to be compiled with clang++,
      # based on the provided CMake toolchain files.
      # <https://github.com/vadimcn/codelldb/tree/master/cmake>
      rustPlatform = makeRustPlatform {
        inherit stdenv cargo rustc;
      };

      inherit
        pname
        src
        version
        cargoHash
        stdenv
        codelldb-launch
        ;
    }
  );

  nodeDeps = (
    callPackage ./node_deps.nix {
      inherit
        pname
        src
        version
        npmDepsHash
        ;
    }
  );

  codelldb-types = (
    callPackage ./codelldb-types.nix {
      rustPlatform = makeRustPlatform {
        inherit stdenv cargo rustc;
      };

      inherit
        pname
        src
        version
        cargoHash
        ;
    }
  );

  codelldb-launch = (
    callPackage ./codelldb-launch.nix {
      rustPlatform = makeRustPlatform {
        inherit stdenv cargo rustc;
      };

      inherit
        pname
        src
        version
        cargoHash
        ;
    }
  );
in
lib.customisation.makeOverridable stdenv.mkDerivation {
  pname = "vscode-extension-${publisher}-${pname}";
  inherit
    src
    version
    vscodeExtUniqueId
    vscodeExtPublisher
    vscodeExtName
    ;

  installPrefix = "share/vscode/extensions/${vscodeExtUniqueId}";

  nativeBuildInputs = [
    cmake
    makeWrapper
    nodejs
    unzip
    codelldb-types
    codelldb-launch
  ];

  patches = [ ./patches/cmake-build-extension-only.patch ];

  # Make devDependencies available to tools/prep-package.js
  preConfigure = ''
    cp -r ${nodeDeps}/lib/node_modules .
  '';

  postConfigure = ''
    cp -r ${nodeDeps}/lib/node_modules .
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    export HOME="$TMPDIR/home"
    mkdir $HOME
  '';

  cmakeFlags = [
    # Do not append timestamp to version.
    "-DVERSION_SUFFIX="
  ];
  makeFlags = [ "vsix_bootstrap" ];

  preBuild = lib.optionalString stdenv.hostPlatform.isDarwin ''
    export HOME=$TMPDIR
  '';

  installPhase = ''
    ext=$out/$installPrefix
    runHook preInstall

    unzip ./codelldb-bootstrap.vsix 'extension/*' -d ./vsix-extracted

    mkdir -p $ext/adapter
    mv -t $ext vsix-extracted/extension/*
    cp -t $ext/ -r ${adapter}/share/*
    wrapProgram $ext/adapter/codelldb \
      --prefix LD_LIBRARY_PATH : "$ext/lldb/lib" \
      --set-default LLDB_DEBUGSERVER_PATH "${adapter.lldbServer}"

    # Used by VSCode
    mkdir -p $ext/bin
    cp ${codelldb-launch}/bin/codelldb-launch $ext/bin/codelldb-launch

    # Mark that all components are installed.
    touch $ext/platform.ok

    runHook postInstall
  '';

  # `adapter` will find python binary and libraries at runtime.
  postFixup = ''
    wrapProgram $out/$installPrefix/adapter/codelldb \
      --prefix PATH : "${python3}/bin" \
      --prefix LD_LIBRARY_PATH : "${python3}/lib"
  '';

  passthru = {
    inherit lldb;
    adapter = adapter.override { standalone = true; };
    updateScript = ./update.sh;
  };

  meta = {
    description = "Native debugger extension for VSCode based on LLDB";
    homepage = "https://github.com/vadimcn/vscode-lldb";
    license = [ lib.licenses.mit ];
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
}
