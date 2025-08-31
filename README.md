# piRNA Workflow Project

A bioinformatics workflow system for piRNA and ChIP-seq analysis, featuring reproducible Snakemake pipelines and shared resources. This project is a **work in progress** that builds upon and extends the original methodologies from the Peng-He-Lab.

## 🚀 Project Overview

This repository contains a bioinformatics workflow system that is **converting all workflows** from the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA) from shell scripts to Snakemake:

- **CHIP-seq Pipeline**: ✅ Converted - ChIP-seq analysis from raw FASTQ to BigWig visualization
- **TotalRNA-seq Pipeline**: ✅ Converted - Total RNA-seq processing with rRNA removal and alignment
- **piRNA-seq Pipeline**: 🚧 Converting - Specialized piRNA analysis pipeline
- **Fusion Reads Pipeline**: 📋 Planned - Detection and analysis of fusion reads
- **RIP-seq Pipeline**: 📋 Planned - RNA immunoprecipitation sequencing
- **Shared Resources**: Common scripts, genomes, and data files used by all workflows

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
- **Phase 2**: 🚧 piRNA-seq (In Progress)
- **Phase 3**: 📋 Fusion Reads and RIP-seq (Planned)
- **Goal**: Complete conversion of all 5 original workflows to Snakemake

## 📁 Project Structure

```
piRNA_workflow/
├── CHIP-seq/                 # ✅ ChIP-seq analysis pipeline (Converted)
│   ├── Snakefile            # Main workflow definition
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed ChIP-seq documentation
├── totalRNA-seq/            # ✅ Total RNA-seq processing pipeline (Converted)
│   ├── Snakefile            # Main workflow definition
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed RNA-seq documentation
├── piRNA-seq/               # 🚧 piRNA-seq pipeline (Converting)
│   ├── Snakefile            # Main workflow definition (in progress)
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed piRNA-seq documentation
├── fusion-reads/            # 📋 Fusion reads pipeline (Planned)
│   ├── Snakefile            # Main workflow definition (planned)
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed fusion reads documentation
├── RIP-seq/                 # 📋 RIP-seq pipeline (Planned)
│   ├── Snakefile            # Main workflow definition (planned)
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed RIP-seq documentation
├── Shared/                   # Common resources
│   ├── Scripts/             # Shared Python scripts
│   ├── DataFiles/           # Common genome files and datasets
│   └── README.md            # Shared resources documentation
└── README.md                 # This file
```

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
- **Updated software versions** and best practices
- **Enhanced reproducibility** and scalability

## 🚀 Quick Start

### Prerequisites

1. **Install Miniconda**:
   ```bash
   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
   bash Miniconda3-latest-Linux-x86_64.sh
   ```

2. **Install mamba** (recommended):
   ```bash
   conda install mamba -n base -c conda-forge
   ```

### Basic Usage

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd piRNA_workflow
   ```

2. **Run ChIP-seq pipeline**:
   ```bash
   cd CHIP-seq
   snakemake --use-conda --conda-frontend mamba --cores 8
   ```

3. **Run TotalRNA-seq pipeline**:
   ```bash
   cd totalRNA-seq
   snakemake --use-conda --conda-frontend mamba --cores 8
   ```

## 📊 Workflow Status

Based on the [Peng-He-Lab/Luo_2025_piRNA repository](https://github.com/Peng-He-Lab/Luo_2025_piRNA), we are converting all 5 original workflows from shell scripts to Snakemake:

### ✅ **Completed Workflows**
- **ChIP-seq Pipeline**: ✅ **Converted to Snakemake**
  - Quality Control: FastQC, adapter trimming, quality filtering
  - Read Mapping: Bowtie alignment to reference genome
  - Signal Generation: BigWig tracks and enrichment analysis
  - Coverage Analysis: Multiple bin sizes and resolutions
  - Transposon Analysis: Specialized transposon element analysis

- **TotalRNA-seq Pipeline**: ✅ **Converted to Snakemake**
  - Quality Control: Multi-step FastQC analysis
  - Read Processing: Adapter and length trimming
  - rRNA Removal: Bowtie-based ribosomal RNA filtering
  - Alignment: STAR transcriptome mapping
  - Vector Mapping: Vector sequence analysis

### 🚧 **Workflows in Progress**
- **piRNA-seq Pipeline**: 🚧 **Converting to Snakemake**
  - Specialized piRNA analysis pipeline
  - Adapter trimming and quality control
  - piRNA-specific mapping and analysis

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

## 📈 Performance

### Recommended System Requirements
- **CPU**: 8+ cores (24+ for server environments)
- **Memory**: 16GB+ RAM (32GB recommended)
- **Storage**: 50GB+ free space (100GB+ for multiple samples)
- **Time**: 2-4 hours per sample (faster with more cores)

### Optimization Tips
- **Use SSD storage** for faster I/O
- **Increase cores** for parallel processing
- **Monitor memory usage** during peak operations
- **Use mamba** for complex environments

## 📚 Documentation

- **[CHIP-seq README](CHIP-seq/README.md)**: Comprehensive ChIP-seq pipeline documentation
- **[TotalRNA-seq README](totalRNA-seq/README.md)**: RNA-seq processing documentation
- **[Shared Resources README](Shared/README.md)**: Common resources and scripts
- **[Quick Setup Guide](CHIP-seq/QUICK_SETUP.md)**: Fast setup instructions
- **[Dataset Recommendations](CHIP-seq/DATASET_RECOMMENDATIONS.md)**: Data quality guidelines
- **[Shared Paths Refactoring](SHARED_PATHS_REFACTORING.md)**: Documentation of path management improvements

## 🐛 Troubleshooting

### Common Issues
1. **Environment Creation**: Use `--conda-frontend mamba` for complex environments
2. **Memory Issues**: Reduce cores with `--cores 4`
3. **File Not Found**: Check file paths in Snakefiles
4. **Python Version**: Each tool uses its own environment

### Getting Help
1. Check the troubleshooting sections in individual READMEs
2. Review the CHANGELOG.md files for recent changes
3. Open an issue on the repository
4. Contact the development team

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **[Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA)**: Original pipeline development and methodology
- **Luo et al. 2025**: Original research and methodology development
- **Snakemake community**: Workflow engine and best practices
- **Bioconda contributors**: Software packaging and distribution
- **Open-source bioinformatics community**: Tools and resources

## 📞 Support

For issues and questions:
1. Check the troubleshooting sections above
2. Review the individual README files
3. Open an issue on the repository
4. Contact the development team

## 📖 Citation

If you use this workflow in your research, please cite:

### Original Research
- **Luo et al. 2025**: [Paper Title](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) - Original methodology and findings

### Original Repository
- **Peng-He-Lab/Luo_2025_piRNA**: [https://github.com/Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA) - Source of original scripts and methodology

### This Workflow
- **piRNA Workflow Project**: Modernized and extended version of the original pipelines

---

**Last Updated**: December 2024  
**Version**: 2.0.0  
**Status**: Work in Progress - Converting all workflows to Snakemake  
**Progress**: 2/5 workflows completed (40%)  
**Based on**: [Luo et al. 2025](https://www.sciencedirect.com/science/article/pii/S1097276523007979?dgcid=coauthor) and [Peng-He-Lab/Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA)
