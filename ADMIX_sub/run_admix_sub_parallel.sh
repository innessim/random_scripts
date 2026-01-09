#!/bin/bash
# Script 2: Run ADMIXTURE on prepared PLINK files
# Run this AFTER 01_prepare_plink_files.sh

THREADS=2  # Per ADMIXTURE job
K_MIN=2
K_MAX=10
REPS=10

# Array of subset names
SUBSETS=("Sequoia" "Sierra" "ZeeRest")

for SUBSET in "${SUBSETS[@]}"; do
    echo "========================================="
    echo "Processing subset: $SUBSET"
    echo "========================================="
    
    cd "$SUBSET" || exit 1
    
    # Check if PLINK files exist
    if [ ! -f "${SUBSET}.bed" ]; then
        echo "Error: ${SUBSET}.bed not found! Run prepare_plink_files.sh first."
        cd ..
        continue
    fi
    
    # Function to run ADMIXTURE with unique seed per replicate
    run_admixture() {
        K=$1
        REP=$2
        SUBSET=$3
        THREADS=$4
        echo "Running $SUBSET: K=$K, Replicate=$REP"
        OUTDIR="admix_out${K}_rep${REP}"
        mkdir -p "$OUTDIR"
        cd "$OUTDIR"
        SEED=$((1000 + K * 100 + REP))
        admixture --cv -s $SEED ../${SUBSET}.bed ${K} -j${THREADS} > log${K}.out 2>&1
        cd ..
    }
    
    export -f run_admixture
    export SUBSET THREADS
    
    # Run ADMIXTURE in parallel
    echo "Running ADMIXTURE (K=$K_MIN to $K_MAX, $REPS replicates each)..."
    parallel -j 24 run_admixture {1} {2} $SUBSET $THREADS ::: $(seq $K_MIN $K_MAX) ::: $(seq 1 $REPS)
    
    echo "Completed: $SUBSET"
    cd ..
done

echo "========================================="
echo "All ADMIXTURE runs completed!"
echo "========================================="
