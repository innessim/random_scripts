#!/bin/bash

# strict: biallelic SNPs, per-genotype DP>=8 & GQ>=30, site present in >=90% samples, MAF>=0.05
# Filter VCF

bcftools view -m2 -M2 -v snps ../ipyrad_output/lib_set.vcf.gz \
  | bcftools filter -i 'FMT/DP>6' \
  | bcftools filter -i 'F_MISSING<=0.2' -Oz -o filtered_F_strict.vcf.gz

bcftools index filtered_F_strict.vcf.gz

# Extract unique population names
populations=$(cut -f2 ../ipyrad_output/popfile_formatted.txt | sort -u)

# Calculate F for each population
for pop in $populations; do
  # Create directory for this population
  mkdir -p F_by_pop/${pop}
  
  # Extract samples for this population
  grep -w "$pop" ../ipyrad_output/popfile_formatted.txt | cut -f1 > F_by_pop/${pop}/${pop}_samples.txt

  echo "Processing population: $pop"
  vcftools --gzvcf filtered_F_strict.vcf.gz \
    --keep F_by_pop/${pop}/${pop}_samples.txt \
    --het \
    --out F_by_pop/${pop}/${pop}_F &> /dev/null  
done
