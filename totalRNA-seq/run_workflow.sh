#!/bin/bash

# TotalRNA-seq Snakemake Workflow Runner
# This script provides easy commands for running the workflow

set -e  # Exit on any error

echo "TotalRNA-seq Snakemake Workflow"
echo "================================"

# Check if Snakemake is installed
if ! command -v snakemake &> /dev/null; then
    echo "Error: Snakemake is not installed."
    echo "Please install it first: conda install -c bioconda -c conda-forge snakemake"
    exit 1
fi

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  setup     - Create conda environments"
    echo "  dryrun    - Show what will be executed (dry run)"
    echo "  run       - Run the complete workflow"
    echo "  clean     - Clean up output files"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup"
    echo "  $0 dryrun"
    echo "  $0 run"
}

# Function to create conda environments
setup_environments() {
    echo "Creating conda environments..."
    snakemake --use-conda --conda-create-envs-only
    echo "Conda environments created successfully!"
}

# Function to run dry run
dry_run() {
    echo "Performing dry run..."
    snakemake --use-conda --dryrun
}

# Function to run the workflow
run_workflow() {
    echo "Running the complete workflow..."
    snakemake --use-conda --cores 4
    echo "Workflow completed successfully!"
}

# Function to clean up
clean_up() {
    echo "Cleaning up output files..."
    rm -rf results/
    echo "Cleanup completed!"
}

# Main script logic
case "${1:-help}" in
    setup)
        setup_environments
        ;;
    dryrun)
        dry_run
        ;;
    run)
        run_workflow
        ;;
    clean)
        clean_up
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
