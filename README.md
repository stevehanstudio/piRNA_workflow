# piRNA Workflow Project

A bioinformatics workflow system for piRNA and ChIP-seq analysis, featuring reproducible Snakemake pipelines and shared resources. This project is a **work in progress** that builds upon and extends the original methodologies from the Peng-He-Lab.

## 🚀 Project Overview

This repository contains a bioinformatics workflow system that is **converting all workflows** from the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA) from shell scripts to Snakemake:

- **CHIP-seq Pipeline**: ✅ Converted - ChIP-seq analysis from raw FASTQ to BigWig visualization
- **TotalRNA-seq Pipeline**: ✅ Converted - Total RNA-seq processing with rRNA removal and alignment
- **piRNA-seq Pipeline**: 📋 Next Priority - Specialized piRNA analysis pipeline
- **Fusion Reads Pipeline**: 📋 Planned - Detection and analysis of fusion reads
- **RIP-seq Pipeline**: 📋 Planned - RNA immunoprecipitation sequencing
- **Shared Resources**: Common scripts, genomes, and data files used by all workflows

## 🎯 Quick Start

Use the unified workflow manager with **intelligent automation** and **interactive guidance**:

```bash
# Quick start - run workflows with numeric shortcuts
./run_workflow.sh 1    # Run ChIP-seq workflow (interactive mode)
./run_workflow.sh 4    # Run totalRNA-seq workflow (interactive mode)

# Interactive selection (no arguments)
./run_workflow.sh      # Prompts: "Please select a workflow (1 or 4):"

# Traditional text options still work
./run_workflow.sh chip-seq run
./run_workflow.sh totalrna-seq status

# Validate inputs before running
./run_workflow.sh 1 check-inputs    # Check all required files
./run_workflow.sh 4 check-inputs    # Validate totalRNA-seq files

# Troubleshooting commands
./run_workflow.sh 1 unlock          # Fix lock errors
./run_workflow.sh 1 fix-incomplete  # Handle incomplete files
```

**🆕 Enhanced Features:**
- ✅ **Smart Resource Detection**: Auto-detects CPU cores, load, and memory
- ✅ **Auto-Unlock Stale Locks**: Automatically unlocks directories after interrupted runs
- ✅ **Config-Aware Validation**: Reads actual results_dir from config.yaml
- ✅ **Index Fallback Support**: Validates source files for auto-building missing indexes
- ✅ **Input Validation**: Checks all required files before running
- ✅ **Overwrite Protection**: Prompts before overwriting existing results
- ✅ **Execution Timing**: Shows total runtime upon completion
- ✅ **Auto-Force Rerun**: Automatically uses `--forceall --rerun-incomplete` when overwriting
- ✅ **Interactive Core Selection**: Suggests optimal core count based on system load
- ✅ **Comprehensive Error Handling**: Unlock, incomplete files, missing inputs

For detailed usage, see [WORKFLOW_MANAGER.md](WORKFLOW_MANAGER.md).

## 🎯 Development Priorities

### **Current Status**
- ✅ **CHIP-seq Pipeline**: Fully converted and production-ready
- ✅ **totalRNA-seq Pipeline**: Fully converted and production-ready
- 📋 **piRNA-seq Pipeline**: **Next priority** - ready to begin conversion

### **Confirmed Next Steps**
The **piRNA-seq Pipeline** has been confirmed as the next workflow to convert from shell scripts to Snakemake. This decision is based on:

1. **Logical progression**: Builds on the completed CHIP-seq and totalRNA-seq workflows
2. **Shared resources**: Can leverage existing genome files, indexes, and scripts
3. **Workflow integration**: Will complete the core trio of sequencing analysis pipelines
4. **User demand**: piRNA analysis is a key component of the original research

### **piRNA-seq Conversion Plan**
When ready to begin, the piRNA-seq conversion will include:
- Analysis of existing shell scripts from the original repository
- Creation of Snakemake workflow structure
- Development of conda environment definitions
- Integration with shared resources and existing workflows
- Comprehensive documentation and testing

