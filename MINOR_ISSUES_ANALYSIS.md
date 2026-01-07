# Minor Issues Analysis: Deviations from Original Pipeline

**Date:** January 6, 2026  
**Purpose:** Investigate if the 2 minor issues are actual deviations from the original pipeline

---

## Issue #1: Bedmap Interpolation - **CONFIRMED DEVIATION** ⚠️

### Original Pipeline (ChIP-seq.md, lines 107, 126-131)

**For Vector Coverage:**
```bash
awk -vOFS="\t" '{ print $1, $2, $3, ".", $4 }' $bg4 > signal.bed
bedops --chop $i signal.bed | bedmap --echo --echo-map-score - signal.bed \
       | sed -e 's/|/\t/g' > $bg4.chopped.bg4
```

**For Transposon Coverage (42AB and 20A):**
```bash
awk -vOFS="\t" '{ print $1, $2, $3, ".", $4 }' $bam.$i.42AB.bg4 > signal.bed
bedops --chop $i signal.bed | bedmap --echo --echo-map-score - signal.bed \
       | sed -e 's/|/\t/g' > $bam.$i.42AB.bg4chopped.bg4
```

**What it does:**
1. Converts bg4 to BED format (adds "." as 4th column)
2. `bedops --chop $i` - Chops into uniform bins of size `$i` (10, 50, 100, 500, 1000)
3. `bedmap --echo --echo-map-score - signal.bed` - **Interpolates scores from original bedgraph onto the chopped bins**
4. Converts pipe-delimited output to tab-delimited

**The interpolation step is critical:** It maps the original coverage scores onto the new uniform bins, ensuring continuous coverage values.

---

### Current Snakemake Implementation (Snakefile, lines 654, 686)

**For Coverage:**
```python
rule chop_bedgraph:
    shell:
        """
        bedops --chop {input.bg4} > {output.chopped}
        """
```

**For Transposon:**
```python
rule chop_bedgraph_transposon:
    shell:
        """
        bedops --chop {input.bg4} > {output.chopped}
        """
```

**What it does:**
1. Only chops into uniform bins
2. **Missing:** bedmap interpolation step
3. **Missing:** BED format conversion
4. **Missing:** Output format conversion (pipe to tab-delimited)

---

### Impact of Deviation

**What's missing:**
- ❌ **Score interpolation** - The chopped bins will have no coverage scores (just coordinates)
- ❌ **Uniform binning with preserved scores** - Original preserves coverage values when creating uniform bins

**Potential consequences:**
- Chopped bedgraph files will be empty or have no scores (just bin coordinates)
- Downstream analysis expecting interpolated scores will fail or give incorrect results
- Output will be fundamentally different from original pipeline

**This is a SIGNIFICANT deviation** that will affect analysis results.

---

## Issue #2: Transposon Region Flags - **CONFIRMED DEVIATION** ⚠️⚠️

### Original Pipeline (ChIP-seq.md, lines 119-124, 126-131)

**Transposon Coverage:**
```bash
# For 42AB transposon
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chr2R:2144349-2386719 -o $bam.$i.42AB.bg4
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chr2R:2144349-2386719 --samFlagInclude 16 -o $bam.$i.42AB.Minus.bg4
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chr2R:2144349-2386719 --samFlagExclude 16 -o $bam.$i.42AB.Plus.bg4

# For 20A transposon
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chrX:21392175-21431907 -o $bam.$i.20A.bg4
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chrX:21392175-21431907 --samFlagInclude 16 -o $bam.$i.20A.Minus.bg4
deepTools-2.4.2_develop/bin/bamCoverage -b $bam -of bedgraph -bs $i \
    --region chrX:21392175-21431907 --samFlagExclude 16 -o $bam.$i.20A.Plus.bg4
```

**What it does:**
- ✅ **42AB transposon:** Analyzes specific region `chr2R:2144349-2386719` (242,370 bp)
- ✅ **20A transposon:** Analyzes specific region `chrX:21392175-21431907` (39,732 bp)
- ✅ Uses `--region` flags to restrict analysis to these specific genomic regions
- ✅ Processes both transposons in parallel

**Coverage bins processed:** 10, 50, 100, 500, 1000 bp

---

### Current Snakemake Implementation (Snakefile, lines 658-675)

**Transposon Coverage:**
```python
rule bam_coverage_transposon:
    shell:
        """
        mkdir -p {RESULTS_DIR}/transposon
        EFFECTIVE_SIZE=$(awk '{{sum += $2}} END {{print sum}}' {input.chrom_sizes})
        bamCoverage -b {input.bam} -o {output.total} --binSize {wildcards.binsize} \
            --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE
        bamCoverage -b {input.bam} -o {output.minus} --binSize {wildcards.binsize} \
            --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand forward
        bamCoverage -b {input.bam} -o {output.plus} --binSize {wildcards.binsize} \
            --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE --filterRNAstrand reverse
        """
```

**What it does:**
- ❌ **No `--region` flags** - Analyzes entire genome instead of specific transposon regions
- ❌ **Only 42AB implemented** - 20A transposon completely missing
- ✅ Uses RPGC normalization (not in original, but this is an improvement)
- ✅ Uses `--filterRNAstrand` instead of `--samFlagInclude/Exclude` (acceptable)

