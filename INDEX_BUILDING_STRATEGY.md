# Index Building Strategy

## Overview

This document explains our approach to handling bioinformatics index files in the piRNA workflow project.

## Why Indexes Are Not Stored in This Repository

### **1. File Size Issues**
- **Bowtie indexes** (`.ebwt` files): 2-10GB each
- **STAR indexes**: 10-50GB each
- **BWA indexes**: 5-20GB each
- **Git repositories** become bloated and slow
- **Cloning** becomes impractical for users

### **2. Generated vs Source Files**
- **Index files are generated** from reference files (`.fa`, `.gtf`)
- **They can be recreated** using the source files
- **Not source code** - they're computational artifacts
- **Platform-specific** in some cases

### **3. Best Practices**
- **Git should contain source files** (`.fa`, `.gtf`)
- **Indexes should be built** during workflow execution
- **Users should generate** their own indexes
- **Keeps repo lightweight** and fast

## Our Solution: Automatic Index Building

### **1. Index Building Rules in Snakefiles**
We've added rules to automatically build indexes when needed:

#### **CHIP-seq Snakefile**
```python
rule build_dm6_bowtie_index:
    input:
        dm6_fa = DM6_REFERENCE
    output:
        index_files = expand(f"{DM6_BOWTIE_INDEX}.{{ext}}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    conda:
        "envs/bowtie.yaml"
    shell:
        """
        mkdir -p $(dirname {DM6_BOWTIE_INDEX})
        bowtie-build {input.dm6_fa} {DM6_BOWTIE_INDEX}
        """

rule build_vector_42AB_index:
    input:
        vector_fa = VECTOR_42AB_REF
    output:
        index_files = expand(f"{VECTOR_42AB_INDEX}.{{ext}}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    conda:
        "envs/bowtie.yaml"
    shell:
        """
        mkdir -p $(dirname {VECTOR_42AB_INDEX})
        bowtie-build {input.vector_fa} {VECTOR_42AB_INDEX}
        """
```

#### **TotalRNA-seq Snakefile**
```python
rule build_vector_42AB_index:
    input:
        vector_fa = VECTOR_42AB_REF
    output:
        index_files = expand(f"{VECTOR_42AB_INDEX}.{{ext}}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    conda:
        "envs/bowtie.yaml"
    shell:
        """
        mkdir -p $(dirname {VECTOR_42AB_INDEX})
        bowtie-build {input.vector_fa} {VECTOR_42AB_INDEX}
        """

rule build_rrna_index:
    input:
        rrna_fa = RRNA_REFERENCE
    output:
        index_files = expand("dmel_rRNA_unit.{{ext}}", ext=["1.ebwt", "2.ebwt", "3.ebwt", "4.ebwt", "rev.1.ebwt", "rev.2.ebwt"])
    conda:
        "envs/bowtie.yaml"
    shell:
        """
        bowtie-build {input.rrna_fa} dmel_rRNA_unit
        """
```

### **2. Automatic Dependencies**
Indexes are automatically built when needed:
- **Genome mapping** depends on `build_dm6_bowtie_index`
- **Vector mapping** depends on `build_vector_42AB_index`
- **rRNA removal** depends on `build_rrna_index`

### **3. User Experience**
- **No manual index building** required
- **Indexes built automatically** during first run
- **Cached for subsequent runs** (Snakemake handles this)
- **Transparent to users**

## What's in Git vs Generated

### **✅ Keep in Git (Source Files)**
- `dm6.fa` - Reference genome
- `dm6.gtf` - Gene annotations  
- `42AB_UBIG.fa` - Vector sequences
- `AllAdaptors.fa` - Adapter sequences
- `dm6-blacklist.v2.bed.gz` - Blacklist regions
- `dmel_rRNA_unit.fa` - rRNA sequences

### **❌ Remove from Git (Generated Files)**
- `*.ebwt` - Bowtie index files
- `*.bt2` - Bowtie2 index files
- `STAR/` - STAR index directories
- `*.fai` - FASTA index files
- `bowtie-indexes/` - Index directories
- `genomes/` - Generated genome directories

## .gitignore Configuration

### **Root Level .gitignore**
We've created a comprehensive `.gitignore` at the root level that ignores:
- All index file types
- Generated directories
- Large data files
- Results and intermediate files

### **Workflow-Specific .gitignore**
Each workflow directory also has its own `.gitignore` for workflow-specific files.

## Benefits of This Approach

### **1. Repository Management**
- **Smaller repo size** - Faster cloning and pushing
- **Cleaner history** - No large binary files
- **Better performance** - Git operations are faster

### **2. User Experience**
- **Automatic setup** - No manual index building
- **Reproducible** - Indexes built from source files
- **Flexible** - Works on different systems

### **3. Professional Standards**
- **Follows bioinformatics best practices**
- **Industry standard approach**
- **Better collaboration** - Easier to share code

## Migration Steps

### **1. Remove Indexes from Git**
```bash
# Remove index files from git (but keep locally)
git rm --cached Shared/DataFiles/genome/rrna/*.ebwt
git rm --cached Shared/DataFiles/genome/YichengVectors/*.ebwt
git rm --cached Shared/DataFiles/genome/*.fai
git rm --cached bowtie-indexes/
git rm --cached genomes/

# Commit the removal
git commit -m "Remove generated index files from version control"
```

### **2. Test Index Building**
```bash
# Test that indexes are built automatically
snakemake --use-conda --cores 4 build_dm6_bowtie_index
snakemake --use-conda --cores 4 build_vector_42AB_index
```

### **3. Verify Workflow Runs**
```bash
# Test complete workflow
snakemake --use-conda --cores 4
```

## Troubleshooting

### **Common Issues**

1. **Index Files Not Found**
   - Ensure source files exist (`.fa` files)
   - Check that index building rules are included
   - Verify conda environments are properly configured

2. **Permission Errors**
   - Ensure write permissions in output directories
   - Check disk space for large indexes

3. **Index Building Fails**
   - Verify source file integrity
   - Check conda environment for required tools
   - Review error messages for specific issues
