#!/bin/bash

# Script to download dm6 GTF annotations from Ensembl
# This will provide gene annotations needed for STAR transcriptome mode

set -e

echo "Downloading dm6 GTF annotations from Ensembl..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Define paths relative to project root
ANNOTATIONS_DIR="${PROJECT_ROOT}/totalRNA-seq/indexes/annotations"

# Create annotations directory
mkdir -p "$ANNOTATIONS_DIR"

# Download GTF file from Ensembl (BDGP6.32 = dm6)
echo "Downloading Drosophila_melanogaster.BDGP6.32.109.gtf.gz..."
wget -O "$ANNOTATIONS_DIR/dm6.gtf.gz" \
     "https://ftp.ensembl.org/pub/release-109/gtf/drosophila_melanogaster/Drosophila_melanogaster.BDGP6.32.109.gtf.gz"

# Uncompress the file
echo "Uncompressing GTF file..."
gunzip "$ANNOTATIONS_DIR/dm6.gtf.gz"

echo "GTF file downloaded successfully!"
echo "Location: $ANNOTATIONS_DIR/dm6.gtf"
echo "File size: $(du -h "$ANNOTATIONS_DIR/dm6.gtf" | cut -f1)"

# Now we need to recreate the STAR index with GTF annotations
echo ""
echo "Next step: Recreate STAR index with GTF annotations"
echo "Run: ./recreate_star_index_with_gtf.sh"

