#!/bin/bash

# ChIP-seq workflow with custom paths pointing to piRNA_workflow directory
# This allows testing the workflow without duplicating large reference files

./run_workflow.sh 1 run \
  --genome-path ~/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genome/dm6.fa \
  --index-path ~/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genome/bowtie-indexes/dm6 \
  --dataset-path ~/Projects/HeLab/piRNA_workflow/Shared/DataFiles/datasets/chip-seq/chip_inputs \
  --vector-path ~/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genome/YichengVectors/42AB_UBIG \
  --adapter-path ~/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genome/AllAdaptors.fa \
  --cores 12

