# Shared Resources

This folder contains resources shared between the CHIP-seq and totalRNA-seq workflows.

## Scripts/

### trimfastq.py
- **Source**: Original script from Georgi Marinov (modified 12/06/2012)
- **Purpose**: Trims FASTQ files to specified lengths with various options
- **Usage**: Used by both workflows for read length trimming
- **Dependencies**: Python 2.7 (legacy script, managed via conda environment)

### filter_trimfastq.py
- **Purpose**: Filters output from trimfastq.py to remove progress messages
- **Usage**: Used by totalRNA-seq workflow to clean up trimfastq.py output
- **Dependencies**: Python 2.7 (legacy script, managed via conda environment)

### makewigglefromBAM-NH.py
- **Purpose**: Converts BAM files to wiggle format for visualization
- **Usage**: Used by CHIP-seq workflow to generate BigWig tracks
- **Dependencies**: Python, samtools

## DataFiles/

### .gitignore
- **Purpose**: Common gitignore rules for both workflows
- **Usage**: Symbolically linked from both workflow directories
- **Contents**: Ignores common bioinformatics file types, results, and temporary files

### genome/
- **dm6.fa**: Drosophila melanogaster reference genome (dm6 assembly)
- **dm6.fa.fai**: Genome index file for samtools
- **dm6-blacklist.v2.bed.gz**: Blacklist regions for dm6 genome
- **AllAdaptors.fa**: Common adapter sequences for trimming

#### bowtie-indexes/
- **dm6.*.ebwt**: Bowtie index files for dm6 genome mapping
- **dm6.chrom.sizes**: Chromosome size information for dm6

#### annotations/
- **dm6.gtf**: Gene annotation file for dm6 genome

#### rrna/
- **dmel_rRNA_unit.*.ebwt**: Bowtie index files for rRNA removal

#### star-index/
- **Note**: STAR index files are generated during workflow execution

## datasets/

### chip-seq/
- **srr_datasets/**: Individual SRR datasets from public repositories
  - `SRR030270.fastq` (627MB) - ChIP-seq dataset
  - `SRR030295.fastq` (904MB) - ChIP-seq dataset  
  - `SRR030360.fastq` (132MB) - ChIP-seq dataset
  - `SRR10094667.fastq` (8.6GB) - ChIP-seq dataset
- **chip_inputs/**: ChIP input control datasets
  - `White_GLKD_ChIP_input_*.fastq` - White GLKD ChIP input samples
  - `Panx_GLKD_ChIP_input_*.fastq` - Panx GLKD ChIP input samples
- **combined/**: Merged and processed datasets
  - `all.fastq` (8.6GB) - Combined dataset for analysis

### totalrna-seq/
- **all.50mers.fastq** (6.1GB) - Length-trimmed totalRNA-seq dataset
- **all_cutadapt.50mers.fastq** (6.1GB) - Adapter-trimmed and length-trimmed dataset

## Benefits of Shared Resources

1. **Reduced Duplication**: No need to maintain multiple copies of the same scripts
2. **Easier Maintenance**: Update shared scripts in one location
3. **Consistency**: Both workflows use the same versions of shared tools
4. **Version Control**: Single source of truth for shared resources

## Workflow Integration

Both workflows reference these shared resources using relative paths:
- CHIP-seq: `../Shared/Scripts/`
- totalRNA-seq: `../Shared/Scripts/`

## Notes

- The trimfastq.py script requires Python 2.7 due to legacy dependencies (managed via conda environment)
- Both workflows maintain their own Snakefiles and configurations
- Shared resources are read-only from the workflow perspective
- Python 2.7 scripts are automatically managed by Snakemake conda environments

## Modern Alternatives

For new projects, consider replacing legacy Python 2.7 scripts with:
- **cutadapt**: Modern adapter trimming and length filtering
- **seqtk**: Fast sequence toolkit for read manipulation
- **bioawk**: Bioinformatics-aware awk for sequence processing

## Related Documentation

- **[Main Project README](../README.md)**: Overview of the entire piRNA workflow project
- **[CHIP-seq README](../CHIP-seq/README.md)**: ChIP-seq pipeline documentation
- **[TotalRNA-seq README](../totalRNA-seq/README.md)**: RNA-seq processing documentation

---

**Last Updated**: December 2024  
**Status**: Production Ready
