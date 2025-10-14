# Original implementation: https://github.com/NixOS/nixpkgs/pull/383013
# After merging should be in https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/editors/vscode/extensions/vadimcn.vscode-lldb
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
  # nix-repl> rev = "1.11.7"
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = ""; }
  # nix-repl> :b src
  #
  # Write here the hash that you `got:`.
  hash = "sha256-qbpl+/GsMjhs7xZdt8r3CM5gYOowBlu/yCd5RmU2eXE=";

  # Write here the hash from above.
  # nix-repl> src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = "v${rev}"; hash = "sha256-qbpl+/GsMjhs7xZdt8r3CM5gYOowBlu/yCd5RmU2eXE="; }

  # nix-repl> :b pkgs.rustPlatform.buildRustPackage { cargoHash = ""; name = "dummy"; inherit src; useFetchCargoVendor = true; }
  #
  # Write here the hash that you `got:`.
  cargoHash = "sha256-jAr/5wW9Vy2xfgHKeJGz/vuIRuouVAGH3XHFdQ34x4A=";

  # nix-repl> :b pkgs.buildNpmPackage { npmDepsHash = ""; name = "dummy"; inherit src; dontNpmBuild = true; }
  #
  # Write here the hash that you `got:`.
  npmDepsHash = "sha256-cS7Fr4mrq0QIPFtG5VjLEOOiC2QuVDW+Ispt2LmI258=";

  src = fetchFromGitHub {
    owner = "vadimcn";
    repo = "codelldb";
    rev = "v${version}";
    hash = hash;
  };

  lldb = llvmPackages_19.lldb;

  adapter = (
    callPackage ./adapter.nix {
      # The adapter is meant to be compiled with clang++,
      # based on the provided CMake toolchain files.
      # <https://github.com/vadimcn/codelldb/tree/master/cmake>
      rustPlatform = makeRustPlatform {
        stdenv = llvmPackages_19.libcxxStdenv;
        inherit cargo rustc;
      };
      stdenv = llvmPackages_19.libcxxStdenv;

      inherit
        pname
        src
        version
        cargoHash
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
    callPackage ./lldb-types.nix {
      inherit
        pname
        src
        version
        cargoHash
        nodeDeps
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
    cargo
    makeWrapper
    nodejs
    unzip
  ];

  patches = [ ./patches/cmake-build-extension-only.patch ];

  # Make devDependencies available to tools/prep-package.js
  preConfigure = ''
    cp -r ${nodeDeps}/lib/node_modules .
  '';

  postConfigure = ''
    cp -r ${nodeDeps}/lib/node_modules .

    # Copy pre-built package.json and generated types from codelldb-types
    cp ${codelldb-types}/package.json .
    mkdir -p generated
    cp -r ${codelldb-types}/generated/* generated/

    # Touch the files to ensure they're newer than dependencies
    touch package.json generated/codelldb.ts
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
    inherit lldb adapter codelldb-types;
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
