# Shared Paths Refactoring Documentation

## Overview

This document describes the refactoring of shared file paths in the piRNA workflow Snakefiles from hardcoded relative paths to centralized variables.

## What Was Changed

### Before (Hardcoded Paths)
Previously, both Snakefiles contained hardcoded relative paths like:
```python
# CHIP-seq Snakefile
python2 ../Shared/Scripts/trimfastq.py
bowtie ../Shared/DataFiles/genome/bowtie-indexes/dm6
reference="../Shared/DataFiles/genome/dm6.fa"

# totalRNA-seq Snakefile
TRIMFASTQ_SCRIPT = "../Shared/Scripts/trimfastq.py"
vector_index = "../Shared/DataFiles/genome/YichengVectors/42AB_UBIG"
```

### After (Centralized Variables)
Now both Snakefiles use centralized path variables at the top:

#### CHIP-seq Snakefile
```python
# Shared file paths - centralized configuration
# These variables centralize all shared file paths for easy maintenance
# If you need to change the location of shared files, update these variables only
SHARED_SCRIPTS = "../Shared/Scripts"
SHARED_DATA = "../Shared/DataFiles"
SHARED_GENOME = f"{SHARED_DATA}/genome"

# Scripts
TRIMFASTQ_SCRIPT = f"{SHARED_SCRIPTS}/trimfastq.py"
MAKEWIGGLE_SCRIPT = f"{SHARED_SCRIPTS}/makewigglefromBAM-NH.py"

# Genome files
DM6_REFERENCE = f"{SHARED_GENOME}/dm6.fa"
DM6_BLACKLIST = f"{SHARED_GENOME}/dm6-blacklist.v2.bed.gz"
DM6_CHROM_SIZES = f"{SHARED_GENOME}/bowtie-indexes/dm6.chrom.sizes"
DM6_BOWTIE_INDEX = f"{SHARED_GENOME}/bowtie-indexes/dm6"

# Vector files
VECTOR_42AB_INDEX = f"{SHARED_GENOME}/YichengVectors/42AB_UBIG"
VECTOR_42AB_REF = f"{SHARED_GENOME}/YichengVectors/42AB_UBIG.fa"
VECTOR_20A_INDEX = f"{SHARED_GENOME}/YichengVectors/20A"
VECTOR_20A_REF = f"{SHARED_GENOME}/YichengVectors/20A.fa"

# Adapter files
ADAPTERS_FILE = f"{SHARED_DATA}/AllAdaptors.fa"
```

#### totalRNA-seq Snakefile
```python
# Shared file paths - centralized configuration
# These variables centralize all shared file paths for easy maintenance
# If you need to change the location of shared files, update these variables only
SHARED_SCRIPTS = "../Shared/Scripts"
SHARED_DATA = "../Shared/DataFiles"
SHARED_GENOME = f"{SHARED_DATA}/genome"

# Scripts
TRIMFASTQ_SCRIPT = f"{SHARED_SCRIPTS}/trimfastq.py"

# Vector files
VECTOR_42AB_INDEX = f"{SHARED_GENOME}/YichengVectors/42AB_UBIG"
VECTOR_42AB_REF = f"{SHARED_GENOME}/YichengVectors/42AB_UBIG.fa"
```

## Benefits of This Approach

### 1. **Easier Maintenance**
- **Single location** to update shared file paths
- **No need to search** through entire Snakefile for path changes
- **Reduced risk** of missing path updates

### 2. **Better Readability**
- **Clear organization** of shared resources
- **Descriptive variable names** make code more self-documenting
- **Easier to understand** what files are being used

### 3. **Consistency**
- **Uniform path structure** across both workflows
- **Reduced duplication** of path definitions
- **Easier to spot** inconsistencies

### 4. **Flexibility**
- **Easy to change** shared file locations
- **Simple to add** new shared resources
- **Configurable** for different environments

## Usage Examples

### Before (Hardcoded)
```python
rule example:
    input:
        reference="../Shared/DataFiles/genome/dm6.fa"
    shell:
        "bowtie ../Shared/DataFiles/genome/bowtie-indexes/dm6"
```

### After (Variables)
```python
rule example:
    input:
        reference=DM6_REFERENCE
    shell:
        "bowtie {DM6_BOWTIE_INDEX}"
```

## Files Updated

1. **`CHIP-seq/Snakefile`**
   - Added path variables at the top
   - Updated all hardcoded `../Shared/` references
   - Centralized script, genome, vector, and adapter paths

2. **`totalRNA-seq/Snakefile`**
   - Added path variables at the top
   - Updated vector file references
   - Centralized script and genome paths

## Path Variables Available

### Scripts
- `TRIMFASTQ_SCRIPT`: Path to trimfastq.py
- `MAKEWIGGLE_SCRIPT`: Path to makewigglefromBAM-NH.py

### Genome Files
- `DM6_REFERENCE`: dm6.fa reference genome
- `DM6_BLACKLIST`: dm6 blacklist regions
- `DM6_CHROM_SIZES`: dm6 chromosome sizes
- `DM6_BOWTIE_INDEX`: dm6 bowtie index directory

### Vector Files
- `VECTOR_42AB_INDEX`: 42AB vector bowtie index
- `VECTOR_42AB_REF`: 42AB vector reference
- `VECTOR_20A_INDEX`: 20A vector bowtie index
- `VECTOR_20A_REF`: 20A vector reference

### Adapter Files
- `ADAPTERS_FILE`: Common adapter sequences

## Future Improvements

### 1. **Configuration File**
Consider moving these paths to a `config.yaml` file:
```yaml
shared:
  scripts: "../Shared/Scripts"
  data: "../Shared/DataFiles"
  genome: "../Shared/DataFiles/genome"
```

### 2. **Environment Variables**
Consider using environment variables for flexibility:
```python
SHARED_SCRIPTS = os.getenv("SHARED_SCRIPTS", "../Shared/Scripts")
```

### 3. **Path Validation**
Add validation to ensure shared files exist:
```python
import os
if not os.path.exists(DM6_REFERENCE):
    raise FileNotFoundError(f"Reference genome not found: {DM6_REFERENCE}")
```

## Maintenance Notes

### Adding New Shared Files
1. **Add variable** at the top of the Snakefile
2. **Use variable** throughout the workflow
3. **Update this documentation** if needed

### Changing Shared File Locations
1. **Update variable** at the top of the Snakefile
2. **No need to search** for hardcoded paths
3. **Test workflow** to ensure paths are correct

### Moving Workflows
If you move the workflow directories, you may need to update the relative paths in the variables (e.g., change `../Shared` to `../../Shared`).

---

**Last Updated**: December 2024  
**Status**: Completed  
**Impact**: Low risk, high benefit
