{
  handleGzippedZip =
    {
      vscode-utils,

      mktplcRef,
      vsix,

      ...
    }:
    vscode-utils.buildVscodeMarketplaceExtension {
      inherit mktplcRef;

      vsix = vsix.overrideAttrs { curlOpts = "--compressed"; };
    };
}
