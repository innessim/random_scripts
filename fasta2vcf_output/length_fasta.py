#!/usr/bin/env python3
import sys
from pathlib import Path
import gzip
from multiprocessing import Pool, cpu_count
from tqdm import tqdm
from heapq import nsmallest, nlargest

EXTS = {".fa", ".fasta", ".fna", ".fas", ".fa.gz", ".fasta.gz"}

def seq_len(path: Path) -> tuple[str, int]:
    """Return (filename, sequence length) for a single-sequence FASTA."""
    is_gz = path.suffix == ".gz"
    opener = (lambda p: gzip.open(p, "rt")) if is_gz else (lambda p: open(p, "r"))
    length = 0
    with opener(path) as fh:
        for line in fh:
            if not line.startswith(">"):
                length += len(line.strip())
    return (str(path), length)

def main(directory: str, top_n: int, mode: str):
    dirpath = Path(directory)
    files = [f for f in dirpath.iterdir() if any(str(f).endswith(ext) for ext in EXTS)]
    if not files:
        print("No FASTA files found.")
        return

    results = []
    with Pool(processes=cpu_count()) as pool:
        for res in tqdm(pool.imap_unordered(seq_len, files), total=len(files), desc="Processing"):
            results.append(res)

    if mode == "shortest":
        top = nsmallest(min(top_n, len(results)), results, key=lambda x: x[1])
        print(f"\nTop {len(top)} shortest sequences:")
    else:
        top = nlargest(min(top_n, len(results)), results, key=lambda x: x[1])
        print(f"\nTop {len(top)} longest sequences:")

    for i, (fname, length) in enumerate(top, 1):
        print(f"{i}. {Path(fname).name}\t{length}")

    extreme_file, extreme_len = top[0]
    extreme_label = "Shortest" if mode == "shortest" else "Longest"
    print(f"\n{extreme_label} sequence length: {extreme_len} (in {Path(extreme_file).name})")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.exit(f"Usage: {sys.argv[0]} /path/to/fastas --mode shortest|longest [topN]")
    directory = sys.argv[1]
    if sys.argv[2] != "--mode" or len(sys.argv) < 4:
        sys.exit("You must specify --mode shortest or --mode longest")
    mode = sys.argv[3].lower()
    if mode not in {"shortest", "longest"}:
        sys.exit("Mode must be 'shortest' or 'longest'")
    top = int(sys.argv[4]) if len(sys.argv) == 5 else 5
    main(directory, top, mode)

