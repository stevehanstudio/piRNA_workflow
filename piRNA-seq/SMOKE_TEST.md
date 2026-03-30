# piRNA-seq Smoke Test

## Purpose

Minimal validation that the piRNA-seq workflow defines a complete DAG.

## Command

```bash
cd piRNA-seq
snakemake -n all --cores 1
```

(Use `conda run -n snakemake_env snakemake ...` if Snakemake is only installed in that environment.)

## Expected Result

- Exit code `0`
- DAG includes at least these rules:

  - `bowtie_index_vector` (runs when `42AB_UASG.*.ebwt` are absent)
  - `fastqc_raw`
  - `trim_adapters`
  - `size_select_pirna`
  - `fastqc_filtered`
  - `map_genome_align`
  - `remove_chrM`
  - `filter_unique_genome_reads`
  - `map_vectors`
  - `coverage`
  - `summary_report`
  - `all`

## Latest Local Check

- Date: 2026-03-30
- Note: Rule set updated for Luo 2025 parity and `42AB_UASG`; job count depends on whether vector indexes already exist.
