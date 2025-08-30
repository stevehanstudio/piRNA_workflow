# Dataset Recommendations for ChIP-seq Pipeline

## Current Dataset Issues

The current dataset (SRR030295/SRR030270) has **very poor quality**:
- **100% of reads dropped** with standard Trimmomatic parameters
- **Very low quality scores** (lots of `?` characters in FASTQ)
- **Old sequencing technology** (likely from early 2000s)
- **Requires extremely lenient parameters** to retain any reads

> **⚠️ Warning**: These datasets are primarily for testing pipeline functionality. For production analysis, use high-quality datasets as recommended below.

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
```

### **Step 2: Quality Check**
```bash
# Run FastQC
fastqc SRR_NEW_DATASET_1.fastq.gz

# Check quality scores
head -1000 SRR_NEW_DATASET_1.fastq.gz | grep "^@" -A 1 -B 1 | tail -100
```

### **Step 3: Test Trimmomatic**
```bash
# Test with standard parameters
trimmomatic SE SRR_NEW_DATASET_1.fastq.gz test_trimmed.fastq \
    ILLUMINACLIP:AllAdaptors.fa:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:50

# Check survival rate
echo "Surviving reads: $(wc -l < test_trimmed.fastq | awk '{print $1/4}')"
```

### **Step 4: Expected Results**
- ✅ **>80% reads survive** Trimmomatic
- ✅ **Good quality scores** in FastQC
- ✅ **Low adapter content** (<5%)
- ✅ **Consistent read lengths**

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
1. **Run FastQC** on sample data
2. **Test Trimmomatic** with standard parameters
3. **Verify mapping rates** with Bowtie
4. **Check for technical artifacts**

### **Phase 3: Pipeline Testing**
1. **Update Snakefile** with new sample names
2. **Test complete pipeline** with new data
3. **Verify all outputs** are generated correctly
4. **Document results** and quality metrics

### **Phase 4: Documentation Update**
1. **Update README.md** with new dataset info
2. **Modify CHANGELOG.md** to reflect changes
3. **Update sample configuration** in Snakefile
4. **Test with standard parameters** throughout

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

## Next Steps

1. **Search for high-quality datasets** using the strategies above
2. **Download and test** sample data for quality
3. **Update pipeline configuration** with new datasets
4. **Test complete pipeline** with standard parameters
5. **Update documentation** with new dataset information

This will provide a much better demonstration of the pipeline's capabilities and ensure reproducible, high-quality results.

## Related Documentation

- **[Main README](README.md)**: Comprehensive pipeline documentation
- **[Quick Setup Guide](QUICK_SETUP.md)**: Fast setup instructions
- **[Main Project README](../README.md)**: Overview of the entire project

---

**Last Updated**: December 2024  
**Status**: Active Development  
**Priority**: High - Dataset quality significantly impacts pipeline performance 