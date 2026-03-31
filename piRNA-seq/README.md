# piRNA-seq Analysis Pipeline (Snakemake)

Snakemake workflow aligned to [Luo 2025 piRNA-seq.md](https://github.com/Peng-He-Lab/Luo_2025_piRNA/blob/main/piRNA-seq.md) for trimming, length filtering (23–29 nt), Bowtie flags, `samtools` 0.1.8 / 0.1.16 usage, full-library vector mapping (`42AB_UASG`), and chrM filtering.

## Why `42AB_UASG` (not `42AB_UBIG`)?

`42AB_UBIG` is the vector bundled for **ChIP-seq / totalRNA-seq** in this repo ([Peng-He-Lab DataFiles](https://github.com/Peng-He-Lab/Luo_2025_piRNA/tree/main/DataFiles)). The **piRNA** protocol in `piRNA-seq.md` maps to **`42AB_UASG`**, so this workflow uses that index prefix by default.

## Tool versions (Apptainer)

With `./run_workflow.sh 2 run --use-apptainer`, Snakemake runs inside `containers/pirna_pipeline.sif`, which already includes:

| Tool | Version / source |
|------|------------------|
| FastQC | 0.11.3 (zip install) |
| cutadapt | 1.8.3 (`pip` in a minimal conda env at build time) |
| Bowtie | 1.0.1 [Peng-He-Lab hamrhein_nh patch](https://github.com/Peng-He-Lab/bowtie-1.0.1-hamrhein_nh_patch) (compiled) |
| samtools | 0.1.8 and 0.1.16 (compiled; `SAMTOOLS_018` / `SAMTOOLS_016` in the container) |
| deepTools | 2.4.2 (`pip` at build time) |

`run_workflow.sh` does **not** pass `--use-conda` for piRNA-seq, so rules use these binaries instead of `envs/core.yaml`.

## Vector Bowtie index

If `42AB_UASG.*.ebwt` files are missing but `42AB_UASG.fa` is present, the workflow runs `bowtie-build` once via the `bowtie_index_vector` rule:

```bash
bowtie-build Shared/DataFiles/genomes/YichengVectors/42AB_UASG.fa Shared/DataFiles/genomes/YichengVectors/42AB_UASG
```

(prefix path without `.fa`, same as Bowtie expects).

## Quick start

```bash
./run_workflow.sh 2 run --use-apptainer --genome-version dm3 --dataset-path ./Shared/DataFiles/datasets/pirna-seq/your.fq.gz
```

For DAG checks without the Apptainer image, install `snakemake` on the host and run `snakemake -n all` from `piRNA-seq/` (rules still expect compatible `bowtie` / `samtools` on `PATH`).

## Pipeline steps (summary)

1. Raw FASTQC (`-k 6`)
2. Adapter trim (TruSeq small RNA adapter from `piRNA-seq.md`, `-m 15`)
3. Length filter 23–29 nt (`cutadapt -m/-M`)
4. Filtered FASTQC (`-k 6`)
5. `bowtie_index_vector` (if `.ebwt` missing)
6. Genome alignment + `samtools view` / `sort` (0.1.8 / 0.1.16)
7. Remove chrM (`egrep -v`, as in the published shell pipeline)
8. Optional MAPQ &gt; 0 filter → `*.genome.unique.bam` (Luo shell uses Bowtie `-m 1` only; set `analysis.mapq_filter_unique: false` in `config.yaml` for parity)
9. Vector alignment of the **full** 23–29 nt library (not genome-unmapped only)
10. Genome `bamCoverage` 10 bp bedgraph (from unique BAM)
11. Vector + (optional) transposon-cluster bedgraphs from `genome.te_regions` — 10/100/1000 bp, ± strand, then bedops/bedmap chop; set `te_regions: {}` to skip
12. Summary report

See `SMOKE_TEST.md` for dry-run expectations.

## Required inputs

- Sample FASTQ (`config.yaml` → `sample.fastq`)
- Genome FASTA + Bowtie index prefix (`genome.fasta`, `genome.bowtie_index`)
- `genome.chrom_sizes`
- `references.vector_index` → `42AB_UASG` prefix and `42AB_UASG.fa`

## Outputs

Under `results/`: `fastqc_raw/`, `fastqc_filtered/`, `trimmed/`, `mapping/` (including `*.genome.aln.bam` before chrM filter), `coverage/`, `reports/`.
