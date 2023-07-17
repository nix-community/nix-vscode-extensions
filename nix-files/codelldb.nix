{ pkgs, platforms }:

let
  inherit (platforms) linux-x64 linux-arm64 darwin-x64 darwin-arm64;
in
[
  # https://github.com/nix-community/nix-vscode-extensions/issues/34
  {
    name = "vscode-lldb";
    version = "1.9.2";
    publisher = "vadimcn";
    engineVersion = "^1.60.0";
  }
  [
    {
      platform = linux-x64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-x86_64-linux.vsix";
      sha256 = "0x9xz31xml2hnssc5zpm2c6wck9qpcdgxlp7zrqjdc854lmx52w9";
    }
    {
      platform = linux-arm64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-aarch64-linux.vsix";
      sha256 = "1d5d1akz82nf349f0ivx1a53xbw1y7sj41h4dhy6qay3smlk3hlh";
    }
    {
      platform = darwin-x64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-x86_64-darwin.vsix";
      sha256 = "0p50vgq9ciaxjgdfb6xbjzfcdb6chpp892dpz56398xw60cyjdhb";
    }
    {
      platform = darwin-arm64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-aarch64-darwin.vsix";
      sha256 = "0lgwjrr57zpfvwx3w7icmj3lfjwqwqw8l4d9jqhmwybp285mrcjx";
    }
  ]
]
