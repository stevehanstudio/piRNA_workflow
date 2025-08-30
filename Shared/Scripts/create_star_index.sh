#!/bin/bash

# Script to create STAR genome index from dm6.fa
# This is a one-time setup that will make the STAR alignment work

set -e

echo "Creating STAR genome index from dm6.fa..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Debug: Show the paths
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"

# Define paths relative to project root
DM6_FA="${PROJECT_ROOT}/Shared/DataFiles/genome/dm6.fa"
STAR_INDEX_DIR="${PROJECT_ROOT}/Shared/DataFiles/genome/star-index"

# Debug: Show the calculated paths
echo "Calculated dm6.fa path: $DM6_FA"
echo "Calculated STAR index dir: $STAR_INDEX_DIR"

# Check if dm6.fa exists
if [ ! -f "$DM6_FA" ]; then
    echo "Error: dm6.fa not found at $DM6_FA"
    echo "Please ensure the file exists in the Shared/DataFiles/genome directory"
    exit 1
fi

# Create output directory
mkdir -p "$STAR_INDEX_DIR"

# Create STAR index
echo "Building STAR genome index..."
echo "Using genome file: $DM6_FA"
echo "Output directory: $STAR_INDEX_DIR"

STAR --runMode genomeGenerate \
     --genomeDir "$STAR_INDEX_DIR" \
     --genomeFastaFiles "$DM6_FA" \
     --runThreadN 8 \
     --genomeSAindexNbases 12

echo "STAR genome index created successfully!"
echo "Index location: $STAR_INDEX_DIR"
echo "You can now use '$STAR_INDEX_DIR' as the genome_dir in your workflow."

