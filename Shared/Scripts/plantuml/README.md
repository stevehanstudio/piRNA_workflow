# PlantUML Diagrams

This folder contains PlantUML (`.puml`) files that document workflow structures and project organization.

## Diagrams Overview

### **chipseq_workflow.puml**
- **Purpose**: Documents the complete CHIP-seq analysis workflow
- **Content**: Step-by-step workflow from raw FASTQ to final outputs
- **Features**: Sample-aware file naming, parallel processing paths
- **Output**: Visual representation of CHIP-seq pipeline
- **Usage**: Documentation and workflow understanding

## Workflow Documentation

### **CHIP-seq Workflow**
The CHIP-seq workflow processes two sample types:
- **ChIP sample**: Experimental sample with antibody enrichment
- **Input control**: Control sample without antibody enrichment

**Key Processing Paths**:
1. **Quality Control**: FastQC, adapter trimming, quality filtering
2. **Genome Mapping**: Bowtie alignment to dm6 reference
3. **Vector Mapping**: Bowtie alignment to vector sequences
4. **Signal Generation**: BigWig tracks and enrichment analysis
5. **Coverage Analysis**: Multiple bin sizes and resolutions
6. **Transposon Analysis**: Specialized transposon element analysis

### **File Naming Convention**
- **Sample-aware**: `{sample}.{filetype}` for individual samples
- **Comparison**: `{chip}_vs_{input}.enrichment.bigwig` for enrichment
- **Resolution-specific**: `{sample}.{binsize}.{strand}.bg4` for coverage
- **Transposon-specific**: `{sample}.{binsize}.{transposon}.{strand}.bg4`

## Usage

### **Viewing Diagrams**
```bash
# Install PlantUML
sudo apt-get install plantuml

# Generate PNG from PUML
plantuml chipseq_workflow.puml

# Generate SVG from PUML
plantuml -tsvg chipseq_workflow.puml
```

### **Online Viewer**
- Use [PlantUML Online Server](http://www.plantuml.com/plantuml/uml/)
- Copy and paste PUML content
- View generated diagrams

### **IDE Integration**
- **VS Code**: PlantUML extension
- **IntelliJ**: PlantUML plugin
- **Vim/Emacs**: PlantUML support

## Diagram Maintenance

### **When to Update**
- **Workflow changes** in Snakefiles
- **New processing steps** added
- **File naming** conventions change
- **Sample types** modified

### **Best Practices**
- **Keep diagrams current** with actual workflow
- **Use consistent naming** conventions
- **Include file outputs** for clarity
- **Document sample types** and relationships

## Future Diagrams

### **Planned Additions**
- **totalRNA-seq workflow** diagram
- **piRNA-seq workflow** diagram
- **Project structure** diagram
- **Data flow** diagram
- **Component relationships** diagram

### **Integration Goals**
- **Automated generation** from Snakefiles
- **Interactive diagrams** with clickable elements
- **Version control** integration
- **Documentation generation** pipeline

---

**Last Updated**: December 2024  
**Status**: Active - Workflow documentation
