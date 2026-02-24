# piRNA Workflow Project

A bioinformatics workflow for piRNA and ChIP-seq analysis, using reproducible Snakemake pipelines and shared resources. This project is a **work in progress** that builds upon and extends the original methodologies from the Peng He Lab.

## 🚀 Project Overview

This repository contains a bioinformatics workflow system that is **converting all workflows** from the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA) from shell scripts to Snakemake:

| Pipeline | Description | Status |
|----------|-------------|--------|
| **CHIP-seq** | ChIP-seq analysis from raw FASTQ to BigWig visualization | ✅ Converted |
| **TotalRNA-seq** | Total RNA-seq processing with rRNA removal and alignment | ✅ Converted |
| **piRNA-seq** | Specialized piRNA analysis pipeline | 📋 Next Priority |
| **Fusion Reads** | Detection and analysis of fusion reads | 📋 Planned |
| **RIP-seq** | RNA immunoprecipitation sequencing | 📋 Planned |

**Shared Resources**: Common scripts, genomes, and data files used by all workflows

## 🎯 Quick Start

```bash
# Recommended (when data is in Shared/DataFiles/genomes, etc.)
./run_workflow.sh 1 run --use-apptainer --defaults   # ChIP-seq
./run_workflow.sh 4 run --use-apptainer --defaults   # totalRNA-seq

# Interactive mode - guided setup with smart resource detection
./run_workflow.sh

# Or use numeric shortcuts
./run_workflow.sh 1    # Run ChIP-seq workflow
./run_workflow.sh 4    # Run totalRNA-seq workflow
```

**Key Features:**
- ✅ Interactive workflow selection and core allocation
- ✅ Smart resource detection and optimization
- ✅ Automatic error recovery and lock management
- ✅ Input validation and overwrite protection

> **Advanced Users**: You can also run workflows directly with Snakemake. See the individual workflow READMEs ([CHIP-seq](CHIP-seq/README.md) or [totalRNA-seq](totalRNA-seq/README.md)) for direct Snakemake usage examples.

📖 **For detailed usage and troubleshooting**, see [WORKFLOW_MANAGER.md](WORKFLOW_MANAGER.md)

## 🔄 Relationship to Original Work

This project **builds upon and enhances** the original work by [Luo et al. 2025](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) and the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA).

### **Key Improvements**
- **Shell Scripts → Snakemake**: Converted original shell-based pipelines to reproducible Snakemake workflows
- **Manual Dependencies → Conda**: Automated environment management with conda/mamba
- **Hardcoded Paths → Variables**: Centralized path management for better maintainability
- **Single-threaded → Parallel**: Added parallel processing capabilities
- **Flexible Configuration**: Easy customization for different datasets
- **Performance Optimization**: Resource-aware execution and monitoring
- **Documentation**: Comprehensive READMEs and setup guides

## 📁 Project Structure

```
 piRNA_workflow/
├── CHIP-seq/                 # ✅ ChIP-seq analysis pipeline (Production Ready)
│   ├── Snakefile            # Main workflow definition
│   ├── config.yaml          # Configuration file
│   ├── envs/                # Conda environment definitions + Apptainer .def files
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed ChIP-seq documentation
├── totalRNA-seq/            # ✅ Total RNA-seq processing pipeline (Production Ready)
│   ├── Snakefile            # Main workflow definition
│   ├── config.yaml          # Configuration file
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed RNA-seq documentation
├── Shared/                  # Common resources for all workflows
│   ├── Scripts/             # Shared Python, shell, and Mermaid diagrams
│   ├── DataFiles/           # Common genome files and datasets
│   │   ├── genomes/         # Reference genomes, annotations, indexes (can be symlinked)
│   │   └── datasets/        # Input FASTQ files
│   └── README.md            # Shared resources documentation
├── containers/              # Apptainer definition files (build with apptainer build)
│   ├── pipeline.def         # Unified pipeline container (Bowtie, FastQC, Cutadapt, etc.)
│   └── CONTAINER_KNOWN_ISSUES.md
├── run_workflow.sh          # Unified workflow manager script
├── WORKFLOW_MANAGER.md      # Workflow manager documentation
└── README.md                # This file
```

## 🎯 Key Features

### **Reproducibility**
- **Snakemake workflows** for reproducible analysis
- **Conda environments** for dependency management
- **Apptainer containers** (recommended): unified pipeline image with pinned tool versions (Bowtie 1.0.1-nh, FastQC 0.11.3, Cutadapt 1.8.3, etc.). This is the easiest option—without it, users must compile several tools (patched Bowtie, samtools 0.1.8/0.1.16) themselves.
- **Version-controlled** configurations and parameters

