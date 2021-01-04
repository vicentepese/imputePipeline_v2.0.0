# Initialize output 
PATLIST=/labs/mignot/GPC1_LGI1/Resources/LGI1_patList.txt

# Parse patient list from Stanford dataset (Plates 77to 121)
STANFORDFILE=/home/vipese/imputePipeline/Resources/Stanford_patList.csv
PLATES77=/oak/stanford/scg/lab_mignot/GENOS_QTLS_2019/CHR1_Plates_77_to_121_PMRA_shapeit_SORTED_SORTED.sample
for i in `cat $STANFORDFILE`
do
grep $i $PLATES77
done > $PATLIST

# Parse patient listfrom Stanford dataset II (GPC_PsychChip)
GPCPLATES=/labs/mignot/GPC_PsychChip/gpc1_pchip-qc.fam
for i in `cat $STANFORDFILE`
do 
grep $i $GPCPLATES
done > tmp
awk '{
    $1=$1" "$1; print $1
}' tmp >> $PATLIST
rm -r tmp


# Concat patients from Oxford
OXFORDPATLIST=/home/vipese/imputePipeline/Resources/Oxford_patList.txt
awk -F ',' 'NR>=2 {
    $1=$1" "$1;
    print $1;}' $OXFORDPATLIST >> $PATLIST

# Concat patients from Lyon 
LYONPATLIST=/home/vipese/imputePipeline/Resources/Lyon_patlist.csv
awk '{print $0}' $LYONPATLIST >> $PATLIST
