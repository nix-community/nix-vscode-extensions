{ pkgs }:
{

  vadimcn.vscode-lldb = _: {
    postInstall = ''
      declare isDarwin=${if pkgs.stdenv.isDarwin then "true" else "false"}
      if [[ $isDarwin == "false" ]]; then
        cd "$out/$installPrefix"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./adapter/codelldb
        patchelf --add-rpath "${pkgs.lib.makeLibraryPath [ pkgs.zlib ]}" ./lldb/lib/liblldb.so
      fi
    '';
  };

  # C# Related
  ms-dotnettools.vscode-dotnet-runtime = _: {
    postPatch = ''
      chmod +x "$PWD/dist/install scripts/dotnet-install.sh"
    '';
  };
  # Custom Patch C# Devkit to work, credit to https://github.com/NixOS/nixpkgs/issues/270423#issuecomment-1902482401 for the initial bash script
  ms-dotnettools.csdevkit = _: {
    postPatch = with pkgs; ''
      declare -A platform_map=(
        ["x86_64-linux"]="linux-x64"
        ["aarch64-linux"]="linux-arm64"
        ["x86_64-darwin"]="darwin-x64"
        ["aarch64-darwin"]="darwin-arm64"
      )

      declare patchCommand=${if stdenv.isDarwin then "install_name_tool" else "patchelf"}
      declare add_rpath_command=${if stdenv.isDarwin then "-add_rpath" else "--set-rpath"}

      patchelf_add_icu_as_needed() {
        declare elf="''${1?}"
        declare icu_major_v="${lib.head (lib.splitVersion (lib.getVersion icu.name))}"
        for icu_lib in icui18n icuuc icudata; do
          patchelf --add-needed "lib''${icu_lib}.so.$icu_major_v" "$elf"
        done
      }

      patchelf_common() {
        declare elf="''${1?}"
        chmod +x "$elf"
        patchelf_add_icu_as_needed "$elf"
        patchelf --add-needed "libssl.so" "$elf"
        patchelf --add-needed "libz.so.1" "$elf"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          --set-rpath "${
            lib.makeLibraryPath [
              stdenv.cc.cc
              openssl
              zlib
              icu.out
            ]
          }:\$ORIGIN" \
          "$elf"
      }

      sed -i -E -e 's/(e.extensionPath,"cache")/require("os").homedir(),".cache","Microsoft", "csdevkit","cache"/g' "$PWD/dist/extension.js"
      sed -i -E -e 's/o\.chmod/console.log/g' "$PWD/dist/extension.js"

      declare platform="''${platform_map[${stdenv.system}]}"
      if [[ -z "$platform" ]]; then
        echo "Unsupported platform: ${stdenv.system}"
        exit 1
      fi

      declare new_rpath="${
        lib.makeLibraryPath [
          stdenv.cc.cc
          openssl
          zlib
          icu.out
        ]
      }:\$ORIGIN"
      declare base_path="./components/vs-green-server/platforms/$platform/node_modules"
      declare -a paths=(
        "@microsoft/visualstudio-server.$platform/Microsoft.VisualStudio.Code.Server"
        "@microsoft/servicehub-controller-net60.$platform/Microsoft.ServiceHub.Controller"
        "@microsoft/visualstudio-code-servicehost.$platform/Microsoft.VisualStudio.Code.ServiceHost"
        "@microsoft/visualstudio-reliability-monitor.$platform/Microsoft.VisualStudio.Reliability.Monitor"
      )

      for path in "''${paths[@]}"; do
        $patchCommand $add_rpath_command "$new_rpath" "$base_path/$path"
      done
    '';
  };
}
