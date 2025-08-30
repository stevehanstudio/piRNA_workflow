# piRNA Workflow Project

A comprehensive bioinformatics workflow system for piRNA and ChIP-seq analysis, featuring reproducible Snakemake pipelines and shared resources.

## 🚀 Project Overview

This repository contains a complete bioinformatics workflow system with three main components:

- **CHIP-seq Pipeline**: ChIP-seq analysis from raw FASTQ to BigWig visualization
- **TotalRNA-seq Pipeline**: Total RNA-seq processing with rRNA removal and alignment
- **Shared Resources**: Common scripts, genomes, and data files used by both workflows

## 📁 Project Structure

```
piRNA_workflow/
├── CHIP-seq/                 # ChIP-seq analysis pipeline
│   ├── Snakefile            # Main workflow definition
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed ChIP-seq documentation
├── totalRNA-seq/            # Total RNA-seq processing pipeline
│   ├── Snakefile            # Main workflow definition
│   ├── envs/                # Conda environment definitions
│   ├── results/             # Analysis outputs
│   └── README.md            # Detailed RNA-seq documentation
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

## 📊 Supported Analyses

### ChIP-seq Pipeline
- **Quality Control**: FastQC, adapter trimming, quality filtering
- **Read Mapping**: Bowtie alignment to reference genome
- **Signal Generation**: BigWig tracks and enrichment analysis
- **Coverage Analysis**: Multiple bin sizes and resolutions
- **Transposon Analysis**: Specialized transposon element analysis

### TotalRNA-seq Pipeline
- **Quality Control**: Multi-step FastQC analysis
- **Read Processing**: Adapter and length trimming
- **rRNA Removal**: Bowtie-based ribosomal RNA filtering
- **Alignment**: STAR transcriptome mapping
- **Vector Mapping**: Vector sequence analysis

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

- **Peng-He-Lab**: Original pipeline development and methodology
- **Snakemake community**: Workflow engine and best practices
- **Bioconda contributors**: Software packaging and distribution
- **Open-source bioinformatics community**: Tools and resources

## 📞 Support

For issues and questions:
1. Check the troubleshooting sections above
2. Review the individual README files
3. Open an issue on the repository
4. Contact the development team

---

**Last Updated**: December 2024  
**Version**: 2.0.0  
**Status**: Active Development
