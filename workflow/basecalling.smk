## Nanopore dorado snakemake: 1. Basecalling.
## This is a snakemake pipeline to process Nanopore data using Dorado.

## Run basecalling: Specific cluster parameters. 
## snakemake -s workflow/basecalling.smk --cluster "sbatch --account=pi-spott --partition=gpu --ntasks-per-node=8 --nodes=1 --gres=gpu:1"
## snakemake -s workflow/basecalling.smk --profile workflow/basecalling

## Testing: Dry-run and DAG generation. 
## snakemake -np -s workflow/basecalling.smk 
## snakemake -s workflow/basecalling.smk --dag | dot -Tpng > basecalling_dag.png


##########
## PARAMETERS
## Read config file: Input and output directories. 
##########

configfile: "/project/spott/dveracruz/Dorado_nanopore/workflow/run_samples.yaml"
#configfile: "/project/spott/dveracruz/Dorado_nanopore/workflow/dorado_config.yaml"

## Parameters needed for this pipeline. 
in_dir=config['in_dir']
out_dir=config['out_dir']


## set the working directory. 
workdir:out_dir

##########
## DORADO PARAMETERS
##########

## PATH TO DORADO executables ## Tested with Dorado-0.4.3-linux-x64
dorado_exec= config['dorado_exec']

## PATHS TO DORADO MODELS
dorado_models_dir=config['dorado_models_dir']

## Base model and modified base models
base_model=config['model_base']
model_6mA=config['model_6mA']
model_5mC=config['model_5mC']


##########
## SETUP
##########

## List all the folders in the input directory. 
import os
parts = os.listdir(in_dir)

## Create log directory if it does not exists. 
log_dir = f"{out_dir}/logs"
os.makedirs(f"{out_dir}/logs", exist_ok=True)
os.makedirs(f"{out_dir}/basecalling", exist_ok=True)
##########
## RULES
###########

## 1. Basecalling
rule all:
    input: expand("{out_dir}/basecalling/{part}_bc.bam", in_dir=in_dir, out_dir=out_dir, part=parts)

rule basecalling:
    input: 
        lambda wildcards: f"{in_dir}/{wildcards.part}"
    output: 
        "{out_dir}/basecalling/{part}_bc.bam",
    params: 
        dorado = {dorado_exec},
        base_model = lambda wildcards: f"{dorado_models_dir}/{base_model}",
        modified_bases_models = lambda wildcards: f"{dorado_models_dir}/{model_6mA},{dorado_models_dir}/{model_5mC}",
    shell:
        """
        ## Run basecalling
        {params.dorado} basecaller {params.base_model} {input} --min-qscore 8 \
        --modified-bases-models {params.modified_bases_models} \
        --device "cuda:all" --verbose --batchsize 256 > {output}
        """

