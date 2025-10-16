# Shared Scripts

This directory contains scripts and workflow diagrams shared across all pipelines.

## Directory Structure

```
Scripts/
├── python/          # Python scripts for data processing
├── shell/           # Bash scripts for setup and index building
├── mermaid/         # Mermaid workflow diagrams
└── README.md        # This file
```

## Script Categories

### **Python Scripts** (`python/`)
- Data processing scripts used by workflows
- Automatically managed by Snakemake workflows via conda environments

### **Shell Scripts** (`shell/`)
- Index building scripts (STAR, rRNA, Bowtie)
- Data download and preparation utilities

### **Mermaid Diagrams** (`mermaid/`)
- Workflow visualization in Mermaid format
- `chipseq_workflow.mmd` - ChIP-seq pipeline diagram
- `totalrnaseq_workflow.mmd` - TotalRNA-seq pipeline diagram
- Renders natively on GitHub

## Usage

### **Python Scripts**
Python scripts are automatically invoked by Snakemake workflows - no manual execution needed.

### **Shell Scripts**
```bash
cd shell/
chmod +x *.sh
./create_star_index.sh  # Build STAR genome index
./create_rrna_index.sh  # Build rRNA index
```

### **Mermaid Diagrams**
View `.mmd` files directly on GitHub, or generate PNGs using [Mermaid Chart](https://www.mermaidchart.com/):
1. Copy the contents of the `.mmd` file
2. Paste into the Mermaid Chart editor
3. Export as PNG and save to `../../DataFiles/workflow_images/`

## Snakemake Integration

Python scripts are referenced in Snakefiles using relative paths:
```python
SHARED_SCRIPTS = "../Shared/Scripts"
TRIMFASTQ_SCRIPT = f"{SHARED_SCRIPTS}/python/trimfastq.py"
```

Dependencies are automatically managed by conda environments defined in each workflow's `envs/` directory.

## Related Documentation

- **[Main Project README](../../README.md)**: Overview of the piRNA workflow project
- **[Shared Resources README](../README.md)**: DataFiles and shared resources
- **[Workflow Manager Guide](../../WORKFLOW_MANAGER.md)**: Workflow execution guide
