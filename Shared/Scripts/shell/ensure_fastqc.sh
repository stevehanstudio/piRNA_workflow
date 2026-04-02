#!/bin/bash
# Ensure FastQC 0.11.3 Apptainer image is built.
# Run from project root: ./Shared/Scripts/shell/ensure_fastqc.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
FASTQC_SIF="${PROJECT_ROOT}/CHIP-seq/envs/fastqc_0.11.3.sif"
PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$PROJECT_ROOT/containers/pirna_pipeline.sif}"

# When pipeline container exists (SIF), FastQC is built-in - skip individual build
if [[ -f "$PIPELINE_SIF" ]]; then
    echo "FastQC 0.11.3 is available from pipeline container (no separate build needed)"
    exit 0
fi
FASTQC_DEF="${PROJECT_ROOT}/CHIP-seq/envs/fastqc_0.11.3.def"

# Check if Apptainer is available
if ! command -v apptainer &>/dev/null; then
    echo "Error: Apptainer is not installed or not in PATH." >&2
    echo "Install Apptainer: https://apptainer.org/docs/admin/latest/installation.html" >&2
    exit 1
fi

# Check if SIF already exists and is valid
if [[ -f "$FASTQC_SIF" ]]; then
    if apptainer exec "$FASTQC_SIF" true &>/dev/null; then
        echo "FastQC 0.11.3 is already installed at: $FASTQC_SIF"
        exit 0
    fi
    echo "Existing SIF appears corrupted, rebuilding..."
    rm -f "$FASTQC_SIF"
fi

# Build the image - try multiple methods for unprivileged systems
build_success=false
build_error=""

# Method 1: Standard build (works with root/setuid)
echo "Building FastQC 0.11.3 Apptainer image..."
build_error=$(apptainer build "$FASTQC_SIF" "$FASTQC_DEF" 2>&1) || true
if [[ -f "$FASTQC_SIF" ]] && apptainer exec "$FASTQC_SIF" true &>/dev/null; then
    build_success=true
fi

# Method 2: Fakeroot (works if user namespaces enabled)
if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
    echo "Standard build requires privileges. Trying --fakeroot..."
    rm -f "$FASTQC_SIF"
    if apptainer build --fakeroot "$FASTQC_SIF" "$FASTQC_DEF" 2>/dev/null; then
        build_success=true
    fi
fi

# Method 3: Remote builder (Sylabs Cloud - no local privileges needed)
if [[ "$build_success" != "true" ]] && { [[ "$build_error" == *"mount namespace"* ]] || [[ "$build_error" == *"privileges"* ]]; }; then
    echo "Trying remote builder (Sylabs Cloud)..."
    rm -f "$FASTQC_SIF"
    if apptainer build --remote "$FASTQC_SIF" "$FASTQC_DEF" 2>/dev/null; then
        build_success=true
    fi
fi

if [[ "$build_success" == "true" ]]; then
    # If built with sudo, chown to the actual user so they can use it
    if [[ -n "$SUDO_USER" ]] && [[ "$(stat -c %u "$FASTQC_SIF" 2>/dev/null)" == "0" ]]; then
        chown "$SUDO_USER:" "$FASTQC_SIF" 2>/dev/null || sudo chown "$SUDO_USER:" "$FASTQC_SIF"
    fi
    echo "FastQC 0.11.3 installed at: $FASTQC_SIF"
    exit 0
fi

# Build failed - print helpful message
echo "" >&2
echo "Error: Could not build FastQC Apptainer image." >&2
echo "" >&2
echo "Original error:" >&2
echo "$build_error" | head -5 >&2
echo "" >&2
echo "Apptainer build requires one of the following:" >&2
echo "" >&2
echo "Option 1 - Build with sudo (one-time, recommended):" >&2
echo "  sudo $0" >&2
echo "  # Then fix ownership so you can use it: sudo chown \$(whoami): \"$FASTQC_SIF\"" >&2
echo "" >&2
echo "Option 2 - Use remote builder (no root needed):" >&2
echo "  1. Create free account: https://cloud.sylabs.io/" >&2
echo "  2. Get token and run: apptainer remote login" >&2
echo "  3. Re-run this workflow" >&2
echo "" >&2
echo "Option 3 - Enable user namespaces (requires admin):" >&2
echo "  sudo sysctl -w kernel.unprivileged_userns_clone=1" >&2
echo "  sudo sysctl -w user.max_usernamespaces=15076" >&2
echo "" >&2
exit 1
