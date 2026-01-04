# Yicheng's Issues Verification - After dm3 Run

**Date:** Check after dm3 pipeline run  
**Purpose:** Verify if previously identified issues are still present

---

## Issues Identified and Current Status

### ⚠️ **Issue 1: Bowtie flag `--sam-nh` - Modified Bowtie Required** - **PENDING**
**Location:** `rule bowtie_mapping` (line 304)

**Original Issue:** The original shell script used `--sam-nh` which exists in a **modified version of Bowtie** created by Henry, but not in standard Bowtie.

**Current Status:** ⚠️ **USING STANDARD BOWTIE (TEMPORARY)**
- Currently uses `--sam` flag (standard Bowtie flag)
- Waiting to obtain the modified Bowtie version from Henry
- Once available, should be updated to use `--sam-nh`

**Verification:**
```python
# Line 304 in CHIP-seq/Snakefile
bowtie {DM6_BOWTIE_INDEX} -p {threads} -v 2 -k 1 -m 1 -t --sam --best --strata -y --quiet
```

**Action Required:**
- Once modified Bowtie is obtained from Henry, update to:
  ```python
  bowtie ... --sam-nh --best --strata ...
  ```
- This is **not a bug** - it's a dependency on a specialized tool version
- Current implementation works with standard Bowtie as a temporary solution

---

### ⚠️ **Issue 2: Vector Mapping Flags** - **STILL PRESENT (INCORRECT)**
**Location:** `rule bowtie_vector_mapping` (line 388)

**Original Issue:** 
- Original had: `-v 2 -k 1 -m 1` (report 1 best alignment, allow 2 mismatches)
- Snakemake version incorrectly changed to: `-v 0 -a -m 1` (perfect matches only, report all alignments)
- The problem: `-a` (report all) with `-v 2` (2 mismatches) generated too many alignments and failed
- Workaround: `-v 0` (perfect matches only) was used to make it work
- **Correct fix:** Should be `-v 2 -k 1 -m 1` (report 1 best, allow 2 mismatches)

**Current Status:** ⚠️ **STILL HAS WORKAROUND**
- Line 388: `bowtie ... -v 0 -a -m 1 ...`
- Uses workaround (`-v 0`) instead of correct flags (`-v 2 -k 1 -m 1`)

**Current Code:**
```python
# Line 388 in CHIP-seq/Snakefile
bowtie {VECTOR_42AB_INDEX} -p {threads} --chunkmbs 1024 -v 0 -a -m 1 -t --sam --best --strata -q
```

**Should Be:**
```python
bowtie {VECTOR_42AB_INDEX} -p {threads} --chunkmbs 1024 -v 2 -k 1 -m 1 -t --sam --best --strata -q
```

**Impact:** 
- Currently only finds perfect matches (0 mismatches)
- Original pipeline allowed 2 mismatches for vector mapping
- May miss some vector reads with sequencing errors

---

### ✅ **Issue 3: Missing `-clip` flag in `wigToBigWig`** - **FIXED**
**Location:** `rule make_bigwig` (line 430)

**Original Issue:** The original shell script used `wigToBigWig -clip` but the Snakemake version was missing the `-clip` flag.

**Current Status:** ✅ **FIXED**
- Line 430: `wigToBigWig -clip {output}.bg4 {input.chrom_sizes} {output}`
- `-clip` flag now included

**Current Code:**
```python
# Line 430 in CHIP-seq/Snakefile
wigToBigWig -clip {output}.bg4 {input.chrom_sizes} {output}
```

**Impact:**
- The `-clip` flag clips wiggle data that extends beyond chromosome ends
- BigWig files will now be valid and properly handle edge cases at chromosome boundaries
- Consistent with original pipeline behavior

---

### ✅ **Issue 4: Duplicate Removal (`rmdup` vs `markdup`)** - **FIXED**
**Location:** `rule samtools_rmdup` (line 371)

**Original Issue:** Original used deprecated `samtools rmdup -s`, should use `samtools markdup`.

**Current Status:** ✅ **FIXED**
- Line 371: `samtools markdup {input.bam} {output.rmdup_bam}`
- Uses correct modern command

**Verification:**
```python
# Line 371 in CHIP-seq/Snakefile
samtools markdup {input.bam} {output.rmdup_bam}
```

---

### ✅ **Issue 5: Coverage Normalization (RPGC)** - **FIXED**
**Location:** `rule bam_coverage` and `rule bam_coverage_transposon` (lines 462-464, 492-494)

**Original Issue:** Missing RPGC normalization with effective genome size.

**Current Status:** ✅ **FIXED**
- Lines 462-464: `--normalizeUsing RPGC --effectiveGenomeSize 143726002`
- Properly normalized coverage tracks

**Verification:**
```python
# Lines 462-464 in CHIP-seq/Snakefile
bamCoverage -b {input.bam} -o {output.total} --binSize {wildcards.binsize} --normalizeUsing RPGC --effectiveGenomeSize 143726002
```

**Note:** The effective genome size (143726002) is hardcoded for dm6. This should be genome-specific when using dm3 or other genomes.

