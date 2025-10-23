# piRNA Workflow Manager

This document describes the unified workflow management script for running ChIP-seq and totalRNA-seq workflows.

## Overview

The `run_workflow.sh` script provides a unified interface for managing both workflows in this project:
- **ChIP-seq workflow** (`CHIP-seq/`)
- **totalRNA-seq workflow** (`totalRNA-seq/`)

## Prerequisites

### **Platform Requirements**

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

### **Software Dependencies**

1. **Conda environment**: Create the `snakemake_env` environment:
   ```bash
   conda create -n snakemake_env -c bioconda -c conda-forge snakemake
   ```

2. **Install bc** (if not already present):
   ```bash
   # Ubuntu/Debian
   sudo apt-get install bc

   # macOS (usually pre-installed, if not):
   brew install bc

   # WSL2 users
   sudo apt-get install bc
   ```

3. **Workflow directories**: Ensure both `CHIP-seq/` and `totalRNA-seq/` directories exist with valid Snakefiles.

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
| `check-inputs` | Validate all required input files are present |
| `fix-incomplete` | Fix incomplete files and continue workflow |
| `unlock` | Unlock workflow directory (fixes lock errors) |
| `status` | Check workflow status and progress |
| `clean` | Clean up output files |
| `help` | Show help message |

### Options

| Option | Description |
|--------|-------------|
| `--cores N` | Number of CPU cores to use (prompts interactively if not specified) |
| `--rerun-incomplete` | Re-run incomplete jobs |

### Path Override Options

| Option | Description |
|--------|-------------|
| `--genome-path PATH` | Override genome FASTA file path |
| `--index-path PATH` | Override bowtie index directory path |
| `--dataset-path PATH` | Override input dataset directory/file path |
| `--vector-path PATH` | Override vector index directory path |
| `--adapter-path PATH` | Override adapter sequences file path |

#### How Path Overrides Work

When you use path override options, the workflow manager preserves your original configuration:

1. **Creates temporary config**: A `config_override.yaml` file is created in the workflow directory
2. **Substitutes paths**: Your custom paths are inserted into this temporary config
3. **Runs workflow**: Snakemake uses the override config instead of the original
4. **Auto-cleanup**: The temporary file is automatically deleted after completion
5. **Original preserved**: Your `config.yaml` remains unchanged

**Benefits:**
- ✅ **Safe testing** of different datasets without editing configs
- ✅ **Original configuration** always preserved
- ✅ **Easy A/B testing** - compare multiple datasets quickly
- ✅ **No accidental commits** of test paths
- ✅ **Reproducible defaults** - config.yaml contains production values

**Example workflow:**
```bash
# Test dataset A
./run_workflow.sh 1 run --dataset-path /data/datasetA --cores 8

# Test dataset B (config.yaml unchanged)
./run_workflow.sh 1 run --dataset-path /data/datasetB --cores 8

# Production run (uses config.yaml defaults)
./run_workflow.sh 1 run --cores 8
```

### Interactive Features

The script now includes several interactive features to improve user experience:

1. **Smart Core Detection**:
   - Automatically detects total CPU cores and current system load
   - Suggests optimal core count based on system resources
   - Prompts user with intelligent default (just press Enter to accept)

2. **Auto-Unlock Stale Locks**:
   - Detects stale locks from interrupted runs (SSH disconnects, kills, etc.)
   - Checks if Snakemake processes are actually running
   - Automatically unlocks if safe (no active processes)
   - Prevents manual unlock steps after connection drops

3. **Config-Aware Results Detection**:
   - Reads actual `results_dir` from config.yaml
   - Only checks the configured results directory for overwrites
   - Ignores old/archived `results_*` directories
   - Supports both relative and absolute paths

4. **Index Fallback Validation**:
   - Validates source FASTA files for index building
   - Doesn't require pre-built indexes if source files exist
   - Supports Snakemake's fallback index-building rules
   - Shows informative notes when indexes will be auto-built

5. **Overwrite Protection**:
   - Checks for existing results before running workflows
   - Shows preview of existing files and prompts for confirmation
   - Prevents accidental overwriting of valuable results
   - Auto-applies `--forceall --rerun-incomplete` when user confirms

6. **Execution Timing**:
   - Tracks total execution time for `run` and `run-force` commands
   - Displays formatted time (HH:MM:SS) upon completion

7. **Input File Validation**:
   - Comprehensive checking of all required input files
   - Intelligent validation for indexes vs source files
   - Specific guidance on missing files with download instructions
   - Pre-flight validation prevents workflow failures

