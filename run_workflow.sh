#!/bin/bash

# piRNA Workflow Manager
# Unified script for running ChIP-seq and totalRNA-seq workflows

set -e  # Exit on any error

echo "======================================"
echo "   piRNA Workflow Manager"
echo "======================================"
echo ""

# Check if snakemake_env conda environment is available
check_environment() {
    if ! conda info --envs | grep -q snakemake_env; then
        echo "Error: snakemake_env conda environment not found."
        echo "Please create it first with:"
        echo "  conda create -n snakemake_env -c bioconda -c conda-forge snakemake"
        exit 1
    fi
}

# Function to detect system resources and suggest optimal core count
get_optimal_cores() {
    local total_cores=$(nproc)
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')

    # Calculate suggested cores based on system load
    local suggested_cores
    if (( $(echo "$load_avg < $total_cores * 0.3" | bc -l) )); then
        # Low load: use up to 75% of cores
        suggested_cores=$(echo "$total_cores * 0.75" | bc | cut -d. -f1)
    elif (( $(echo "$load_avg < $total_cores * 0.6" | bc -l) )); then
        # Medium load: use up to 50% of cores
        suggested_cores=$(echo "$total_cores * 0.5" | bc | cut -d. -f1)
    else
        # High load: use up to 25% of cores
        suggested_cores=$(echo "$total_cores * 0.25" | bc | cut -d. -f1)
    fi

    # Ensure at least 1 core
    if [[ $suggested_cores -lt 1 ]]; then
        suggested_cores=1
    fi

    echo $suggested_cores
}

# Function to prompt user for core count
prompt_cores() {
    local total_cores=$(nproc)
    local suggested_cores=$(get_optimal_cores)
    local load_avg=$(uptime | awk -F'load average:' '{ print $2 }' | awk '{ print $1 }' | sed 's/,//')
    local memory_gb=$(free -g | awk '/^Mem:/{print $2}')

    echo "=== System Resources ===" >&2
    echo "Total CPU cores: $total_cores" >&2
    echo "Current load average: $load_avg" >&2
    echo "Available memory: ${memory_gb}GB" >&2
    echo "" >&2

    while true; do
        read -p "Number of cores to use [$suggested_cores]: " user_cores >&2

        # Use suggested cores if user just presses enter
        if [[ -z "$user_cores" ]]; then
            echo $suggested_cores
            return
        fi

        # Validate user input
        if [[ "$user_cores" =~ ^[0-9]+$ ]] && [[ $user_cores -ge 1 ]] && [[ $user_cores -le $total_cores ]]; then
            echo $user_cores
            return
        else
            echo "Invalid input. Please enter a number between 1 and $total_cores." >&2
        fi
    done
}

# Function to check if outputs already exist
check_existing_outputs() {
    local workflow_dir=$1
    local existing_dirs=()

    # Try to read the actual configured results directory from config.yaml
    local config_file="$workflow_dir/config.yaml"
    local results_dir=""

    if [[ -f "$config_file" ]]; then
        # Extract results_dir from config.yaml
        # Look for: results_dir: "path" or results_dir: path
        results_dir=$(grep -E '^\s*results_dir\s*:\s*' "$config_file" | sed -E 's/^\s*results_dir\s*:\s*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//' | head -1)

        # If results_dir is relative, prepend workflow_dir
        if [[ -n "$results_dir" && ! "$results_dir" =~ ^/ ]]; then
            results_dir="$workflow_dir/$results_dir"
        fi
    fi

    # Fallback to default patterns if config reading failed
    if [[ -z "$results_dir" ]]; then
        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            results_dir="$workflow_dir/results"
        elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
            results_dir="$workflow_dir/results"
        fi
    fi

    # Check if the configured results directory exists and is non-empty
    if [[ -n "$results_dir" ]] && [[ -d "$results_dir" ]] && [[ -n "$(ls -A "$results_dir" 2>/dev/null)" ]]; then
        existing_dirs+=("$results_dir")
    fi

    # If existing results found, prompt user
    if [[ ${#existing_dirs[@]} -gt 0 ]]; then
        echo "Warning: Existing results directories found:" >&2
        echo "" >&2
        for dir in "${existing_dirs[@]}"; do
            echo "Directory: $dir" >&2
            echo "Contents:" >&2
            ls -la "$dir/" | head -5 >&2
            local file_count=$(ls -A "$dir" | wc -l)
            if [[ $file_count -gt 5 ]]; then
                echo "... and $(( file_count - 5 )) more items" >&2
            fi
            echo "" >&2
        done

        while true; do
            read -p "Do you want to proceed and potentially overwrite existing results? (y/N): " choice >&2
            case $choice in
                [Yy]* )
                    echo "FORCE_OVERWRITE"  # Signal that user wants to overwrite
                    return 0
                    ;;
                [Nn]* | "" )
                    echo "Operation cancelled by user." >&2
                    exit 0
                    ;;
                * )
                    echo "Please answer yes (y) or no (n)." >&2
                    ;;
            esac
        done
    fi
    return 0
}

