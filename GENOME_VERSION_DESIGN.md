# Genome Version Support Design Document

**Date:** November 7, 2025  
**Status:** Design Phase  
**Goal:** Make ChIP-seq and totalRNA-seq workflows genome-agnostic to support multiple species

---

## Table of Contents
1. [Current State Analysis](#current-state-analysis)
2. [Proposed Design](#proposed-design)
3. [Implementation Plan](#implementation-plan)
4. [Examples](#examples)
5. [Migration Strategy](#migration-strategy)
6. [Testing Plan](#testing-plan)

---

## Current State Analysis

### Hardcoded Elements in CHIP-seq Workflow

#### Config.yaml
```yaml
references:
  dm6_fasta: "../Shared/DataFiles/genome/dm6.fa"
  dm6_blacklist: "../Shared/DataFiles/genome/dm6-blacklist.v2.bed.gz"
  dm6_chrom_sizes: "../Shared/DataFiles/genome/bowtie-indexes/dm6.chrom.sizes"
  dm6_bowtie_index: "../Shared/DataFiles/genome/bowtie-indexes/dm6"
```

#### Snakefile (Line References)
- Line 22-25: Variable definitions with `dm6_` prefix
- Line 126: `rule build_dm6_bowtie_index`
- Line 167: Rule for building chromosome sizes
- Multiple output files use hardcoded sample names

**Issues:**
- Config keys are genome-specific (`dm6_fasta`, `dm6_blacklist`)
- Rule names include genome version
- No way to specify different genome without manual editing

### Hardcoded Elements in totalRNA-seq Workflow

#### Config.yaml
```yaml
rrna_index: "../Shared/DataFiles/genome/rrna/dmel_rRNA_unit"
# No genome configuration at all - hardcoded in Snakefile
```

#### Snakefile (Line References)
- Line 22: `DM6_REFERENCE = config.get("dm6_fasta", f"{SHARED_GENOME}/dm6.fa")`
- Line 23: `RRNA_REFERENCE = config.get("rrna_fasta", f"{SHARED_GENOME}/rrna/dmel_rRNA_unit.fa")`
- Line 29-30: `dm6.gtf` and `dm6_chr_harmonized.gtf`
- Line 53-62: All output files have `dm6.50mer` prefix
- Line 101: **Chromosome harmonization hardcoded for Drosophila**:
  ```python
  sed 's/^2L/chr2L/; s/^2R/chr2R/; s/^3L/chr3L/; s/^3R/chr3R/; s/^4/chr4/; s/^X/chrX/; s/^Y/chrY/; s/^mitochondrion_genome/chrM/'
  ```
- Line 233-260: Output filenames with `dm6` hardcoded

**Critical Issues:**
- Output file naming is genome-specific
- Chromosome harmonization only works for Drosophila
- Species-specific rRNA naming (`dmel_`)

---

## Proposed Design

### Design Principles

1. **Backward Compatibility**: Existing dm6 workflows should work without changes
2. **Minimal Config Changes**: Users should only need to specify genome version and paths
3. **Automatic Path Construction**: Derive related files from genome version where possible
4. **Flexible Naming**: Support different naming conventions per species
5. **Clear Defaults**: Sensible defaults for common genomes

### Configuration Structure

#### New Config Schema (Both Workflows)

```yaml
# Genome configuration
genome:
  version: "dm6"                    # e.g., dm6, hg38, mm10, ce11
  species: "drosophila"             # e.g., drosophila, human, mouse, celegans
  rrna_species: "dmel"              # Species code for rRNA (dmel, hsap, mmus, cele)
  chromosome_prefix: "chr"          # Prefix for chromosomes (chr, empty, etc.)
  
  # Paths - constructed automatically if not specified
  fasta: "../Shared/DataFiles/genome/{version}.fa"
  bowtie_index: "../Shared/DataFiles/genome/bowtie-indexes/{version}"
  chrom_sizes: "../Shared/DataFiles/genome/bowtie-indexes/{version}.chrom.sizes"
  
  # Optional files (not all genomes have these)
  blacklist: "../Shared/DataFiles/genome/{version}-blacklist.v2.bed.gz"  # Optional
  
  # Annotations
  gtf: "../Shared/DataFiles/genome/annotations/{version}.gtf"
  rrna_index: "../Shared/DataFiles/genome/rrna/{rrna_species}_rRNA_unit"

# Original config sections continue below...
samples:
  chip: "Panx_GLKD_ChIP_input_1st_S1_R1_001"
  input: "Panx_GLKD_ChIP_input_2nd_S4_R1_001"
# ... etc
```

#### Chromosome Harmonization Mapping

Create a new configuration file: `Shared/DataFiles/genome/chromosome_mappings.yaml`

```yaml
# Chromosome name harmonization for different species
drosophila:
  source_to_ucsc:
    "2L": "chr2L"
    "2R": "chr2R"
    "3L": "chr3L"
    "3R": "chr3R"
    "4": "chr4"
    "X": "chrX"
    "Y": "chrY"
    "mitochondrion_genome": "chrM"
