#!/bin/bash
# Verify the single pipeline container is available (Apptainer only).
# IMPORTANT: This script must NOT rebuild automatically. Many servers/HPC systems
# do not permit unprivileged builds, and users should never be prompted to build
# or lose an existing image due to an overly aggressive health check.
#
# Run from project root: ./Shared/Scripts/shell/ensure_pipeline_container.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# Default: repo-relative image. Override for shared/cached SIFs: export PIRNA_PIPELINE_SIF=/path/to/pirna_pipeline.sif
PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$PROJECT_ROOT/containers/pirna_pipeline.sif}"
PIPELINE_DEF="${PROJECT_ROOT}/containers/pipeline.def"

# Use sudo for Apptainer exec when unprivileged execution fails (APPTAINER_SUDO=1)
APPTAINER_CMD="apptainer"
[[ "${APPTAINER_SUDO:-0}" == "1" ]] && APPTAINER_CMD="sudo apptainer"

# Require Apptainer runtime
if ! command -v apptainer &>/dev/null; then
    echo "Error: Apptainer is not installed or not in PATH." >&2
    echo "Install Apptainer: https://apptainer.org/docs/admin/latest/installation.html" >&2
    exit 1
fi

# Check if SIF exists
if [[ ! -f "$PIPELINE_SIF" ]]; then
    echo "Error: Pipeline container not found at: $PIPELINE_SIF" >&2
    echo "" >&2
    echo "This workflow expects a prebuilt pipeline container (Option A)." >&2
    echo "Ask your lab/admin to build it once on a machine with build permissions, then copy it here." >&2
    echo "" >&2
    echo "Use a different path (e.g. lab share) without copying into the repo:" >&2
    echo "  export PIRNA_PIPELINE_SIF=/path/to/pirna_pipeline.sif" >&2
    echo "  # or: ./run_workflow.sh ... --use-apptainer --pipeline-sif /path/to/pirna_pipeline.sif" >&2
    echo "" >&2
    echo "Build command (admin/dev machine):" >&2
    echo "  cd $PROJECT_ROOT && sudo apptainer build containers/pirna_pipeline.sif containers/pipeline.def" >&2
    echo "" >&2
    echo "Then copy the resulting SIF to this path (or set PIRNA_PIPELINE_SIF):" >&2
    echo "  $PIPELINE_SIF" >&2
    exit 1
fi

# Health check (do NOT delete on failure)
if $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
    echo "Pipeline container is available at: $PIPELINE_SIF"
    exit 0
fi

echo "Error: Pipeline container exists but failed to run: $PIPELINE_SIF" >&2
echo "" >&2
echo "This can happen if the SIF is wrong-architecture, partially copied, or otherwise unusable on this host." >&2
echo "" >&2
echo "To diagnose, run:" >&2
echo "  $APPTAINER_CMD exec \"$PIPELINE_SIF\" snakemake --version" >&2
echo "" >&2
echo "Do NOT rebuild on this machine unless you have build permissions. Re-copy a known-good prebuilt SIF instead." >&2
exit 1
