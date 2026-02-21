#!/bin/bash
# Build samtools 0.1.16 from source (original pipeline version).
# Used when pre-built x86 binary segfaults on ARM64 (e.g. under Box64 emulation).
# Run from project root: ./Shared/Scripts/shell/ensure_samtools_016.sh
# Source: https://sourceforge.net/projects/samtools/files/samtools/0.1.16/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SAMTOOLS_016_DIR="${PROJECT_ROOT}/Shared/Scripts/bin/samtools-0.1.16"
SAMTOOLS_BIN="${SAMTOOLS_016_DIR}/samtools"
SRC_CACHE="${PROJECT_ROOT}/Shared/Scripts/bin/.samtools_016_src"
SAMTOOLS_URL="https://sourceforge.net/projects/samtools/files/samtools/0.1.16/samtools-0.1.16.tar.bz2/download"
TARBALL="samtools-0.1.16.tar.bz2"

# Check if already built and working
if [[ -x "$SAMTOOLS_BIN" ]]; then
    # On ARM64, pre-built x86 binary segfaults under Box64; require native build
    if command -v file &>/dev/null; then
        if file "$SAMTOOLS_BIN" 2>/dev/null | grep -q "x86-64"; then
            echo "Existing binary is x86 (segfaults on ARM64), rebuilding for native arch..."
            rm -f "$SAMTOOLS_BIN"
        elif "$SAMTOOLS_BIN" rmdup 2>&1 | head -1 | grep -q "Usage:"; then
            echo "samtools 0.1.16 already installed at: $SAMTOOLS_BIN"
            exit 0
        else
            echo "Existing binary appears broken, rebuilding..."
            rm -f "$SAMTOOLS_BIN"
        fi
    elif "$SAMTOOLS_BIN" rmdup 2>&1 | head -1 | grep -q "Usage:"; then
        echo "samtools 0.1.16 already installed at: $SAMTOOLS_BIN"
        exit 0
    else
        echo "Existing binary appears broken, rebuilding..."
        rm -f "$SAMTOOLS_BIN"
    fi
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
mkdir -p "$SAMTOOLS_016_DIR"

# Download source
mkdir -p "$SRC_CACHE"
if [[ ! -f "$SRC_CACHE/$TARBALL" ]]; then
    echo "Downloading samtools 0.1.16 source..."
    curl -sL "$SAMTOOLS_URL" -o "$SRC_CACHE/$TARBALL" || \
        wget -q -O "$SRC_CACHE/$TARBALL" "$SAMTOOLS_URL" || {
        echo "Error: Failed to download samtools 0.1.16" >&2
        exit 1
    }
fi

# Build
BUILD_DIR=$(mktemp -d)
trap "rm -rf '$BUILD_DIR'" EXIT

echo "Building samtools 0.1.16 from source..."
tar -xjf "$SRC_CACHE/$TARBALL" -C "$BUILD_DIR"
cd "$BUILD_DIR/samtools-0.1.16"

# Disable ncurses (optional dep)
sed -i 's/-D_CURSES_LIB=1/-D_CURSES_LIB=0/' Makefile
sed -i 's/^LIBCURSES=	-lcurses/LIBCURSES=	# -lcurses/' Makefile

make -j$(nproc 2>/dev/null || echo 1)

# Install
cp samtools "$SAMTOOLS_BIN"
chmod +x "$SAMTOOLS_BIN"

echo "samtools 0.1.16 installed at: $SAMTOOLS_BIN"
exit 0
