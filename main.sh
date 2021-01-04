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
PREFIX=$(jq -r '.folder.SLURM_IMPUTE_LOG' settings.json)