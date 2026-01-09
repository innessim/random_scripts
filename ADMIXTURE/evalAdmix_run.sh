# input prefix (no extensions)
FILE=filtered_maf_05_converted

# list of specific K values to evaluate
K_VALUES=(2 3 4 5 6 7 8 9 10)

# number of threads
THREADS=48

# path to evalAdmix binary
EVALADMIX=/work/innessim/software/evalAdmix/evalAdmix

# create output directory
mkdir -p evalAdmix_results

# loop through each specified K
for K in "${K_VALUES[@]}"
do
    $EVALADMIX \
        -plink $FILE \
        -fname admix_out${K}/${FILE}.${K}.P \
        -qname admix_out${K}/${FILE}.${K}.Q \
        -P $THREADS \
        -o evalAdmix_results/evalAdmix_K${K}.corres.txt
done