## 🔄 Relationship to Original Work

This project is a **modernization and extension** of the original work by [Luo et al. 2025](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) and the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA).

### **What We've Modernized**
- **Shell Scripts → Snakemake**: Converted original shell-based pipelines to reproducible Snakemake workflows
- **Manual Dependencies → Conda**: Automated environment management with conda/mamba
- **Hardcoded Paths → Variables**: Centralized path management for better maintainability
- **Single-threaded → Parallel**: Added parallel processing capabilities
- **Documentation**: Comprehensive READMEs and setup guides

### **What We've Extended**
- **Additional QC Steps**: Enhanced quality control and reporting
- **Flexible Configuration**: Easy customization for different datasets
- **Performance Optimization**: Resource-aware execution and monitoring
- **Modern Tools**: Updated to current software versions and best practices

### **Conversion Plan**
- **Phase 1**: ✅ CHIP-seq and TotalRNA-seq (Completed)
- **Phase 2**: 📋 piRNA-seq (Next Priority - Not Started)
- **Phase 3**: 📋 Fusion Reads and RIP-seq (Planned)
- **Goal**: Complete conversion of all 5 original workflows to Snakemake

### **Next Steps**
The **piRNA-seq Pipeline** has been identified as the next priority for conversion from shell scripts to Snakemake. This pipeline will focus on:
- Specialized piRNA analysis and processing
- Adapter trimming and quality control for piRNA data
- piRNA-specific mapping and annotation
- Integration with existing CHIP-seq and totalRNA-seq workflows

## 📁 Project Structure

```
piRNA_workflow/
├── CHIP-seq/                 # ✅ ChIP-seq analysis pipeline (Production Ready)
│   ├── Snakefile            # Main workflow definition
│   ├── config.yaml          # Configuration file
│   ├── envs/                # Conda environment definitions (13 files)
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed ChIP-seq documentation
├── totalRNA-seq/            # ✅ Total RNA-seq processing pipeline (Production Ready)
│   ├── Snakefile            # Main workflow definition
│   ├── config.yaml          # Configuration file
│   ├── envs/                # Conda environment definitions (9 files)
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed RNA-seq documentation
├── Shared/                  # Common resources for all workflows
│   ├── Scripts/             # Shared Python, shell, and PlantUML scripts
│   ├── DataFiles/           # Common genome files and datasets
│   │   ├── genome/          # Reference genomes and indexes
│   │   └── datasets/        # Input FASTQ files
│   └── README.md            # Shared resources documentation
├── run_workflow.sh          # Unified workflow manager script
├── WORKFLOW_MANAGER.md      # Workflow manager documentation
└── README.md                # This file
```

