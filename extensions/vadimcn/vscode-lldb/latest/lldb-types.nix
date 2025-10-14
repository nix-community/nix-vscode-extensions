{
  rustPlatform,
  nodejs,
  nodeDeps,
  stdenv,

  pname,
  src,
  version,

  cargoHash,
}:
# codelldb-types.nix
rustPlatform.buildRustPackage {
  pname = "${pname}-types";
  inherit version src cargoHash;

  nativeBuildInputs = [ nodejs ];

  buildAndTestSubdir = "src/codelldb-types";
  cargoBuildFlags = [ "--bin=codelldb-types" ];

  # Don't run normal install - we need custom workflow
  dontCargoInstall = true;

  postBuild = ''
    # Go back to the workspace root
    cd $NIX_BUILD_TOP/source

    # The binary is in target/<rust-target>/release/codelldb-types
    RUST_TARGET="${stdenv.hostPlatform.rust.rustcTarget}"
    CODELLDB_TYPES_BIN="./target/$RUST_TARGET/release/codelldb-types"

    echo "Looking for binary at: $CODELLDB_TYPES_BIN"
    ls -la $CODELLDB_TYPES_BIN

    # Generate schema by running codelldb-types
    $CODELLDB_TYPES_BIN codelldb.schema.json

    # Copy node_modules for prep-package.js
    cp -r ${nodeDeps}/lib/node_modules .

    # Process package.json (substitute @VERSION@ with actual version)
    sed "s/@VERSION@/${version}/g" package.json > package.pre.json
    node tools/prep-package.js package.pre.json package.json

    # Generate TypeScript types
    mkdir -p generated
    npm run json2ts -- codelldb.schema.json generated/codelldb.ts

  '';

  installPhase = ''
    mkdir -p $out
    cp package.json $out/
    cp -r generated $out/
  '';
}
