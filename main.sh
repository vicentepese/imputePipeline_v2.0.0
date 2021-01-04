#!/bin/bash -l
#SBATCH --job-name=MAIN_LGI1
#SBATCH --mem-per-cpu=16000
#SBATCH --output=MAIN_LGI1.out
#SBATCH --error=MAIN_LGI1.err
#SBATCH --account=mignot
#SBATCH --time=12:00:00

# Read JSON file
SETTINGS=pwd/settings.json

# Initialize variables 
PREFIX=$(jq -r '.prefix' $SETTINGS)
REF=$(jq -r '.ref' $SETTINGS)

# Intialize folders
FILESFOLDER=$(jq -r '.folder.FILESFOLDER' $SETTINGS)
GWAS_BY_CHR_FOLDER=$(jq -r '.folder.GWAS_BY_CHR' $SETTINGS)
SLURM_IMPUTE_LOG=$(jq -r '.folder.SLURM_IMPUTE_LOG' $SETTINGS)
SHAPEIT_IMPUTE_LOG=$(jq -r '.folder.SHAPEIT_IMPUTE_LOG' $SETTINGS)
BINFILES_FOLDER=$(jq -r '.folder.BINFILES_FOLDER' $SETTINGS)
SCRIPTS=${FILESFOLDER}scripts/

# Compute pipeline
python scripts/imputePipe.py -F $PREFIX -Ref $REF

# Sleep until job done 
USERFLAG="INIT
    USERFLAG"
while $(echo "$USERFLAG" | wc -l) -lt 1 
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done



