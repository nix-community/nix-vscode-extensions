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

  postPatch = ''
    # In 1.12.3, upstream bumped the `@vscode/test-cli` and `@vscode/test-electron`
    # devDependencies in `package.json` without updating `package-lock.json`,
    # which makes `npm ci` try to fetch missing packuments offline
    # and fail with `ENOTCACHED`.
    # Align `package.json` with `package-lock.json`.
    substituteInPlace package.json \
      --replace-warn '"@vscode/test-cli": "^0.0.15"' '"@vscode/test-cli": "^0.0.11"' \
      --replace-warn '"@vscode/test-electron": "^3.1.0"' '"@vscode/test-electron": "^2.5.2"'
  '';

  nativeBuildInputs = [
    python3
    pkg-config
  ]
  ++ lib.optionals stdenv.isDarwin [ clang_20 ];

  buildInputs = [ libsecret ];

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp -r node_modules $out/lib

    runHook postInstall
  '';
}