# Function to check required input files
check_input_files() {
    local workflow_dir=$1
    local missing_files=()
    local missing_dirs=()
    local all_files_present=true

    echo "=== Input File Validation ===" >&2
    echo "Checking required input files for $workflow_dir workflow..." >&2
    echo "" >&2

    if [[ "$workflow_dir" == "CHIP-seq" ]]; then
        # CHIP-seq required files
        local required_files=(
            "Shared/DataFiles/genome/dm6.fa"
            "Shared/DataFiles/genome/dm6-blacklist.v2.bed.gz"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.chrom.sizes"
            "Shared/DataFiles/genome/AllAdaptors.fa"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.fa"
            "Shared/Scripts/python/trimfastq.py"
            "Shared/Scripts/python/makewigglefromBAM-NH.py"
        )

        local required_dirs=(
            "Shared/DataFiles/datasets/chip-seq/chip_inputs"
            "Shared/DataFiles/genome/bowtie-indexes"
            "Shared/DataFiles/genome/YichengVectors"
        )

        # Check for dm6 bowtie indexes: either indexes exist OR source file exists
        local dm6_bowtie_index_files=(
            "Shared/DataFiles/genome/bowtie-indexes/dm6.1.ebwt"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.2.ebwt"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.3.ebwt"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.4.ebwt"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.rev.1.ebwt"
            "Shared/DataFiles/genome/bowtie-indexes/dm6.rev.2.ebwt"
        )

        # Check if all dm6 index files exist
        local all_dm6_indexes_exist=true
        for index_file in "${dm6_bowtie_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_dm6_indexes_exist=false
                break
            fi
        done

        # If indexes don't exist, dm6.fa must exist (so Snakemake can build them)
        if [[ "$all_dm6_indexes_exist" == "false" ]]; then
            # dm6.fa is already in required_files, so we're good - Snakemake will build indexes
            echo "ℹ️  Note: dm6 bowtie indexes will be built from dm6.fa" >&2
        fi

        # Check for vector index files: either indexes exist OR source file exists
        local vector_index_files=(
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.1.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.2.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.3.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.4.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.rev.1.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.rev.2.ebwt"
        )

        # Check if all vector index files exist
        local all_vector_indexes_exist=true
        for index_file in "${vector_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_vector_indexes_exist=false
                break
            fi
        done

        # If indexes don't exist, 42AB_UBIG.fa must exist (so Snakemake can build them)
        if [[ "$all_vector_indexes_exist" == "false" ]]; then
            # 42AB_UBIG.fa is already in required_files, so we're good - Snakemake will build indexes
            echo "ℹ️  Note: Vector bowtie indexes will be built from 42AB_UBIG.fa" >&2
        fi

    elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
        # totalRNA-seq required files (basic files that are always needed)
        local required_files=(
            "Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq"
            "Shared/DataFiles/genome/dm6.fa"
            "Shared/DataFiles/genome/annotations/dm6.gtf"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.fa"
            "Shared/Scripts/python/trimfastq.py"
        )

        local required_dirs=(
            "Shared/DataFiles/datasets/totalrna-seq"
            "Shared/DataFiles/genome/rrna"
            "Shared/DataFiles/genome/annotations"
            "Shared/DataFiles/genome/YichengVectors"
        )

        # Check for rRNA: either source file OR index files must exist
        local rrna_source="Shared/DataFiles/genome/rrna/dmel_rRNA_unit.fa"
        local rrna_index_files=(
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.1.ebwt"
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.2.ebwt"
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.3.ebwt"
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.4.ebwt"
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.rev.1.ebwt"
            "Shared/DataFiles/genome/rrna/dmel_rRNA_unit.rev.2.ebwt"
        )

        # Check if rRNA indexes exist (preferred) or source file exists
        local rrna_available=false
        if [[ -f "$rrna_source" ]]; then
            rrna_available=true
            required_files+=("$rrna_source")
        else
            # Check if all index files exist
            local all_rrna_indexes_exist=true
            for index_file in "${rrna_index_files[@]}"; do
                if [[ ! -f "$index_file" ]]; then
                    all_rrna_indexes_exist=false
                    break
                fi
            done
            if [[ "$all_rrna_indexes_exist" == "true" ]]; then
                rrna_available=true
                # Don't add to required_files since they exist
            else
                # Neither source nor complete indexes exist
                required_files+=("${rrna_index_files[@]}")
            fi
        fi

        # Check for vector index files
        local vector_index_files=(
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.1.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.2.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.3.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.4.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.rev.1.ebwt"
            "Shared/DataFiles/genome/YichengVectors/42AB_UBIG.rev.2.ebwt"
        )

        required_files+=("${vector_index_files[@]}")
    fi

    # Check directories first
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
            all_files_present=false
        fi
    done

    # Check files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
            all_files_present=false
        fi
    done

    # Report results
    if [[ "$all_files_present" == "true" ]]; then
        echo "✅ All required input files are present!" >&2
        echo "" >&2
        return 0
    else
        echo "❌ Missing required input files:" >&2
        echo "" >&2

        if [[ ${#missing_dirs[@]} -gt 0 ]]; then
            echo "Missing directories:" >&2
            for dir in "${missing_dirs[@]}"; do
                echo "  • $dir" >&2
            done
            echo "" >&2
        fi

        if [[ ${#missing_files[@]} -gt 0 ]]; then
            echo "Missing files:" >&2
            for file in "${missing_files[@]}"; do
                echo "  • $file" >&2
            done
            echo "" >&2
        fi

        echo "📋 Required actions:" >&2
        echo "" >&2

        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            echo "1. Download and prepare reference files:" >&2
            echo "   • Download dm6.fa, dm6-blacklist.v2.bed.gz, AllAdaptors.fa" >&2
            echo "   • Build bowtie indexes: bowtie-build dm6.fa dm6" >&2
            echo "   • Build vector indexes: bowtie-build 42AB_UBIG.fa 42AB_UBIG" >&2
            echo "   • Create chromosome sizes: samtools faidx dm6.fa && cut -f1,2 dm6.fa.fai > dm6.chrom.sizes" >&2
            echo "" >&2
            echo "2. Place input FASTQ files in:" >&2
            echo "   Shared/DataFiles/datasets/chip-seq/chip_inputs/" >&2
            echo "" >&2
        elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
            echo "1. Download and prepare reference files:" >&2
            echo "   • Download dm6.fa, dm6.gtf, dmel_rRNA_unit.fa" >&2
            echo "   • Build rRNA index: bowtie-build dmel_rRNA_unit.fa dmel_rRNA_unit" >&2
            echo "   • Build vector index: bowtie-build 42AB_UBIG.fa 42AB_UBIG" >&2
            echo "" >&2
            echo "2. Place input FASTQ file:" >&2
            echo "   Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq" >&2
            echo "" >&2
        fi

        echo "3. For detailed setup instructions, see:" >&2
        echo "   • $workflow_dir/README.md" >&2
        echo "   • INDEX_BUILDING_STRATEGY.md" >&2
        echo "" >&2

        while true; do
            read -p "Would you like to proceed anyway? The workflow will likely fail. (y/N): " choice >&2
            case $choice in
                [Yy]* )
                    echo "⚠️  Proceeding with missing files - workflow may fail!" >&2
                    echo "" >&2
                    return 0
                    ;;
                [Nn]* | "" )
                    echo "Workflow cancelled. Please prepare the required files first." >&2
                    exit 1
                    ;;
                * )
                    echo "Please answer yes (y) or no (n)." >&2
                    ;;
            esac
        done
    fi
}

# Function to interactively select workflow
select_workflow() {
    echo "Available workflows:" >&2
    echo "  1) ChIP-seq analysis workflow" >&2
    echo "  4) Total RNA-seq analysis workflow" >&2
    echo "" >&2
    while true; do
        read -p "Please select a workflow (1 or 4): " choice >&2
        case $choice in
            1)
                echo "chip-seq"
                return
                ;;
            4)
                echo "totalrna-seq"
                return
                ;;
            *)
                echo "Invalid choice. Please enter 1 or 4." >&2
                ;;
        esac
    done
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [WORKFLOW] [COMMAND] [OPTIONS]"
    echo ""
    echo "Workflows:"
    echo "  1 | chip-seq      - ChIP-seq analysis workflow"
    echo "  4 | totalrna-seq  - Total RNA-seq analysis workflow"
    echo ""
    echo "Commands (default: run):"
    echo "  setup         - Create conda environments for the workflow"
    echo "  dryrun        - Show what will be executed (dry run)"
    echo "  run           - Run the complete workflow [DEFAULT]"
    echo "  run-force     - Force re-run all steps of the workflow"
    echo "  fix-incomplete - Fix incomplete files and continue workflow"
    echo "  check-inputs  - Validate all required input files are present"
    echo "  unlock        - Unlock workflow directory (fixes lock errors)"
    echo "  status        - Check workflow status and progress"
    echo "  clean         - Clean up output files"
    echo "  help          - Show this help message"
    echo ""
    echo "Options:"
    echo "  --cores N     - Number of CPU cores to use (prompts interactively if not specified)"
    echo "  --rerun-incomplete - Re-run incomplete jobs"
    echo ""
    echo "Interactive Features:"
    echo "  • Auto-detects system resources and suggests optimal core count"
    echo "  • Prompts before overwriting existing results"
    echo "  • Displays total execution time upon completion"
    echo "  • Interactive workflow selection if not specified"
    echo ""
    echo "Examples:"
    echo "  $0 1 run --cores 4        # Run ChIP-seq workflow with 4 cores"
    echo "  $0 chip-seq dryrun        # Dry run ChIP-seq workflow (will prompt for cores)"
    echo "  $0 4                      # Run totalRNA-seq (will prompt for cores)"
    echo "  $0 totalrna-seq status    # Check totalRNA-seq status"
    echo "  $0 1 fix-incomplete       # Fix incomplete ChIP-seq files and continue"
    echo "  $0 4 check-inputs         # Validate totalRNA-seq input files"
    echo "  $0                        # Interactive mode - prompts for workflow and cores"
    echo ""
    echo "Note: Workflows must be run from their respective directories."
}

