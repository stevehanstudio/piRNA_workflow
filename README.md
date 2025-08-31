# Shared Scripts

This directory contains scripts organized by type for the piRNA workflow project.

## Directory Structure

```
Scripts/
├── python/          # Python scripts for data processing
├── shell/           # Bash/shell scripts for setup and maintenance
├── plantuml/        # PlantUML diagrams for workflow documentation
└── README.md        # This file
```

## Script Categories

### **Python Scripts** (`python/`)
- **Data processing** scripts used by workflows
- **Legacy Python 2.7** scripts (managed via conda)
- **Modern Python 3** scripts for new functionality
- **Automatically managed** by Snakemake workflows

### **Shell Scripts** (`shell/`)
- **Setup scripts** for initial configuration
- **Maintenance scripts** for updates and maintenance
- **Index building** scripts for bioinformatics tools
- **File download** and preparation scripts

### **PlantUML Diagrams** (`plantuml/`)
- **Workflow documentation** in visual format
- **Project structure** diagrams
- **Data flow** representations
- **Component relationship** diagrams

## Quick Start

### **Python Scripts**
```bash
# Scripts are automatically used by workflows
# No manual execution required
cd python/
ls -la  # View available scripts
```

### **Shell Scripts**
```bash
# Setup scripts for initial configuration
cd shell/
chmod +x *.sh  # Make executable
./create_star_index.sh  # Create STAR index
./create_rrna_index.sh  # Create rRNA index
```

### **PlantUML Diagrams**
```bash
# View workflow diagrams
cd plantuml/
plantuml chipseq_workflow.puml  # Generate PNG
# Or use online viewer: http://www.plantuml.com/plantuml/uml/
```

## Script Management

### **Adding New Scripts**
1. **Python scripts** → `python/` folder
2. **Shell scripts** → `shell/` folder
3. **PlantUML diagrams** → `plantuml/` folder
4. **Update README** in appropriate folder
5. **Test functionality** before committing

### **Script Dependencies**
- **Python scripts**: Managed by conda environments
- **Shell scripts**: Require bioinformatics tools (Bowtie, STAR, etc.)
- **PlantUML**: Requires PlantUML installation for generation

### **Version Control**
- **All scripts** are version controlled
- **Generated outputs** are ignored by .gitignore
- **Index files** are built automatically, not stored

## Integration with Workflows

### **Snakemake Integration**
- **Python scripts** are called by Snakefile rules
- **Paths updated** to use new folder structure
- **Automatic execution** during workflow runs

### **Path References**
```python
# Updated paths in Snakefiles
SHARED_SCRIPTS = "../Shared/Scripts"
TRIMFASTQ_SCRIPT = f"{SHARED_SCRIPTS}/python/trimfastq.py"
```

## Maintenance

### **Regular Tasks**
- **Update documentation** when scripts change
- **Test functionality** after modifications
- **Validate outputs** for correctness
- **Check dependencies** for updates

### **Quality Assurance**
- **Code review** for new scripts
- **Testing** in different environments
- **Documentation** updates
- **Error handling** improvements

## Future Improvements

### **Script Modernization**
- **Python 3 conversion** for legacy scripts
- **Enhanced error handling** and logging
- **Unit testing** framework
- **Parameter validation**

### **Automation**
- **CI/CD integration** for script testing
- **Automated documentation** generation
- **Dependency management** automation
- **Performance monitoring**

---

**Last Updated**: December 2024  
**Status**: Active - Organized and documented
