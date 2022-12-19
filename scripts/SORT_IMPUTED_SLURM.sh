#!/bin/bash -l
#SBATCH --job-name=SORT_LGI1
#SBATCH --mem-per-cpu=16000
#SBATCH --output=SORT_LGI1.out
#SBATCH --error=SORT_LGI1.err
#SBATCH --array=1-22
#SBATCH --account=mignot
#SBATCH --time=12:00:00

# Parse arguments
PROGNAME=$0

usage() {
  cat << EOF >&2
Usage: $PROGNAME [-p <path>]

-d <directory>: Path where concatenated outputs from imputePipe.py are located
-p <prefix>: Prefix
EOF
  exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    echo '-p <path>: Path where outputs from imputePipe.py are located'
    echo '-s <save-path>: Path where .bgen files are saved'
    shift
    shift
    ;;
    -d|--directory)
    FILEPATH="$2"
    shift # past argument
    shift # past value
    ;;
    -p|--prefix)
    PREFIX="$2"
    shift
    shift
    ;;
    *)    # unknown option
    usage # save it in an array for later
esac
done

# Print
echo "Sorting files in $FILEPATH"

# Read settings
SLURMDIR=$(jq -r '.folder.SLURM_IMPUTE_LOG' settings.json)
GWASBYCHR=$(jq -r '.folder.GWAS_BY_CHR' settings.json)

# Load module
module load qctool/v2.0.1

# Go to path 
cd $FILEPATH

# Create sample file 
echo "ID_1 ID_2" >> CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".sample
echo "0 0" >> CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".sample
awk '{
    $1=$2" "$2;
    print $1;
  }' "$GWASBYCHR""$PREFIX"_CHR"$SLURM_ARRAY_TASK_ID".fam >> CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".sample

# Sort using QCTOOLS v2 and convert to bgen 
qctool_v2.0.1 \
-filetype gen \
-sort \
-g CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".impute.gz \
-s CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".sample \
-og CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".bgen \
-os CHR"$SLURM_ARRAY_TASK_ID"_"$PREFIX".sample


# Print 
echo "File saved in $SAVEPATH"

