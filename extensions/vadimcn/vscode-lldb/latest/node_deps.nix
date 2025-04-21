{
  buildNpmPackage,

  libsecret,
  python3,
  pkg-config,

  pname,
  src,
  version,

  npmDepsHash,
}:
buildNpmPackage {
  pname = "${pname}-node-deps";
  inherit version src;

  inherit npmDepsHash;

  nativeBuildInputs = [
    python3
    pkg-config
  ];

  buildInputs = [ libsecret ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib

    runHook postInstall
  '';
}
