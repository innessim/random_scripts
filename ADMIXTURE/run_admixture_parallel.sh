#!/bin/bash

# Set number of threads per job (adjust as needed)
THREADS=

# Path to your input file (without .bed/.bim/.fam extensions)
FILE=filtered_maf_05_converted

# Range of K values and replicates
K_MIN=1
K_MAX=10
REPS=10

# Function to run ADMIXTURE with unique seed per replicate
run_admixture() {
    K=$1
    REP=$2
    echo "Running K=$K, Replicate=$REP"
    OUTDIR="admix_out${K}_rep${REP}"
    mkdir -p "$OUTDIR"
    cd "$OUTDIR"
    SEED=$((1000 + K * 100 + REP))  # deterministic but unique
    admixture --cv -s $SEED ../${FILE}.bed ${K} -j${THREADS} > log${K}.out 2>&1
    cd ..
}

export -f run_admixture
export FILE THREADS

# Run in parallel using GNU parallel
parallel -j 48 run_admixture {1} {2} ::: $(seq $K_MIN $K_MAX) ::: $(seq 1 $REPS)

