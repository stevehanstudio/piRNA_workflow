# Data Sources Documentation

**Last Updated:** November 7, 2025  
**Purpose:** Track the origin and download information for all reference genome data files

---

## Overview

This document tracks all reference genome files, annotations, and related data files used in the piRNA workflow. Each genome version is documented with download sources, dates, and file checksums where applicable.

---

## Drosophila melanogaster

### dm6 (BDGP Release 6)

**Genome Assembly:**
- **Source:** UCSC Genome Browser
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/dm6/bigZips/
- **File:** `dm6.fa`
- **Size:** 140 MB (146,638,899 bytes)
- **Date Added:** August 29, 2024

**Annotations:**
- **Source:** Ensembl / FlyBase
- **File:** `annotations/dm6.gtf`
- **Notes:** Used for gene annotations and quantification

**Blacklist:**
- **Source:** ENCODE Blacklist Project
- **Download URL:** https://github.com/Boyle-Lab/Blacklist
- **File:** `dm6-blacklist.v2.bed.gz`
- **Size:** 1.7 KB
- **Purpose:** Genomic regions with artifactual signals in ChIP-seq

**rRNA Reference:**
- **File:** `rrna/dmel_rRNA_unit.fa`
- **Source:** Custom curated
- **Purpose:** Filter ribosomal RNA sequences

---

### dm3 (BDGP Release 5)

**Genome Assembly:**
- **Source:** UCSC Genome Browser
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/dm3/bigZips/dm3.fa.gz
- **File:** `dm3.fa`
- **Size:** 165 MB (173,295,909 bytes)
- **Download Date:** November 7, 2025
- **Original Release:** January 23, 2020 (UCSC timestamp)

**Annotations:**
- **Source:** UCSC Genome Browser (Ensembl Genes track)
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/dm3/bigZips/genes/dm3.ensGene.gtf.gz
- **File:** `annotations/dm3.gtf`
- **Size:** 70 MB (73,286,304 bytes)
- **Download Date:** November 7, 2025
- **Original Release:** January 10, 2020 (UCSC timestamp)
- **Notes:** Uses Ensembl gene models for BDGP5

**Blacklist:**
- **Status:** Not available for dm3
- **Workaround:** Use dm6 blacklist or skip blacklist filtering for dm3

**rRNA Reference:**
- **File:** `rrna/dmel_rRNA_unit.fa` (shared with dm6)
- **Notes:** Same rRNA sequences applicable to both dm3 and dm6

---

## Homo sapiens (Human)

### hg38 (GRCh38)

**Genome Assembly:**
- **Source:** UCSC Genome Browser
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
- **File:** `hg38.fa`
- **Size:** 3.1 GB (3,321,963,140 bytes)
- **Download Date:** November 7, 2025
- **Original Release:** January 15, 2014 (UCSC timestamp)
- **Download Time:** ~38 seconds at 25 MB/s
- **Compressed Size:** 984 MB

**Annotations:**
- **Source:** Ensembl Release 110
- **Download URL:** https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz
- **File:** `annotations/hg38.gtf`
- **Size:** 1.4 GB (1,469,091,643 bytes)
- **Download Date:** November 7, 2025
- **Original Release:** April 24, 2023 (Ensembl Release 110)
- **Download Time:** ~8 seconds at 6.5 MB/s
- **Compressed Size:** 54 MB

**Blacklist:**
- **Source:** ENCODE Blacklist v2 (Boyle Lab)
- **Download URL:** https://github.com/Boyle-Lab/Blacklist/raw/master/lists/hg38-blacklist.v2.bed.gz
- **File:** `hg38-blacklist.v2.bed.gz`
- **Size:** 5.8 KB (5,867 bytes)
- **Download Date:** November 7, 2025
- **Purpose:** Regions with artifactual signals in ChIP-seq
- **Reference:** Amemiya HM, Kundaje A, Boyle AP. The ENCODE Blacklist: Identification of Problematic Regions of the Genome. Scientific Reports 9, 9354 (2019). doi:10.1038/s41598-019-45839-z

**rRNA Reference:**
- **Source:** NCBI Nucleotide Database
- **Download URL:** https://www.ncbi.nlm.nih.gov/sviewer/ (IDs: 555853, 555851, 555869)
- **File:** `rrna/hsap_rRNA_unit.fa`
- **Size:** 45 KB (46,006 bytes)
- **Download Date:** November 7, 2025
- **Content:** Human ribosomal DNA complete repeating units
  - U13369.1: Human ribosomal DNA complete repeating unit
  - Additional 18S, 5.8S, 28S rRNA sequences
- **Purpose:** Filter ribosomal RNA sequences in totalRNA-seq

---

## Mus musculus (Mouse)

### mm10 (GRCm38)

**Status:** Not yet downloaded  
**Download Sources (for future use):**

