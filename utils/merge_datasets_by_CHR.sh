#!/bin/bash -l

#SBATCH --job-name=QCTOOLMerge
#SBATCH --mem-per-cpu=16000
#SBATCH --time=8:00:00
#SBATCH --account=mignot
#SBATCH --array=1-22

# Parse databases
# readarray -t conversations < <(get_json_array | jq -c '.[]')

# PREFIX
PREFIX=LGI1

# Path to files / databases
# Oxford
OXFORD_IN=/labs/mignot/LGI1/Oxford_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_Oxford_LGI1.bgen
OXFORD_SAMPLE=/labs/mignot/LGI1/Oxford_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_Oxford_LGI1.sample

# Lyon
LYON_IN=/labs/mignot/PMRA_PLATES_125B3_131_133_to_141/imputePipeline/imputeFiles/CHR"${SLURM_ARRAY_TASK_ID}"_Stanford_125B3_131_133_to_141Qced_SORTED.bgen
LYON_SAMPLE=/labs/mignot/PMRA_PLATES_125B3_131_133_to_141/imputePipeline/imputeFiles/CHR"${SLURM_ARRAY_TASK_ID}"_Stanford_125B3_131_133_to_141Qced_SORTED.sample

# Previous databases
PREVIOUSCASE_IN=/oak/stanford/scg/lab_mignot/GENOS_QTLS_2019/CHR"${SLURM_ARRAY_TASK_ID}"_Plates_77_to_121_PMRA_shapeit_SORTED_SORTED.bgen
PREVIOUSCASE_SAMPLE=/oak/stanford/scg/lab_mignot/GENOS_QTLS_2019/CHR"${SLURM_ARRAY_TASK_ID}"_Plates_77_to_121_PMRA_shapeit_SORTED_SORTED.sample

# Previous databases II
PREVIOUSCONTROL_IN=/oak/stanford/scg/lab_mignot/LGI1/GPC1_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_GPC_LGI1.bgen
PREVIOUSCONTROL_SAMPLE=/oak/stanford/scg/lab_mignot/LGI1/GPC1_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_GPC_LGI1.sample

# File to patlist
sampleIDs=/labs/mignot/GPC_LGI1/Resources/LGI1_patList.txt

# Out folder
OUTFOLDER=/oak/stanford/scg/lab_mignot/LGI1/LGI1_GWAS/

# Load module
module load qctool/v2.0.1

# Merge datasets
qctool_v2.0.1 \
-g $OXFORD_IN \
-s $OXFORD_SAMPLE \
-g $LYON_IN \
-s $LYON_SAMPLE  \
-g $PREVIOUSCASE_IN \
-s $PREVIOUSCASE_SAMPLE \
-g $PREVIOUSCONTROL_IN \
-s $PREVIOUSCONTROL_SAMPLE \
-assume-chromosome "$SLURM_ARRAY_TASK_ID" \
-compare-variants-by position,alleles \
-incl-samples $sampleIDs \
-threads 16 \
-threshold 0.8 \
-ofiletype binary_ped \
-og ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX} \
-os ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.sample

# Modify .fam file: ISSUE -- When converting to bed, QCTOOLS ignores the IIDs in the sample files -- loses also pheno and sex
awk 'NR>2 {print $0}' ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.sample > temp_"$SLURM_ARRAY_TASK_ID"
awk 'FNR==NR{a[NR]=$1;next}{$1=a[FNR]}1' temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam > fam_temp_"$SLURM_ARRAY_TASK_ID" && mv fam_temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam
awk 'FNR==NR{a[NR]=$2;next}{$2=a[FNR]}1' temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam  > fam_temp_"$SLURM_ARRAY_TASK_ID" && mv fam_temp_"$SLURM_ARRAY_TASK_ID" ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_${PREFIX}.fam
