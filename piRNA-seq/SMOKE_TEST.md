# piRNA-seq Smoke Test

## Purpose

Provide a minimal, repeatable validation that the piRNA-seq MVP workflow can build a complete DAG with no external sample data pre-staged.

## Command

```bash
cd piRNA-seq
conda run -n snakemake_env snakemake --dry-run --cores 1
```

## Expected Result

- Exit code `0`
- DAG includes all MVP rules:
  - `bootstrap_example_fastq`
  - `fastqc_raw`
  - `trim_adapters`
  - `size_select_pirna`
  - `fastqc_filtered`
  - `map_genome`
  - `filter_unique_genome_reads`
  - `extract_non_genome_reads`
  - `map_vectors`
  - `coverage`
  - `summary_report`
  - `all`

## Latest Local Check

- Date: 2026-02-26
- Result: Pass (`12` jobs in dry-run DAG)
