#!/bin/bash
# Wrapper script to run CLUMPAK BestK analysis on all subsets

# ========== USER SETTINGS ==========
REPS=10
KMIN=2  # Start at K=2 (K=1 = no structure)
KMAX=10
OUTDIR="bestKbyEvanno"
CLUMPAK_INPUT="admix_logfile_for_clumpak.txt"
SIF_PATH="/work/innessim/software/singularity_containers/clumpak_1.1.sif"
# ===================================

SUBSETS=("Sequoia" "Sierra" "ZeeRest")

# Step 1: Pull CLUMPAK container if it doesn't exist
if [ ! -f "$SIF_PATH" ]; then
  echo "Downloading CLUMPAK Singularity container..."
  singularity pull --arch amd64 "$SIF_PATH" library://james-s-santangelo/clumpak/clumpak:1.1
fi

for SUBSET in "${SUBSETS[@]}"; do
    echo "========================================="
    echo "Finding best K for: $SUBSET"
    echo "========================================="
    
    cd "$SUBSET" || exit 1
    
    # Step 2: Write input file for CLUMPAK
    echo "Writing input file for CLUMPAK: $CLUMPAK_INPUT"
    > "$CLUMPAK_INPUT"  # clear the file if it exists
    
    for K in $(seq $KMIN $KMAX); do
      for REP in $(seq 1 $REPS); do
        LOGFILE="admix_out${K}_rep${REP}/log${K}.out"
        if [[ -f "$LOGFILE" ]]; then
          # Extract the line and pull just the number
          LIKE=$(grep "Loglikelihood:" "$LOGFILE" | awk '{print $2}' | grep -Eo "^-?[0-9]+\.[0-9]+$")
          if [[ -n "$LIKE" ]]; then
            echo "${K} ${LIKE}" >> "$CLUMPAK_INPUT"
          else
            echo "Warning: No valid likelihood in $LOGFILE"
          fi
        else
          echo "Missing file: $LOGFILE"
        fi
      done
    done
    
    # Step 3: Run CLUMPAK BestKByEvanno.pl inside Singularity
    mkdir -p "$OUTDIR"
    
    echo "Running CLUMPAK BestKByEvanno for $SUBSET..."
    singularity exec --bind "$PWD":"$PWD" --home "$PWD" "$SIF_PATH" \
      perl /opt/bin/BestKByEvanno.pl \
        --id "${SUBSET}_best_k" \
        --d "$OUTDIR" \
        --f "$CLUMPAK_INPUT" \
        --inputtype lnprobbyk
    
    echo "✅ Completed: $SUBSET"
    cd ..
done

echo "========================================="
echo "All subsets completed!"
echo "Check output in each subset's $OUTDIR directory"
echo "========================================="
