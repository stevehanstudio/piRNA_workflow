# TotalRNA-seq Processing Pipeline

This repository contains a Snakemake workflow for processing totalRNA-seq data, converting the original shell commands into a reproducible and scalable pipeline.

## Overview

The pipeline performs the following steps:
1. **Quality Control**: Initial FastQC analysis on raw reads
2. **Adapter Trimming**: Optional adapter removal using cutadapt
3. **Read Trimming**: Trims reads to a specified length using cutadapt
4. **Final Quality Control**: FastQC analysis on trimmed reads
5. **Ribosomal RNA Removal**: Maps reads against rRNA references using bowtie
6. **Transcriptome Alignment**: Maps unmapped reads to transcriptome using STAR
7. **Vector Mapping**: Maps unmapped reads to vector sequences using bowtie

## Prerequisites

- [Conda](https://docs.conda.io/en/latest/) or [Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- [Snakemake](https://snakemake.readthedocs.io/) (will be installed via conda)

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd totalRNA-seq
```

2. Install Snakemake and create conda environments:
```bash
# Install Snakemake
conda install -c bioconda -c conda-forge snakemake

# Create all conda environments
snakemake --use-conda --conda-create-envs-only
```

## Configuration

Edit `config.yaml` to customize your workflow:

```yaml
# Input file
fastq_file: "all.fastq"

# Read trimming parameters
read_length: 50

# Adapter sequences (leave empty if not trimming adapters)
adapters: "AGATCGGAAGAGC"
```

## Usage

### Basic Run

Run the complete workflow:
```bash
snakemake --use-conda
```

### Dry Run

Check what will be executed without running:
```bash
snakemake --use-conda --dryrun
```

### Run with Specific Number of Cores

```bash
snakemake --use-conda --cores 4
```

### Run Specific Rules

Run only the initial FastQC:
```bash
snakemake --use-conda fastqc_initial
```

Run only the trimming step:
```bash
snakemake --use-conda trim_reads
```

## Output Files

All outputs are organized in the `results/` directory:

- `results/fastqc_initial/` - Initial FastQC quality reports
- `results/fastqc_trimmed/` - FastQC quality reports after trimming
- `results/cutadapt/` - Adapter-trimmed reads (if adapters specified)
- `results/trimmed/` - Length-trimmed reads
- `results/rrna_removal/` - rRNA mapping results and unmapped reads
- `results/star_alignment/` - STAR alignment results and sorted BAM files
- `results/vector_mapping/` - Vector mapping results and sorted BAM files

## Workflow Rules

- `fastqc_initial`: Initial FastQC quality check
- `cutadapt_trim`: Optional adapter trimming
- `trim_reads`: Read trimming to specified length
- `fastqc_trimmed`: Final quality check on trimmed reads
- `rrna_removal`: Ribosomal RNA removal using bowtie
- `star_alignment`: Transcriptome alignment using STAR
- `vector_mapping`: Vector sequence mapping using bowtie

## Troubleshooting

### Conda Environment Issues

If you encounter conda environment problems:
```bash
# Remove and recreate environments
snakemake --use-conda --conda-clean-envs
snakemake --use-conda --conda-create-envs-only
```

### Python 2.7 Requirement

The `trimfastq.py` script requires Python 2.7. The conda environment `trimfastq.yaml` handles this automatically.

## Original Commands

This workflow replaces the following shell commands:

```bash
# Create directory
mkdir -p FastQCk6

# Initial FastQC
FastQC-0.11.3/fastqc all.fastq -o FastQCk6 -k 6

# Read trimming
python2 trimfastq.py all.fastq 50 stdout > allfastq50

# Final FastQC
FastQC-0.11.3/fastqc allfastq50 -o FastQCk6 -k 6

# Ribosomal RNA removal
bowtie dmel_rRNA_unit -p 8 -v 2 -k 1 --best -t --sam-nh -q \
    allfastq50 --un Unmapped50.fastq allfastq.rRNA.mapped50.map

# STAR alignment
STAR --genomeDir dm6/ --readFilesIn Unmapped50.fastq --runThreadN 8 \
     --genomeLoad NoSharedMemory --outFilterMultimapNmax 1 --alignSJoverhangMin 8 \
     --alignSJDBoverhangMin 1 --outFilterMismatchNmax 999 \
     --outFilterMismatchNoverReadLmax 0.0 --alignIntronMin 20 \
     --alignIntronMax 1000000 --alignMatesGapMax 1000000 \
     --outSAMheaderCommentFile COfile.txt --outSAMheaderHD @HD VN:1.4 SO:coordinate \
     --outSAMunmapped Within --outFilterType BySJout --outSAMattributes NH HI AS NM MD \
     --outSAMtype BAM SortedByCoordinate --quantMode TranscriptomeSAM GeneCounts \
     --sjdbScore 1 --limitBAMsortRAM 30000000000 --outFileNamePrefix dm6.50mer \
     --outSAMstrandField intronMotif

# Vector mapping
bowtie UBIG -p 8 --chunkmbs 1024 -v 0 -a -m 1 -t --sam-nh --best --strata -q --sam \
    Unmapped50.fastq -k 1 --al dm6.50mer.UBIG.vectoronly.fastq | \
    samtools view -F 4 -bT UBIG.fa - | samtools sort - dm6.50mer.UBIG.vectoronly.dup
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Add your license information here]
