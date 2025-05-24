#!/bin/bash

#SBATCH --time=18:00:00
#SBATCH --account=pi-spott
#SBATCH --partition=spott
#SBATCH --job-name=Nano_basecalling
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=4GB

#load python module
#module load python
configfile="/project/spott/dveracruz/Dorado_nanopore/workflow/run_samples.yaml"


echo Starting Time is `date "+%Y-%m-%d %H:%M:%S"`
start=$(date +%s)

#activate env
source activate /project/spott/dveracruz/bin/miniconda3/envs/fiber_sq

# set umask to avoid locking each other out of directories
#umask 002
smk=/project/spott/dveracruz/Dorado_nanopore/workflow

## Make DAG
snakemake -s $smk/basecalling.smk --configfile $configfile --profile workflow/basecalling --dag | dot -Tpng > basecalling_DAG_${SLURM_JOB_ID}.png

## Run snakemake
snakemake -s $smk/basecalling.smk --configfile $configfile --profile workflow/basecalling --rerun-incomplete


echo Ending Time is `date "+%Y-%m-%d %H:%M:%S"`
end=$(date +%s)
time=$(( ($end - $start) / 60 ))
echo Used Time is $time mins