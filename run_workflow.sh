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
    echo "  --cores N     - Number of CPU cores to use (default: 8)"
    echo "  --rerun-incomplete - Re-run incomplete jobs"
    echo ""
    echo "Examples:"
    echo "  $0 1 run --cores 4        # Run ChIP-seq workflow with 4 cores"
    echo "  $0 chip-seq dryrun        # Dry run ChIP-seq workflow"
    echo "  $0 4                      # Run totalRNA-seq (default command)"
    echo "  $0 totalrna-seq status    # Check totalRNA-seq status"
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

# Parse cores option
CORES=8
EXTRA_FLAGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --cores)
            CORES="$2"
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
    COMMAND=${1:-run}  # If no workflow was provided, treat first arg as command
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
        echo "Running $WORKFLOW workflow..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all --use-conda --cores $CORES $EXTRA_FLAGS"
        echo "Workflow completed successfully!"
        ;;
    run-force)
        echo "Force running $WORKFLOW workflow (all steps)..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --use-conda --cores $CORES $EXTRA_FLAGS"
        echo "Workflow completed successfully!"
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
