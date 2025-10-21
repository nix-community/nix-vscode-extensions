{
  lib,
  buildNpmPackage,

  stdenv,
  libsecret,
  python3,
  pkg-config,
  clang_20,

  pname,
  src,
  version,
  npmDepsHash,
}:
buildNpmPackage {
  pname = "${pname}-node-deps";
  inherit version src;

  inherit npmDepsHash;

  nativeBuildInputs =
    [
      python3
      pkg-config
    ]
    ++ lib.optionals stdenv.isDarwin [clang_20];

  buildInputs = [libsecret];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib

    runHook postInstall
  '';
}
