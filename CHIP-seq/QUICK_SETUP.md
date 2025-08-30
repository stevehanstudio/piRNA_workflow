# Quick Setup Guide

## Prerequisites

1. **Install Miniconda**: Download and install [Miniconda](https://docs.conda.io/en/latest/miniconda.html)

2. **Install mamba** (recommended for faster environment creation):
   ```bash
   conda install mamba -n base -c conda-forge
   ```

## Setup

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd piRNA_workflow/CHIP-seq
   ```

2. **Create the main environment**:
   ```bash
   mamba create -n snakemake_env python=3.8 snakemake
   conda activate snakemake_env
   ```

3. **Download required data files** (see README.md for details)

4. **Run the workflow** (Snakemake will create tool environments automatically):
   ```bash
   snakemake --use-conda --cores 4
   ```

## How It Works

- **Snakemake creates environments automatically** when you use `--use-conda`
- **No need to pre-create environments** - Snakemake handles this
- **Each rule uses its own environment** defined in the `envs/` directory
- **mamba can speed up environment creation** for complex environments

## Why mamba?

- **Faster**: mamba is significantly faster than conda for environment creation
- **Drop-in replacement**: mamba is fully compatible with conda
- **Better dependency resolution**: More efficient package solving

## Troubleshooting

If you encounter issues:
1. **Ensure mamba is installed**: `conda install mamba -n base -c conda-forge`
2. **Try using conda instead**: Remove `--conda-frontend mamba` from the command
3. **Check environment files exist** in `envs/` directory
4. **Check the main README.md** for comprehensive troubleshooting
5. **Review the dataset recommendations** if using poor quality data

## Related Documentation

- **[Main README](README.md)**: Comprehensive pipeline documentation
- **[Dataset Recommendations](DATASET_RECOMMENDATIONS.md)**: Data quality guidelines
- **[Main Project README](../README.md)**: Overview of the entire project

---

**Last Updated**: December 2024  
**Status**: Production Ready 