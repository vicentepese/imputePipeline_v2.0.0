#!/bin/bash -l

#SBATCH --job-name=MERGE_COHORT
#SBATCH --mem-per-cpu=16000
#SBATCH --time=8:00:00
#SBATCH --account=mignot

# Read JSON file
SETTINGS=$(pwd)/settings.json

# Initialize prefix and folder
PREFIX=$(jq -r '.prefix' $SETTINGS)
BIN_FOLDER=$(jq -r '.folder.BIN_FOLDER' $SETTINGS)

# Initialize Minimum Allele Frequency for filtering
MAF=$(jq -r '.MAF' $SETTINGS)

# Create mergelist 
MERGELIST="$BIN_FOLDER"mergelist.txt
ls -1 "$BIN_FOLDER"*.bed | xargs -n 1 basename | cut -f1 -d.  > $MERGELIST
MERGEVAR=($(cat $MERGELIST))
rm $MERGELIST

# Load module 
module load plink

## FIRST PASS ##
for i in $(seq 0 1)
do 
    # Print 
    echo "------------------------------------------------------------------------------"
    echo "QCing "${MERGEVAR[$i]}

    # Parse duplicated variants
    plink --bfile ${FILES}${MERGEVAR[$i]} --list-duplicate-vars suppress-first \
        --allow-no-sex --out temp >> temp
    awk '{print $4}' temp.dupvar > DUPSNPS.txt
    rm -r temp*

    # QC (duplicated variants and MAF)
    plink --bfile ${FILES}${MERGEVAR[$i]} --exclude DUPSNPS.txt \
        --allow-no-sex \
        --maf $MAF \
        --make-bed --out ${FILES}${MERGEVAR[$i]}_QC 

    # Print 
    echo "------------------------------------------------------------------------------"

done 

# Merge first pass
plink --bfile ${FILES}${MERGEVAR[0]}_QC --bmerge ${FILES}${MERGEVAR[1]}_QC \
--make-bed --out ${FILES}${PREFIX}

# For loop to merge 
LENFILES=${#MERGEVAR[@]}

for IDX in $(seq 2 21)
do

    # Take CHR 
    CHR=${MERGEVAR[$IDX]}

    # Print 
    echo "------------------------------------------------------------------------------"
    echo "QCing "${CHR}

    # Parse duplicated variants
    echo "------------------------------------------------------------------------------"
    plink --bfile ${FILES}${CHR} --list-duplicate-vars suppress-first \
        --allow-no-sex --out temp > temp
    awk '{print $4}' temp.dupvar > DUPSNPS.txt
    rm -r temp*

    # QC (duplicated variants and MAF)
    echo "------------------------------------------------------------------------------"
    plink --bfile ${FILES}${CHR} --exclude DUPSNPS.txt \
        --allow-no-sex \
        --maf $MAF \
        --make-bed --out ${FILES}${CHR}_QC 

    # Merge 
    plink --bfile ${FILES}${PREFIX} --bmerge ${FILES}${CHR}_QC \
        --make-bed --out ${FILES}temp 
    mv ${FILES}temp.bim ${FILES}${PREFIX}.bim
    mv ${FILES}temp.bed ${FILES}${PREFIX}.bed
    mv ${FILES}temp.fam ${FILES}${PREFIX}.fam

    echo "------------------------------------------------------------------------------"
done 
