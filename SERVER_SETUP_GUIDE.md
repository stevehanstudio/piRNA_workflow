# Server Setup Guide

## Issue: Missing Required Files

When running on the server, the workflow requires specific input files. If files are missing, you have two options:

### Option 1: Provide Actual File Paths (Recommended)

When prompted for paths, **don't just press Enter** - provide the actual paths where files exist on the server:

```bash
./run_workflow.sh 1 run

# When prompted, enter actual paths:
Genome FASTA file path: /path/to/where/dm6.fa/actually/is
Bowtie index directory path: /path/to/where/bowtie/indexes/are
Input dataset directory path: /path/to/where/FASTQ/files/are
Vector index directory path: /path/to/where/vector/indexes/are  
Adapter sequences file path: /path/to/where/AllAdaptors.fa/is
```

### Option 2: Find Files on the Server

To locate files on the server, try:

```bash
# Find dm6.fa
find /mnt /home /data -name "dm6.fa" 2>/dev/null | head -5

# Find AllAdaptors.fa
find /mnt /home /data -name "AllAdaptors.fa" 2>/dev/null | head -5

# Find bowtie indexes
find /mnt /home /data -name "dm6.1.ebwt" 2>/dev/null | head -5

# Find vector files
find /mnt /home /data -name "42AB_UBIG.fa" 2>/dev/null | head -5
```

### Option 3: Use Environment Variables

You can also set environment variables before running:

```bash
export GENOME_PATH="/actual/path/to/dm6.fa"
export INDEX_PATH="/actual/path/to/bowtie-indexes/dm6"
export DATASET_PATH="/actual/path/to/chip-seq/chip_inputs"
export VECTOR_PATH="/actual/path/to/YichengVectors/42AB_UBIG"
export ADAPTER_PATH="/actual/path/to/AllAdaptors.fa"

./run_workflow.sh 1 run
```

### Option 4: Create Symbolic Links

If files exist elsewhere, create symlinks in the expected locations.

**Option A: Symlink the entire genomes directory** (recommended when data is on another drive):

```bash
# If your genome data lives on another drive (e.g. /mnt/data/...)
ln -s /actual/path/to/genomes ./Shared/DataFiles/genomes
```

When using the Apptainer pipeline container (`--use-apptainer`), the workflow manager automatically bind-mounts the symlink target so the path resolves inside the container. See WORKFLOW_MANAGER.md for details.

**Option B: Symlink individual files**:

```bash
# Create directory structure
mkdir -p ./Shared/DataFiles/genomes/bowtie-indexes
mkdir -p ./Shared/DataFiles/genomes/YichengVectors
mkdir -p ./Shared/DataFiles/datasets/chip-seq/chip_inputs

# Create symlinks to actual files
ln -s /actual/path/to/dm6.fa ./Shared/DataFiles/genomes/dm6.fa
ln -s /actual/path/to/AllAdaptors.fa ./Shared/DataFiles/genomes/AllAdaptors.fa
ln -s /actual/path/to/bowtie-indexes/dm6 ./Shared/DataFiles/genomes/bowtie-indexes/dm6
ln -s /actual/path/to/42AB_UBIG.fa ./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG.fa
```

### Required Files Summary

For CHIP-seq workflow, you need:

1. **Genome FASTA**: `dm6.fa`
2. **Genome indexes**: `dm6.1.ebwt`, `dm6.2.ebwt`, etc. (OR the workflow will build from dm6.fa)
3. **Chromosome sizes**: `dm6.chrom.sizes` (can be generated: `samtools faidx dm6.fa && cut -f1,2 dm6.fa.fai > dm6.chrom.sizes`)
4. **Blacklist**: `dm6-blacklist.v2.bed.gz` (optional but recommended)
5. **Adapter file**: `AllAdaptors.fa`
6. **Vector file**: `42AB_UBIG.fa` (OR indexes `42AB_UBIG.1.ebwt`, etc.)
7. **Input FASTQ files**: In the dataset directory

### Quick Check Command

Before running, verify files exist:

```bash
# Check with custom paths
./run_workflow.sh 1 check-inputs \
  --genome-path /path/to/dm6.fa \
  --index-path /path/to/bowtie-indexes/dm6 \
  --dataset-path /path/to/chip_inputs \
  --vector-path /path/to/YichengVectors/42AB_UBIG \
  --adapter-path /path/to/AllAdaptors.fa
```


