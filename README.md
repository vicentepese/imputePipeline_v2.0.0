# Imputation_pipeline_v2

## Introduction
This pipeline attempts to improve the initial [1000 Genome Imputation Pipeline](https://github.com/Mignot-Lab/imputePipeline) designed by [@adiamb](https://github.com/adiamb). This version automatizes the process and provides a final output of imputed PED binary (_.bed_) files using a settings-logic. 

This pipeline is SLURM-dependant, and therefore may only be used with Stanford SCG cloud-computing services. 

## Description
The pipeline performs the following steps:
1. Takes base PLINK format _.bed_ files, splits them into chromosomes (1 to 22), phases them using [SHAPEIT](https://mathgen.stats.ox.ac.uk/genetics_software/shapeit/shapeit.html), and subsequently imputes each chromosome individually to [1000 Genomes Phase I](https://www.internationalgenome.org/) in segments of 1 mb. (Unmodified  from [Original Code](https://github.com/Mignot-Lab/imputePipeline)).
2. Cleans up SLURM and SHAPEIT _.log_ files (Added to Original Code)
3. Concatenates the imputed segments from step 1) (Modified from Original Code)
4. Sorts and converts to _.bgen_ format (Modified from Original Code)

## Requirements
### Packages
The pipeline requires the following modules: <br>
``plink``  <br>
``qctool/v2.0.1``

### Settings
To operate the pipeline, all the arguments must be introduced through the `settings.json` file. Particularly, you must keep in mind:
1. To write to __total path__, and _not_ the relative path.
2. To write a slash (/) at the end of each path. 
For more information regarding each of the elements in the `settings.json` file, please refer to the _info_ element within the file. 

### Computation 
To run the pipeline:
1. Clone the repository.
2. Copy the _.bed_ files inside the directory.
3. Fill up the `settings.json` file.
4. Run from the repository's directory `sbatch main.sh`

## Issues 
The pipeline encompasses certain issues that must be taken into consideration prior to its utilization:
1. Low memory: the pipeline can be computationally heavy, and may not perform correctly with large datasets. Allow always ~50 GB of free space.
2. The pipeline will fail if the files to be imputed contain duplicated variants (by position) or IDs.
3. The pipeline only accepts a file at a time. That is, it will not deal with multiple _.bed_ files or databases.

## Future changes
The following changes are recommended to improve the pipeline
1. Add headers to files.
2. Improve `main.sh`
3. Cleaning may be put into a single bash file in order to tidy up `main.sh`
4. Include QC (remove duplciated variants and IIDs)

