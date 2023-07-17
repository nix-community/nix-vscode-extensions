(import
  (
    let
      lock = (builtins.fromJSON (builtins.readFile ../nix-dev/flake.lock)).nodes.flakes.locked;
    in
    (
      import
        "${fetchTarball {
          url = "https://github.com/deemp/flakes/archive/${lock.rev}.tar.gz";
          sha256 = lock.narHash;
        }}/source-flake"
    ).outputs.flake-compat.outPath
  )
  { src = ./.; }
).defaultNix
