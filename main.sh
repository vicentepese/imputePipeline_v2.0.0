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
GWAS_BY_CHR_FOLDER=$(jq -r '.folder.GWAS_BY_CHR' $SETTINGS)
SLURM_IMPUTE_LOG=$(jq -r '.folder.SLURM_IMPUTE_LOG' $SETTINGS)
SHAPEIT_IMPUTE_LOG=$(jq -r '.folder.SHAPEIT_IMPUTE_LOG' $SETTINGS)
IMPUTEFILES_FOLDER=$(jq -r '.folder.SHAPEIT_IMPUTE_LOG' $SETTINGS)
BINFILES_FOLDER=$(jq -r '.folder.BINFILES_FOLDER' $SETTINGS)

