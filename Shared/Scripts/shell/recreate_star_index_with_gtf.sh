#!/bin/bash

# Script to recreate STAR genome index with GTF annotations
# This will enable transcriptome mode and gene counting

set -e

echo "Recreating STAR genome index with GTF annotations..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define paths relative to project root
DM6_FA="${PROJECT_ROOT}/Shared/DataFiles/genomes/dm6.fa"
GTF_FILE="${PROJECT_ROOT}/totalRNA-seq/indexes/annotations/dm6.gtf"
STAR_INDEX_DIR="${PROJECT_ROOT}/Shared/DataFiles/genomes/star-index"

# Check if GTF file exists
if [ ! -f "$GTF_FILE" ]; then
    echo "Error: GTF file not found at $GTF_FILE"
    echo "Please ensure the file exists or run download_gtf.sh first."
    exit 1
fi

# Check if dm6.fa exists
if [ ! -f "$DM6_FA" ]; then
    echo "Error: dm6.fa not found at $DM6_FA"
    echo "Please ensure the file exists in the Shared/DataFiles/genomes directory"
    exit 1
fi

# Remove old index
echo "Removing old STAR index..."
rm -rf "$STAR_INDEX_DIR"

# Create new index with GTF annotations
echo "Creating new STAR index with GTF annotations..."
echo "Using genome file: $DM6_FA"
echo "Using GTF file: $GTF_FILE"
echo "Output directory: $STAR_INDEX_DIR"

STAR --runMode genomeGenerate \
     --genomeDir "$STAR_INDEX_DIR" \
     --genomeFastaFiles "$DM6_FA" \
     --sjdbGTFfile "$GTF_FILE" \
     --runThreadN 8 \
     --genomeSAindexNbases 12

echo "STAR genome index with GTF annotations created successfully!"
echo "Index location: $STAR_INDEX_DIR"
echo "Now the transcriptome mode should work in your workflow."