**📋 Planned Workflows** (see [Development Priorities](#-development-priorities) for details):
- `piRNA-seq/` - Next priority for conversion
- `fusion-reads/` - Planned future pipeline
- `RIP-seq/` - Planned future pipeline

## 🎯 Key Features

### **Reproducibility**
- **Snakemake workflows** for reproducible analysis
- **Conda environments** for dependency management
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

### **Modernization**
- **Conversion from shell scripts** to Snakemake workflows
- **Standardized config.yaml** files for easy parameter management
- **Individual conda environments** for reliable dependency management
- **Updated software versions** and best practices
- **Enhanced reproducibility** and scalability

## 🚀 Quick Start

### Prerequisites

#### **Platform Requirements**

The workflow manager (`run_workflow.sh`) is designed for **Linux/macOS** and requires the following Unix utilities:

- `nproc` - CPU core detection
- `uptime` - System load monitoring
- `free` - Memory availability checking
- `bc` - Floating-point arithmetic for resource calculations
- `pgrep` - Process detection for lock management

**For Windows Users:**
- ✅ **Recommended**: Use [WSL2 (Windows Subsystem for Linux)](https://docs.microsoft.com/en-us/windows/wsl/install) for full compatibility
- ⚠️ **Git Bash Users**: Auto-resource detection may fail. Use `--cores N` flag to manually specify core count:
  ```bash
  ./run_workflow.sh 1 run --cores 4
  ```

#### **Software Dependencies**

1. **Install Miniconda**:
   ```bash
   # Linux
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh

   # macOS
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh
   bash Miniconda3-latest-MacOSX-x86_64.sh
   ```

2. **Install mamba** (recommended for faster dependency resolution):
   ```bash
   conda install mamba -n base -c conda-forge
   ```

3. **Install bc** (if not already present):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install bc

   # macOS (usually pre-installed, if not):
   brew install bc

   # WSL2 users
   sudo apt-get install bc
   ```

### Basic Usage

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd piRNA_workflow
   ```

2. **Create the snakemake environment** (one-time setup):
   ```bash
   conda create -n snakemake_env -c bioconda -c conda-forge snakemake
   conda activate snakemake_env
   ```

3. **Run workflows using the unified manager**:
   ```bash
   # Interactive mode - guided setup
   ./run_workflow.sh

   # Quick runs with automatic resource detection
   ./run_workflow.sh 1    # ChIP-seq (prompts for cores)
   ./run_workflow.sh 4    # totalRNA-seq (prompts for cores)

   # Manual control
   ./run_workflow.sh 1 run --cores 8
   ./run_workflow.sh totalrna-seq dryrun
   ```

4. **Validate inputs before running**:
   ```bash
   ./run_workflow.sh 1 check-inputs     # Verify ChIP-seq requirements
   ./run_workflow.sh 4 check-inputs     # Verify totalRNA-seq requirements
   ```

## 📊 Workflow Status

Based on the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA), we are converting all 5 original workflows from shell scripts to Snakemake:

### ✅ **Completed Workflows**
- **ChIP-seq Pipeline**: ✅ **Converted to Snakemake** ⭐ **Production Ready**
  - Quality Control: FastQC, adapter trimming, quality filtering
  - Read Mapping: Bowtie alignment to reference genome
  - Signal Generation: BigWig tracks and enrichment analysis
  - Coverage Analysis: Multiple bin sizes and resolutions
  - Transposon Analysis: Specialized transposon element analysis
  - **Enhanced Features**: Parameterized paths, flexible sample naming, robust error handling

- **TotalRNA-seq Pipeline**: ✅ **Converted to Snakemake**
  - Quality Control: Multi-step FastQC analysis
  - Read Processing: Adapter and length trimming
  - rRNA Removal: Bowtie-based ribosomal RNA filtering
  - Alignment: STAR transcriptome mapping
  - Vector Mapping: Vector sequence analysis

### 📋 **Next Priority**
- **piRNA-seq Pipeline**: 📋 **Next to Convert** (Not Started)
  - Specialized piRNA analysis pipeline
  - Adapter trimming and quality control for piRNA data
  - piRNA-specific mapping and annotation
  - **Status**: Ready to begin conversion from shell scripts to Snakemake

### 📋 **Planned Workflows**
- **Fusion Reads Pipeline**: 📋 **Planned for Snakemake conversion**
  - Detection and analysis of fusion reads
  - Based on `fusion-reads-workflow-wz-v2.sh`
  - Integration with other workflows

- **RIP-seq Pipeline**: 📋 **Planned for Snakemake conversion**
  - RNA immunoprecipitation sequencing
  - Uses adapter trimming from piRNA-seq
  - Followed by Total RNA-seq pipeline

### 🔄 **Workflow Integration**
- **Shared Components**: All workflows will use common resources and scripts
- **Consistent Interface**: Uniform Snakemake rule structure across all pipelines
- **Modular Design**: Easy to run individual workflows or combined analyses

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
- **[Quick Setup Guide](CHIP-seq/QUICK_SETUP.md)**: Fast setup instructions
- **[Dataset Recommendations](CHIP-seq/DATASET_RECOMMENDATIONS.md)**: Data quality guidelines

## 🛠️ Workflow Manager Features

The `run_workflow.sh` script provides a comprehensive workflow management system:

### **🔍 Input Validation**
```bash
./run_workflow.sh 1 check-inputs    # Validate all required files
./run_workflow.sh 4 check-inputs    # Check totalRNA-seq requirements
```
- Checks for reference genomes, indexes, and input datasets
- Provides specific guidance on missing files
- Offers download commands and setup instructions

### **🧠 Smart Resource Detection**
```bash
./run_workflow.sh 1    # Auto-detects system resources
# Output:
# === System Resources ===
# Total CPU cores: 16
# Current load average: 2.1
# Available memory: 32GB
# Number of cores to use [12]:
```
- Analyzes CPU cores, load average, and memory
- Suggests optimal core count based on system load
- Allows manual override or acceptance of suggestion

### **🛡️ Safety Features**
```bash
./run_workflow.sh 1 run    # Checks for existing results
# Warning: Existing results directories found:
# Do you want to proceed and potentially overwrite existing results? (y/N):
```
- Detects existing output directories
- Prompts before overwriting valuable results
- Automatically applies `--forceall` when confirmed

### **🔧 Troubleshooting Commands**
```bash
./run_workflow.sh 1 unlock          # Fix Snakemake lock errors
./run_workflow.sh 1 fix-incomplete  # Handle incomplete files
./run_workflow.sh 1 status          # Check workflow progress
./run_workflow.sh 1 clean           # Remove output files
```

### **⏱️ Execution Monitoring**
- Displays total execution time upon completion
- Shows formatted time (HH:MM:SS)
- Tracks resource usage during runs

## 🐛 Troubleshooting

### **Platform-Specific Issues**

#### **Windows Git Bash**
If you see errors like `nproc: command not found`, `free: command not found`, or `bc: command not found`:
```bash
# Workaround: Manually specify cores to bypass auto-detection
./run_workflow.sh 1 run --cores 4
./run_workflow.sh 4 dryrun --cores 8
```

**Better Solution**: Use WSL2 for full Linux compatibility:
1. Install WSL2: `wsl --install` (in PowerShell as Administrator)
2. Install Ubuntu from Microsoft Store
3. Clone repository inside WSL2 and run normally

#### **macOS**
If `bc` is missing:
```bash
brew install bc
```

### **Workflow Manager Issues**
```bash
# Lock errors (previous run interrupted)
./run_workflow.sh 1 unlock

# Incomplete files (run was interrupted)
./run_workflow.sh 1 fix-incomplete

# Missing input files
./run_workflow.sh 1 check-inputs

# Check what would run without executing
./run_workflow.sh 1 dryrun
```

### **Common Snakemake Issues**
1. **Environment Creation**: Use `--conda-frontend mamba` for faster dependency resolution
2. **Memory Issues**: Reduce cores with `--cores 4` or let the script suggest optimal cores
3. **File Not Found**: Use `check-inputs` command to verify all required files
4. **Permission Issues**: Ensure write access to output directories
5. **Incomplete Files**: Use `fix-incomplete` command to clean metadata

### **Performance Optimization**
- Let the script auto-detect optimal core count based on system load
- Use `dryrun` to preview computational requirements
- Monitor system resources during execution
- Use `status` to check progress of long-running workflows

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **[Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA)**: Original pipeline development and methodology
- **Luo et al. 2025**: Original research and methodology development
- **Snakemake community**: Workflow engine and best practices
- **Bioconda contributors**: Software packaging and distribution
- **Open-source bioinformatics community**: Tools and resources

## 📖 Citation

If you use this workflow in your research, please cite:

### Original Research
- **Luo et al. 2025**: [Paper Title](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) - Original methodology and findings

### Original Repository
- **Peng-He-Lab/Luo_2025_piRNA**: [https://github.com/Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA) - Source of original scripts and methodology
