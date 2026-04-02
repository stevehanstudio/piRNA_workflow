#!/bin/bash
# Ensure Cutadapt 1.8.3 container is built (Python 2.7, original pipeline version).
# Apptainer only. Run from project root: ./Shared/Scripts/shell/ensure_cutadapt.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CUTADAPT_SIF="${PROJECT_ROOT}/CHIP-seq/envs/cutadapt_1.8.3.sif"
PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$PROJECT_ROOT/containers/pirna_pipeline.sif}"

# When pipeline container exists (SIF), Cutadapt is built-in - skip individual build
if [[ -f "$PIPELINE_SIF" ]]; then
    echo "Cutadapt 1.8.3 is available from pipeline container (no separate build needed)"
    exit 0
fi
CUTADAPT_DEF="${PROJECT_ROOT}/CHIP-seq/envs/cutadapt_1.8.3.def"
DEF_DIR="$(dirname "$CUTADAPT_DEF")"
HAS_APPTAINER=false
command -v apptainer &>/dev/null && HAS_APPTAINER=true

# Check if SIF already exists and is valid (Apptainer path)
if [[ -f "$CUTADAPT_SIF" ]] && [[ "$HAS_APPTAINER" == "true" ]]; then
    if apptainer exec "$CUTADAPT_SIF" cutadapt --version &>/dev/null; then
        echo "Cutadapt 1.8.3 is already installed at: $CUTADAPT_SIF"
        exit 0
    fi
    echo "Existing SIF appears corrupted, rebuilding..."
    rm -f "$CUTADAPT_SIF"
fi

build_success=false
build_error=""

# Method 1: Apptainer standard build
if [[ "$HAS_APPTAINER" == "true" ]]; then
    echo "Building Cutadapt 1.8.3 Apptainer image..."
    build_error=$(cd "$DEF_DIR" && apptainer build "$(realpath "$CUTADAPT_SIF")" "$(basename "$CUTADAPT_DEF")" 2>&1) || true
    if [[ -f "$CUTADAPT_SIF" ]] && apptainer exec "$CUTADAPT_SIF" cutadapt --version &>/dev/null; then
        build_success=true
    fi

    # Method 2: Fakeroot
    if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
        echo "Trying --fakeroot..."
        rm -f "$CUTADAPT_SIF"
        if (cd "$DEF_DIR" && apptainer build --fakeroot "$(realpath "$CUTADAPT_SIF")" "$(basename "$CUTADAPT_DEF")" 2>/dev/null); then
            build_success=true
        fi
    fi
fi

# Method 3: Apptainer remote builder
if [[ "$build_success" != "true" ]] && [[ "$HAS_APPTAINER" == "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
    echo "Trying remote builder..."
    rm -f "$CUTADAPT_SIF"
    if (cd "$DEF_DIR" && apptainer build --remote "$(realpath "$CUTADAPT_SIF")" "$(basename "$CUTADAPT_DEF")" 2>/dev/null); then
        build_success=true
    fi
fi

if [[ "$build_success" == "true" ]]; then
    if [[ -n "$SUDO_USER" ]] && [[ "$(stat -c %u "$CUTADAPT_SIF" 2>/dev/null)" == "0" ]]; then
        chown "$SUDO_USER:" "$CUTADAPT_SIF" 2>/dev/null || sudo chown "$SUDO_USER:" "$CUTADAPT_SIF"
    fi
    echo "Cutadapt 1.8.3 installed at: $CUTADAPT_SIF"
    exit 0
fi

echo "Error: Could not build Cutadapt container." >&2
[[ -n "$build_error" ]] && echo "$build_error" | head -5 >&2
exit 1
