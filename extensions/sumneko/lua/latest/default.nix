{ pkgs, ... }:
{
  patches = [ ./remove-chmod.patch ];

  postInstall = ''
    ln -sf ${pkgs.lua-language-server}/bin/lua-language-server \
      $out/$installPrefix/server/bin/lua-language-server
  '';
}