### **Scalability**
- **Parallel processing** with configurable core usage
- **Modular design** for easy customization
- **Resource-aware** execution

### **Quality Control**
- **Multi-step QC** with FastQC integration
- **Adapter trimming** and quality filtering
- **Comprehensive reporting** at each step

### **Analysis Capabilities**
- **ChIP-seq**: Peak detection, enrichment analysis, BigWig generation
- **RNA-seq**: rRNA removal, transcriptome alignment, vector mapping
- **Coverage analysis** at multiple resolutions
- **Transposon-specific** analysis

### **Workflow Enhancements**
- **Conversion from shell scripts** to Snakemake workflows
- **Standardized config.yaml** files for easy parameter management
- **Individual conda environments** for reliable dependency management
- **Updated software versions** and best practices
- **Enhanced reproducibility** and scalability

## 🚀 Setup

### Platform Support

The workflows are tested on **Ubuntu Linux** for:
- **x86_64 (amd64)** — e.g. lab servers, most PCs
- **ARM64 (aarch64)** — e.g. Apple Silicon Macs (via Linux/VM), ARM dev boards

Conda-only mode also runs on macOS. Apptainer containers require Linux.

### Prerequisites

1. **Install Miniconda** (if not already installed):
   ```bash
   # Linux x86_64
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh

   # Linux ARM64
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh
   bash Miniconda3-latest-Linux-aarch64.sh

   # macOS
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
   bash Miniconda3-latest-MacOSX-x86_64.sh
   ```

2. **Install mamba** (recommended for faster dependency resolution):
   ```bash
   conda install mamba -n base -c conda-forge
   ```

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd piRNA_workflow
   ```

2. **Create the snakemake environment** (one-time setup):
   ```bash
   conda create -n snakemake_env -c bioconda -c conda-forge snakemake
   ```

3. **Recommended – Apptainer container**: The easiest way to run the pipelines—no manual compilation. Several tools (patched Bowtie, samtools 0.1.8/0.1.16) require building from source otherwise. Install Apptainer and build the pipeline container:
   ```bash
   # Ubuntu: install Apptainer
   sudo add-apt-repository -y ppa:apptainer/ppa
   sudo apt-get update && sudo apt-get install -y apptainer

   # Or see https://apptainer.org/docs/admin/latest/installation.html for other distros
   ```
   Then build the container (run from project root):
   ```bash
   apptainer build containers/pirna_pipeline.sif containers/pipeline.def
   ```
   The workflow will use it automatically when available. Or run with `--use-apptainer` to let the workflow manager build individual tool containers.

4. **Run a workflow**:
   ```bash
   ./run_workflow.sh
   ```

The script will guide you through workflow selection, path configuration, and resource allocation.

📖 **For platform requirements, container setup, detailed commands, and troubleshooting**, see [WORKFLOW_MANAGER.md](WORKFLOW_MANAGER.md)

## 🔧 Configuration

### Environment Management
- **Automatic environment creation** with `--use-conda`
- **Tool-specific environments** for optimal performance
- **mamba support** for faster dependency resolution

### Sample Configuration
- **Flexible sample naming** in Snakefiles
- **Configurable parameters** for analysis steps
- **Easy customization** for different datasets

## 📚 Documentation

- **[CHIP-seq README](CHIP-seq/README.md)**: Comprehensive ChIP-seq pipeline documentation
- **[TotalRNA-seq README](totalRNA-seq/README.md)**: RNA-seq processing documentation
- **[Shared Resources README](Shared/README.md)**: Common resources and scripts
- **[Workflow Manager Guide](WORKFLOW_MANAGER.md)**: Detailed usage, container setup, and troubleshooting
- **[Container Known Issues](containers/CONTAINER_KNOWN_ISSUES.md)**: Known build/runtime issues for the shared pipeline container (EBSeq, unprivileged exec, etc.)
- **[Dataset Recommendations](CHIP-seq/DATASET_RECOMMENDATIONS.md)**: Data quality guidelines

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📖 Citation

If you use this workflow in your research, please cite:

### Original Research
- **Luo et al. 2025**: [Paper Title](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) - Original methodology and findings

### Original Repository
- **Peng-He-Lab/Luo_2025_piRNA**: [https://github.com/Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA) - Source of original scripts and methodology
