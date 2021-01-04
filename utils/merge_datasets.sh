#!/bin/bash -l

#SBATCH --job-name=QCTOOLMerge
#SBATCH --mem-per-cpu=16000
#SBATCH --time=8:00:00
#SBATCH --account=mignot

# Initialize folders / files
FILES=/labs/mignot/LGI1_GWAS/
MERGELIST=/labs/mignot/GPC1_LGI1/mergelist.txt

# Initialize plink variables 
MAF=0.05

# Create mergelist 
ls -1 "$FILES"*.bed | xargs -n 1 basename | cut -f1 -d.  > $MERGELIST
MERGEVAR=($(cat $MERGELIST))

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
--make-bed --out ${FILES}LGI1_GWAS

# For loop to merge 
LENFILES=${#MERGEVAR[@]}

for IDX in $(seq 2 $LENFILES)
do

    # Take CHR 
    CHR=${MERGEVAR[$IDX]}

    # Print 
    echo "------------------------------------------------------------------------------"
    echo "QCing "${CHR}

    # Parse duplicated variants
    echo "------------------------------------------------------------------------------"
    plink --bfile ${FILES}${CHR} --list-duplicate-vars suppress-first \
        --allow-no-sex --out temp >> temp
    awk '{print $4}' temp.dupvar > DUPSNPS.txt
    rm -r temp*

    # QC (duplicated variants and MAF)
    echo "------------------------------------------------------------------------------"
    plink --bfile ${FILES}${CHR} --exclude DUPSNPS.txt \
        --allow-no-sex \
        --maf $MAF \
        --make-bed --out ${FILES}${CHR}_QC 

    # Merge 
    plink --bfile ${FILES}LGI1_GWAS --bmerge ${FILES}${MERGEVAR[1]}_QC \
        --make-bed --out ${FILES}temp 
    cp ${FILES}temp* ${FILES}LGI1_GWAS*

    echo "------------------------------------------------------------------------------"
done 



########### ALTERNATIVE #############

LENFILES=${#MERGEVAR[@]}
for i in $(seq 0 $LENFILES)
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

# Change mergelist to plink format
awk -v FILEPATH=$FILES '{
    $1=FILEPATH$1"_QC.bed "FILEPATH$1"_QC.bim "FILEPATH$1"_QC.fam";
    print $1
}' $MERGELIST > mergeList_plink.txt

# Full merge 
plink --bfile ${FILES}CHR1_LGI1_QC --merge-list mergeList_plink.txt \
    --out ${FILES}LGI1_GWAS

