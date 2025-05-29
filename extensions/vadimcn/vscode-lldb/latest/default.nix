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

  # Hashes of releases (https://github.com/vadimcn/codelldb/releases)
  hash =
    {
      "1.11.0" = "sha256-BzLKRs1fbLN4XSltnxPsgUG7ZJSMz/yJ/jQDZ9OTVxY=";
      "1.11.1" = "sha256-b063cCuiDpaeSSWxY0sbKsZucY7BCxI5s+35soJRFFQ=";
      "1.11.2" = "sha256-wj0X7nAcMU+kwl2qQRKixF+kTbTlnpgU7BYwaibIIKQ=";
      "1.11.3" = "sha256-zqaJzRTYc2gsipnbn4t16u62C/gkIohenWJDTEvZRvU=";
      "1.11.4" = "sha256-+Pe7ij5ukF5pLgwvr+HOHjIv1TQDiPOEeJtkpIW9XWI=";
      "1.11.5" = "sha256-mp50QmYmqMjIUfGKAt8fWcov4Bn9ruya+SwXGT3T/zk=";
    }
    .${version};

  # If you want to add a new version and a hash to `cargoHash` or `npmDepsHash`:
  # - Open `nix-repl` (e.g., via the `nix repl` command).
  # - Build `f` with the version and the hash of the `src` of the new version.
  # - Use the `got:` hash.

  # nix-repl> f = rev: hash: pkgs.rustPlatform.buildRustPackage { cargoHash = ""; name = "dummy"; src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = rev; hash = hash; }; useFetchCargoVendor = true; }
  # nix-repl> :b f "1.11.4" "sha256-+Pe7ij5ukF5pLgwvr+HOHjIv1TQDiPOEeJtkpIW9XWI="
  cargoHash =
    {
      "1.11.0" = "sha256-cLmL+QnFh2HwS2FcKTmGYI1NsrGV7MLWf3UBhNzBo0g=";
      "1.11.1" = "sha256-HFu3u/DX+SOIwwgk7+2EbQZ1tp9yqaV1CxiCN1PgXwM=";
      "1.11.2" = "sha256-Bl7bD+ulRJkeTdzyS8T/eMBmFaeqgMFFg3OTwSfo/RY=";
      "1.11.3" = "sha256-Nh4YesgWa1JR8tLfrIRps9TBdsAfilXu6G2/kB08co8=";
      "1.11.4" = "sha256-Nh4YesgWa1JR8tLfrIRps9TBdsAfilXu6G2/kB08co8=";
      "1.11.5" = "sha256-nTQbgYDDDI+pnKpCAUWDtk5rujjlK+7ZLUgPp1C/foo=";
    }
    .${version};

  # nix-repl> f = rev: hash: pkgs.buildNpmPackage { npmDepsHash = ""; name = "dummy"; src = pkgs.fetchFromGitHub { owner = "vadimcn"; repo = "codelldb"; rev = rev; hash = hash; }; dontNpmBuild = true; }
  # nix-repl> :b f "1.11.4" "sha256-+Pe7ij5ukF5pLgwvr+HOHjIv1TQDiPOEeJtkpIW9XWI="
  npmDepsHash =
    {
      "1.11.0" = "sha256-JRLXPsru+4cJe/WInYSr57+Js7mohL1CMR9LLCXORDg=";
      "1.11.1" = "sha256-4CCvOh7XOUsdI/gzDfx0OwzE7rhdCYFO49wVv6Gn/J0=";
      "1.11.2" = "sha256-oqRV9oDYPJkSkvYJA0jCgDyfzy6AnYq/ftRPM3swDyE=";
      "1.11.3" = "sha256-Efeun7AFMAnoNXLbTGH7OWHaBHT2tO9CodfjKrIYw40=";
      "1.11.4" = "sha256-Efeun7AFMAnoNXLbTGH7OWHaBHT2tO9CodfjKrIYw40=";
      "1.11.5" = "sha256-mHSY4LqcQiaVs6qvusxjybdKyrMh9sQatBanpIo6xk4=";
    }
    .${version};

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
  ];

  patches = [ ./patches/cmake-build-extension-only.patch ];

  # Make devDependencies available to tools/prep-package.js
  preConfigure = ''
    cp -r ${nodeDeps}/lib/node_modules .
  '';

  postConfigure =
    ''
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
