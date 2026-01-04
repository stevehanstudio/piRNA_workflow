#!/bin/bash

# Script to create rRNA index from dm6 genome
# This extracts known rRNA regions and creates a bowtie index

set -e

echo "Creating rRNA index from dm6 genome..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define paths relative to project root
DM6_FA="${PROJECT_ROOT}/Shared/DataFiles/genomes/dm6.fa"
RRNA_INDEX_DIR="${PROJECT_ROOT}/totalRNA-seq/indexes/rrna"

# Check if dm6.fa exists
if [ ! -f "$DM6_FA" ]; then
    echo "Error: dm6.fa not found at $DM6_FA"
    echo "Please ensure the file exists in the Shared/DataFiles/genomes directory"
    exit 1
fi

# Create output directory
mkdir -p "$RRNA_INDEX_DIR/rrna_sequences"

# Extract mitochondrial rRNA (chrM contains rRNA genes)
echo "Extracting mitochondrial rRNA sequences..."
samtools faidx "$DM6_FA" chrM > "$RRNA_INDEX_DIR/rrna_sequences/dm6_mito_rRNA.fa"

# Create a simple rRNA index with common rRNA sequences
# For now, we'll use the mitochondrial genome as it contains rRNA genes
echo "Creating bowtie index..."
cd "$RRNA_INDEX_DIR"
bowtie-build rrna_sequences/dm6_mito_rRNA.fa dmel_rRNA_unit
cd "$PROJECT_ROOT"

echo "Ribosomal RNA index created successfully!"
echo "Index files: $RRNA_INDEX_DIR/dmel_rRNA_unit.*"
echo "You can now use '$RRNA_INDEX_DIR/dmel_rRNA_unit' as the rRNA index in your workflow."
