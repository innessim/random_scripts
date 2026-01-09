#!/bin/bash
# Script 1: Convert VCF to PLINK format for each subset
# This generates .bed/.bim/.fam files and keeps log files

VCF="../filtered_maf_05.recode.vcf.gz"

# Array of subset names
SUBSETS=("Sequoia" "Sierra" "ZeeRest")

for SUBSET in "${SUBSETS[@]}"; do
    echo "========================================="
    echo "Processing subset: $SUBSET"
    echo "========================================="
    
    cd "$SUBSET" || exit 1
    
    # Check if keep file exists
    if [ ! -f "pop_${SUBSET}.txt" ]; then
        echo "Error: pop_${SUBSET}.txt not found!"
        cd ..
        continue
    fi
    
    # Convert VCF to PLINK format
    if [ -f "${SUBSET}.bed" ]; then
        echo "PLINK files already exist for ${SUBSET}. Skipping..."
    else
        echo "Converting VCF to PLINK format..."
        plink --vcf "$VCF" \
              --double-id \
              --keep "pop_${SUBSET}.txt" \
              --allow-extra-chr \
              --geno 0.5 \
              --maf 0.05 \
              --make-bed \
              --out "${SUBSET}_temp" | tee plink_convert.log
        
        # Set all chromosomes to 0 for unlinked RAD loci (better for ADMIXTURE)
        echo "Setting all chromosomes to 0 for unlinked loci..."
        awk '{$1=0; print}' "${SUBSET}_temp.bim" > "${SUBSET}.bim"
        cp "${SUBSET}_temp.bed" "${SUBSET}.bed"
        cp "${SUBSET}_temp.fam" "${SUBSET}.fam"
        
        # Clean up temp files
        rm "${SUBSET}_temp".*
        
        # Count SNPs retained
        NSNPS=$(wc -l < "${SUBSET}.bim")
        NSAMPLES=$(wc -l < "${SUBSET}.fam")
        echo "Summary for ${SUBSET}:"
        echo "  Samples: $NSAMPLES"
        echo "  SNPs: $NSNPS"
        echo ""
    fi
    
    cd ..
done

echo "========================================="
echo "PLINK conversion completed!"
echo "Check plink_convert.log in each subset directory for details."
echo "========================================="
