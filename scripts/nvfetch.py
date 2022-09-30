import argparse
import sys
from pathlib import Path
import subprocess
import shutil
from scripts.common import (
    BLOCK_DIR,
    ENCODING,
    write_file,
    clean_file,
    set_head,
    GENERATED,
    append_json,
    append_nix,
    nix_head
)

my_parser = argparse.ArgumentParser(prog="run-nvfetcher", description="Run nvfetcher")

my_parser.add_argument(
    "--target",
    metavar="STRING",
    type=str,
    help="Name of target marketplace",
    default="vscode-marketplace",
)

my_parser.add_argument(
    "--block-size",
    metavar="NUMBER",
    type=int,
    help="How many extensions (size of a block) to fetch before writing the file",
    default=3,
)

my_parser.add_argument(
    "--block-limit",
    metavar="NUMBER",
    type=int,
    help="How many blocks to fetch in total",
    default=2,
)

my_parser.add_argument(
    "--first-block",
    metavar="NUMBER",
    type=int,
    help="Number of the first block",
    default=1,
)

my_parser.add_argument(
    "--threads",
    metavar="NUMBER",
    type=int,
    help="Where to write the generated files",
    default=0,
)

my_parser.add_argument(
    "--action-id",
    metavar="INT",
    type=str,
    help="ID of the action. This is to distinguish the results of parallel nvfetches",
    required=True,
)

args = my_parser.parse_args()

target = args.target
block_size = args.block_size
block_limit = args.block_limit
# 0-base
first_block = args.first_block - 1
threads = args.threads
action_id = args.action_id

# prepare paths

nvfetch = Path("nvfetch")
generated = Path(GENERATED)
toml_file = nvfetch / f"{target}.toml"
dir_generated = generated / target
generated_json = dir_generated / f"{GENERATED}.json"
generated_nix = dir_generated / f"{GENERATED}.nix"

tmp = Path("tmp")
block_json_generated = tmp / generated_json
block_nix_generated = tmp / generated_nix

block_toml = tmp / f"{target}.toml"

tmp_generated = tmp / dir_generated
tmp_generated.mkdir(parents=True, exist_ok=True)

# Initialize accumulator files
acc_json = tmp_generated / "acc.json"
write_file(acc_json, '{"mempty" : {}\n}')

acc_nix = tmp_generated / "acc.nix"
write_file(acc_nix, nix_head + "\n}")

# log accumulators
tmp_log = tmp / "log"
tmp_log.mkdir(parents=True, exist_ok=True)

# will collect skipped blocks
skipped: Path = BLOCK_DIR / "skipped" / target / f"{action_id}.toml"
skipped.parents[0].mkdir(parents=True, exist_ok=True)

outdir = Path(BLOCK_DIR)
out_generated_json = (
    outdir / generated_json.parents[0] / f"{GENERATED}-{action_id}.json"
)

# combine GH action expects that there will be a generated file, even if it's empty
out_generated_json.parents[0].mkdir(parents=True, exist_ok=True)
out_generated_nix = outdir / (generated_nix.parents[0]) / f"{GENERATED}-{action_id}.nix"
out_generated_nix.parents[0].mkdir(parents=True, exist_ok=True)
write_file(out_generated_json, '')
write_file(out_generated_nix, '')

# install missing software
if shutil.which("nvfetcher") is None:
    process = subprocess.run(
        """nix profile install nixpkgs#gawk nixpkgs#nvfetcher nixpkgs#tree""",
        shell=True,
        check=True,
    )

# stats

extension_count: int = 0
with toml_file.open("r", encoding=ENCODING) as tf:
    txt = tf.read()
    extension_count = int((txt.count("[")) / 2)

number_blocks = int((extension_count + block_size) / block_size)

last_block = (
    first_block - 1 + block_limit
    if block_size * (first_block + block_limit) <= extension_count
    else number_blocks - 1
)

extensions_to_load = min(
    (last_block - first_block + 1) * block_size,
    extension_count - (first_block * block_size),
)


def get_extensions_range(start, end):
    """1-base"""
    return start * block_size + 1, min((end + 1) * block_size, extension_count)


def extensions_range_str(first_block_, last_block_):
    start, end = get_extensions_range(first_block_, last_block_)
    return f"extensions: {start} ... {end}"


block_start_label = "┌----------┐"
block_end_label = "└----------┘"
print(block_start_label)
print(f"total extensions: {extension_count}")
print(f"block size: {block_size}")
print(f"total #blocks: {number_blocks}")
print(f"block limit: {block_limit}")
print(f"first block: {first_block + 1}")
print(f"last block: {last_block + 1}")

if last_block < first_block:
    print("\nError: the first block should come before the last block")
    print("Skipping these blocks")
    sys.exit(0)

print(f"#extensions to load: {extensions_to_load}")
print(extensions_range_str(first_block, last_block))
print(block_end_label)

for i in range(first_block, last_block + 1):
    print(block_start_label)
    print(f"block: {i + 1}")
    print(extensions_range_str(i, i))
    start, end = get_extensions_range(i, i)

    start = (start - 1) * 2 + 1
    end = end * 2

    clean_file(block_toml)
    with toml_file.open("r", encoding=ENCODING) as tf, block_toml.open(
        "a", encoding=ENCODING
    ) as bt:
        bracket_counter = 0
        for j in tf:
            if j[0] == "[":
                bracket_counter += 1
            if start <= bracket_counter <= end:
                bt.write(j)

    block_log = tmp_log / f"block{i}.txt"

    TRIALS = 5

    # handle failed blocks
    # we will collect skipped blocks and handle them later
    try:
        subprocess.run(
            # f'printf "nvfetched\n"; touch {block_log}',
            f"nvfetcher -j {threads} -o {tmp_generated} -c \
                {block_toml} -t -r {TRIALS} > {block_log}",
            shell=True,
            check=True,
        )
    # TODO nvfetch skipped
    except Exception as e:
        print(
            f"nvfetcher failed. Appending block {i+1} to {skipped}. We will try to nvfetch it later"
        )
        write_file(block_json_generated, "")
        write_file(block_nix_generated, "")
        with skipped.open("a", encoding=ENCODING) as s, block_toml.open(
            "r", encoding=ENCODING
        ) as bt:
            s.write("\n")
            s.write(bt.read())

    with block_log.open("r", encoding=ENCODING) as bl:
        fetch_url_count = 0
        check_count = 0
        for j in bl:
            if j.find("FetchUrl") != -1:
                fetch_url_count += 1
            if j.find("Check") != -1:
                check_count += 1

        print(f"fetched: {fetch_url_count}")
        print(f"checked: {check_count}")

    append_json(acc=acc_json, block=block_json_generated)
    append_nix(acc=acc_nix, block=block_nix_generated)

    print(block_end_label)

set_head(acc_nix, 5, nix_head)

shutil.copy(acc_json, out_generated_json)
shutil.copy(acc_nix, out_generated_nix)