**Coverage bins:** Only implements binsize wildcard (not multiple fixed bins: 10, 50, 100, 500, 1000)

---

### Impact of Deviation

**Missing `--region` flags:**
- ❌ Analyzes **entire genome** instead of specific transposon regions
- ❌ Coverage values will be averaged across entire genome (much lower signal)
- ❌ Transposon-specific enrichment will be diluted/diluted
- ❌ **Completely different analysis scope** - this is a major deviation

**Missing 20A transposon:**
- ❌ **Half of the transposon analysis is missing**
- ❌ Cannot compare 42AB vs 20A transposon enrichment
- ❌ Analysis is incomplete

**This is a CRITICAL deviation** that changes the entire analysis scope.

---

## Summary of Deviations

| Issue | Original Behavior | Current Implementation | Deviation Severity | Impact |
|-------|------------------|----------------------|-------------------|--------|
| **Bedmap Interpolation** | `bedops --chop \| bedmap --echo --echo-map-score` | `bedops --chop` only | ⚠️ **HIGH** | Chopped files will have no scores |
| **42AB Region Flag** | `--region chr2R:2144349-2386719` | No region flag | ⚠️⚠️ **CRITICAL** | Analyzes entire genome instead |
| **20A Transposon** | Full 20A analysis implemented | Missing entirely | ⚠️⚠️ **CRITICAL** | Half of analysis missing |

---

## Recommended Fixes

### Fix #1: Restore Bedmap Interpolation

**For `chop_bedgraph` rule:**
```python
shell:
    """
    # Convert bg4 to BED format (add "." as 4th column)
    awk -vOFS="\t" '{{ print $1, $2, $3, ".", $4 }}' {input.bg4} > signal.bed
    # Chop into uniform bins and interpolate scores
    bedops --chop {wildcards.binsize} signal.bed | \
        bedmap --echo --echo-map-score - signal.bed | \
        sed -e 's/|/\t/g' > {output.chopped}
    rm signal.bed
    """
```

**For `chop_bedgraph_transposon` rule:**
```python
shell:
    """
    awk -vOFS="\t" '{{ print $1, $2, $3, ".", $4 }}' {input.bg4} > signal.bed
    bedops --chop {wildcards.binsize} signal.bed | \
        bedmap --echo --echo-map-score - signal.bed | \
        sed -e 's/|/\t/g' > {output.chopped}
    rm signal.bed
    """
```

### Fix #2: Add Transposon Region Flags

**Add to config.yaml:**
```yaml
genome:
  transposon_regions:
    dm3:
      "42AB": "chr2R:2144349-2386719"
      "20A": "chrX:21392175-21431907"
    dm6:
      "42AB": "chr2R:2144349-2386719"  # Need to convert coordinates
      "20A": "chrX:21392175-21431907"  # Need to convert coordinates
```

**Modify `bam_coverage_transposon` rule:**
```python
rule bam_coverage_transposon:
    output:
        total = RESULTS_DIR + "/transposon/{sample}.{binsize}.{transposon}.bg4",
        minus = RESULTS_DIR + "/transposon/{sample}.{binsize}.{transposon}.Minus.bg4",
        plus = RESULTS_DIR + "/transposon/{sample}.{binsize}.{transposon}.Plus.bg4"
    shell:
        """
        mkdir -p {RESULTS_DIR}/transposon
        EFFECTIVE_SIZE=$(awk '{{sum += $2}} END {{print sum}}' {input.chrom_sizes})
        REGION={config['genome']['transposon_regions'][config['genome']['version']][wildcards.transposon]}
        bamCoverage -b {input.bam} -o {output.total} --binSize {wildcards.binsize} \
            --region $REGION --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE
        bamCoverage -b {input.bam} -o {output.minus} --binSize {wildcards.binsize} \
            --region $REGION --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE \
            --filterRNAstrand forward
        bamCoverage -b {input.bam} -o {output.plus} --binSize {wildcards.binsize} \
            --region $REGION --normalizeUsing RPGC --effectiveGenomeSize $EFFECTIVE_SIZE \
            --filterRNAstrand reverse
        """
```

**Add expand for 20A transposon:**
```python
# In the expand() calls for transposon analysis
expand(
    RESULTS_DIR + "/transposon/{{sample}}.{{binsize}}.{{transposon}}.{{strand}}.bg4",
    sample=SAMPLES,
    binsize=TRANSPOSON_BINSIZES,
    transposon=["42AB", "20A"],  # Add 20A
    strand=["total", "Minus", "Plus"]
)
```

---

## Conclusion

**Both issues are CONFIRMED DEVIATIONS from the original pipeline:**

1. ⚠️ **Bedmap interpolation is missing** - This will result in empty or incorrect chopped bedgraph files
2. ⚠️⚠️ **Transposon region flags are missing** - This fundamentally changes the analysis scope (entire genome vs specific regions)
3. ⚠️⚠️ **20A transposon is missing** - This is incomplete analysis

**These are not minor issues - they are significant deviations that will affect analysis results.**

**Recommendation:** Fix both issues before using the pipeline for production analysis.

