# Dataset Recommendations for ChIP-seq Pipeline

## Required Input Files

### **Complete File Requirements**

The ChIP-seq workflow requires the following files to be present before running:

#### **1. Reference Genome Files**
- `dm6.fa` - Drosophila melanogaster reference genome (dm6 assembly)
- `dm6-blacklist.v2.bed.gz` - Genomic blacklist regions
- `dm6.chrom.sizes` - Chromosome sizes file

#### **2. Bowtie Index Files** (either pre-built OR source files)
- **Option A: Pre-built indexes** (recommended for speed)
  - `dm6.1.ebwt`, `dm6.2.ebwt`, `dm6.3.ebwt`, `dm6.4.ebwt`
  - `dm6.rev.1.ebwt`, `dm6.rev.2.ebwt`
- **Option B: Source files** (workflow will build indexes)
  - `dm6.fa` (already required above)

#### **3. Vector Reference Files**
- `42AB_UBIG.fa` - Vector reference sequence
- **Vector indexes** (either pre-built OR source file)
  - **Option A: Pre-built indexes**
    - `42AB_UBIG.1.ebwt`, `42AB_UBIG.2.ebwt`, `42AB_UBIG.3.ebwt`, `42AB_UBIG.4.ebwt`
    - `42AB_UBIG.rev.1.ebwt`, `42AB_UBIG.rev.2.ebwt`
  - **Option B: Source file**
    - `42AB_UBIG.fa` (already required above)

#### **4. Adapter Sequences**
- `AllAdaptors.fa` - Adapter sequences for trimming

#### **5. Input Dataset Files**
- **ChIP sample FASTQ**: `{sample_name}.fastq` (e.g., `Panx_GLKD_ChIP_input_1st_S1_R1_001.fastq`)
- **Input control FASTQ**: `{sample_name}.fastq` (e.g., `Panx_GLKD_ChIP_input_2nd_S4_R1_001.fastq`)

#### **6. Python Scripts**
- `trimfastq.py` - Read trimming script
- `makewigglefromBAM-NH.py` - BigWig generation script

### **File Validation**

Use the workflow manager to validate all required files:

```bash
# Check if all required files are present
./run_workflow.sh 1 check-inputs

# Check with custom paths
./run_workflow.sh 1 check-inputs \
  --dataset-path /path/to/your/data \
  --genome-path /path/to/dm6.fa
```

## TotalRNA-seq Input Requirements

For completeness, the totalRNA-seq workflow requires:

#### **1. Input Dataset**
- `all.50mers.fastq` - Combined 50-mer reads dataset

#### **2. Reference Files** (same as ChIP-seq)
- `dm6.fa` - Reference genome
- `dm6.gtf` - Gene annotation file
- `dm6_chr_harmonized.gtf` - Chromosome-harmonized GTF

#### **3. rRNA Reference**
- `dmel_rRNA_unit.fa` - Ribosomal RNA sequences
- **rRNA indexes** (pre-built OR source file)

#### **4. Vector Files** (same as ChIP-seq)
- `42AB_UBIG.fa` and indexes

#### **5. Python Scripts**
- `trimfastq.py` - Read trimming script

**Validation:**
```bash
./run_workflow.sh 4 check-inputs
```

## Using Custom Datasets

The workflow manager (`run_workflow.sh`) supports flexible dataset configuration, making it easy to test different datasets without modifying configuration files.

### **Quick Start with Custom Dataset**

#### **Option 1: Interactive Mode**
```bash
# Run workflow manager without arguments for interactive prompts
./run_workflow.sh

# You'll be prompted for:
# 1. Workflow selection (1 for ChIP-seq)
# 2. Custom dataset path (or press Enter for default)
# 3. Other paths if needed (genome, indexes, etc.)
# 4. Number of cores to use
```

#### **Option 2: Command-Line Mode**
```bash
# Specify custom dataset path directly
./run_workflow.sh 1 run --dataset-path /path/to/your/chip-seq/data

# Test with dry-run first
./run_workflow.sh 1 dryrun --dataset-path /path/to/your/chip-seq/data

# Override multiple paths at once
./run_workflow.sh 1 run \
    --dataset-path /path/to/data \
    --genome-path /path/to/genome.fa \
    --cores 8
```

### **Testing a New Dataset**
```bash
# 1. Download and prepare your dataset
fastq-dump --split-3 --gzip SRR_NEW_DATASET

# 2. Test quality
fastqc SRR_NEW_DATASET_1.fastq.gz

# 3. Dry-run with the new dataset
./run_workflow.sh 1 dryrun --dataset-path /path/to/new/dataset

# 4. Run the pipeline
./run_workflow.sh 1 run --dataset-path /path/to/new/dataset --cores 8
```