8. **Error Recovery**:
   - Automatic Snakemake lock detection and resolution
   - Incomplete file cleanup and recovery with `--rerun-incomplete`
   - Smart metadata management

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
# Then shows system resources and prompts for cores
```

### Interactive Core Selection
```bash
# Run workflow with automatic core detection
./run_workflow.sh 1
# Output:
# === System Resources ===
# Total CPU cores: 16
# Current load average: 2.1
# Available memory: 32GB
#
# Number of cores to use [12]:
# Press Enter to use suggested 12 cores, or enter a different number
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

### Input Validation and Troubleshooting
```bash
# Validate all required input files before running
./run_workflow.sh 1 check-inputs
./run_workflow.sh 4 check-inputs

# Fix common workflow issues
./run_workflow.sh 1 unlock          # Resolve lock errors
./run_workflow.sh 1 fix-incomplete  # Handle incomplete files

# Check workflow status and progress
./run_workflow.sh 1 status
./run_workflow.sh 4 dryrun
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

### Complete Workflow Examples
```bash
# Example 1: First-time setup and validation
./run_workflow.sh 1 check-inputs     # Validate requirements
./run_workflow.sh 1 setup           # Create environments
./run_workflow.sh 1                 # Run with interactive prompts

# Example 2: Troubleshooting interrupted workflows
./run_workflow.sh 1 unlock          # Clear locks
./run_workflow.sh 1 fix-incomplete  # Fix incomplete files
./run_workflow.sh 1 run --rerun-incomplete

# Example 3: Production run with manual control
./run_workflow.sh chip-seq run --cores 16 --rerun-incomplete
```

## Features

- **Unified Interface**: Single script for both workflows
- **Numeric Shortcuts**: Use `1` for ChIP-seq, `4` for totalRNA-seq
- **Interactive Selection**: Prompts for workflow selection when none specified
- **Smart Resource Detection**: Auto-detects system resources and suggests optimal core count
- **Auto-Unlock Stale Locks**: Automatically fixes locks from interrupted runs
- **Config-Aware Results Detection**: Reads actual results_dir from config.yaml
- **Index Fallback Support**: Validates source files for auto-building missing indexes
- **Overwrite Protection**: Prompts before overwriting existing results
- **Execution Timing**: Displays total runtime upon workflow completion
- **Default Command**: `run` is the default - just specify workflow to start
- **Environment Management**: Automatically activates `snakemake_env`
- **Error Handling**: Validates environments, auto-unlocks, and handles incomplete files
- **Flexible Options**: Configurable cores and advanced flags
- **Status Checking**: Monitor workflow progress
- **Easy Cleanup**: Remove results directories
- **Modern Snakemake**: Updated commands with `--rerun-incomplete` support

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

### Input File Issues
If workflows fail due to missing files:
```bash
# Check what's missing
./run_workflow.sh [workflow] check-inputs

# Follow the provided download and setup instructions
# Then validate again
./run_workflow.sh [workflow] check-inputs
```

### Lock and Incomplete File Issues
If workflows are interrupted (e.g., SSH disconnects):

**✨ Auto-unlock (recommended):**
The workflow manager automatically detects and unlocks stale locks when you run:
```bash
./run_workflow.sh [workflow] run
# The script will detect stale locks and auto-unlock before running
```

**Manual unlock (if needed):**
```bash
# Manually clear Snakemake locks
./run_workflow.sh [workflow] unlock

# Fix incomplete files
./run_workflow.sh [workflow] fix-incomplete

# Resume workflow
./run_workflow.sh [workflow] run --rerun-incomplete
```

**💡 Tip:** Use `screen` or `tmux` to prevent SSH disconnections:
```bash
screen -S workflow_run
./run_workflow.sh 1
# Press Ctrl+A then D to detach
# Later: screen -r workflow_run to reattach
```

## Workflow-Specific Notes

### totalRNA-seq
- **Input files**: Uses shared datasets in `Shared/DataFiles/datasets/totalrna-seq/`
- **Key features**: Automatic chromosome harmonization for UCSC/Ensembl compatibility
- **Output**: Results in `totalRNA-seq/results/`

### ChIP-seq
- **Input files**: Configure in workflow-specific config files
- **Output**: Results in `CHIP-seq/results/`

## Best Practices

- **Run from project root**: Always execute `./run_workflow.sh` from the project root directory
- **Use screen/tmux**: For long-running workflows, use `screen` or `tmux` to prevent SSH disconnections
- **Check inputs first**: Run `check-inputs` before starting a workflow to catch missing files early
- **Monitor progress**: Use `status` or `dryrun` commands to check workflow state
- **Preserve results**: The script will prompt before overwriting existing results
