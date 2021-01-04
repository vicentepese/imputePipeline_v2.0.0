#!/bin/bash -l

#SBATCH --job-name=QCTOOLMerge
#SBATCH --mem-per-cpu=16000
#SBATCH --time=8:00:00
#SBATCH --account=mignot
#SBATCH --array=1-22

# Parse databases
readarray -t conversations < <(get_json_array | jq -c '.[]')

# Path to files / databases
# Oxford
OXFORD_IN=/labs/mignot/Oxford_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_LGI1_QC.bgen
OXFORD_SAMPLE=/labs/mignot/Oxford_LGI1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_LGI1_QC.sample

# Lyon
LYON_IN=/labs/mignot/PMRA_PLATES_125B3_131_133_to_141/imputePipeline/imputeFiles/CHR"${SLURM_ARRAY_TASK_ID}"_Stanford_125B3_131_133_to_141Qced_SORTED.bgen
LYON_SAMPLE=/labs/mignot/PMRA_PLATES_125B3_131_133_to_141/imputePipeline/imputeFiles/CHR"${SLURM_ARRAY_TASK_ID}"_Stanford_125B3_131_133_to_141Qced_SORTED.sample

# Previous databases
PREVIOUSCASE_IN=/oak/stanford/scg/lab_mignot/GENOS_QTLS_2019/CHR"${SLURM_ARRAY_TASK_ID}"_Plates_77_to_121_PMRA_shapeit_SORTED_SORTED.bgen
PREVIOUSCASE_SAMPLE=/oak/stanford/scg/lab_mignot/GENOS_QTLS_2019/CHR"${SLURM_ARRAY_TASK_ID}"_Plates_77_to_121_PMRA_shapeit_SORTED_SORTED.sample

# Previous databases II
PREVIOUSCONTROL_IN=/labs/mignot/GPC1_LGI1/GPC1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_gpc1_pchip-QC.bgen
PREVIOUSCONTROL_SAMPLE=/labs/mignot/GPC1_LGI1/GPC1_Imputed/CHR"${SLURM_ARRAY_TASK_ID}"_gpc1_pchip-QC.sample

# File to patlist
sampleIDs=/labs/mignot/GPC1_LGI1/Resources/LGI1_patList.txt

# Out folder
OUTFOLDER=/labs/mignot/LGI1_GWAS/

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
-incl-samples $sampleIDs \
-compare-variants-by position,alleles \
-threads 16 \
-threshold 0.8 \
-ofiletype binary_ped \
-og ${OUTFOLDER}CHR"$SLURM_ARRAY_TASK_ID"_LGI1