# Function to activate snakemake environment and run command
run_snakemake() {
    local workflow_dir=$1
    local command=$2
    shift 2

    echo "Activating snakemake_env..."
    echo "Running in directory: ${workflow_dir}"
    echo "Command: ${command}"
    echo ""

    # Use conda run to execute in the snakemake_env environment with proper directory
    conda run -n snakemake_env bash -c "
        cd '${workflow_dir}'
        # Set up sm alias
        alias sm='snakemake'
        ${command}
    "
}

# Parse cores option and other flags
CORES=""
EXTRA_FLAGS=""
CORES_SPECIFIED=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --cores)
            CORES="$2"
            CORES_SPECIFIED=true
            shift 2
            ;;
        --rerun-incomplete)
            EXTRA_FLAGS="${EXTRA_FLAGS} --rerun-incomplete"
            shift
            ;;
        *)
            break
            ;;
    esac
done

# Parse workflow and command
WORKFLOW=${1:-}
COMMAND=${2:-run}

# If no workflow specified, interactively select one
if [[ -z "$WORKFLOW" ]]; then
    WORKFLOW=$(select_workflow)
    COMMAND="run"  # Default to run when interactively selected
fi

# Convert numeric workflow options
case "$WORKFLOW" in
    1)
        WORKFLOW="chip-seq"
        ;;
    4)
        WORKFLOW="totalrna-seq"
        ;;
