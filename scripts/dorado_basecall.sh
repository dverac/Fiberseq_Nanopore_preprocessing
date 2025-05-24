#!/bin/bash
#SBATCH --account=pi-spott
#SBATCH --job-name=basecalling
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --partition=gpu
#SBATCH --ntasks-per-node=8
#SBATCH --mem=80G
#SBATCH --nodes=1
#SBATCH --gres=gpu:1
#SBATCH --array=0-1 

## Modify the array size according to the number of folders in $in_dir, 0-(n-1)

## Run parameters.
#in_dir=/project/spott/lizarraga/nanopore/dorado/raw/pod5_pass
#out_dir=/project/spott/lizarraga/nanopore/dorado/results/22_09_24

## Testing set: Subset from the data from the 22_09_24 run, in raw/pod5_pass.
in_dir=/project/spott/dveracruz/Dorado_nanopore/test/raw
out_dir=/project/spott/dveracruz/Dorado_nanopore/test

## Create output directory
mkdir -p $out_dir/basecalling

############################################
## DORADO basecalling parameters
## Executable, model, qscore, modified bases models for 6mA and 5mC
############################################
dorado=/project/spott/lizarraga/nanopore/dorado/dorado-0.4.3-linux-x64/bin/dorado
base_model=/project/spott/lizarraga/nanopore/dorado/dorado_models/dna_r10.4.1_e8.2_400bps_sup@v4.2.0
qscore=8 ## In case this parameter also depends in the model.
modif_6mA=/project/spott/lizarraga/nanopore/dorado/dorado_models/dna_r10.4.1_e8.2_400bps_sup@v4.2.0_6mA@v2
modif_5mC=/project/spott/lizarraga/nanopore/dorado/dorado_models/dna_r10.4.1_e8.2_400bps_sup@v4.2.0_5mC@v2

# Get all subdirectories in $in_dir -> Select the correct one using the SLURM_ARRAY_TASK_ID
# folders=($(ls -d $in_dir/*)) Full path. 
folders=($(ls $in_dir))
part_dir=${folders[$SLURM_ARRAY_TASK_ID]}


############################################
## MAIN: Basecalling
############################################
# set umask to avoid locking each other out of directories
umask 002

$dorado basecaller $base_model $in_dir/${part_dir} --min-qscore $qscore  --modified-bases-models $modif_6mA,$modif_5mC --device "cuda:all" --verbose --batchsize 256 > $out_dir/basecalling/${part_dir}_bc.bam
