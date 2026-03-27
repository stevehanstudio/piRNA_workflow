# piRNA-seq Analysis Pipeline (Snakemake)

This directory contains the first MVP Snakemake implementation for piRNA-seq conversion.

## Scope of This MVP

The current workflow provides a dry-run and smoke-testable rule graph for:

1. Raw FASTQ QC
2. Adapter trimming
3. piRNA size selection
4. Genome mapping
5. Unique-read filtering
6. Non-genome read extraction
7. Vector mapping
8. Coverage bedgraph generation
9. Summary report generation

This is intended as the implementation baseline for iterative parity work against the original shell pipeline.

## Quick Start

```bash
cd piRNA-seq
conda activate snakemake_env
snakemake --use-conda --cores 8 --dry-run
```

If the configured sample FASTQ is not present yet, the workflow can bootstrap a tiny synthetic FASTQ for DAG validation during dry-run.

For reproducible smoke-test steps and expected output, see `SMOKE_TEST.md`.

## Required Inputs

- `config.yaml` sample FASTQ (`sample.fastq`)
- Bowtie genome index prefix (`genome.bowtie_index`)
- Bowtie vector index prefix (`references.vector_index`)
- Genome chromosome sizes file (`genome.chrom_sizes`)

## Outputs

Primary outputs are written under `results/`:

- `fastqc_raw/` and `fastqc_filtered/`
- `trimmed/`
- `mapping/`
- `coverage/`
- `reports/`
