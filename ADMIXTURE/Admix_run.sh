# input file name
FILE=filtered_maf_05_converted

# loop through iterations of K
for i in {2..10}
do
    mkdir -p admix_out${i}                      # Create output dir for this K
    cd admix_out${i}                            # Enter the directory
    admixture --cv ../$FILE.bed $i -j48  > log${i}.out  # Run admixture using file from parent dir
    cd ..                                       # Go back to parent directory
done

# identify cv error for each K
for i in {2..10}
do
    awk '/CV/ {print '${i}', $3, $4}' admix_out${i}/log${i}.out
done > $FILE.cv.error

