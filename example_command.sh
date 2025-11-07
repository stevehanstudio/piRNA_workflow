#!/bin/bash

# =============================================================================
# Instructions to Run Snakemake Workflow with Your Own Dataset
# =============================================================================

# STEP 1: Log in to the He Lab server
# ssh <your_username>@10.7.73.103

# STEP 2: Clone the repository
# git clone https://github.com/stevehanstudio/piRNA_workflow.git
# cd piRNA_workflow

# STEP 3: Create the snakemake conda environment (one-time setup)
# conda create -n snakemake_env -c bioconda -c conda-forge snakemake

# STEP 4: Run the workflow with your dataset
# 
# OPTION A: Interactive Mode (Recommended for first-time users)
# Simply run the script without arguments and follow the prompts:
# ./run_workflow.sh
# The script will interactively prompt you to:
#   - Select a workflow (1 for CHIP-seq, 4 for totalRNA-seq)
#   - Provide custom paths or use defaults from config.yaml
#   - Choose optimal core count based on system resources
#
# OPTION B: Command-line Mode (Recommended for automation/batch processing)
# Specify all parameters directly on the command line:

./run_workflow.sh 1 run \
  --genome-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/dm6.fa \
  --index-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/bowtie-indexes/dm6 \
  --dataset-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/datasets/chip-seq/chip_inputs \
  --vector-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/YichengVectors/42AB_UBIG \
  --adapter-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/AllAdaptors.fa \
  --cores 24

# NOTES:
# - The script will validate all input files before running
# - If --cores is not specified, the script will interactively prompt for optimal core count
# - To omit any path argument, the workflow will use defaults from config.yaml
# - For totalRNA-seq, change '1' to '4' and adjust paths accordingly
# - See WORKFLOW_MANAGER.md for detailed documentation and troubleshooting

