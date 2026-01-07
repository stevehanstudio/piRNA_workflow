# CHIP-seq Pipeline Comparison: Original vs Snakemake

**Date:** January 6, 2026  
**Original Source:** [Peng-He-Lab/Luo_2025_piRNA/ChIP-seq.md](https://github.com/Peng-He-Lab/Luo_2025_piRNA/blob/main/ChIP-seq.md)  
**Snakemake Version:** `CHIP-seq/Snakefile`

---

## Executive Summary

| Component | Original | Snakemake | Status | Notes |
|-----------|----------|-----------|--------|-------|
| **Adapter Trimming** | 6 sequential cutadapt calls | Single cutadapt with file input | ✅ Fixed | Simplified, equivalent |
| **Trimmomatic** | `MAXINFO:35:0.9` | `LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15` | ⚠️ Different | Different quality filter |
| **Bowtie Mapping** | `--sam-nh` (patched) | `--sam-nh` (patched) + header fix | ✅ Fixed | Uses patched Bowtie, adds headers |
| **Vector Mapping Flags** | `-v 2 -k 1 -m 1` | `-v 2 -k 1 -m 1` | ✅ Fixed | Now matches original |
| **Duplicate Removal** | `rmdup -s` | `markdup` | ✅ Updated | Modern command |
| **wigToBigWig** | `-clip` flag | `-clip` flag | ✅ Fixed | Now includes clip flag |
| **RPGC Normalization** | Not specified | Dynamic calculation | ✅ Enhanced | Calculated from chrom.sizes |
| **Bedmap Interpolation** | `bedops --chop \| bedmap` | `bedops --chop` only | ⚠️ Simplified | Missing interpolation |
| **Transposon Regions** | `--region` flags specified | No `--region` flags | ⚠️ Missing | 20A also missing |
| **Genome Support** | dm3 only | Multi-genome (dm3, dm6, etc.) | ✅ Enhanced | Genome-agnostic |

---

## Detailed Step-by-Step Comparison

### 1. Quality Control (FastQC)

**Original:**
```bash
FastQC-0.11.3/fastqc all.fastq -o FastQCk6 -k 6
```

**Snakemake:**
```python
fastqc {input.fastq} -o {RESULTS_DIR}/fastqc_raw
```

**Status:** ✅ **Equivalent**  
**Notes:** Same functionality, different output directory structure.

---

### 2. Adapter Trimming

**Original:**
```bash
cutadapt -a CTGTCTCTTATACAC all.fastq | \
cutadapt -a CGTATGCCGTCTTCTGCTTG - | \
cutadapt -g TGCCGTCTTCTGCTTG - | \
cutadapt -g GGTAACTTTGTGTTT - | \
cutadapt -g CTTTGTGTTTGA - | \
cutadapt -a CACTCGTCGGCAGCGTTAGATGTGTATAAG - > trimmedfastq
```

**Snakemake:**
```python
cutadapt -a file:{input.adapters} -o {output.trimmed} {input.fastq}
```

**Status:** ✅ **Fixed/Improved**  
**Notes:**
- Original: 6 sequential `cutadapt` calls piped together
- Snakemake: Single call using adapter file (`AllAdaptors.fa`)
- **Equivalent functionality** - both remove all adapters, just different method
- Snakemake version is cleaner and easier to maintain

---

### 3. Quality Trimming (Trimmomatic)

**Original:**
```bash
trimmomatic-0.33.jar SE -threads 4 -trimlog trimmomatic.log trimmedfastq alltrimmedfastq \
ILLUMINACLIP:AllAdaptors.fa:2:30:10 MAXINFO:35:0.9 MINLEN:50
```

**Snakemake:**
```python
trimmomatic SE {input.fastq} {output.trimmed} \
    ILLUMINACLIP:{ADAPTERS_FILE}:2:30:10 \
    LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:50
```

**Status:** ⚠️ **Different Parameters**  
**Differences:**
- **Original:** `MAXINFO:35:0.9` - Adaptive quality filter based on information content
- **Snakemake:** `LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15` - Fixed quality thresholds

**Impact:**
- `MAXINFO` is more sophisticated - adapts to read quality
- Fixed thresholds may be more or less aggressive depending on data quality
- **Should verify:** Do both produce similar results?

---

### 4. Trim to 50bp

**Original:**
```bash
python trimfastq.py alltrimmedfastq 50 -stdout > allfastq50
```

**Snakemake:**
```python
python {TRIMFASTQ_SCRIPT} {input.alltrimmed} 50 -stdout 2>/dev/null > {output.trimmed_50bp}
```

**Status:** ✅ **Equivalent**  
**Notes:** Same command, just redirects stderr.

---

### 5. Genome Mapping (Bowtie)

**Original:**
```bash
bowtie-1.0.1/bowtie genome/bowtie-indexes/dm3 -p 8 -v 2 -k 1 -m 1 -t --sam-nh --best -y --strata -q \
 --sam allfastq50 | samtools-0.1.8/samtools view -bT genome/bowtie-indexes/dm3.fa - | \
 samtools-0.1.16/bin/samtools sort - dm3.50mer.unique.dup
```

**Snakemake:**
```python
{BOWTIE_CMD} {DM6_BOWTIE_INDEX} -p {threads} -v 2 -k 1 -m 1 -t --sam-nh --best --strata -y --quiet {input.trimmed_50bp} > {output.sam}
# Then separately:
# samtools_view -> samtools_sort_and_index
```

**Status:** ✅ **Fixed**  
**Differences:**
1. **Original:** Pipes directly to `samtools view -bT` (NO explicit header addition)
   - Uses older samtools-0.1.8 which may tolerate headerless SAM when `-T` reference is provided
   - The `-T` flag provides reference sequence info that may compensate for missing headers
2. **Snakemake:** Adds headers explicitly before `samtools view`
   - Required for newer samtools versions which strictly require SAM headers
   - Python script generates minimal headers from reference FASTA
3. **Flags:** Original uses both `--sam-nh` and `--sam` flags
   - Snakemake uses only `--sam-nh` throughout

**Notes:**
- `--sam-nh` creates SAM files **without headers**
- **Original does NOT add headers** - relies on older samtools + `-T` flag tolerance
- **Snakemake adds headers** - necessary for modern samtools compatibility
- This is a **necessary enhancement** for compatibility with current tool versions

---

### 6. Remove Mitochondrial Reads

**Original:**
```bash
samtools-0.1.16/bin/samtools view dm3.50mer.unique.dup.bam | egrep -v chrM | \
samtools-0.1.8/samtools view -bT genome/bowtie-indexes/dm3.fa - -o dm3.50mer.unique.dup.nochrM.bam
```

**Snakemake:**
```python
samtools view {input.sorted_bam} | egrep -v 'chrM' | samtools view -bT {DM6_REFERENCE} - > {output.no_mito_bam}
```

**Status:** ✅ **Equivalent**  
**Notes:** Same logic, just different variable names.

---

### 7. Duplicate Removal

**Original:**
```bash
samtools-0.1.16/bin/samtools rmdup -s dm3.50mer.unique.dup.nochrM.bam dm3.50mer.unique.nochrM.bam
```

**Snakemake:**
```python
samtools markdup {input.bam} {output.rmdup_bam}
```

**Status:** ✅ **Updated**  
**Notes:**
- `rmdup` is deprecated
- `markdup` is the modern replacement
- **Functionality is equivalent** - both remove duplicates

---

### 8. Vector Mapping

**Original:**
```bash
bowtie-1.0.1/bowtie genomes/YichengVectors/42AB_UBIG -p 8 -v 2 -k 1 -m 1 -t --sam-nh --best -y --strata -q \
 --sam allfastq50 | samtools-0.1.8/samtools view -bT genomes/YichengVectors/42AB_UBIG.fa - | \
 samtools-0.1.16/bin/samtools sort - dm3.50mer.42AB_UASG.vectoronly.dup
```

**Snakemake:**
```python
{BOWTIE_CMD} {VECTOR_42AB_INDEX} -p {threads} --chunkmbs 1024 -v 2 -k 1 -m 1 -t --sam-nh --best --strata -q {input.trimmed_50bp} > {output.sam}
# Then separately processes through samtools_view_vector -> samtools_sort_and_index_vector
```

**Status:** ✅ **Fixed**  
**Differences:**
1. **Snakemake adds:** `--chunkmbs 1024` (memory optimization)
2. **Original:** Pipes directly to `samtools view -bT` (NO explicit header addition)
   - Uses older samtools-0.1.8 which may handle headerless SAM with `-T` flag
3. **Snakemake:** Adds headers before processing (handles `--sam-nh` headerless output)
   - Python script generates headers from reference FASTA
   - Required for modern samtools compatibility
4. **Flags:** Now matches original (`-v 2 -k 1 -m 1`) ✅

---

### 9. BigWig Generation

**Original:**
```bash
python makewigglefromBAM-NH.py --- 50mer.unique.dup.nochrM.bam genome/bowtie-indexes/dm3.chrom.sizes \
dm3.50mer.unique.bg4 -notitle -uniqueBAM -RPM
wigToBigWig -clip dm3.50mer.unique.bg4 genome/bowtie-indexes/dm3.chrom.sizes dm3.50mer.unique.bigWig
```

**Snakemake:**
```python
python {MAKEWIGGLE_SCRIPT} --- {input.bam} {input.chrom_sizes} {output}.bg4 -notitle -uniqueBAM -RPM
wigToBigWig -clip {output}.bg4 {input.chrom_sizes} {output}
```

**Status:** ✅ **Fixed**  
**Notes:**
- Now includes `-clip` flag ✅
- Same Python script and parameters
- Equivalent functionality

---

### 10. Enrichment Track (ChIP vs Input)

**Original:**
```bash
deepTools-2.4.2_develop/bin/bamCompare -b1 ChIP.dm3.50mer.unique.dup.nochrM.bam -b2 Input.dm3.50mer.unique.dup.nochrM.bam \
    -of "bigwig" -o ChIP1.Enrichment.bigWig --binSize 10 -bl dm3-blacklist.bed -p 8
```

**Snakemake:**
```python
bamCompare -b1 {input.chip_bam} -b2 {input.input_bam} -of bigwig -o {output.enrichment_bigwig} --binSize 10 -bl {input.blacklist} -p {threads}
```

**Status:** ✅ **Equivalent**  
**Notes:** Same command, just parameterized.

---

### 11. Vector Coverage Analysis

**Original:**
```bash
for i in 10 100 1000
    do 
        while read bam
            do 
              bamCoverage -b $bam.bam  -of bedgraph -bs $i -o $bam.$i.bg4 
              bamCoverage -b $bam.bam  -of bedgraph -bs $i --samFlagInclude 16 -o $bam.$i.Minus.bg4
              bamCoverage -b $bam.bam  -of bedgraph -bs $i --samFlagExclude 16 -o $bam.$i.Plus.bg4
            done<bams
    done
```

**Snakemake:**
```python
EFFECTIVE_SIZE=$(awk '{sum += $2} END {print sum}' {input.chrom_sizes})
bamCoverage -b {input.bam} -o {output.total} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE
bamCoverage -b {input.bam} -o {output.minus} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand forward
bamCoverage -b {input.bam} -o {output.plus} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand reverse
```

**Status:** ⚠️ **Enhanced but Different**  
**Differences:**
1. **Original:** No normalization specified
2. **Snakemake:** Adds `--normalizeUsing RPGC --effectiveGenomeSize` (calculated dynamically)
3. **Strand filtering:**
   - Original: `--samFlagInclude/Exclude 16` (bitwise flag)
   - Snakemake: `--filterRNAstrand forward/reverse` (more explicit)

**Impact:**
- RPGC normalization is **beneficial** - makes coverage comparable across samples
- Strand filtering is equivalent, just different syntax
- **Should verify:** Does original pipeline normalize elsewhere?

---

### 12. Bedmap Interpolation

**Original:**
```bash
awk -vOFS="\t" '{ print $1, $2, $3, ".", $4 }' $bg4 > signal.bed
bedops --chop $i signal.bed | bedmap --echo --echo-map-score - signal.bed \
       | sed -e 's/|/\t/g' > $bg4.chopped.bg4
```

**Snakemake:**
```python
bedops --chop {input.bg4} > {output.chopped}
```

**Status:** ⚠️ **Simplified**  
**Missing:**
- `bedmap --echo --echo-map-score` interpolation step
- Score interpolation between bins

**Impact:**
- Original creates uniform bins AND interpolates scores
- Snakemake only creates uniform bins
- **Output will differ** - missing score interpolation

**Note:** Currently commented out in `rule all` (line 164-174)

---

### 13. Transposon Coverage Analysis

**Original:**
```bash
bamCoverage -b $bam  -of bedgraph -bs $i --region chr2R:2144349-2386719 -o $bam.$i.42AB.bg4
bamCoverage -b $bam  -of bedgraph -bs $i --region chr2R:2144349-2386719 --samFlagInclude 16 -o $bam.$i.42AB.Minus.bg4 
bamCoverage -b $bam  -of bedgraph -bs $i --region chr2R:2144349-2386719 --samFlagExclude 16 -o $bam.$i.42AB.Plus.bg4
# Same for 20A: chrX:21392175-21431907
```

**Snakemake:**
```python
EFFECTIVE_SIZE=$(awk '{sum += $2} END {print sum}' {input.chrom_sizes})
bamCoverage -b {input.bam} -o {output.total} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE
bamCoverage -b {input.bam} -o {output.minus} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand forward
bamCoverage -b {input.bam} -o {output.plus} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand reverse
```

**Status:** ⚠️ **Missing Region Specification**  
**Differences:**
1. **Original:** `--region chr2R:2144349-2386719` for 42AB
2. **Snakemake:** No `--region` flag - analyzes entire genome
3. **Original:** Also does 20A (`chrX:21392175-21431907`)
4. **Snakemake:** 20A is commented out (line 192-207)

**Impact:**
- Original is **more precise** - only analyzes specific transposon regions
- Snakemake analyzes entire genome, then presumably filters later
- **Should fix:** Add `--region` flags for accurate transposon-specific analysis

---

## Summary of Key Differences

### ✅ **Improvements in Snakemake Version:**
1. **Multi-genome support** - Works with dm3, dm6, and other genomes
2. **RPGC normalization** - Added to coverage analysis (original doesn't specify)
3. **Dynamic effective genome size** - Calculated from chrom.sizes
4. **Modern tools** - Uses `markdup` instead of deprecated `rmdup`
5. **Header handling** - Fixes `--sam-nh` headerless SAM issue
6. **Cleaner adapter trimming** - Single call with adapter file

### ⚠️ **Differences/Potential Issues:**
1. **Trimmomatic parameters** - Different quality filtering approach
2. **Bedmap interpolation** - Missing interpolation step (simplified)
3. **Transposon regions** - Missing `--region` flags (analyzes whole genome)
4. **20A transposon** - Not implemented (only 42AB)

### ✅ **Recently Fixed:**
1. ✅ Bowtie `--sam-nh` flag - Now uses patched Bowtie
2. ✅ Vector mapping flags - Now `-v 2 -k 1 -m 1` (matches original)
3. ✅ `wigToBigWig -clip` - Now includes clip flag
4. ✅ SAM header handling - Adds headers for `--sam-nh` output
5. ✅ Effective genome size - Now dynamic (not hardcoded)

---

## Recommendations

### **High Priority:**
1. **Verify Trimmomatic parameters** - Test if `MAXINFO:35:0.9` vs `LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15` produces similar results
2. **Add transposon region flags** - Use `--region` to analyze only specific transposon regions
3. **Test bedmap interpolation** - Determine if interpolation is needed for downstream analysis

### **Medium Priority:**
1. **Implement 20A transposon analysis** - If needed for your analyses
2. **Compare outputs** - Run both pipelines on same data and compare results

### **Low Priority:**
1. **Restore bedmap interpolation** - If required for publication/comparison
2. **Document parameter choices** - Explain why Trimmomatic parameters differ

---

## Verification Checklist

- [x] Bowtie mapping flags match original
- [x] Vector mapping flags match original  
- [x] `wigToBigWig -clip` flag present
- [x] SAM header handling for `--sam-nh` output
- [x] RPGC normalization with dynamic genome size
- [ ] Trimmomatic parameters tested/verified
- [ ] Transposon region flags added
- [ ] Bedmap interpolation verified/tested
- [ ] 20A transposon analysis implemented (if needed)

---

**Last Updated:** January 6, 2026

