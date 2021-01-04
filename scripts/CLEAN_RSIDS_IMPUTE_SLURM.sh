#!/bin/bash
touch CLEAN_RSID_IMPUTE.sh
chmod 755 CLEAN_RSID_IMPUTE.sh
cat > CLEAN_RSID_IMPUTE.sh <<- EOF
#!/bin/bash -l
#SBATCH --job-name=clean_rsid_impute_files
#SBATCH --mem-per-cpu=16000
#SBATCH --array=1-22
#SBATCH --account=mignot
#SBATCH --time=12:00:00
module load python/2.7
python CLEAN_RSIDS_IMPUTED_FILES.py -F CHR\${SLURM_ARRAY_TASK_ID}_$1 -CHR \$SLURM_ARRAY_TASK_ID -VAR GSA- 
EOF
sbatch --export=ALL CLEAN_RSID_IMPUTE.sh
