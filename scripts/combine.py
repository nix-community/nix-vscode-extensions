import argparse
from pathlib import Path
from scripts.common import (
    BLOCK_DIR,
    GENERATED,
    append_json,
    append_nix,
    write_file,
    nix_head,
    set_head,
)

my_parser = argparse.ArgumentParser(
    prog="combine-generated", description="Combine multiple generated files"
)

my_parser.add_argument(
    "--target",
    metavar="STRING",
    type=str,
    help="Name of target marketplace",
    default="vscode-marketplace",
)

my_parser.add_argument(
    "--out-dir",
    metavar="PATH",
    type=str,
    help="Where to write the combined files",
    default="tmp/out/combined",
)

args = my_parser.parse_args()

# prepare filesystem
target = args.target
in_blocks_dir: Path = Path(BLOCK_DIR) / GENERATED / target
out_dir: Path = Path(args.out_dir) / GENERATED / target

in_blocks_dir.mkdir(parents=True, exist_ok=True)
out_dir.mkdir(parents=True, exist_ok=True)

files_json = list(in_blocks_dir.glob(f"{GENERATED}-*.json"))
files_nix = list(in_blocks_dir.glob(f"{GENERATED}-*.nix"))

files_json.sort()
files_nix.sort()

generated_json = out_dir / f"{GENERATED}.json"
generated_nix = out_dir / f"{GENERATED}.nix"

write_file(generated_json, '{"mempty": {}\n}')
write_file(generated_nix, "{mempty = {};\n}")

for file_json in files_json:
    append_json(acc=generated_json, block=file_json)

for file_nix in files_nix:
    append_nix(acc=generated_nix, block=file_nix)

set_head(generated_json, 2, "{\n")
set_head(generated_nix, 2, nix_head)
