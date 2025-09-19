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
    
    # Check for different result directory patterns
    if [[ "$workflow_dir" == "CHIP-seq" ]]; then
        # CHIP-seq uses configurable results directories
        for dir in "$workflow_dir"/results_*; do
            if [[ -d "$dir" ]] && [[ -n "$(ls -A "$dir" 2>/dev/null)" ]]; then
                existing_dirs+=("$dir")
            fi
        done
    elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
        # totalRNA-seq uses fixed "results" directory
        if [[ -d "$workflow_dir/results" ]] && [[ -n "$(ls -A "$workflow_dir/results" 2>/dev/null)" ]]; then
            existing_dirs+=("$workflow_dir/results")
        fi
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
    
    cd "${workflow_dir}"
    
    # Use conda run to execute in the snakemake_env environment
    conda run -n snakemake_env bash -c "
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
            START_TIME=$(date +%s)
            run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --use-conda --cores $CORES $EXTRA_FLAGS"
        else
            echo "Running $WORKFLOW workflow..."
            START_TIME=$(date +%s)
            run_snakemake "$WORKFLOW_DIR" "snakemake all --use-conda --cores $CORES $EXTRA_FLAGS"
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
        START_TIME=$(date +%s)
        run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --use-conda --cores $CORES $EXTRA_FLAGS"
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Workflow completed successfully!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
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
