#!/bin/bash

# ChIP-seq workflow with custom paths pointing to piRNA_workflow directory
# This allows testing the workflow without duplicating large reference files

./run_workflow.sh 1 run \
  --genome-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/dm6.fa \
  --index-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/bowtie-indexes/dm6 \
  --dataset-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/datasets/chip-seq/chip_inputs \
  --vector-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/YichengVectors/42AB_UBIG \
  --adapter-path /mnt/dev0/hans/piRNA_workflow/Shared/DataFiles/genome/AllAdaptors.fa \
  --cores 12