esac

# Validate workflow
case "$WORKFLOW" in
    chip-seq)
        WORKFLOW_DIR="CHIP-seq"
        ;;
    totalrna-seq)
        WORKFLOW_DIR="totalRNA-seq"
        ;;
    help|--help|-h)
        show_usage
        exit 0
        ;;
    *)
        echo "Error: Unknown workflow '$WORKFLOW'"
        echo ""
        show_usage
        exit 1
        ;;
esac

# Check if workflow directory exists
if [[ ! -d "$WORKFLOW_DIR" ]]; then
    echo "Error: Workflow directory '$WORKFLOW_DIR' not found."
    exit 1
fi

# Check environment before running commands
if [[ "$COMMAND" != "help" ]]; then
    check_environment
fi

# Prompt for cores if not specified and running interactive commands
if [[ "$CORES_SPECIFIED" == "false" && ("$COMMAND" == "run" || "$COMMAND" == "run-force" || "$COMMAND" == "dryrun") ]]; then
    CORES=$(prompt_cores)
    echo "Using $CORES cores for execution." >&2
    echo "" >&2
elif [[ -z "$CORES" ]]; then
    CORES=8  # Default fallback
fi

# Check input files before running workflows (unless it's help, status, clean, unlock, or check-inputs)
if [[ "$COMMAND" != "help" && "$COMMAND" != "status" && "$COMMAND" != "clean" && "$COMMAND" != "unlock" && "$COMMAND" != "check-inputs" ]]; then
    check_input_files "$WORKFLOW_DIR"
