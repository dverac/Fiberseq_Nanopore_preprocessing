#!/bin/bash
#SBATCH --partition=caslake
#SBATCH --account=pi-spott
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=8
#SBATCH --job-name=demux-%x
#SBATCH --output=%x_%A_%a.out
#SBATCH --error=%x_%A_%a.err
#SBATCH --array=0-1 

## Set the array size according to the number of files in $w_dir/basecalling, 0-(n-1)

# set umask to avoid locking each other out of directories
#umask 002

# execute
# w_dir='/project/spott/lizarraga/nanopore/dorado/results/22_09_24'
w_dir=/project/spott/dveracruz/Dorado_nanopore/test
kit="SQK-NBD114-24"


dorado_exec='/project/spott/lizarraga/nanopore/dorado/dorado-0.4.3-linux-x64/bin/dorado'

## Get the files. 
parts=($(ls $w_dir/basecalling))
part_bam=${parts[$SLURM_ARRAY_TASK_ID]}
## from part_bam, omit the path and the _bc.bam
part_name=${part_bam%_bc.bam}


## Run demultiplexing
mkdir $w_dir/barcoded/${part_name}
## -no-trim: if needed, if not check that the alignment works well. 
$dorado_exec demux --output-dir $w_dir/barcoded/${part_name} \
    --kit-name $kit --threads 16 $w_dir/basecalling/${part_bam}

