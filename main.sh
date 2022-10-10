#!/bin/bash -l
#SBATCH --job-name=MAIN_LGI1
#SBATCH --mem-per-cpu=16000
#SBATCH --output=MAIN_LGI1.out
#SBATCH --error=MAIN_LGI1.err
#SBATCH --account=mignot
#SBATCH --time=24:00:00

###################################################################
#Script Name	: main.sh                                                                                       
#Description	: Main script in the imputation pipeline. 
#               + (I) Imputation: takes in base plink format bed files,
#               + splits them into chromosomes ( 1 to 22) and then phases them using shapeit. 
#               + after phasing each chromosome is imputed to 1000 genomes phase 3 in 1mb chunks.
#               + Original code: https://github.com/Mignot-Lab/imputePipeline by @adiamb
#               + (II) Clean up: cleans slurm and shape-it logs
#               + (III) Concatenaion: Uses Uses QCTools to concat imputed segments (Original code: see above)
#               + (IV) Sorting and convertings: Uses QCTools v2 to sort and convert by CHR 
#Args           : Settings-based argument: settings.json                                                                                           
#Author       	: Vicente Peris Sempere                         
#Email         	: vipese@stanford.edu                                        
###################################################################

######## INITIALIZE ########

# Read JSON file
SETTINGS=$(pwd)/settings.json

# Initialize variables 
PREFIX=$(jq -r '.prefix' $SETTINGS)
REF=$(jq -r '.ref' $SETTINGS)

# Intialize folders
FILESFOLDER=$(jq -r '.folder.FILESFOLDER' $SETTINGS)
GWAS_BY_CHR_FOLDER=$(jq -r '.folder.GWAS_BY_CHR' $SETTINGS)
SLURM_IMPUTE_LOG=$(jq -r '.folder.SLURM_IMPUTE_LOG' $SETTINGS)
SHAPEIT_IMPUTE_LOG=$(jq -r '.folder.SHAPEIT_IMPUTE_LOG' $SETTINGS)
BINFILES_FOLDER=$(jq -r '.folder.BIN_FOLDER' $SETTINGS)
SCRIPTS=${FILESFOLDER}scripts/

########## PREPROCESSING ###########

# Load module 
module load plink 

# If files are not binarize, binarize
FILES=$(ls *${PREFIX}*)
if [ ! -f ${PREFIX}.bed ]; then 
    plink --file ${PREFIX} --allow-no-sex --no-sex --no-fid --no-parents --no-pheno --make-bed --out ${PREFIX}
fi

# Create list duplicated variants by name and position
awk 'a[$2]++{print $0}' ${PREFIX}.bim > Dup_vars_name_pos.txt
awk 'a[$4]++{print $0}' ${PREFIX}.bim >> Dup_vars_name_pos.txt
sort -k3n ${PREFIX}.bim | uniq -f2 -D >> Dup_vars_name_pos.txt

# Iteratively remove multi-allelic variants (PLINK does not manage them well)
NDUPVARS=$(awk 'END{print NR}' ${FILESFOLDER}Dup_vars_name_pos.txt)
while [ $NDUPVARS -gt 1 ];
do 
    plink --bfile ${PREFIX} --exclude Dup_vars_name_pos.txt\
        --allow-no-sex \
        --make-bed --out gwastempFilt > gwastempFilt
    rm -r ${PREFIX}.bed ${PREFIX}.fam ${PREFIX}.bim
    mv gwastempFilt.bed ${PREFIX}.bed;  mv gwastempFilt.fam ${PREFIX}.fam;  mv gwastempFilt.bim ${PREFIX}.bim;
    rm -r gwastempFilt*

    awk 'a[$2]++{print $0}' ${PREFIX}.bim > Dup_vars_name_pos.txt
    sort -k3n ${PREFIX}.bim | uniq -f2 -D >> Dup_vars_name_pos.txt
    NDUPVARS=$(awk 'END{print NR}' ${FILESFOLDER}Dup_vars_name_pos.txt)
done

# Filter out low genotyping in samples and variants (Shape it throw an error at fully missing vars or subjects)
plink --bfile ${PREFIX} --allow-no-sex \
    --mind --geno \
    --make-bed --out gwastempFilt > gwastempFilt
mv gwastempFilt.bed ${PREFIX}.bed;  mv gwastempFilt.fam ${PREFIX}.fam;  mv gwastempFilt.bim ${PREFIX}.bim;


########## IMPUTE PIPELINE ##########
# Run pipeline
python scripts/imputePipe.py -F $PREFIX -Ref $REF

# Sleep until job done 
USERFLAG="INIT 
    USERFLAG
    LINE"
while [ $(echo "$USERFLAG" | wc -l) -gt 2 ];
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done

######## CLEAN UP #########

# Clean up: copy CHR files in directory 
if [ -d $GWAS_BY_CHR_FOLDER ]; then rm -Rf $GWAS_BY_CHR_FOLDER; fi
mkdir $GWAS_BY_CHR_FOLDER
mv ${PREFIX}_CHR* $GWAS_BY_CHR_FOLDER

# Clean up: copy slurm outputs 
if [ -d $SLURM_IMPUTE_LOG ]; then rm -Rf $SLURM_IMPUTE_LOG; fi
mkdir $SLURM_IMPUTE_LOG
mv slurm* $SLURM_IMPUTE_LOG

# Clean up shapeit
if [ -d $SHAPEIT_IMPUTE_LOG ]; then rm -Rf $SHAPEIT_IMPUTE_LOG; fi
mkdir $SHAPEIT_IMPUTE_LOG
mv shapeit* $SHAPEIT_IMPUTE_LOG

########## CONCAT IMPUTED SEGEMENTS ##########

# Clean BINFILES folder / create directory
if [ -d $BINFILES_FOLDER ]; then rm -Rf $BINFILES_FOLDER; fi
mkdir $BINFILES_FOLDER

# Run concatenation
sbatch scripts/CAT_IMPUTE_SLURM.sh -d ${FILESFOLDER}/imputeFiles/ -s $BINFILES_FOLDER -c $SCRIPTS -p $PREFIX

# Sleep until job done 
USERFLAG="INIT 
    USERFLAG
    LINE"
while [ $(echo "$USERFLAG" | wc -l) -gt 2 ];
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done

######### SORT CHR AND CONVERT TO BGEN #########

# Sort and convert to BGEN
sbatch ${SCRIPTS}SORT_IMPUTED_SLURM.sh -d $BINFILES_FOLDER -p $PREFIX

# Sleep until done 
USERFLAG="INIT 
    USERFLAG
    LINE"
while [ $(echo "$USERFLAG" | wc -l) -gt 2 ];
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done

######### CONVER TO BINARY PLINK AND MERGE #########

# Convert to plink
sbatch ${SCRIPTS}bgen2plink.sh

# Sleep until done 
USERFLAG="INIT 
    USERFLAG
    LINE"
while [ $(echo "$USERFLAG" | wc -l) -gt 2 ];
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done

# Merge
sbatch ${SCRIPTS}merge_cohort.sh

# Move slurm to log folder
mv slurm* $SLURM_IMPUTE_LOG

