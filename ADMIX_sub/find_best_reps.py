#!/usr/bin/env python3
"""
Script to find the replicate with the lowest log likelihood (highest probability)
for each K value from ADMIXTURE log files.
"""

import os
from collections import defaultdict

def parse_admix_logfile(filepath):
    """
    Parse the admix_logfile_for_clumpak.txt file.
    Returns a dict mapping K values to lists of log likelihoods.
    """
    k_to_loglik = defaultdict(list)
    
    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            
            parts = line.split()
            if len(parts) >= 2:
                try:
                    k_value = int(parts[0])
                    log_likelihood = float(parts[1])
                    k_to_loglik[k_value].append(log_likelihood)
                except ValueError:
                    # Skip lines that don't have numeric values
                    continue
    
    return k_to_loglik

def find_best_reps(k_to_loglik):
    """
    Find the replicate with the lowest log likelihood for each K.
    Returns a dict mapping K to (rep_number, log_likelihood).
    """
    best_reps = {}
    
    for k, logliks in sorted(k_to_loglik.items()):
        if not logliks:
            continue
        
        # Find the index of the minimum log likelihood
        min_idx = logliks.index(min(logliks))
        min_loglik = logliks[min_idx]
        
        # Rep numbering: 1, 2, 3, 4, 5, etc. (1-indexed)
        rep_num = min_idx + 1
        
        best_reps[k] = (rep_num, min_loglik)
    
    return best_reps

def get_best_k_evanno(directory):
    """
    Parse the bestKbyEvanno/output.log file to get the optimal K.
    Returns the optimal K value or None if not found.
    """
    evanno_path = os.path.join(directory, 'bestKbyEvanno', 'output.log')
    
    if not os.path.exists(evanno_path):
        return None
    
    try:
        with open(evanno_path, 'r') as f:
            for line in f:
                if 'Optimal K by Evanno is:' in line:
                    # Extract the K value from the line
                    parts = line.split('Optimal K by Evanno is:')
                    if len(parts) == 2:
                        k_value = int(parts[1].strip())
                        return k_value
    except (IOError, ValueError):
        return None
    
    return None

def main():
    directories = ['Sequoia', 'Sierra', 'ZeeRest']
    logfile_name = 'admix_logfile_for_clumpak.txt'
    
    for directory in directories:
        logfile_path = os.path.join(directory, logfile_name)
        
        if not os.path.exists(logfile_path):
            print(f"WARNING: {logfile_path} not found, skipping...\n")
            continue
        
        print(f"{'='*60}")
        print(f"Directory: {directory}")
        print(f"{'='*60}")
        
        # Get optimal K by Evanno method
        best_k = get_best_k_evanno(directory)
        if best_k is not None:
            print(f"*** Optimal K by Evanno method: {best_k} ***")
            print()
        
        # Parse the log file
        k_to_loglik = parse_admix_logfile(logfile_path)
        
        if not k_to_loglik:
            print(f"No data found in {logfile_path}\n")
            continue
        
        # Find best replicates
        best_reps = find_best_reps(k_to_loglik)
        
        # Display results
        print(f"{'K':<5} {'Best Rep':<10} {'Log Likelihood':<20}")
        print(f"{'-'*35}")
        for k in sorted(best_reps.keys()):
            rep_num, loglik = best_reps[k]
            # Mark the optimal K by Evanno if available
            marker = " <-- OPTIMAL K" if best_k is not None and k == best_k else ""
            print(f"{k:<5} {rep_num:<10} {loglik:<20.6f}{marker}")
        
        print()

if __name__ == "__main__":
    main()