**Genome Assembly:**
- **Source:** UCSC Genome Browser
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/mm10/bigZips/mm10.fa.gz
- **Expected Size:** ~2.7 GB uncompressed

**Annotations:**
- **Source:** Ensembl Release 110
- **Download URL:** https://ftp.ensembl.org/pub/release-110/gtf/mus_musculus/Mus_musculus.GRCm38.110.gtf.gz

**Blacklist:**
- **Source:** ENCODE Blacklist v2
- **Download URL:** https://github.com/Boyle-Lab/Blacklist/raw/master/lists/mm10-blacklist.v2.bed.gz

**rRNA Reference:**
- **Source:** NCBI or custom curation needed
- **Expected File:** `rrna/mmus_rRNA_unit.fa`

---

## Caenorhabditis elegans

### ce11 (WBcel235)

**Status:** Not yet downloaded  
**Download Sources (for future use):**

**Genome Assembly:**
- **Source:** UCSC Genome Browser
- **Download URL:** https://hgdownload.soe.ucsc.edu/goldenPath/ce11/bigZips/ce11.fa.gz
- **Expected Size:** ~100 MB uncompressed

**Annotations:**
- **Source:** Ensembl Release 110
- **Download URL:** https://ftp.ensembl.org/pub/release-110/gtf/caenorhabditis_elegans/Caenorhabditis_elegans.WBcel235.110.gtf.gz

**Blacklist:**
- **Status:** May not be available for ce11
- **Workaround:** Skip blacklist filtering for C. elegans

**rRNA Reference:**
- **Source:** WormBase or NCBI
- **Expected File:** `rrna/cele_rRNA_unit.fa`

---

## Vector and Adapter References

### Vector Sequences (42AB_UBIG)

**Location:** `YichengVectors/42AB_UBIG`  
**Source:** Lab-specific plasmid vectors  
**Purpose:** Remove vector contamination from sequencing data  
**Files:**
- `42AB_UBIG.fa` - Vector reference sequences
- `42AB_UBIG.*.ebwt` - Bowtie indexes

### Adapter Sequences

**File:** `AllAdaptors.fa`  
**Size:** 1.4 KB  
**Source:** Illumina adapter sequences compilation  
**Purpose:** Trim adapters from sequencing reads  
**Content:** Common Illumina sequencing adapters including:
- TruSeq adapters
- Nextera adapters
- Universal adapters

---

## Bowtie Indexes

**Location:** `bowtie-indexes/`

All bowtie indexes are either:
1. **Pre-built** (downloaded from external sources)
2. **Auto-generated** by the workflow using `bowtie-build`

### Currently Available Indexes:

- `dm6.*` - Pre-built or auto-generated
- Additional indexes built on first run as needed

### Indexes to Build:

- `hg38.*` - Will be built automatically on first hg38 workflow run
- `dm3.*` - Will be built automatically on first dm3 workflow run
- `mm10.*` - Will be built when mm10 genome is added

**Build Time Estimates:**
- dm6: ~5-10 minutes
- hg38: ~30-45 minutes (larger genome)
- dm3: ~5-10 minutes

---

## STAR Indexes

**Location:** `star-index/`

STAR indexes for RNA-seq alignment are built automatically by the workflow.

**Build Requirements:**
- Sufficient RAM (≥32 GB for human genome)
- Genome FASTA file
- GTF annotation file

**Build Time Estimates:**
- dm6: ~10-15 minutes
- hg38: ~45-60 minutes
- dm3: ~10-15 minutes

---

## RSEM Indexes

**Location:** `.` (genome directory root)

RSEM indexes for transcript quantification:
- `rsem.grp`
- `rsem.ti`
- `rsem.transcripts.fa`
- `rsem.seq`
- `rsem.idx.fa`
- `rsem.n2g.idx.fa`

**Status:** Currently built for dm6  
**Auto-generation:** Will be built for new genomes as needed

---

## File Organization

```
Shared/DataFiles/genome/
├── {genome}.fa                          # Main genome FASTA
├── {genome}-blacklist.v2.bed.gz        # Blacklist regions (if available)
├── {genome}.fa.fai                     # FASTA index (auto-generated)
│
├── annotations/
│   ├── {genome}.gtf                    # Gene annotations
│   └── {genome}_chr_harmonized.gtf     # Chromosome-harmonized GTF (auto-generated)
│
├── bowtie-indexes/
│   ├── {genome}.1.ebwt                 # Bowtie index files (auto-generated)
│   ├── {genome}.2.ebwt
│   ├── {genome}.3.ebwt
│   ├── {genome}.4.ebwt
│   ├── {genome}.rev.1.ebwt
│   ├── {genome}.rev.2.ebwt
│   └── {genome}.chrom.sizes            # Chromosome sizes (auto-generated)
│
├── rrna/
│   ├── {species}_rRNA_unit.fa          # rRNA reference sequences
│   └── {species}_rRNA_unit.*.ebwt      # rRNA bowtie indexes (auto-generated)
│
├── star-index/                          # STAR indexes (auto-generated)
└── YichengVectors/                      # Lab-specific vectors
```

