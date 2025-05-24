## Nanopore dorado snakemake: 2. Demultiplex

## Run demultiplex: Specific cluster parameters. PROFILE WORKING.
## snakemake -s workflow/demultiplex.smk --profile workflow/demux_align  
## snakemake -s workflow/demultiplex.smk --cluster "sbatch --account=pi-spott --mem=80000 --ntasks-per-node=8" --jobs 10 --use-conda

## Testing: Dry-run and print DAG.
## snakemake -np -s workflow/demultiplex.smk --profile workflow/demux_align
## snakemake -s workflow/demultiplex.smk --dag | dot -Tpng > demux_align_dag.png

##  IF the conda environment is not activated, try with the source activate command in the rules, or module load samtools.

##########
## PARAMETERS
## Read config file: Working directories, kit name, barcodes, and sample names.
##########

#configfile: "/project/spott/dveracruz/Dorado_nanopore/workflow/dorado_config.yaml"
configfile: "/project/spott/dveracruz/Dorado_nanopore/workflow/run_samples.yaml"

## Parameters needed for this pipeline. 
w_dir=config['out_dir']

kit_name = config['kit_name']
barcodes = config['barcodes']
sample_names = config['sample_names']

## Make sure that barcodes & sample names are lists.
#if type(barcodes) is not list:
#    barcodes = [barcodes]
#if type(sample_names) is not list:
#    sample_names = [sample_names]

## Create a dictionary with the sample names and barcodes: Index is the barcode, value is the sample name.
samples = dict(zip(barcodes, sample_names))

## Print parameters: INPUT and OUTPUT directories.
#print(f"Working_directory: {w_dir}")

## set the working directory. 
workdir:w_dir

##########
## DORADO PARAMETERS
##########
## PATH TO DORADO executables
dorado_exec=config['dorado_exec']

##########
## SETUP
##########

## List all the folders in the input directory. 
import os
## Check if basecalling folder is present, if not exit. 
if not os.path.exists(w_dir+'/basecalling'):
   print("Basecalling folder not found in working directory, please run basecalling.smk first.")
   exit(1)
## List all the parts in the basecalling folder. 
parts = os.listdir(w_dir+'/basecalling')
## Keep only the first 1-2 number prior the suffix _bc.bam in parts. 
parts = [part.split('_')[0] for part in parts]

## Check if at least 1 part is present, if not exit.
if len(parts) == 0:
   print("No parts found in basecalling folder, please run basecalling.smk first.")
   exit(1)

## Default resources for all rules. 
slurm_extra = "--mem=40000 --ntasks-per_node=8"

##########
## RULES
###########

## 2. Demultiplexing. 
rule all:
    ## Output of demultiplexing is the barcoded bam files.
    #input: expand(f"{w_dir}/barcoded/{{part}}/{kit_name}_barcode{{bc}}.bam", part=parts, bc=barcodes),
    #input: expand(f"{w_dir}/{{bc}}.aligned.bam", bc = barcodes),
    #input: expand(f"{w_dir}/{{sample}}.aligned.sort.bam", sample = sample_names)
    input: expand(f"{w_dir}/{{sample}}.aligned.sort.bam.csi", sample = sample_names)

rule demux:
    input: f"{w_dir}/basecalling/{{part}}_bc.bam"
    output: 
        demux_done = touch(f"{w_dir}/barcoded/{{part}}/demux_done.txt"),
        barcoded_bams = expand(f"{w_dir}/barcoded/{{part}}/{kit_name}_barcode{{bc}}.bam", part="{part}", bc=barcodes)
    params: 
        out_dir = f"{w_dir}/barcoded/{{part}}",
        dorado = dorado_exec,
        threads = 16,
        kit = kit_name,
    resources:
        mem_mb = 50000,
        ntasks_per_node = 8,
    shell:
        """
        ## Run Demultiplexing.
        #{params.dorado} demux --output-dir {params.out_dir} --kit-name {params.kit} --no-trim --threads {params.threads} {input}
        {params.dorado} demux --output-dir {params.out_dir} --kit-name {params.kit} -n 100000 --no-trim {input}
        touch {output.demux_done}
        """

## Align each barcoded bam file. 
rule align:
    input:
        lambda wildcards: f"{w_dir}/barcoded/{wildcards.part}/{kit_name}_barcode{wildcards.bc}.bam"
    output:
        temp("{w_dir}/barcoded/{part}/{bc}_aligned.bam")
    params:
        dorado = dorado_exec,
        threads = 16,
        ref = "/project/spott/reference/human/GRCh38/genome/hg38.fa",
    resources:
        mem_mb = 60000,
        ntasks_per_node = 16,
    conda: 'fiber_sq'
    shell:
        """
        # source activate /project/spott/dveracruz/bin/miniconda3/envs/fiber_sq
        umask 002
        {params.dorado} aligner --verbose  --threads {params.threads} {params.ref} {input} > {output}
        """

## Merge the aligned bams.
rule merge: 
    input: 
        expand(f"{w_dir}/barcoded/{{part}}/{{bc}}_aligned.bam", part=parts, bc="{bc}")
    output: 
        temp(f"{w_dir}/{{bc}}.aligned.bam")
    conda: 'fiber_sq'
    resources:
        mem_mb = 50000,
        ntasks_per_node = 2,
    shell:
        """
        # conda activate fiber_sq
        samtools merge {input} -o {output}
        """

rule sort:
    input: "{w_dir}/{bc}.aligned.bam"
    output: "{w_dir}/{bc}.aligned.sort.bam"
    conda: 'fiber_sq'
    resources:
        mem_mb = 50000,
        ntasks_per_node = 4,
    shell:
        """
        # conda activate fiber_sq
        samtools sort {input} -o {output}
        """

## Using python, change the name of the aligned.bam files: instead of bc, the sample name of the same index.
rule change_name:
    input: 
        expand(f"{w_dir}/{{bc}}.aligned.sort.bam", bc=barcodes)
    output: 
        expand(f"{w_dir}/{{sample}}.aligned.sort.bam", sample=sample_names)
    run:
        ## Change the name of the aligned bam files. 
        for i in range(len(barcodes)):
            os.rename(input[i], output[i])

rule index:
    input: "{w_dir}/{sample}.aligned.sort.bam"
    output: "{w_dir}/{sample}.aligned.sort.bam.csi"
    conda: 'fiber_sq'
    resources:
        mem_mb = 50000,
        ntasks_per_node = 8,
    shell:
        """
        # conda activate fiber_sq
        samtools index -c {input}
        """
