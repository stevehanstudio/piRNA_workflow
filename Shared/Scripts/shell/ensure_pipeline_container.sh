#!/bin/bash
# Build or ensure the single pipeline container is available (Apptainer only).
# Run from project root: ./Shared/Scripts/shell/ensure_pipeline_container.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PIPELINE_SIF="${PROJECT_ROOT}/containers/pirna_pipeline.sif"
PIPELINE_DEF="${PROJECT_ROOT}/containers/pipeline.def"

# Use sudo for Apptainer when unprivileged execution fails (APPTAINER_SUDO=1)
APPTAINER_CMD="apptainer"
[[ "${APPTAINER_SUDO:-0}" == "1" ]] && APPTAINER_CMD="sudo apptainer"

# Check if SIF already exists and works
if [[ -f "$PIPELINE_SIF" ]]; then
    if $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
        echo "Pipeline container already installed at: $PIPELINE_SIF"
        exit 0
    fi
    echo "Existing SIF appears corrupted, rebuilding..."
    rm -f "$PIPELINE_SIF"
fi

# Require Apptainer
if ! command -v apptainer &>/dev/null; then
    echo "Error: Apptainer is not installed or not in PATH." >&2
    echo "Install Apptainer: https://apptainer.org/docs/admin/latest/installation.html" >&2
    exit 1
fi

# Verify definition file and cpuid source exist
if [[ ! -f "$PIPELINE_DEF" ]]; then
    echo "Error: Apptainer definition not found at $PIPELINE_DEF" >&2
    exit 1
fi
if [[ ! -f "$PROJECT_ROOT/CHIP-seq/envs/cpuid_arm64.h" ]]; then
    echo "Error: CHIP-seq/envs/cpuid_arm64.h not found (required for Bowtie ARM64 build)." >&2
    exit 1
fi

build_success=false
build_error=""

# Method 1: Standard Apptainer build (from .def, no Docker)
echo "Building pipeline container with Apptainer (from definition file)..."
cd "$PROJECT_ROOT"
build_error=$(apptainer build "$PIPELINE_SIF" "$PIPELINE_DEF" 2>&1) || true
if [[ -f "$PIPELINE_SIF" ]] && $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
    build_success=true
fi

# Method 2: Fakeroot (unprivileged build when user namespaces enabled)
if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]] || [[ "$build_error" == *"permission"* ]]; }; then
    echo "Standard build requires privileges. Trying --fakeroot..."
    rm -f "$PIPELINE_SIF"
    if apptainer build --fakeroot "$PIPELINE_SIF" "$PIPELINE_DEF" 2>/dev/null; then
        if $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
            build_success=true
        fi
    fi
fi

# Method 3: sudo apptainer build (when user has sudo)
if [[ "$build_success" != "true" ]] && [[ "$(id -u)" != "0" ]] && command -v sudo &>/dev/null; then
    echo "Trying sudo apptainer build (one-time, may prompt for password)..."
    rm -f "$PIPELINE_SIF"
    if (cd "$PROJECT_ROOT" && sudo apptainer build "$PIPELINE_SIF" "$PIPELINE_DEF" 2>/dev/null); then
        if $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
            build_success=true
        fi
    fi
fi

if [[ "$build_success" == "true" ]]; then
    # Fix ownership if SIF was built as root (sudo)
    if [[ "$(stat -c %u "$PIPELINE_SIF" 2>/dev/null)" == "0" ]]; then
        run_user="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
        [[ -z "$run_user" ]] && run_user="$USER"
        sudo chown "${run_user}:" "$PIPELINE_SIF" 2>/dev/null || true
    fi
    echo "Pipeline container installed at: $PIPELINE_SIF"
    exit 0
fi

# All methods failed
echo "" >&2
echo "Error: Could not build pipeline container." >&2
echo "" >&2
echo "Original error:" >&2
echo "$build_error" | head -10 >&2
echo "" >&2
echo "Options:" >&2
echo "  1. Build with sudo (recommended): sudo $0" >&2
echo "     Or run: cd $PROJECT_ROOT && sudo apptainer build $PIPELINE_SIF $PIPELINE_DEF" >&2
echo "     Then: sudo chown \$(whoami): $PIPELINE_SIF" >&2
echo "  2. Enable user namespaces (admin): sysctl kernel.unprivileged_userns_clone=1" >&2
exit 1
