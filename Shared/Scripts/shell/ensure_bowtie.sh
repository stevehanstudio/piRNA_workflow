#!/bin/bash
# Ensure patched Bowtie 1.0.1 (hamrhein_nh) Apptainer image is built.
# Run from project root: ./Shared/Scripts/shell/ensure_bowtie.sh
# Source: https://github.com/Peng-He-Lab/bowtie-1.0.1-hamrhein_nh_patch

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
BOWTIE_SIF="${PROJECT_ROOT}/CHIP-seq/envs/bowtie_1.0.1_nh.sif"
BOWTIE_DEF="${PROJECT_ROOT}/CHIP-seq/envs/bowtie_1.0.1_nh.def"
PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$PROJECT_ROOT/containers/pirna_pipeline.sif}"

# When pipeline container exists (SIF), Bowtie is built-in - skip individual build
if [[ -f "$PIPELINE_SIF" ]]; then
    echo "Bowtie 1.0.1-nh is available from pipeline container (no separate build needed)"
    exit 0
fi

# Check if Apptainer is available
if ! command -v apptainer &>/dev/null; then
    echo "Error: Apptainer is not installed or not in PATH." >&2
    echo "Install Apptainer: https://apptainer.org/docs/admin/latest/installation.html" >&2
    exit 1
fi

# Check if SIF already exists and is valid
if [[ -f "$BOWTIE_SIF" ]]; then
    if apptainer exec "$BOWTIE_SIF" bowtie --version &>/dev/null; then
        echo "Bowtie 1.0.1-nh is already installed at: $BOWTIE_SIF"
        exit 0
    fi
    echo "Existing SIF appears corrupted, rebuilding..."
    rm -f "$BOWTIE_SIF"
fi

# Build the image - try multiple methods for unprivileged systems
build_success=false
build_error=""

# Method 1: Standard build (works with root/setuid)
echo "Building Bowtie 1.0.1-nh Apptainer image..."
DEF_DIR="$(dirname "$BOWTIE_DEF")"
build_error=$(cd "$DEF_DIR" && apptainer build "$(realpath "$BOWTIE_SIF")" "$(basename "$BOWTIE_DEF")" 2>&1) || true
if [[ -f "$BOWTIE_SIF" ]] && apptainer exec "$BOWTIE_SIF" bowtie --version &>/dev/null; then
    build_success=true
fi

# Method 2: Fakeroot (works if user namespaces enabled)
if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
    echo "Standard build requires privileges. Trying --fakeroot..."
    rm -f "$BOWTIE_SIF"
    if (cd "$DEF_DIR" && apptainer build --fakeroot "$(realpath "$BOWTIE_SIF")" "$(basename "$BOWTIE_DEF")" 2>/dev/null); then
        build_success=true
    fi
fi

# Method 3: Remote builder (Sylabs Cloud)
if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
    echo "Trying remote builder (Sylabs Cloud)..."
    rm -f "$BOWTIE_SIF"
    if (cd "$DEF_DIR" && apptainer build --remote "$(realpath "$BOWTIE_SIF")" "$(basename "$BOWTIE_DEF")" 2>/dev/null); then
        build_success=true
    fi
fi

if [[ "$build_success" == "true" ]]; then
    if [[ -n "$SUDO_USER" ]] && [[ "$(stat -c %u "$BOWTIE_SIF" 2>/dev/null)" == "0" ]]; then
        chown "$SUDO_USER:" "$BOWTIE_SIF" 2>/dev/null || sudo chown "$SUDO_USER:" "$BOWTIE_SIF"
    fi
    echo "Bowtie 1.0.1-nh installed at: $BOWTIE_SIF"
    exit 0
fi

# Build failed
echo "" >&2
echo "Error: Could not build Bowtie Apptainer image." >&2
echo "" >&2
echo "Original error:" >&2
echo "$build_error" | head -10 >&2
echo "" >&2
echo "Options: sudo $0  |  apptainer remote login + re-run" >&2
exit 1
