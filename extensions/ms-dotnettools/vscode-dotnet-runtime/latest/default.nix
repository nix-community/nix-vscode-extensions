{ pkgs, ... }:
let
  dotnetInstall = pkgs.fetchurl {
    url = "https://dot.net/v1/dotnet-install.sh";
    hash = "sha256-GbCniQw3EgG5RL8PjNu2Rg0FPWPdvqGM/tPkGZdpzhc=";
  };
in
{
  postPatch = ''
    DOTNET_INSTALL="$PWD/dist/install scripts/dotnet-install.sh"
    ln -s ${dotnetInstall} "$DOTNET_INSTALL"
    chmod +x "$DOTNET_INSTALL"
  '';
}
