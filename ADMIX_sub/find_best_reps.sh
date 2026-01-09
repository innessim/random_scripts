#!/bin/bash
# Script to find the replicate with the lowest log likelihood (highest probability)
# for each K value from ADMIXTURE log files.

directories=("Sequoia" "Sierra" "ZeeRest")
logfile_name="admix_logfile_for_clumpak.txt"

for dir in "${directories[@]}"; do
    logfile="${dir}/${logfile_name}"
    
    if [ ! -f "$logfile" ]; then
        echo "WARNING: $logfile not found, skipping..."
        echo ""
        continue
    fi
    
    echo "============================================================"
    echo "Directory: $dir"
    echo "============================================================"
    
    # Get optimal K by Evanno method
    evanno_file="${dir}/bestKbyEvanno/output.log"
    best_k=""
    if [ -f "$evanno_file" ]; then
        best_k=$(grep "Optimal K by Evanno is:" "$evanno_file" | sed -n 's/.*Optimal K by Evanno is: \([0-9]*\).*/\1/p')
        if [ -n "$best_k" ]; then
            echo "*** Optimal K by Evanno method: $best_k ***"
        fi
    fi
    echo ""
    
    # Get unique K values
    k_values=$(awk '{print $1}' "$logfile" | sort -n | uniq)
    
    printf "%-5s %-10s %-20s\n" "K" "Best Rep" "Log Likelihood"
    echo "-----------------------------------"
    
    for k in $k_values; do
        # Get all log likelihoods for this K value
        logliks=$(awk -v k="$k" '$1 == k {print $2}' "$logfile")
        
        # Find the minimum log likelihood and its line number
        best_rep=""
        best_loglik=""
        line_num=0
        min_loglik=""
        
        while IFS= read -r loglik; do
            line_num=$((line_num + 1))
            
            if [ -z "$min_loglik" ] || (( $(echo "$loglik < $min_loglik" | bc -l) )); then
                min_loglik="$loglik"
                best_loglik="$loglik"
                
                # Rep numbering: 1, 2, 3, 4, 5, etc. (1-indexed)
                best_rep=$line_num
            fi
        done <<< "$logliks"
        
        # Mark the optimal K if it matches
        marker=""
        if [ -n "$best_k" ] && [ "$k" == "$best_k" ]; then
            marker=" <-- OPTIMAL K"
        fi
        
        printf "%-5s %-10s %-20s%s\n" "$k" "$best_rep" "$best_loglik" "$marker"
    done
    
    echo ""
done
