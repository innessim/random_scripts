#!/bin/bash

# ========= USER SETTINGS =========
REPS=10
TARGET_K=3
OUTFILE="likelihood_summary_K${TARGET_K}.tsv"
# =================================

# Clear or create the output file
echo -e "K\tREP\tLogLikelihood" > "$OUTFILE"

# Loop through REPs for K=TARGET_K
for REP in $(seq 1 $REPS); do
  LOGFILE="admix_out${TARGET_K}_rep${REP}/log${TARGET_K}.out"
  if [[ -f "$LOGFILE" ]]; then
    LIKE=$(grep "Loglikelihood:" "$LOGFILE" | awk '{print $2}' | grep -Eo "^-?[0-9]+\.[0-9]+$")
    if [[ -n "$LIKE" ]]; then
      echo -e "${TARGET_K}\t${REP}\t${LIKE}" >> "$OUTFILE"
    else
      echo "Warning: No valid likelihood in $LOGFILE"
    fi
  else
    echo "Missing file: $LOGFILE"
  fi
done

# Print the most likely replicate for K
echo ""
echo "Best run for K=$TARGET_K:"
awk 'NR==1 {next} {if ($3 > max || NR==2) {max=$3; line=$0}} END {print line}' "$OUTFILE"

