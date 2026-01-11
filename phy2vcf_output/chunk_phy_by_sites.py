#!/usr/bin/env python3
import sys
from pathlib import Path

def main():
    if len(sys.argv) != 3:
        print("Usage: python3 chunk_phy_by_sites.py <input.phy> <chunk_size>")
        sys.exit(1)

    infile = Path(sys.argv[1])
    chunk_size = int(sys.argv[2])

    with open(infile) as f:
        header = f.readline()
        ntaxa, nsites = map(int, header.strip().split())
        lines = [line.rstrip('\n\r') for line in f]

    names = []
    seqs = []
    for line in lines:
        parts = line.strip().split(maxsplit=1)
        if len(parts) != 2:
            print(f"Error: line missing sequence?\n{line}")
            sys.exit(1)
        name, seq = parts
        seq = seq.replace(" ", "")
        names.append(name)
        seqs.append(seq)

    seq_lens = set(len(s) for s in seqs)
    if len(seq_lens) != 1:
        print(f"Error: sequences have inconsistent lengths: {seq_lens}")
        sys.exit(1)
    if seq_lens.pop() != nsites:
        print(f"Warning: sequence length mismatch with header sites ({nsites})")

    nchunks = (nsites + chunk_size - 1) // chunk_size

    outdir = Path.cwd() / "chunks"
    outdir.mkdir(exist_ok=True)

    for i in range(nchunks):
        start = i * chunk_size
        end = min((i + 1) * chunk_size, nsites)
        chunk_file = outdir / f"chunk_{i+1:03d}.phy"
        with open(chunk_file, "w") as out_f:
            # PHYLIP header is only two numbers: number of samples and chunk length
            out_f.write(f"{ntaxa} {end - start}\n")
            for name, seq in zip(names, seqs):
                out_f.write(f"{name}    {seq[start:end]}\n")

    print(f"Done! Created {nchunks} chunks in {outdir}/")

if __name__ == "__main__":
    main()

