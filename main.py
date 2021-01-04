import json
import subprocess
import os 

def main():

    # Import settings 
    with open('settings.json', 'r') as inFile:
        settings = json.load(inFile)

    # Run impute pipeline
    prefix, ref = settings['prefix'], settings['ref']
    subprocess.call(['python scripts/imputePipe.py -F {prefix} -Ref {ref}'.format(prefix = prefix, ref = ref)], shell=True)

    # Clean up: copy CHR files in directory 
    GWAS_BY_CHR_FOLDER = settings['folder']['GWAS_BY_CHR']
    subprocess.call(['if [ -d "{GWASFOLDER}" ]; then rm -Rf {GWASFOLDER}; fi '.format(GWASFOLDER = GWAS_BY_CHR_FOLDER)], shell= True)
    subprocess.call(['mkdir {GWASFOLDER}'.format(GWASFOLDER = GWAS_BY_CHR_FOLDER)], shell= True)
    subprocess.call(['mv {prefix}_CHR* {GWASFOLDER}'.format(prefix = prefix, GWASFOLDER = GWAS_BY_CHR_FOLDER)], shell= True)

    # Clean up: copy slurm outputs in directory 
    SLURM_IMPUTE_LOG = settings['folder']['SLURM_IMPUTE_LOG']
    subprocess.call(['if [ -d "{SLURMLOG}" ]; then rm -Rf {SLURMLOG}; fi '.format(SLURMLOG = SLURM_IMPUTE_LOG)], shell= True)
    subprocess.call(['[ -d "{SLURMLOG}" ] || mkdir {SLURMLOG}'.format(SLURMLOG = SLURM_IMPUTE_LOG)], shell= True)
    subprocess.call(['mv slurm* {SLURMLOG}'.format(SLURMLOG = SLURM_IMPUTE_LOG)], shell= True)

    # Clean up: copy shapeit outputs in directory
    SHAPEIT_IMPUTE_LOG = settings['folder']['SHAPEIT_IMPUTE_LOG']
    subprocess.call(['if [ -d "{SHAPEITLOG}" ]; then rm -Rf {SHAPEITLOG}; fi '.format(SHAPEITLOG = SHAPEIT_IMPUTE_LOG)], shell= True)
    subprocess.call(['[ -d "{SHAPEITLOG}" ] || mkdir {SHAPEITLOG}'.format(SHAPEITLOG = SHAPEIT_IMPUTE_LOG)], shell= True)
    subprocess.call(['mv shape* {SHAPEITLOG}'.format(SHAPEITLOG = SHAPEIT_IMPUTE_LOG)], shell= True)

    # Concat imputation output
    imputeFiles_folder = os.getcwd() + '/imputeFiles/'
    Bin_folder = settings['folder']['BIN_FOLDER']
    scripts = os.getcwd() + '/scripts/'
    subprocess.call(['sbatch {scripts}CAT_IMPUTE_SLURM.sh -d {path} -s {savepath} -c {scripts} -p {prefix}'.format(path = imputeFiles_folder, \
        savepath = Bin_folder, scripts = scripts, prefix = prefix)], shell = True)

    # Sort CHR and convert to bgen 
    subprocess.call(['sbatch  {scripts}SORT_IMPUTED_SLURM.sh -d {path} -s {savepath} -p {prefix}'.format(path = Bin_folder, savepath = Bin_folder, \
        scripts = scripts, prefix = prefix)], shell = True)

    # Convert to binary ped
    # subprocess.call('sbatch scripts/CONVERT_GEN2BED.sh -p {path} -s {savepath}'.format(path = Bin_folder, savepath = Bin_folder), shell = True)

if __name__ == "__main__":
    main()