---

## Download Instructions

### To Add a New Genome:

**1. Create Directory Structure:**
```bash
cd Shared/DataFiles/genome
mkdir -p annotations rrna bowtie-indexes
```

**2. Download Genome FASTA:**
```bash
# Example for hg38
wget https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz
```

**3. Download Annotations:**
```bash
# Example for hg38 from Ensembl
cd annotations
wget https://ftp.ensembl.org/pub/release-110/gtf/homo_sapiens/Homo_sapiens.GRCh38.110.gtf.gz
gunzip Homo_sapiens.GRCh38.110.gtf.gz
mv Homo_sapiens.GRCh38.110.gtf hg38.gtf
```

**4. Download Blacklist (if available):**
```bash
# Example for hg38
cd ..
wget https://github.com/Boyle-Lab/Blacklist/raw/master/lists/hg38-blacklist.v2.bed.gz
```

**5. Prepare rRNA Reference:**
```bash
# Download or curate species-specific rRNA sequences
cd rrna
wget -O hsap_rRNA_unit.fa "https://www.ncbi.nlm.nih.gov/sviewer/viewer.cgi?tool=portal&save=file&db=nuccore&report=fasta&id=555853"
```

**6. Update This Documentation:**
- Add download URLs
- Record file sizes
- Note download date
- Document any special considerations

---

## Data Verification

### Checksums (MD5)

To generate checksums for verification:
```bash
cd Shared/DataFiles/genome
md5sum *.fa > checksums.md5
md5sum annotations/*.gtf >> checksums.md5
```

### File Integrity Checks

Before using downloaded files:
1. Verify file sizes match expected values
2. Check FASTA format validity: `grep "^>" genome.fa | head`
3. Check GTF format validity: `head annotations/genome.gtf`
4. Ensure no corruption during download

---

## Citation Information

### Genome Assemblies

**UCSC Genome Browser:**
- Kent WJ, et al. The human genome browser at UCSC. Genome Res. 2002 Jun;12(6):996-1006.

**Ensembl:**
- Cunningham F, et al. Ensembl 2022. Nucleic Acids Res. 2022 Jan 7;50(D1):D988-D995.

### Blacklist Regions

**ENCODE Blacklist:**
- Amemiya HM, Kundaje A, Boyle AP. The ENCODE Blacklist: Identification of Problematic Regions of the Genome. Scientific Reports 9, 9354 (2019). doi:10.1038/s41598-019-45839-z

### Annotations

**FlyBase (Drosophila):**
- Larkin A, et al. FlyBase: updates to the Drosophila genes and genomes database. Genetics. 2021 Dec 30;219(2):iyab158.

**Ensembl:**
- Release-specific citations available at: https://www.ensembl.org/info/about/publications.html

---

## Storage Requirements

### Current Storage Usage:

| Genome | FASTA | Annotations | Indexes | Total |
|--------|-------|-------------|---------|-------|
| dm6    | 140 MB | ~30 MB | ~500 MB | ~670 MB |
| dm3    | 165 MB | 70 MB | ~600 MB* | ~835 MB* |
| hg38   | 3.1 GB | 1.4 GB | ~12 GB* | ~16.5 GB* |

*Estimated - indexes not yet built

### Recommendations:

- **Minimum:** 50 GB free space for multiple genomes
- **Recommended:** 100+ GB for extensive multi-species work
- **Production:** 500 GB+ if working with many large mammalian genomes

---

## Maintenance Notes

### Regular Updates

**Genome Assemblies:**
- Generally stable; major updates every few years
- Check UCSC/Ensembl for patch releases

**Annotations:**
- Updated regularly (Ensembl releases quarterly)
- Consider updating GTF files annually for latest gene models

**Blacklists:**
- ENCODE Blacklist v2 is current as of 2019
- Check for updates periodically

### Backup Strategy

**Critical Files to Backup:**
1. Original downloaded FASTA files
2. Original GTF files
3. Custom rRNA references
4. This documentation file

**Can Regenerate (don't need backup):**
- Bowtie indexes
- STAR indexes
- RSEM indexes
- Chromosome size files
- FASTA indexes (.fai)

---

## Contact and Support

**Primary Source Websites:**
- **UCSC Genome Browser:** https://genome.ucsc.edu/
- **Ensembl:** https://www.ensembl.org/
- **ENCODE:** https://www.encodeproject.org/
- **NCBI:** https://www.ncbi.nlm.nih.gov/

**Download Issues:**
- Check mirror sites if primary source is slow
- Use `wget --continue` to resume interrupted downloads
- Verify file integrity with checksums when available

---

**Document Version:** 1.0  
**Created:** November 7, 2025  
**Last Updated:** November 7, 2025  
**Maintainer:** Steve Hans Lab

