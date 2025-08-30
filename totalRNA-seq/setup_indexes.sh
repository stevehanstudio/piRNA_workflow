#!/bin/bash

# Setup script for totalRNA-seq workflow
# This script sets up all required indexes by calling scripts from Shared/Scripts

set -e

echo "Setting up indexes for totalRNA-seq workflow..."
echo "This script will create the required indexes for STAR alignment and vector mapping."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_SCRIPTS="${PROJECT_ROOT}/Shared/Scripts"

echo "Project root: $PROJECT_ROOT"
echo "Shared scripts: $SHARED_SCRIPTS"

# Check if Shared/Scripts directory exists
if [ ! -d "$SHARED_SCRIPTS" ]; then
    echo "Error: Shared/Scripts directory not found at $SHARED_SCRIPTS"
    exit 1
fi

# Step 1: Download GTF annotations (if needed)
echo ""
echo "Step 1: Checking GTF annotations..."
GTF_FILE="${SCRIPT_DIR}/indexes/annotations/dm6.gtf"
if [ ! -f "$GTF_FILE" ]; then
    echo "GTF file not found. Downloading..."
    bash "$SHARED_SCRIPTS/download_gtf.sh"
else
    echo "GTF file already exists: $GTF_FILE"
fi

# Step 2: Create rRNA index (if needed)
echo ""
echo "Step 2: Checking rRNA index..."
RRNA_INDEX="${SCRIPT_DIR}/indexes/rrna/dmel_rRNA_unit.1.ebwt"
if [ ! -f "$RRNA_INDEX" ]; then
    echo "rRNA index not found. Creating..."
    bash "$SHARED_SCRIPTS/create_rrna_index.sh"
else
    echo "rRNA index already exists: $RRNA_INDEX"
fi

# Step 3: Create STAR index (if needed)
echo ""
echo "Step 3: Checking STAR index..."
STAR_INDEX="${PROJECT_ROOT}/Shared/DataFiles/genome/star-index/genomeParameters.txt"
if [ ! -f "$STAR_INDEX" ]; then
    echo "STAR index not found. Creating..."
    bash "$SHARED_SCRIPTS/create_star_index.sh"
else
    echo "STAR index already exists: $STAR_INDEX"
fi

# Step 4: Recreate STAR index with GTF annotations
echo ""
echo "Step 4: Recreating STAR index with GTF annotations..."
bash "$SHARED_SCRIPTS/recreate_star_index_with_gtf.sh"

echo ""
echo "Setup complete! All required indexes have been created."
echo "You can now run the snakemake workflow."
