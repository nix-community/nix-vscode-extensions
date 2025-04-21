{
  lib,
  jq,
  rust-analyzer,
  moreutils,
  setDefaultServerPath ? true,

  mktplcRef,
  vsix,
  buildVscodeMarketplaceExtension,
  ...
}:
buildVscodeMarketplaceExtension {
  inherit mktplcRef vsix;

  nativeBuildInputs = lib.optionals setDefaultServerPath [
    jq
    moreutils
  ];

  preInstall = lib.optionalString setDefaultServerPath ''
    jq '(.contributes.configuration[] | select(.title == "server") | .properties."rust-analyzer.server.path".default) = $s' \
      --arg s "${rust-analyzer}/bin/rust-analyzer" \
      package.json | sponge package.json
  '';

  meta = {
    description = "Alternative rust language server to the RLS";
    homepage = "https://github.com/rust-lang/rust-analyzer";
    license = [
      lib.licenses.mit
      lib.licenses.asl20
    ];
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
}
