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
  supportedVersion = "1.12.1";
  extFullName = "${mktplcRef.publisher}.${mktplcRef.name}";
in
assert lib.asserts.assertMsg (mktplcRef.version == supportedVersion) ''
  The version `${mktplcRef.version}` of `${extFullName}` is not supported.
   
  Only the version `${supportedVersion}` is supported.

  Try `extensions.${stdenv.hostPlatform.system}.vscode-marketplace-universal.${extFullName}`
  or  `extensions.${stdenv.hostPlatform.system}.open-vsx-universal.${extFullName}`.
'';
let
  inherit (mktplcRef) publisher version;
  pname = mktplcRef.name;

  vscodeExtUniqueId = "${publisher}.${pname}";
  vscodeExtPublisher = publisher;
  vscodeExtName = pname;

  # If you want to add a new version and a hash, run `nix repl` and load the `nixpkgs` flake.

  # nix-repl> :lf nixpkgs
  # nix-repl> pkgs = legacyPackages.${builtins.currentSystem}

  # Get the hash of a source code in a release (https://github.com/vadimcn/codelldb/releases)
  #
  # nix-repl> rev = "1.12.1"
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = ""; }
  # nix-repl> :b src
  #
  # Write here the hash that you `got:`.
  hash = "sha256-B8iCy4NXG7IzJVncbYm5VoAMfhMfxGF+HW7M5sVn5b0=";

  # Write here the hash from above.
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = "sha256-B8iCy4NXG7IzJVncbYm5VoAMfhMfxGF+HW7M5sVn5b0="; }

  # nix-repl> :b pkgs.rustPlatform.buildRustPackage { cargoHash = ""; name = "dummy"; inherit src; useFetchCargoVendor = true; }
  #
  # Write here the hash that you `got:`.
  cargoHash = "sha256-fuUTLdavMiYfpyxctXes2GJCsNZd5g1d4B/v+W/Rnu8=";

  # nix-repl> :b pkgs.buildNpmPackage { npmDepsHash = ""; name = "dummy"; inherit src; dontNpmBuild = true; }
  #
  # Write here the hash that you `got:`.
  npmDepsHash = "sha256-TCeIBrlsNuphW2gVsX97+Wu1lOG5gDwS7559YA1d10M=";

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
    inherit lldb adapter;
    updateScript = ./update.sh;
  };

  meta = {
    description = "Native debugger extension for VSCode based on LLDB";
    homepage = "https://github.com/vadimcn/vscode-lldb";
    license = [ lib.licenses.mit ];
    maintainers = [ lib.maintainers.r4v3n6101 ];
    platforms = lib.platforms.all;
  };
}
