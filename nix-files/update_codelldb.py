#!/bin/bash

import os

a ='''
# don't motify this file for it's created by update_codelldb.py.
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
      sha256 = "%s";
    }
    {
      platform = linux-arm64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-aarch64-linux.vsix";
      sha256 = "%s";
    }
    {
      platform = darwin-x64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-x86_64-darwin.vsix";
      sha256 = "%s";
    }
    {
      platform = darwin-arm64;
      url = "https://github.com/vadimcn/codelldb/releases/download/v1.9.2/codelldb-aarch64-darwin.vsix";
      sha256 = "%s";
    }
  ]
]'''%(
    os.getenv("x86_64_linux") or "",
    os.getenv("aarch64_linux") or "",
    os.getenv("x86_64_darwin") or "",
    os.getenv("aarch64_darwin") or "",
    )

print(a)
