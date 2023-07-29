(builtins.getFlake "github:deemp/flakes/${(builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.flakes.locked.rev}").outputs.makeDefault ./.