---

### ⚠️ **Issue 6: Strand Filtering (samFlagInclude/Exclude vs filterRNAstrand)** - **PARTIALLY FIXED**
**Location:** `rule bam_coverage` (lines 463-464)

**Original Issue:** Original used `samFlagInclude/Exclude 16` which is less clear than `filterRNAstrand`.

**Current Status:** ✅ **FIXED** (but check if correct for ChIP-seq)
- Lines 463-464: `--filterRNAstrand forward/reverse`
- More explicit than flag-based filtering

**Note:** `filterRNAstrand` is typically for RNA-seq. For ChIP-seq, we might need `--filterRNAstrand` or different approach depending on library type.

---

### ⚠️ **Issue 7: Bedmap Interpolation Removed** - **STILL PRESENT**
**Location:** `rule chop_bedgraph` and `rule chop_bedgraph_transposon` (lines 476, 506)

**Original Issue:** Original used `bedops --chop | bedmap` with interpolation. Snakemake version only uses `bedops --chop`.

**Current Status:** ⚠️ **SIMPLIFIED (MAY BE INTENTIONAL)**
- Line 476: `bedops --chop {input.bg4} > {output.chopped}`
- Missing bedmap interpolation step

**Impact:** 
- Only chops into uniform bins
- Doesn't interpolate scores like the original
- May be intentional simplification, but differs from original

---

### ⚠️ **Issue 8: Transposon Analysis - Missing Region Flags** - **STILL PRESENT**
**Location:** `rule bam_coverage_transposon` (lines 492-494)

**Original Issue:** Original had `--region` flags for specific transposon regions (42AB, 20A). Current version only does 42AB and lacks `--region` specification.

**Current Status:** ⚠️ **PARTIALLY IMPLEMENTED**
- Only implements 42AB transposon analysis
- 20A transposon is commented out/missing
- Missing `--region` flags for specific genomic regions

**Impact:**
- May analyze entire genome instead of specific transposon regions
- 20A transposon analysis not available

---

### ⚠️ **Issue 9: Hardcoded Effective Genome Size** - **STILL PRESENT**
**Location:** Multiple rules (lines 462, 463, 464, 492, 493, 494)

**Issue:** Effective genome size `143726002` is hardcoded for dm6. When using dm3 or other genomes, this should be genome-specific.

**Current Status:** ⚠️ **HARDCODED**
- `--effectiveGenomeSize 143726002` appears 6 times
- Should be dynamic based on `GENOME_VERSION`

**Impact:**
- Incorrect normalization when using dm3 or other genomes
- Coverage tracks will be incorrectly normalized

**Suggested Fix:**
- Add to config: `effective_genome_size: 143726002` for dm6, different value for dm3
- Use in rules: `--effectiveGenomeSize {config['genome']['effective_genome_size']}`

---

## Summary Table

| Issue | Status | Priority | Impact |
|-------|--------|----------|--------|
| 1. `--sam-nh` flag (modified Bowtie) | ⚠️ Pending | Low | Waiting for modified Bowtie from Henry |
| 2. Vector mapping flags (`-v 0` vs `-v 2 -k 1`) | ⚠️ Still present | **High** | May miss vector reads |
| 3. Missing `-clip` in wigToBigWig | ⚠️ Still present | **High** | Invalid BigWig data |
| 4. `rmdup` vs `markdup` | ✅ Fixed | - | - |
| 5. RPGC normalization | ✅ Fixed | - | - |
| 6. Strand filtering | ✅ Fixed | - | - |
| 7. Bedmap interpolation | ⚠️ Still present | Medium | Different output |
| 8. Transposon region flags | ⚠️ Still present | Medium | Less precise analysis |
| 9. Hardcoded genome size | ⚠️ Still present | **High** (for dm3) | Wrong normalization for dm3 |

---

## Critical Issues to Fix for dm3

**Still Present:**
1. **Vector mapping flags** (Issue #2) - Should allow 2 mismatches, not just perfect matches

**Fixed:**
- ✅ **Hardcoded effective genome size** (Issue #9) - Now dynamically calculated from chrom.sizes
- ✅ **Missing `-clip` flag** (Issue #3) - Added to `wigToBigWig` command

**Note:** Issue #1 (`--sam-nh` flag) is not a bug - it requires the modified Bowtie version from Henry. Current implementation uses standard Bowtie with `--sam` flag as a temporary solution.

---

## Recommendations

1. **Immediate fixes needed:**
   - Fix vector mapping: Change `-v 0 -a -m 1` → `-v 2 -k 1 -m 1`

2. **Completed fixes:**
   - ✅ Added `-clip` flag to `wigToBigWig`
   - ✅ Made effective genome size dynamic (calculated from chrom.sizes)

2. **Verify after fixes:**
   - Check if vector mapping now finds more reads
   - Verify BigWig files are valid
   - Confirm coverage normalization is correct for dm3

3. **Optional improvements:**
   - Restore bedmap interpolation if needed
   - Add transposon region flags if specific regions are required
   - Add 20A transposon analysis if needed

