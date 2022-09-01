#!/bin/bash -l

#SBATCH --job-name=BGEN2PLINK
#SBATCH --mem-per-cpu=16000
#SBATCH --time=8:00:00
#SBATCH --account=mignot
#SBATCH --array=1-22

######## INITIALIZE ########

# Read JSON file
SETTINGS=$(pwd)/settings.json

# Initialize variables 
PREFIX=$(jq -r '.prefix' $SETTINGS)
REF=$(jq -r '.ref' $SETTINGS)
MERGE=$(jq -r '.merge' $SETTINGS)

# Intialize folders
GWAS_BY_CHR_FOLDER=$(jq -r '.folder.GWAS_BY_CHR' $SETTINGS)

# Path to files / databases
DATA_IN=${GWAS_BY_CHR_FOLDER}CHR"${SLURM_ARRAY_TASK_ID}"_${PREFIX}.bgen
DATA_SAMPLE=${GWAS_BY_CHR_FOLDER}CHR"${SLURM_ARRAY_TASK_ID}"_${PREFIX}.sample

# Load module
module load qctool/v2.0.1

# Merge datasets
qctool_v2.0.1 \
-g $DATA_IN \
-s $DATA_SAMPLE \
-assume-chromosome "$SLURM_ARRAY_TASK_ID" \
-compare-variants-by position,alleles \
-incl-samples $sampleIDs \
-threads 16 \
-threshold 0.8 \
-ofiletype binary_ped \
-og ${GWAS_BY_CHR_FOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX} \
-os ${GWAS_BY_CHR_FOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.sample

# Modify .fam file: ISSUE -- When converting to bed, QCTOOLS ignores the IIDs in the sample files -- loses also pheno and sex
awk 'NR>2 {print $0}' ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.sample > temp_"$SLURM_ARRAY_TASK_ID"
awk 'FNR==NR{a[NR]=$1;next}{$1=a[FNR]}1' temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam > fam_temp_"$SLURM_ARRAY_TASK_ID" && mv fam_temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam
awk 'FNR==NR{a[NR]=$2;next}{$2=a[FNR]}1' temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam  > fam_temp_"$SLURM_ARRAY_TASK_ID" && mv fam_temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam
rm temp_"$SLURM_ARRAY_TASK_ID"
rm m_temp_"$SLURM_ARRAY_TASK_ID"