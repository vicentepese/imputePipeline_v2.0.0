#!/bin/sh
#1 - chromosome number
#2 total length of chr
#3 file name
#4 shapeit_jobID
mkdir -p imputeFiles
for i in `seq 0 $2` 
do
interval=`echo $i'e6 '$(($i +1))'e6'`
command=`echo ./bin/impute2 -known_haps_g "$3"_CHR"$1".haps -h /labs/mignot/IMPUTE_REFERENCE_PHASE1/ALL.chr"$1".integrated_phase1_v3.20101123.snps_indels_svs.genotypes.nomono.haplotypes.gz -l /labs/mignot/IMPUTE_REFERENCE_PHASE1/ALL.chr"$1".integrated_phase1_v3.20101123.snps_indels_svs.genotypes.nomono.legend.gz -m /labs/mignot/IMPUTE_REFERENCE_PHASE1/genetic_map_chr"$1"_combined_b37.txt -int "$interval" -buffer 500 -Ne 20000 -o imputeFiles/CHR"$1"_"$3"."$i"`
touch tmpchr"$1".$i.sh
chmod 755 tmpchr"$1".$i.sh
if [[ $4 -eq 0 ]]; then
cat > tmpchr"$1".$i.sh <<-EOF
#!/bin/bash -l
#SBATCH --job-name=EM_$i.chr"$1"
#SBATCH --mem-per-cpu=10000
#SBATCH --time=12:00:00
#SBATCH --account=mignot
$command 
EOF
else
cat > tmpchr"$1".$i.sh <<-EOF
#!/bin/bash -l
#SBATCH --job-name=EM_$i.chr"$1"
#SBATCH --depend=afterok:"$4"_"$1"
#SBATCH --mem-per-cpu=10000
#SBATCH --time=12:00:00
#SBATCH --account=mignot
$command
EOF
fi
pending=$(squeue -t pd -u $USER -h | wc -l)
sbatch tmpchr"$1".$i.sh
while [[ ${pending} -gt 100 ]]
do
sleep 60
pending=$(squeue -t pd -u $USER -h | wc -l)
done
rm tmpchr"$1".$i.sh
done
