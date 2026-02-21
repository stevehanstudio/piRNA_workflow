#!/bin/bash
# Build samtools 0.1.8 from source (original pipeline version).
# Used when pre-built binaries are unavailable (e.g. ARM64 - x86 binary segfaults).
# Run from project root: ./Shared/Scripts/shell/ensure_samtools_018.sh
# Source: https://sourceforge.net/projects/samtools/files/samtools/0.1.8/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SAMTOOLS_018_DIR="${PROJECT_ROOT}/Shared/Scripts/bin/samtools-0.1.8"
SAMTOOLS_BIN="${SAMTOOLS_018_DIR}/samtools"
SRC_CACHE="${PROJECT_ROOT}/Shared/Scripts/bin/.samtools_018_src"
SAMTOOLS_URL="https://sourceforge.net/projects/samtools/files/samtools/0.1.8/samtools-0.1.8.tar.bz2/download"
TARBALL="samtools-0.1.8.tar.bz2"

# Check if already built and working
if [[ -x "$SAMTOOLS_BIN" ]]; then
    if "$SAMTOOLS_BIN" 2>&1 | head -1 | grep -q "samtools"; then
        echo "samtools 0.1.8 already installed at: $SAMTOOLS_BIN"
        exit 0
    fi
    echo "Existing binary appears broken, rebuilding..."
    rm -f "$SAMTOOLS_BIN"
fi

# Check build dependencies
MISSING_DEPS=()
command -v gcc &>/dev/null || MISSING_DEPS+=("gcc")
command -v make &>/dev/null || MISSING_DEPS+=("make")
echo '#include <zlib.h>' | gcc -x c - -fsyntax-only -lz &>/dev/null || MISSING_DEPS+=("zlib (zlib1g-dev or zlib-devel)")

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "Error: Missing build dependencies:" >&2
    printf '  - %s\n' "${MISSING_DEPS[@]}" >&2
    echo "" >&2
    echo "On Ubuntu/Debian: sudo apt-get install build-essential zlib1g-dev" >&2
    echo "On RHEL/Fedora:   sudo dnf install gcc make zlib-devel" >&2
    exit 1
fi

# Create target directory
mkdir -p "$SAMTOOLS_018_DIR"

# Download source
mkdir -p "$SRC_CACHE"
if [[ ! -f "$SRC_CACHE/$TARBALL" ]]; then
    echo "Downloading samtools 0.1.8 source..."
    curl -sL "$SAMTOOLS_URL" -o "$SRC_CACHE/$TARBALL" || \
        wget -q -O "$SRC_CACHE/$TARBALL" "$SAMTOOLS_URL" || {
        echo "Error: Failed to download samtools 0.1.8" >&2
        exit 1
    }
fi

# Build
BUILD_DIR=$(mktemp -d)
trap "rm -rf '$BUILD_DIR'" EXIT

echo "Building samtools 0.1.8 from source..."
tar -xjf "$SRC_CACHE/$TARBALL" -C "$BUILD_DIR"
cd "$BUILD_DIR/samtools-0.1.8"

# Disable ncurses (optional dep; avoids libncurses-dev requirement)
sed -i 's/-D_CURSES_LIB=1/-D_CURSES_LIB=0/' Makefile
sed -i 's/^LIBCURSES=	-lcurses/LIBCURSES=	# -lcurses/' Makefile

make -j$(nproc 2>/dev/null || echo 1)

# Install
cp samtools "$SAMTOOLS_BIN"
chmod +x "$SAMTOOLS_BIN"

echo "samtools 0.1.8 installed at: $SAMTOOLS_BIN"
exit 0