### **Benefits of This Approach**
- ✅ **No config file editing** required
- ✅ **Easy A/B testing** of different datasets
- ✅ **Original configs preserved** (creates temporary override)
- ✅ **Quick validation** with check-inputs command
- ✅ **Interactive prompts** guide you through setup

## Recommended High-Quality Datasets

### 🎯 **Option 1: Recent ENCODE Datasets (Recommended)**

#### **Search Strategy:**
1. Visit [ENCODE Portal](https://www.encodeproject.org/)
2. Search: "Drosophila melanogaster" + "ChIP-seq"
3. Filter by: "Released" + "High quality" + "2020-2024"

#### **Expected Quality:**
- **Illumina NextSeq/HiSeq** sequencing
- **High quality scores** (Phred scores >30)
- **Standard Trimmomatic parameters** work well
- **Good mapping rates** (>80%)

### 🎯 **Option 2: Recent Publications (2020-2024)**

#### **Search Strategy:**
1. Search [NCBI SRA](https://www.ncbi.nlm.nih.gov/sra) for:
   ```
   "Drosophila melanogaster"[Organism] AND "ChIP-seq"[Strategy] AND "2020:2024"[dp]
   ```

2. Look for datasets with:
   - **Recent publication dates**
   - **High read counts** (>10M reads)
   - **Good quality metrics**

#### **Example Search Terms:**
- `"Drosophila melanogaster ChIP-seq 2023"`
- `"Drosophila melanogaster H3K27Ac 2024"`
- `"Drosophila melanogaster transcription factors 2023"`

### 🎯 **Option 3: Specific High-Quality Datasets**

#### **Known Good Datasets:**
```bash
# These are examples - verify availability before using
SRR12345678  # H3K27Ac ChIP - 2023 study
SRR12345679  # Input control - matching sample
```

#### **How to Verify Quality:**
```bash
# Download a small sample and check quality
fastq-dump --split-3 --gzip SRR12345678 -X 10000
fastqc SRR12345678_1.fastq.gz
```

### 🎯 **Option 4: Simulated Test Data**

#### **Create Synthetic Dataset:**
```bash
# Generate high-quality synthetic reads
wgsim -N 1000000 -1 50 -2 0 dm6.fa test_chip.fastq /dev/null
wgsim -N 1000000 -1 50 -2 0 dm6.fa test_input.fastq /dev/null
```

## Quality Assessment Criteria

### **1. Sequencing Technology**
- ✅ **Illumina NextSeq/HiSeq** (2015+)
- ✅ **High-throughput sequencing**
- ❌ **Old Sanger sequencing**
- ❌ **Very old Illumina platforms**

### **2. Quality Scores**
- ✅ **Phred scores >30** (most bases)
- ✅ **Consistent quality** across reads
- ❌ **Many low-quality bases** (`?`, `!`, `"`)
- ❌ **Poor quality at read ends**

### **3. Read Length**
- ✅ **50-150bp reads** (standard for ChIP-seq)
- ✅ **Consistent length** across dataset
- ❌ **Very short reads** (<30bp)
- ❌ **Highly variable lengths**

### **4. Adapter Content**
- ✅ **Low adapter contamination** (<5%)
- ✅ **Clean read ends**
- ❌ **High adapter content** (>10%)
- ❌ **Multiple adapter types**

## Testing New Datasets

### **Step 1: Download Sample**
```bash
# Download first 10,000 reads for testing
fastq-dump --split-3 --gzip SRR_NEW_DATASET -X 10000

# Place in a test directory
mkdir -p test_datasets/chip-seq
mv SRR_NEW_DATASET*.fastq.gz test_datasets/chip-seq/
```

### **Step 2: Quality Check**
```bash
# Run FastQC
fastqc test_datasets/chip-seq/SRR_NEW_DATASET*.fastq.gz

# Check quality scores manually
zcat test_datasets/chip-seq/SRR_NEW_DATASET_1.fastq.gz | head -400 | tail -100
```

### **Step 3: Test with Workflow Manager**
```bash
# Validate input files (checks if all required files exist)
./run_workflow.sh 1 check-inputs --dataset-path test_datasets/chip-seq

# Dry-run to see what will execute
./run_workflow.sh 1 dryrun --dataset-path test_datasets/chip-seq

# Run the pipeline
./run_workflow.sh 1 run --dataset-path test_datasets/chip-seq --cores 4
```

### **Step 4: Evaluate Results**
```bash
# Check FastQC reports in results
ls -la CHIP-seq/results/fastqc_trimmed/

# Check mapping rates
grep "overall alignment rate" CHIP-seq/results/bowtie/*.sam

# Verify BigWig tracks were generated
ls -la CHIP-seq/results/bowtie/*.bigwig
```

### **Expected Results**
- ✅ **>80% reads survive** trimming steps
- ✅ **Good quality scores** in FastQC reports
- ✅ **High mapping rates** (>70%)
- ✅ **Clean BigWig tracks** generated

## Recommended Search Strategy

### **1. ENCODE Portal Search**
```bash
# Visit: https://www.encodeproject.org/
# Search: "Drosophila melanogaster" + "ChIP-seq"
# Filter: Released, High quality, 2020-2024
```

### **2. NCBI SRA Search**
```bash
# Advanced search with quality filters
# Organism: Drosophila melanogaster
# Strategy: ChIP-seq
# Date: 2020-2024
# Platform: Illumina
```

### **3. GEO Database Search**
```bash
# Visit: https://www.ncbi.nlm.nih.gov/geo/
# Search: "Drosophila melanogaster ChIP-seq"
# Filter by: Recent publications, High quality
```

### **4. Literature Search**
```bash
# Search recent papers for:
# - "Drosophila melanogaster ChIP-seq"
# - "High-quality sequencing data"
# - "Illumina NextSeq/HiSeq"
```

## Implementation Plan

### **Phase 1: Dataset Identification**
1. **Search ENCODE portal** for recent datasets
2. **Check NCBI SRA** for high-quality options
3. **Review recent publications** for data availability
4. **Download sample data** for quality testing

### **Phase 2: Quality Testing**
```bash
# Download candidate dataset
fastq-dump --split-3 --gzip SRR_CANDIDATE -X 10000

# Run quality checks
fastqc SRR_CANDIDATE*.fastq.gz

# Test with workflow manager (dry-run)
./run_workflow.sh 1 dryrun --dataset-path /path/to/SRR_CANDIDATE
```

### **Phase 3: Pipeline Testing**
```bash
# Run complete pipeline with new dataset
./run_workflow.sh 1 run --dataset-path /path/to/SRR_CANDIDATE --cores 8

# Verify all outputs are generated
./run_workflow.sh 1 status

# Check quality metrics
ls -la CHIP-seq/results/
```

### **Phase 4: Adoption (Optional)**
If the new dataset is better than the default:
1. **Update config.yaml** to use new dataset as default
2. **Document dataset details** in README.md
3. **Commit changes** to repository
4. **Update documentation** with quality metrics

> **Note**: With the workflow manager, you don't need to modify configuration files to test datasets. Only update the default config if you want to permanently adopt a new dataset.

## Expected Benefits

### **With High-Quality Dataset:**
- ✅ **Standard Trimmomatic parameters** work well
- ✅ **High mapping rates** (>80%)
- ✅ **Good quality BigWig tracks**
- ✅ **Reliable enrichment analysis**
- ✅ **Reproducible results**

### **Current Dataset Issues:**
- ❌ **Requires custom parameters** for poor quality
- ❌ **Low mapping rates** due to quality issues
- ❌ **Unreliable enrichment analysis**
- ❌ **Poor demonstration** of pipeline capabilities

## Quick Reference Commands

### **Finding and Testing New Datasets**
```bash
# 1. Search and download a candidate dataset
fastq-dump --split-3 --gzip SRR_CANDIDATE

# 2. Quick quality check
fastqc SRR_CANDIDATE*.fastq.gz

# 3. Test with workflow manager
./run_workflow.sh 1 check-inputs --dataset-path /path/to/SRR_CANDIDATE
./run_workflow.sh 1 dryrun --dataset-path /path/to/SRR_CANDIDATE

# 4. Run full pipeline
./run_workflow.sh 1 run --dataset-path /path/to/SRR_CANDIDATE --cores 8

# 5. Compare results with default dataset
ls -la CHIP-seq/results/
```

### **Comparing Multiple Datasets**
```bash
# Test dataset A
./run_workflow.sh 1 run --dataset-path /path/to/datasetA --cores 8
mv CHIP-seq/results CHIP-seq/results_datasetA

# Test dataset B
./run_workflow.sh 1 run --dataset-path /path/to/datasetB --cores 8
mv CHIP-seq/results CHIP-seq/results_datasetB

# Compare quality metrics
grep "overall alignment rate" CHIP-seq/results_datasetA/bowtie/*.sam
grep "overall alignment rate" CHIP-seq/results_datasetB/bowtie/*.sam
```

## Next Steps

1. **Search for high-quality datasets** using the strategies above
2. **Download and test** sample data for quality
3. **Test with workflow manager** using `--dataset-path` option
4. **Compare results** with default dataset
5. **Optionally update** config.yaml if new dataset is superior

This will provide a much better demonstration of the pipeline's capabilities and ensure reproducible, high-quality results.

## Related Documentation

- **[ChIP-seq Pipeline README](README.md)**: Comprehensive pipeline documentation
- **[Workflow Manager Guide](../WORKFLOW_MANAGER.md)**: Complete guide to run_workflow.sh features
- **[Main Project README](../README.md)**: Overview of the entire project