fi

# Check for existing outputs before running destructive commands
FORCE_RERUN=false
if [[ "$COMMAND" == "run" || "$COMMAND" == "run-force" ]]; then
    OUTPUT_CHECK_RESULT=$(check_existing_outputs "$WORKFLOW_DIR")
    if [[ "$OUTPUT_CHECK_RESULT" == "FORCE_OVERWRITE" && "$COMMAND" == "run" ]]; then
        FORCE_RERUN=true
        echo "Note: Will force re-run all steps to ensure outputs are regenerated." >&2
        echo "" >&2
    fi
fi

# Execute commands
case "$COMMAND" in
    setup)
        echo "Setting up conda environments for $WORKFLOW..."
        run_snakemake "$WORKFLOW_DIR" "snakemake --use-conda --conda-create-envs-only all"
        echo "Setup completed successfully!"
        ;;
    dryrun)
        echo "Performing dry run for $WORKFLOW..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all --use-conda --cores $CORES --dry-run"
        ;;
    run)
        if [[ "$FORCE_RERUN" == "true" ]]; then
            echo "Force running $WORKFLOW workflow (all steps)..."
            echo "Note: Cleaning up any incomplete file metadata first..."
            run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata --use-conda" 2>/dev/null || true
            START_TIME=$(date +%s)
            run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --rerun-incomplete --use-conda --cores $CORES $EXTRA_FLAGS"
        else
            echo "Running $WORKFLOW workflow..."
            START_TIME=$(date +%s)
            # Try regular run first, if it fails with incomplete files, suggest fix-incomplete
            if ! run_snakemake "$WORKFLOW_DIR" "snakemake all --use-conda --cores $CORES $EXTRA_FLAGS"; then
                echo ""
                echo "❌ Workflow failed. This might be due to incomplete files from a previous run."
                echo "💡 Try running: $0 $WORKFLOW fix-incomplete"
                echo "   This will clean up incomplete files and resume the workflow."
                exit 1
            fi
        fi
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Workflow completed successfully!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
        ;;
    run-force)
        echo "Force running $WORKFLOW workflow (all steps)..."
        echo "Note: Cleaning up any incomplete file metadata first..."
        run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata --use-conda" 2>/dev/null || true
        START_TIME=$(date +%s)
        run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --rerun-incomplete --use-conda --cores $CORES $EXTRA_FLAGS"
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Workflow completed successfully!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
        ;;
    fix-incomplete)
        echo "Fixing incomplete files for $WORKFLOW workflow..."
        echo "Step 1: Attempting to clean up metadata for incomplete files..."
        # Try to cleanup metadata - this might fail if no specific files are provided, that's OK
        run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata --use-conda || true" 2>/dev/null || true
        echo ""
        echo "Step 2: Re-running workflow with incomplete file recovery..."
        START_TIME=$(date +%s)
        run_snakemake "$WORKFLOW_DIR" "snakemake all --rerun-incomplete --use-conda --cores $CORES $EXTRA_FLAGS"
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Incomplete files fixed and workflow completed!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
        ;;
    check-inputs)
        echo "Validating input files for $WORKFLOW workflow..."
        echo ""
        check_input_files "$WORKFLOW_DIR"
        ;;
    unlock)
        echo "Unlocking $WORKFLOW workflow directory..."
        run_snakemake "$WORKFLOW_DIR" "snakemake --unlock --use-conda"
        echo "Workflow directory unlocked successfully!"
        ;;
    status)
        echo "Checking $WORKFLOW workflow status..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all --use-conda --dry-run --quiet"
        if [[ -d "$WORKFLOW_DIR/results" ]]; then
            echo ""
            echo "Results directory contents:"
            ls -la "$WORKFLOW_DIR/results/"
        else
            echo ""
            echo "No results directory found - workflow hasn't been run yet."
        fi
        ;;
    clean)
        echo "Cleaning up $WORKFLOW output files..."
        if [[ -d "$WORKFLOW_DIR/results" ]]; then
            rm -rf "$WORKFLOW_DIR/results"
            echo "Cleanup completed!"
        else
            echo "No results directory to clean."
        fi
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'"
        echo ""
        show_usage
        exit 1
        ;;
esac
