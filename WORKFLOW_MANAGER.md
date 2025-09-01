# piRNA Workflow Manager

This document describes the unified workflow management script for running ChIP-seq and totalRNA-seq workflows.

## Overview

The `run_workflow.sh` script provides a unified interface for managing both workflows in this project:
- **ChIP-seq workflow** (`CHIP-seq/`)
- **totalRNA-seq workflow** (`totalRNA-seq/`)

## Prerequisites

1. **Conda environment**: Create the `snakemake_env` environment:
   ```bash
   conda create -n snakemake_env -c bioconda -c conda-forge snakemake
   ```

2. **Workflow directories**: Ensure both `CHIP-seq/` and `totalRNA-seq/` directories exist with valid Snakefiles.

## Usage

### Basic Syntax
```bash
./run_workflow.sh [WORKFLOW] [COMMAND] [OPTIONS]
```

### Available Workflows
- `1` or `chip-seq` - ChIP-seq analysis workflow
- `4` or `totalrna-seq` - Total RNA-seq analysis workflow

**Interactive Selection**: If no workflow is specified, the script will prompt you to select one interactively.

### Available Commands (Default: `run`)

| Command | Description |
|---------|-------------|
| `setup` | Create conda environments for the workflow |
| `dryrun` | Show what will be executed (dry run) |
| `run` | Run the complete workflow **[DEFAULT]** |
| `run-force` | Force re-run all steps of the workflow |
| `status` | Check workflow status and progress |
| `clean` | Clean up output files |
| `help` | Show help message |

### Options

| Option | Description |
|--------|-------------|
| `--cores N` | Number of CPU cores to use (default: 8) |
| `--rerun-incomplete` | Re-run incomplete jobs |

## Examples

### Quick Start with Numeric Options
```bash
# Run ChIP-seq workflow (uses default 'run' command)
./run_workflow.sh 1

# Run totalRNA-seq workflow
./run_workflow.sh 4

# Check totalRNA-seq status
./run_workflow.sh 4 status

# Dry run ChIP-seq workflow
./run_workflow.sh 1 dryrun
```

### Interactive Selection
```bash
# No workflow specified - interactive prompt
./run_workflow.sh
# Output: "Please select a workflow (1 or 4):"
# Enter: 1 (for ChIP-seq) or 4 (for totalRNA-seq)
```

### Traditional Text Options
```bash
# Create conda environments for totalRNA-seq
./run_workflow.sh totalrna-seq setup

# Run a dry run to see what will happen
./run_workflow.sh totalrna-seq dryrun

# Run the complete workflow
./run_workflow.sh totalrna-seq run
```

### Advanced Usage
```bash
# Force re-run all steps with 4 cores (numeric option)
./run_workflow.sh 1 run-force --cores 4

# Run with incomplete job recovery
./run_workflow.sh 4 run --rerun-incomplete

# Check workflow status
./run_workflow.sh totalrna-seq status

# Clean up results
./run_workflow.sh chip-seq clean

# Default command with custom cores
./run_workflow.sh 4 --cores 12  # Same as: ./run_workflow.sh 4 run --cores 12
```

## Features

- **Unified Interface**: Single script for both workflows
- **Numeric Shortcuts**: Use `1` for ChIP-seq, `4` for totalRNA-seq
- **Interactive Selection**: Prompts for workflow selection when none specified
- **Default Command**: `run` is the default - just specify workflow to start
- **Environment Management**: Automatically activates `snakemake_env`
- **Error Handling**: Validates environments and directories
- **Flexible Options**: Configurable cores and advanced flags
- **Status Checking**: Monitor workflow progress
- **Easy Cleanup**: Remove results directories
- **Modern Snakemake**: Updated commands and better compatibility

## Troubleshooting

### Environment Issues
If you get environment errors:
```bash
conda create -n snakemake_env -c bioconda -c conda-forge snakemake
```

### Incomplete Files
If workflows show incomplete files:
```bash
./run_workflow.sh [workflow] run --rerun-incomplete
```

### Force Restart
To completely restart a workflow:
```bash
./run_workflow.sh [workflow] clean
./run_workflow.sh [workflow] run-force
```

## Workflow-Specific Notes

### totalRNA-seq
- **Input files**: Uses shared datasets in `Shared/DataFiles/datasets/totalrna-seq/`
- **Key features**: Automatic chromosome harmonization for UCSC/Ensembl compatibility
- **Output**: Results in `totalRNA-seq/results/`

### ChIP-seq
- **Input files**: Configure in workflow-specific config files
- **Output**: Results in `CHIP-seq/results/`

## Migration from Old Scripts

This script replaces the individual `run_workflow.sh` scripts in each workflow directory. The new features include:

- **Better error handling**
- **Unified interface** 
- **Modern Snakemake commands**
- **Flexible core allocation**
- **Status monitoring**

Use this script from the project root instead of the old individual scripts.
