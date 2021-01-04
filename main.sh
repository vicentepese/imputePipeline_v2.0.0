#!/bin/bash -l
#SBATCH --job-name=MAIN_LGI1
#SBATCH --mem-per-cpu=16000
#SBATCH --output=MAIN_LGI1.out
#SBATCH --error=MAIN_LGI1.err
#SBATCH --account=mignot
#SBATCH --time=12:00:00

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

########## IMPUTE PIPELINE ###########

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

######## CLEAN UP #########

# Clean up: copy CHR files in directory 
if [ -d $GWAS_BY_CHR_FOLDER ]; then rm -Rf $GWAS_BY_CHR_FOLDER
mkdir $GWAS_BY_CHR_FOLDER
mv $PREFIX_CHR* $GWAS_BY_CHR_FOLDER

# Clean up: copy slurm outputs 
if [ -d $SLURM_IMPUTE_LOG ]; then rm -Rf $SLURM_IMPUTE_LOG
mkdir $SLURM_IMPUTE_LOG
mv slurm* $SLURM_IMPUTE_LOG

# Clean up shapeit
if [ -d $SHAPEIT_IMPUTE_LOG ]; then rm -Rf $SHAPEIT_IMPUTE_LOG
mkdir $SHAPEIT_IMPUTE_LOG
mv shapeit* $SHAPEIT_IMPUTE_LOG

########## CONCAT IMPUTED SEGEMENTS ##########
sbatch scripts/CAT_IMPUTE_SLURM.sh -d ${FILESFOLDER}/imputeFiles/ -s $BINFILES_FOLDER -c $SCRIPTS -p $PREFIX

# Sleep until job done 
USERFLAG="INIT
    USERFLAG"
while $(echo "$USERFLAG" | wc -l) -lt 1 
do 
    # Update flag
    USERFLAG=$(squeue -u $USER)
    sleep 2m
done

######### SORT CHR AND CONVERT TO BGEN #########
sbatch ${SCRIPTS}SORT_IMPUTED_SLURM.sh -d $FILESFOLDER -s $BINFILES_FOLDER -p $PREFIX