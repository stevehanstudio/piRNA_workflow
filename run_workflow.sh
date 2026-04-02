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

    # Try to read the actual configured results directory from config.yaml
    local config_file="$workflow_dir/config.yaml"
    local results_dir=""

    if [[ -f "$config_file" ]]; then
        # Extract results_dir from config.yaml
        # Look for: results_dir: "path" or results_dir: path
        results_dir=$(grep -E '^\s*results_dir\s*:\s*' "$config_file" | sed -E 's/^\s*results_dir\s*:\s*//; s/^"//; s/"$//; s/^'\''//; s/'\''$//' | head -1)

        # If results_dir is relative, prepend workflow_dir
        if [[ -n "$results_dir" && ! "$results_dir" =~ ^/ ]]; then
            results_dir="$workflow_dir/$results_dir"
        fi
    fi

    # Fallback to default patterns if config reading failed
    if [[ -z "$results_dir" ]]; then
        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            results_dir="$workflow_dir/results"
        elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
            results_dir="$workflow_dir/results"
        fi
    fi

    # Check if the configured results directory exists and is non-empty
    if [[ -n "$results_dir" ]] && [[ -d "$results_dir" ]] && [[ -n "$(ls -A "$results_dir" 2>/dev/null)" ]]; then
        existing_dirs+=("$results_dir")
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

# Helper function to expand ~ in paths
expand_path() {
    local path="$1"
    # Expand ~ to home directory
    if [[ "$path" == "~"* ]]; then
        path="${path/#\~/$HOME}"
    fi
    echo "$path"
}

# Bowtie index prefix (no .fa). Config stores the prefix; workflow appends .fa for references.
pirna_normalize_vector_index_prefix() {
    local p="$1"
    case "$p" in
        *.fa) echo "${p%.fa}" ;;
        *) echo "$p" ;;
    esac
}

# Merge piRNA multi-vector TSV (id<TAB>path per line) into temp config references.vectors (needs PyYAML).
pirna_merge_vectors_into_config() {
    local tc="$1"
    local tsv="$2"
    python3 - "$tc" "$tsv" <<'PY'
import pathlib, sys
try:
    import yaml  # type: ignore
except ImportError:
    sys.stderr.write(
        "error: Python PyYAML is required for multi-vector config (pip install pyyaml).\n"
    )
    sys.exit(1)
tc = pathlib.Path(sys.argv[1])
tsv = pathlib.Path(sys.argv[2])
vectors = []
for line in tsv.read_text().splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    parts = line.split("\t", 1)
    if len(parts) != 2:
        sys.stderr.write("error: each vector line must be: id<TAB>index_path\n")
        sys.exit(1)
    vid, idx = parts[0].strip(), parts[1].strip()
    if not vid or not idx:
        sys.stderr.write("error: empty id or index path in vector list\n")
        sys.exit(1)
    if idx.endswith(".fa"):
        idx = idx[: -len(".fa")]
    vectors.append({"id": vid, "index": idx})
cfg = yaml.safe_load(tc.read_text())
refs = cfg.setdefault("references", {})
refs.pop("vector_index", None)
refs["vectors"] = vectors
tc.write_text(
    yaml.dump(
        cfg,
        default_flow_style=False,
        allow_unicode=True,
        sort_keys=False,
    )
)
PY
}

# Interactive piRNA-seq only: ask how many vectors, then paths (or single vector like legacy).
# Sets VECTOR_PATH (n=1) or PIRNA_MULTI_VECTOR_TSV path to a tab-separated file (n>=2).
prompt_pirna_vector_paths() {
    local default_vector="$1"
    PIRNA_MULTI_VECTOR_TSV=""
    echo "Vectors: map the size-selected library to one or more Bowtie vector indexes." >&2
    read -p "Number of vectors to map [default: 1]: " _nvec_in >&2
    local _n="${_nvec_in:-1}"
    if ! [[ "$_n" =~ ^[0-9]+$ ]]; then
        _n=1
    fi
    if [[ "$_n" -lt 1 ]]; then
        _n=1
    fi
    if [[ "$_n" -eq 1 ]]; then
        echo "Bowtie index prefix: path shared by NAME.fa and NAME.1.ebwt (do not end with .fa; a trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
        return 0
    fi
    if ! python3 -c "import yaml" 2>/dev/null; then
        echo "Multi-vector mode needs Python 3 with PyYAML (pip install pyyaml)." >&2
        echo "Falling back to a single vector; re-run after installing PyYAML to use multiple vectors." >&2
        echo "Bowtie index prefix: path shared by NAME.fa and NAME.1.ebwt (do not end with .fa; a trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
        return 0
    fi
    VECTOR_PATH=""
    local _tsv
    _tsv="$(mktemp /tmp/pirna_vectors.XXXXXX.tsv)"
    echo "Bowtie index prefix per vector: same as single-vector mode (path without .fa; trailing .fa is stripped)." >&2
    local _i
    for ((_i = 1; _i <= _n; _i++)); do
        read -p "  Vector $_i index prefix [default: $default_vector]: " _vpath >&2
        _vpath="${_vpath:-$default_vector}"
        _vpath=$(pirna_normalize_vector_index_prefix "$(expand_path "$_vpath")")
        local _vid
        _vid=$(basename "$_vpath")
        read -p "  Vector $_i id for output filenames [default: $_vid]: " _vid_in >&2
        _vid="${_vid_in:-$_vid}"
        printf '%s\t%s\n' "$_vid" "$_vpath" >> "$_tsv"
    done
    PIRNA_MULTI_VECTOR_TSV="$_tsv"
    export PIRNA_MULTI_VECTOR_TSV
    echo "Using $_n vectors; will write references.vectors to the temporary run config." >&2
}

# Helper function to find existing file path
find_existing_path() {
    local candidate_paths=("$@")
    for path in "${candidate_paths[@]}"; do
        local expanded=$(expand_path "$path")
        if [[ -f "$expanded" ]] || [[ -d "$expanded" ]]; then
            echo "$path"
            return 0
        fi
    done
    # Return the first candidate if none exist (user will need to provide correct path)
    echo "${candidate_paths[0]}"
    return 1
}

# Function to check required input files
check_input_files() {
    local workflow_dir=$1
    local missing_files=()
    local missing_dirs=()
    local all_files_present=true

    echo "=== Input File Validation ===" >&2
    echo "Checking required input files for $workflow_dir workflow..." >&2
    
    # Guardrail: prevent accidental runs when genomes directory is missing or a broken symlink.
    # This avoids the “EdgeXpert got replaced by a symlink” failure mode.
    local genomes_dir="./Shared/DataFiles/genomes"
    local genomes_dir_expanded
    genomes_dir_expanded=$(expand_path "$genomes_dir")
    if [[ -L "$genomes_dir_expanded" ]]; then
        local genomes_target
        genomes_target=$(readlink -f "$genomes_dir_expanded" 2>/dev/null || true)
        if [[ -z "$genomes_target" || ! -d "$genomes_target" ]]; then
            echo "❌ genomes path is a broken symlink: $genomes_dir_expanded" >&2
            echo "Fix options (choose ONE, local only — do not commit):" >&2
            echo "  - Recreate local symlink to your data disk, e.g.:" >&2
            echo "      ln -s /mnt/data/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genomes Shared/DataFiles/genomes" >&2
            echo "  - Or create a real directory at: $genomes_dir_expanded" >&2
            exit 1
        fi
    elif [[ ! -d "$genomes_dir_expanded" ]]; then
        echo "❌ genomes directory not found: $genomes_dir_expanded" >&2
        echo "Fix options (choose ONE, local only — do not commit):" >&2
        echo "  - If genomes live on /mnt/data on this machine:" >&2
        echo "      ln -s /mnt/data/Projects/HeLab/piRNA_workflow/Shared/DataFiles/genomes Shared/DataFiles/genomes" >&2
        echo "  - Or create/populate a real directory at: $genomes_dir_expanded" >&2
        exit 1
    fi
    
    # Use override paths if provided, otherwise use defaults.
    # If --genome-version is provided and --genome-path is not, point to that version's FASTA.
    local effective_genome_version="${GENOME_VERSION:-dm6}"
    local genome_path="${GENOME_PATH:-./Shared/DataFiles/genomes/${effective_genome_version}.fa}"
    local dataset_path="${DATASET_PATH:-./Shared/DataFiles/datasets/chip-seq/chip_inputs}"
    local adapter_path="${ADAPTER_PATH:-./Shared/DataFiles/genomes/AllAdaptors.fa}"
    # piRNA-seq.md uses 42AB_UASG; ChIP/totalRNA in this repo use 42AB_UBIG.
    local vector_path
    if [[ "$workflow_dir" == "piRNA-seq" ]]; then
        vector_path="${VECTOR_PATH:-./Shared/DataFiles/genomes/YichengVectors/42AB_UASG}"
    else
        vector_path="${VECTOR_PATH:-./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG}"
    fi
    
    # Expand ~ in paths
    genome_path=$(expand_path "$genome_path")
    dataset_path=$(expand_path "$dataset_path")
    adapter_path=$(expand_path "$adapter_path")
    vector_path=$(expand_path "$vector_path")
    
    if [[ -n "$GENOME_PATH" || -n "$DATASET_PATH" || -n "$ADAPTER_PATH" || -n "$VECTOR_PATH" ]]; then
        echo "ℹ️  Using custom paths for validation" >&2
    fi
    echo "" >&2

    if [[ "$workflow_dir" == "CHIP-seq" ]]; then
        # Determine paths for genome-related files based on custom paths
        local index_path="${INDEX_PATH:-./Shared/DataFiles/genomes/bowtie-indexes/${effective_genome_version}}"
        index_path=$(expand_path "$index_path")
        local index_dir=$(dirname "$index_path")
        local index_basename=$(basename "$index_path")
        
        local genome_dir=$(dirname "$genome_path")
        
        # CHIP-seq required files - use custom paths if provided
        local required_files=(
            "$genome_path"
            "${genome_dir}/dm6-blacklist.v2.bed.gz"
            "${index_dir}/${index_basename}.chrom.sizes"
            "$adapter_path"
            "${vector_path}.fa"
            "Shared/Scripts/python/trimfastq.py"
            "Shared/Scripts/python/makewigglefromBAM-NH.py"
        )

        local required_dirs=(
            "$dataset_path"
            "$index_dir"
            "$(dirname "$vector_path")"
        )

        # Check for dm6 bowtie indexes: either indexes exist OR source file exists
        local dm6_bowtie_index_files=(
            "${index_path}.1.ebwt"
            "${index_path}.2.ebwt"
            "${index_path}.3.ebwt"
            "${index_path}.4.ebwt"
            "${index_path}.rev.1.ebwt"
            "${index_path}.rev.2.ebwt"
        )

        # Check if all dm6 index files exist
        local all_dm6_indexes_exist=true
        for index_file in "${dm6_bowtie_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_dm6_indexes_exist=false
                break
            fi
        done

        # If indexes don't exist, the genome FASTA must exist (so Snakemake can build them)
        if [[ "$all_dm6_indexes_exist" == "false" ]]; then
            # genome FASTA is already in required_files, so we're good - Snakemake will build indexes
            echo "ℹ️  Note: Genome bowtie indexes will be built from $(basename "$genome_path")" >&2
        fi

        # Check for vector index files: either indexes exist OR source file exists
        local vector_index_files=(
            "${vector_path}.1.ebwt"
            "${vector_path}.2.ebwt"
            "${vector_path}.3.ebwt"
            "${vector_path}.4.ebwt"
            "${vector_path}.rev.1.ebwt"
            "${vector_path}.rev.2.ebwt"
        )

        # Check if all vector index files exist
        local all_vector_indexes_exist=true
        for index_file in "${vector_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_vector_indexes_exist=false
                break
            fi
        done

        # If indexes don't exist, vector .fa must exist (so Snakemake can build them)
        if [[ "$all_vector_indexes_exist" == "false" ]]; then
            # Vector .fa is already in required_files, so we're good - Snakemake will build indexes
            echo "ℹ️  Note: Vector bowtie indexes will be built from $(basename "$vector_path").fa" >&2
        fi

    elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
        # totalRNA-seq - update paths for this workflow
        dataset_path="${DATASET_PATH:-Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq}"
        dataset_path=$(expand_path "$dataset_path")
        
        # For totalRNA-seq, INDEX_PATH refers to rRNA index
        local rrna_index_path="${INDEX_PATH:-./Shared/DataFiles/genomes/rrna/dmel_rRNA_unit}"
        rrna_index_path=$(expand_path "$rrna_index_path")
        local rrna_dir=$(dirname "$rrna_index_path")
        local rrna_basename=$(basename "$rrna_index_path")
        
        # GTF file is in annotations directory alongside genome
        local genome_dir=$(dirname "$genome_path")
        local annotations_dir="${genome_dir}/annotations"
        
        # totalRNA-seq required files (basic files that are always needed)
        local required_files=(
            "$dataset_path"
            "$genome_path"
            "${annotations_dir}/dm6.gtf"
            "${vector_path}.fa"
            "Shared/Scripts/python/trimfastq.py"
        )

        local required_dirs=(
            "$(dirname "$dataset_path")"
            "$rrna_dir"
            "$annotations_dir"
            "$(dirname "$vector_path")"
        )

        # Check for rRNA: either source file OR index files must exist
        local rrna_source="${rrna_dir}/${rrna_basename}.fa"
        local rrna_index_files=(
            "${rrna_index_path}.1.ebwt"
            "${rrna_index_path}.2.ebwt"
            "${rrna_index_path}.3.ebwt"
            "${rrna_index_path}.4.ebwt"
            "${rrna_index_path}.rev.1.ebwt"
            "${rrna_index_path}.rev.2.ebwt"
        )

        # Check if rRNA indexes exist (preferred) or source file exists
        local all_rrna_indexes_exist=true
        for index_file in "${rrna_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_rrna_indexes_exist=false
                break
            fi
        done

        # If rRNA indexes don't exist, check for source file
        if [[ "$all_rrna_indexes_exist" == "false" ]]; then
            # Source file must exist so Snakemake can build indexes
            required_files+=("$rrna_source")
            echo "ℹ️  Note: rRNA bowtie indexes will be built from ${rrna_basename}.fa" >&2
        fi

        # Check for vector index files
        local vector_index_files=(
            "${vector_path}.1.ebwt"
            "${vector_path}.2.ebwt"
            "${vector_path}.3.ebwt"
            "${vector_path}.4.ebwt"
            "${vector_path}.rev.1.ebwt"
            "${vector_path}.rev.2.ebwt"
        )

        # Check if all vector index files exist
        local all_vector_indexes_exist=true
        for index_file in "${vector_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_vector_indexes_exist=false
                break
            fi
        done

        # If vector indexes don't exist, source file must exist
        if [[ "$all_vector_indexes_exist" == "false" ]]; then
            # Vector .fa is already in required_files, so we're good - Snakemake will build indexes
            echo "ℹ️  Note: Vector bowtie indexes will be built from $(basename "$vector_path").fa" >&2
        fi
    elif [[ "$workflow_dir" == "piRNA-seq" ]]; then
        # piRNA-seq - defaults and required files for MVP pipeline
        dataset_path="${DATASET_PATH:-./Shared/DataFiles/datasets/pirna-seq/pirna_sample.fastq.gz}"
        dataset_path=$(expand_path "$dataset_path")

        local index_path="${INDEX_PATH:-./Shared/DataFiles/genomes/bowtie-indexes/${effective_genome_version}}"
        index_path=$(expand_path "$index_path")
        local index_dir=$(dirname "$index_path")
        local index_basename=$(basename "$index_path")

        local genome_dir=$(dirname "$genome_path")

        local required_files=(
            "$dataset_path"
            "$genome_path"
            "${index_dir}/${index_basename}.chrom.sizes"
            "${vector_path}.fa"
        )

        # Only the dataset directory must exist up front. Index/vector directories can be
        # created by Snakemake rules (e.g., bowtie-build rules typically mkdir -p).
        local required_dirs=(
            "$(dirname "$dataset_path")"
        )

        local genome_index_files=(
            "${index_path}.1.ebwt"
            "${index_path}.2.ebwt"
            "${index_path}.3.ebwt"
            "${index_path}.4.ebwt"
            "${index_path}.rev.1.ebwt"
            "${index_path}.rev.2.ebwt"
        )

        local all_genome_indexes_exist=true
        for index_file in "${genome_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_genome_indexes_exist=false
                break
            fi
        done
        if [[ "$all_genome_indexes_exist" == "false" ]]; then
            echo "ℹ️  Note: Genome bowtie indexes will be built from $(basename "$genome_path")" >&2
        fi

        local vector_index_files=(
            "${vector_path}.1.ebwt"
            "${vector_path}.2.ebwt"
            "${vector_path}.3.ebwt"
            "${vector_path}.4.ebwt"
            "${vector_path}.rev.1.ebwt"
            "${vector_path}.rev.2.ebwt"
        )

        local all_vector_indexes_exist=true
        for index_file in "${vector_index_files[@]}"; do
            if [[ ! -f "$index_file" ]]; then
                all_vector_indexes_exist=false
                break
            fi
        done
        if [[ "$all_vector_indexes_exist" == "false" ]]; then
            echo "ℹ️  Note: Vector bowtie indexes will be built from $(basename "$vector_path").fa" >&2
        fi
    fi

    # Check directories first
    for dir in "${required_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            missing_dirs+=("$dir")
            all_files_present=false
        fi
    done

    # Check files
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            missing_files+=("$file")
            all_files_present=false
        fi
    done

    # Report results
    if [[ "$all_files_present" == "true" ]]; then
        echo "✅ All required input files are present!" >&2
        echo "" >&2
        return 0
    else
        echo "❌ Missing required input files:" >&2
        echo "" >&2

        if [[ ${#missing_dirs[@]} -gt 0 ]]; then
            echo "Missing directories:" >&2
            for dir in "${missing_dirs[@]}"; do
                echo "  • $dir" >&2
            done
            echo "" >&2
        fi

        if [[ ${#missing_files[@]} -gt 0 ]]; then
            echo "Missing files:" >&2
            for file in "${missing_files[@]}"; do
                echo "  • $file" >&2
            done
            echo "" >&2
        fi

        echo "📋 Required actions:" >&2
        echo "" >&2

        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            echo "1. Download and prepare reference files:" >&2
            echo "   • Download dm6.fa, dm6-blacklist.v2.bed.gz, AllAdaptors.fa" >&2
            echo "   • Build bowtie indexes: bowtie-build dm6.fa dm6" >&2
            echo "   • Build vector indexes: bowtie-build 42AB_UBIG.fa 42AB_UBIG" >&2
            echo "   • Create chromosome sizes: samtools faidx dm6.fa && cut -f1,2 dm6.fa.fai > dm6.chrom.sizes" >&2
            echo "" >&2
            echo "2. Place input FASTQ files in:" >&2
            echo "   Shared/DataFiles/datasets/chip-seq/chip_inputs/" >&2
            echo "" >&2
        elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
            echo "1. Download and prepare reference files:" >&2
            echo "   • Download dm6.fa, dm6.gtf, dmel_rRNA_unit.fa" >&2
            echo "   • Build rRNA index: bowtie-build dmel_rRNA_unit.fa dmel_rRNA_unit" >&2
            echo "   • Build vector index: bowtie-build 42AB_UBIG.fa 42AB_UBIG" >&2
            echo "" >&2
            echo "2. Place input FASTQ file:" >&2
            echo "   Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq" >&2
            echo "" >&2
        elif [[ "$workflow_dir" == "piRNA-seq" ]]; then
            echo "1. Download and prepare reference files:" >&2
            echo "   • Download ${effective_genome_version}.fa and generate ${effective_genome_version}.chrom.sizes" >&2
            echo "   • Build genome index: bowtie-build ${effective_genome_version}.fa ${effective_genome_version}" >&2
            echo "   • Build vector index: bowtie-build 42AB_UASG.fa 42AB_UASG" >&2
            echo "" >&2
            echo "2. Place input FASTQ file:" >&2
            echo "   ${dataset_path}" >&2
            echo "" >&2
        fi

        echo "3. For detailed setup instructions, see:" >&2
        echo "   • $workflow_dir/README.md" >&2
        # Keep this optional; file may not exist in all checkouts.
        echo "   • (optional) INDEX_BUILDING_STRATEGY.md" >&2
        echo "" >&2

        while true; do
            read -p "Would you like to proceed anyway? The workflow will likely fail. (y/N): " choice >&2
            case $choice in
                [Yy]* )
                    echo "⚠️  Proceeding with missing files - workflow may fail!" >&2
                    echo "" >&2
                    return 0
                    ;;
                [Nn]* | "" )
                    echo "Workflow cancelled. Please prepare the required files first." >&2
                    exit 1
                    ;;
                * )
                    echo "Please answer yes (y) or no (n)." >&2
                    ;;
            esac
        done
    fi
}

# Function to interactively select workflow and configure paths
select_workflow_and_paths() {
    echo "Available workflows:" >&2
    echo "  1) ChIP-seq analysis workflow" >&2
    echo "  2) piRNA-seq analysis workflow" >&2
    echo "  4) Total RNA-seq analysis workflow" >&2
    echo "" >&2
    while true; do
        read -p "Please select a workflow (1, 2, or 4): " choice >&2
        case $choice in
            1)
                WORKFLOW="chip-seq"
                break
                ;;
            2)
                WORKFLOW="pirna-seq"
                break
                ;;
            4)
                WORKFLOW="totalrna-seq"
                break
                ;;
            *)
                echo "Invalid choice. Please enter 1, 2, or 4." >&2
                ;;
        esac
    done
    
    echo "" >&2
    echo "=== Genome Version Configuration ===" >&2
    echo "Specify the genome version for this workflow." >&2
    echo "Common options: dm6, dm3 (Drosophila), hg38, hg19 (Human), mm10, mm9 (Mouse), ce11 (C. elegans)" >&2
    echo "" >&2
    
    # Genome version
    read -p "Genome version [default: dm6]: " genome_version_input >&2
    if [[ -n "$genome_version_input" ]]; then
        GENOME_VERSION="$genome_version_input"
        echo "Using genome version: $GENOME_VERSION" >&2
    else
        GENOME_VERSION="dm6"
        echo "Using default genome version: dm6" >&2
    fi
    echo "" >&2
    
    # Determine species from genome version
    case "$GENOME_VERSION" in
        dm*|BDGP*)
            GENOME_SPECIES="drosophila"
            ;;
        hg*|GRCh*)
            GENOME_SPECIES="human"
            ;;
        mm*|GRCm*)
            GENOME_SPECIES="mouse"
            ;;
        ce*)
            GENOME_SPECIES="celegans"
            ;;
        *)
            read -p "Species name for $GENOME_VERSION (e.g., drosophila, human, mouse): " species_input >&2
            GENOME_SPECIES="${species_input:-drosophila}"
            echo "Using species: $GENOME_SPECIES" >&2
            ;;
    esac
    
    echo "" >&2
    echo "=== Path Configuration (optional) ===" >&2
    echo "You can override the default paths from config.yaml files." >&2
    echo "Press Enter to use defaults, or provide custom paths:" >&2
    echo "" >&2
    
    # Get default paths from config files
    local config_file
    case "$WORKFLOW" in
        chip-seq) config_file="CHIP-seq/config.yaml" ;;
        pirna-seq) config_file="piRNA-seq/config.yaml" ;;
        *) config_file="totalRNA-seq/config.yaml" ;;
    esac
    
    # Genome path - check for existence before suggesting
    local default_genome
    if [[ -n "$GENOME_VERSION" ]]; then
        # Use genomes/ (plural) directory
        default_genome="./Shared/DataFiles/genomes/${GENOME_VERSION}.fa"
        if [[ ! -f "$(expand_path "$default_genome")" ]]; then
            echo "⚠️  Warning: $default_genome does not exist. You may need to provide the correct path." >&2
        fi
    elif [[ "$WORKFLOW" == "chip-seq" ]]; then
        default_genome=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*dm6_fasta\s*:' | sed -E 's/^\s*dm6_fasta\s*:\s*//; s/^"//; s/"$//' | head -1)
        # Check if the config path exists, use genomes/ if not
        if [[ -n "$default_genome" ]] && [[ ! -f "$(expand_path "$default_genome")" ]]; then
            local alt_path="./Shared/DataFiles/genomes/dm6.fa"
            if [[ -f "$(expand_path "$alt_path")" ]]; then
                default_genome="$alt_path"
            fi
        fi
    else
        # For totalRNA-seq, use genomes/ directory
        default_genome="./Shared/DataFiles/genomes/dm6.fa"
        if [[ ! -f "$(expand_path "$default_genome")" ]]; then
            default_genome=$(grep -E '^\s*dm6_fasta\s*:' "$config_file" | sed -E 's/^\s*dm6_fasta\s*:\s*//; s/^"//; s/"$//' | head -1) || default_genome="./Shared/DataFiles/genomes/dm6.fa"
        fi
    fi
    read -p "Genome FASTA file path [default: $default_genome]: " genome_input >&2
    if [[ -n "$genome_input" ]]; then
        GENOME_PATH="$genome_input"
        echo "Using custom genome path: $GENOME_PATH" >&2
    fi
    echo "" >&2
    
    # Index path - check for existence before suggesting
    local default_index
    if [[ -n "$GENOME_VERSION" && ( "$WORKFLOW" == "chip-seq" || "$WORKFLOW" == "pirna-seq" ) ]]; then
        # Use genomes/ (plural) directory
        default_index="./Shared/DataFiles/genomes/bowtie-indexes/${GENOME_VERSION}"
        if [[ ! -d "$(expand_path "$default_index")" ]] && [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]]; then
            # Indexes can be built, so just note if they don't exist yet
            echo "ℹ️  Note: Index directory $default_index not found. Indexes will be built if needed." >&2
        fi
    elif [[ "$WORKFLOW" == "chip-seq" || "$WORKFLOW" == "pirna-seq" ]]; then
        default_index=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*dm6_bowtie_index\s*:' | sed -E 's/^\s*dm6_bowtie_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        # Convert ../Shared to ./Shared since we're running from project root
        if [[ -n "$default_index" ]]; then
            default_index=$(echo "$default_index" | sed 's|^\.\./Shared|./Shared|')
        fi
        # Check if the config path exists, use genomes/ if not
        if [[ -n "$default_index" ]] && [[ ! -d "$(expand_path "$default_index")" ]] && [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]]; then
            local alt_path="./Shared/DataFiles/genomes/bowtie-indexes/dm6"
            if [[ -d "$(expand_path "$alt_path")" ]] || [[ -f "$(expand_path "${alt_path}.1.ebwt")" ]]; then
                default_index="$alt_path"
            fi
        fi
    elif [[ -n "$GENOME_VERSION" && "$WORKFLOW" == "totalrna-seq" ]]; then
        # For totalRNA-seq with genome version, determine rRNA species and construct path dynamically
        local rrna_species
        case "$GENOME_SPECIES" in
            drosophila) rrna_species="dmel" ;;
            human) rrna_species="hsap" ;;
            mouse) rrna_species="mmus" ;;
            celegans) rrna_species="cele" ;;
            *) rrna_species="dmel" ;;  # Default fallback
        esac
        default_index="./Shared/DataFiles/genomes/rrna/${rrna_species}_rRNA_unit"
        if [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]] && [[ ! -f "$(expand_path "${default_index}.fa")" ]]; then
            echo "ℹ️  Note: rRNA index ${default_index} not found. Index will be built if source file exists." >&2
        fi
    else
        # For totalRNA-seq without genome version, get rRNA index from config
        default_index=$(grep -E '^\s*rrna_index\s*:' "$config_file" | sed -E 's/^\s*rrna_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        # Convert ../Shared to ./Shared since we're running from project root
        if [[ -n "$default_index" ]]; then
            default_index=$(echo "$default_index" | sed 's|^\.\./Shared|./Shared|')
        fi
        # Fallback if not found - use genomes/ directory
        if [[ -z "$default_index" ]]; then
            default_index="./Shared/DataFiles/genomes/rrna/dmel_rRNA_unit"
        fi
    fi
    read -p "Bowtie index directory path [default: $default_index]: " index_input >&2
    if [[ -n "$index_input" ]]; then
        INDEX_PATH="$index_input"
        echo "Using custom index path: $INDEX_PATH" >&2
    fi
    echo "" >&2
    
    # Dataset path
    local default_dataset
    if [[ "$WORKFLOW" == "chip-seq" ]]; then
        # For CHIP-seq, get the data_dir under input_data section
        default_dataset=$(grep -A 10 "input_data:" "$config_file" | grep -E '^\s*data_dir\s*:' | sed -E 's/^\s*data_dir\s*:\s*//; s/^"//; s/"$//' | head -1)
        # Convert ../Shared to ./Shared since we're running from project root
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/chip-seq/chip_inputs"
        read -p "Input dataset directory path [default: $default_dataset]: " dataset_input >&2
    elif [[ "$WORKFLOW" == "pirna-seq" ]]; then
        default_dataset=$(grep -A 10 "sample:" "$config_file" | grep -E '^\s*fastq\s*:' | sed -E 's/^\s*fastq\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/pirna-seq/pirna_sample.fastq"
        read -p "Input FASTQ file path [default: $default_dataset]: " dataset_input >&2
    else
        default_dataset=$(grep -E '^\s*fastq_file\s*:' "$config_file" | sed -E 's/^\s*fastq_file\s*:\s*//; s/^"//; s/"$//' | head -1)
        # Convert ../Shared to ./Shared since we're running from project root
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq"
        read -p "Input FASTQ file path [default: $default_dataset]: " dataset_input >&2
    fi
    if [[ -n "$dataset_input" ]]; then
        DATASET_PATH="$dataset_input"
        echo "Using custom dataset path: $DATASET_PATH" >&2
    fi
    echo "" >&2
    
    # Vector path(s)
    local default_vector
    if [[ "$WORKFLOW" == "chip-seq" || "$WORKFLOW" == "pirna-seq" ]]; then
        default_vector=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*(vector_42ab_index|vector_index)\s*:' | sed -E 's/^\s*(vector_42ab_index|vector_index)\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_vector" ]]; then
            default_vector=$(echo "$default_vector" | sed 's|^\.\./Shared|./Shared|')
        fi
        if [[ -z "$default_vector" ]]; then
            if [[ "$WORKFLOW" == "pirna-seq" ]]; then
                default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UASG"
            else
                default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG"
            fi
        fi
    else
        default_vector=$(grep -E '^\s*vector_index\s*:' "$config_file" | sed -E 's/^\s*vector_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_vector" ]]; then
            default_vector=$(echo "$default_vector" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_vector" ]] && default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG"
    fi
    if [[ "$WORKFLOW" == "pirna-seq" ]]; then
        prompt_pirna_vector_paths "$default_vector"
    elif [[ "$WORKFLOW" == "chip-seq" ]]; then
        echo "Bowtie index prefix (path without .fa; trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
    else
        echo "Bowtie index prefix (path without .fa; trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
    fi
    echo "" >&2
    
    # Adapter path
    local default_adapter=$(grep -E '^\s*adapters_file\s*:' "$config_file" | sed -E 's/^\s*adapters_file\s*:\s*//; s/^"//; s/"$//' | head -1)
    # Convert ../Shared to ./Shared since we're running from project root
    if [[ -n "$default_adapter" ]]; then
        default_adapter=$(echo "$default_adapter" | sed 's|^\.\./Shared|./Shared|')
    fi
    [[ -z "$default_adapter" ]] && default_adapter="./Shared/DataFiles/genomes/AllAdaptors.fa"
    read -p "Adapter sequences file path [default: $default_adapter]: " adapter_input >&2
    if [[ -n "$adapter_input" ]]; then
        ADAPTER_PATH="$adapter_input"
        echo "Using custom adapter path: $ADAPTER_PATH" >&2
    fi
    echo "" >&2
}

# Function to check if snakemake is running and auto-unlock if safe
auto_unlock_if_safe() {
    local workflow_dir=$1

    # Check if any snakemake processes are running
    if pgrep -f "snakemake.*$workflow_dir" > /dev/null; then
        echo "⚠️  Snakemake process detected - another workflow may be running." >&2
        echo "Please ensure no other Snakemake instances are using this directory." >&2
        return 1
    fi

    # Check if lock directory exists
    if [[ -d "$workflow_dir/.snakemake/locks" ]] && [[ -n "$(ls -A "$workflow_dir/.snakemake/locks" 2>/dev/null)" ]]; then
        echo "🔓 Stale lock detected - automatically unlocking workflow directory..." >&2
        if [[ "$workflow_dir" == "piRNA-seq" ]]; then
            run_snakemake "$workflow_dir" "snakemake --unlock" 2>&1 | grep -v "Unlocking working directory" || true
        else
            run_snakemake "$workflow_dir" "snakemake --unlock --use-conda --conda-frontend mamba" 2>&1 | grep -v "Unlocking working directory" || true
        fi
        echo "✅ Directory unlocked successfully!" >&2
        echo "" >&2
        return 0
    fi

    return 0
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [WORKFLOW] [COMMAND] [OPTIONS]"
    echo ""
    echo "Workflows:"
    echo "  1 | chip-seq      - ChIP-seq analysis workflow"
    echo "  2 | pirna-seq     - piRNA-seq analysis workflow"
    echo "  4 | totalrna-seq  - Total RNA-seq analysis workflow"
    echo ""
    echo "Commands (default: run):"
    echo "  setup         - Create conda environments for the workflow"
    echo "  dryrun        - Show what will be executed (dry run)"
    echo "  run           - Run the complete workflow [DEFAULT]"
    echo "  run-force     - Force re-run all steps of the workflow"
    echo "  fix-incomplete - Fix incomplete files and continue workflow"
    echo "  check-inputs  - Validate all required input files are present"
    echo "  unlock        - Unlock workflow directory (fixes lock errors)"
    echo "  status        - Check workflow status and progress"
    echo "  clean         - Clean up output files"
    echo "  help          - Show this help message"
    echo ""
    echo "Options:"
    echo "  --cores N     - Number of CPU cores to use (prompts interactively if not specified)"
    echo "  --defaults    - Use default paths and cores without prompting"
    echo "  --rerun-incomplete  - Re-run incomplete jobs"
    echo "  --clean            - Remove workflow results before run/run-force (non-interactive)"
    echo "  --use-apptainer    - Use Apptainer containers for FastQC and Bowtie (ensures 0.11.3 and 1.0.1-nh)"
    echo "  --pipeline-sif PATH - Path to pirna_pipeline.sif (default: ./containers/pirna_pipeline.sif). Same as env PIRNA_PIPELINE_SIF."
    echo "  --use-sudo         - Use sudo for Apptainer exec (when unprivileged execution fails)"
    echo ""
    echo "Genome Configuration Options:"
    echo "  --genome-version VER  - Specify genome version (e.g., dm6, hg38, mm10, ce11)"
    echo ""
    echo "Path Override Options (defaults to config.yaml values):"
    echo "  --genome-path PATH    - Override genome FASTA file path"
    echo "  --index-path PATH     - Override bowtie index directory path"
    echo "  --dataset-path PATH   - Override input dataset directory/file path"
    echo "  --vector-path PATH    - Override vector index directory path (piRNA-seq: single vector; multi-vector: config.yaml references.vectors or interactive prompts)"
    echo "  --adapter-path PATH   - Override adapter sequences file path"
    echo ""
    echo "Interactive Features:"
    echo "  • Auto-detects system resources and suggests optimal core count"
    echo "  • Auto-unlocks stale locks from interrupted runs"
    echo "  • Prompts before overwriting existing results"
    echo "  • Displays total execution time upon completion"
    echo "  • Interactive workflow selection if not specified"
    echo "  • Interactive path configuration for custom input locations"
    echo ""
    echo "Examples:"
    echo "  $0 1 run --cores 4        # Run ChIP-seq workflow with 4 cores"
    echo "  $0 2 run --cores 8        # Run piRNA-seq workflow with 8 cores"
    echo "  $0 chip-seq dryrun        # Dry run ChIP-seq workflow (will prompt for cores)"
    echo "  $0 pirna-seq dryrun       # Dry run piRNA-seq workflow (will prompt for cores)"
    echo "  $0 4                      # Run totalRNA-seq (will prompt for cores)"
    echo "  $0 totalrna-seq status    # Check totalRNA-seq status"
    echo "  $0 1 fix-incomplete       # Fix incomplete ChIP-seq files and continue"
    echo "  $0 4 check-inputs         # Validate totalRNA-seq input files"
    echo "  $0                        # Interactive mode - prompts for workflow, paths, and cores"
    echo ""
    echo "Genome Version Examples:"
    echo "  $0 1 run --genome-version hg38 --cores 24  # Run CHIP-seq with human genome"
    echo "  $0 4 run --genome-version mm10 --cores 16  # Run totalRNA-seq with mouse genome"
    echo "  $0 1 run --genome-version ce11             # Run with C. elegans genome"
    echo ""
    echo "Apptainer Examples:"
    echo "  $0 1 run --use-apptainer --cores 8         # Run CHIP-seq with FastQC in Apptainer"
    echo "  $0 4 run --use-apptainer                   # Run totalRNA-seq with Apptainer"
    echo "  $0 1 run --use-apptainer --use-sudo        # Run with sudo (when unprivileged exec fails)"
    echo "  PIRNA_PIPELINE_SIF=/lab/sifs/pirna_pipeline.sif $0 2 run --use-apptainer  # Shared image path"
    echo "  $0 2 run --use-apptainer --pipeline-sif /lab/sifs/pirna_pipeline.sif       # Same via flag"
    echo ""
    echo "  $0 4 run --defaults                        # Run totalRNA-seq with defaults, no prompts"
    echo ""
    echo "Path Override Examples:"
    echo "  $0 1 run --dataset-path /path/to/my/data  # Use custom dataset directory"
    echo "  $0 1 run --genome-path /path/to/genome.fa # Use custom genome file"
    echo "  $0 4 run --index-path /path/to/indexes    # Use custom bowtie indexes"
    echo "  $0 1 run --vector-path /path/to/vectors   # Use custom vector indexes"
    echo ""
    echo "Note: Workflows must be run from their respective directories."
}

# Function to create temporary config with path overrides
create_temp_config() {
    local workflow_dir=$1
    local original_config="$workflow_dir/config.yaml"
    local temp_config="$workflow_dir/config_override.yaml"
    
    # Copy original config
    cp "$original_config" "$temp_config"
    
    # ==================================================================
    # Inject genome section if GENOME_VERSION is specified
    # ==================================================================
    if [[ -n "$GENOME_VERSION" ]]; then
        echo "" >&2
        echo "Injecting genome configuration for $GENOME_VERSION..." >&2
        
        # Determine rRNA species code from genome species
        local rrna_species
        case "$GENOME_SPECIES" in
            drosophila) rrna_species="dmel" ;;
            human) rrna_species="hsap" ;;
            mouse) rrna_species="mmus" ;;
            celegans) rrna_species="cele" ;;
            *) rrna_species="dmel" ;;  # Default fallback
        esac
        
        # Create genome section if it doesn't exist
        if ! grep -q "^genome:" "$temp_config"; then
            # Insert genome section at the beginning (after comments)
            local temp_file="${temp_config}.tmp"
            (
                # Copy any leading comments
                sed -n '/^#/p; /^$/p; /^[^#]/q' "$temp_config"
                
                # Add genome section
                echo ""
                echo "# Genome configuration (injected by run_workflow.sh)"
                echo "genome:"
                echo "  version: \"$GENOME_VERSION\""
                echo "  species: \"$GENOME_SPECIES\""
                echo "  rrna_species: \"$rrna_species\""
                echo "  fasta: \"../Shared/DataFiles/genomes/{version}.fa\""
                echo "  bowtie_index: \"../Shared/DataFiles/genomes/bowtie-indexes/{version}\""
                echo "  chrom_sizes: \"../Shared/DataFiles/genomes/bowtie-indexes/{version}.chrom.sizes\""
                echo "  blacklist: \"../Shared/DataFiles/genomes/{version}-blacklist.v2.bed.gz\""
                echo "  gtf: \"../Shared/DataFiles/genomes/annotations/{version}.gtf\""
                echo "  rrna_index: \"../Shared/DataFiles/genomes/rrna/{rrna_species}_rRNA_unit\""
                echo "  rrna_fasta: \"../Shared/DataFiles/genomes/rrna/{rrna_species}_rRNA_unit.fa\""
                echo ""
                
                # Copy rest of config (skip leading comments already copied)
                sed -n '/^[^#]/,$ p' "$temp_config"
            ) > "$temp_file"
            mv "$temp_file" "$temp_config"
            
            echo "✓ Genome section injected for $GENOME_VERSION ($GENOME_SPECIES)" >&2
        else
            # Update existing genome section
            sed -i "s|^  version: .*|  version: \"$GENOME_VERSION\"|" "$temp_config"
            sed -i "s|^  species: .*|  species: \"$GENOME_SPECIES\"|" "$temp_config"
            sed -i "s|^  rrna_species: .*|  rrna_species: \"$rrna_species\"|" "$temp_config"
            
            echo "✓ Updated genome version to $GENOME_VERSION" >&2
        fi
    fi
    
    # Apply path overrides if provided (expand ~ to full paths)
    if [[ -n "$GENOME_PATH" ]]; then
        local expanded_genome=$(expand_path "$GENOME_PATH")
        local genome_dir=$(dirname "$expanded_genome")
        sed -i "s|dm6_fasta: .*|dm6_fasta: \"$expanded_genome\"|" "$temp_config"
        echo "Override: Using genome path: $expanded_genome" >&2
        
        # Blacklist is only for ChIP-seq
        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            sed -i "s|dm6_blacklist: .*|dm6_blacklist: \"${genome_dir}/dm6-blacklist.v2.bed.gz\"|" "$temp_config"
            echo "Override: Using blacklist path: ${genome_dir}/dm6-blacklist.v2.bed.gz" >&2
        fi
    fi
    
    if [[ -n "$INDEX_PATH" ]]; then
        local expanded_index=$(expand_path "$INDEX_PATH")
        local index_dir=$(dirname "$expanded_index")
        local index_basename=$(basename "$expanded_index")
        
        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            # For ChIP-seq: INDEX_PATH is dm6 bowtie index
            sed -i "s|dm6_bowtie_index: .*|dm6_bowtie_index: \"$expanded_index\"|" "$temp_config"
            sed -i "s|dm6_chrom_sizes: .*|dm6_chrom_sizes: \"${index_dir}/${index_basename}.chrom.sizes\"|" "$temp_config"
            echo "Override: Using index path: $expanded_index" >&2
            echo "Override: Using chrom.sizes path: ${index_dir}/${index_basename}.chrom.sizes" >&2
        else
            # For totalRNA-seq: INDEX_PATH is rRNA index
            echo "Override: Using rRNA index path: $expanded_index" >&2
        fi
    fi
    
    if [[ -n "$DATASET_PATH" ]]; then
        local expanded_dataset=$(expand_path "$DATASET_PATH")
        if [[ "$workflow_dir" == "CHIP-seq" ]]; then
            sed -i "s|data_dir: .*|data_dir: \"$expanded_dataset\"|" "$temp_config"
        elif [[ "$workflow_dir" == "totalRNA-seq" ]]; then
            sed -i "s|fastq_file: .*|fastq_file: \"$expanded_dataset\"|" "$temp_config"
        elif [[ "$workflow_dir" == "piRNA-seq" ]]; then
            # piRNA-seq config uses: sample: {name, fastq}
            # Keep indentation consistent with config.yaml.
            sed -i "s|^  fastq: .*|  fastq: \"$expanded_dataset\"|" "$temp_config"
        fi
        echo "Override: Using dataset path: $expanded_dataset" >&2
    fi

    local _pirna_multi_merged=false
    if [[ "$workflow_dir" == "piRNA-seq" && -n "${PIRNA_MULTI_VECTOR_TSV:-}" && -f "$PIRNA_MULTI_VECTOR_TSV" ]]; then
        pirna_merge_vectors_into_config "$temp_config" "$PIRNA_MULTI_VECTOR_TSV"
        rm -f "$PIRNA_MULTI_VECTOR_TSV"
        PIRNA_MULTI_VECTOR_TSV=""
        _pirna_multi_merged=true
        echo "Override: piRNA-seq references.vectors merged from interactive multi-vector list" >&2
    fi

    if [[ -n "$VECTOR_PATH" && "$workflow_dir" == "piRNA-seq" && "$_pirna_multi_merged" != "true" ]]; then
        local expanded_vector
        expanded_vector=$(pirna_normalize_vector_index_prefix "$(expand_path "$VECTOR_PATH")")
        if grep -q "vector_index:" "$temp_config"; then
            sed -i "s|vector_index: .*|vector_index: \"$expanded_vector\"|" "$temp_config"
            echo "Override: piRNA-seq vector_index (single-vector / legacy): $expanded_vector" >&2
        else
            echo "Note: piRNA-seq config has no vector_index: line; use references.vectors in config or interactive multi-vector." >&2
        fi
    fi
    
    # Additional totalRNA-seq specific overrides
    if [[ "$workflow_dir" == "totalRNA-seq" ]]; then
        if [[ -n "$GENOME_PATH" ]]; then
            # Add dm6_fasta config entry if it doesn't exist
            local expanded_genome=$(expand_path "$GENOME_PATH")
            local genome_dir=$(dirname "$expanded_genome")
            if ! grep -q "^dm6_fasta:" "$temp_config"; then
                echo "dm6_fasta: \"$expanded_genome\"" >> "$temp_config"
            else
                sed -i "s|^dm6_fasta: .*|dm6_fasta: \"$expanded_genome\"|" "$temp_config"
            fi
            # Add GTF paths
            if ! grep -q "^original_gtf:" "$temp_config"; then
                echo "original_gtf: \"${genome_dir}/annotations/dm6.gtf\"" >> "$temp_config"
            else
                sed -i "s|^original_gtf: .*|original_gtf: \"${genome_dir}/annotations/dm6.gtf\"|" "$temp_config"
            fi
            if ! grep -q "^harmonized_gtf:" "$temp_config"; then
                echo "harmonized_gtf: \"${genome_dir}/annotations/dm6_chr_harmonized.gtf\"" >> "$temp_config"
            else
                sed -i "s|^harmonized_gtf: .*|harmonized_gtf: \"${genome_dir}/annotations/dm6_chr_harmonized.gtf\"|" "$temp_config"
            fi
        fi
        if [[ -n "$INDEX_PATH" ]]; then
            # For totalRNA-seq, INDEX_PATH can override the rRNA index
            local expanded_index=$(expand_path "$INDEX_PATH")
            local rrna_dir=$(dirname "$expanded_index")
            local rrna_basename=$(basename "$expanded_index")
            sed -i "s|rrna_index: .*|rrna_index: \"$expanded_index\"|" "$temp_config"
            # Add rrna_fasta config entry
            if ! grep -q "^rrna_fasta:" "$temp_config"; then
                echo "rrna_fasta: \"${rrna_dir}/${rrna_basename}.fa\"" >> "$temp_config"
            else
                sed -i "s|^rrna_fasta: .*|rrna_fasta: \"${rrna_dir}/${rrna_basename}.fa\"|" "$temp_config"
            fi
        fi
        if [[ -n "$VECTOR_PATH" ]]; then
            # For totalRNA-seq, VECTOR_PATH overrides the vector index and ref
            local expanded_vector
            expanded_vector=$(pirna_normalize_vector_index_prefix "$(expand_path "$VECTOR_PATH")")
            sed -i "s|vector_index: .*|vector_index: \"$expanded_vector\"|" "$temp_config"
            if ! grep -q "^vector_ref:" "$temp_config"; then
                echo "vector_ref: \"${expanded_vector}.fa\"" >> "$temp_config"
            else
                sed -i "s|^vector_ref: .*|vector_ref: \"${expanded_vector}.fa\"|" "$temp_config"
            fi
        fi
    fi
    
    if [[ -n "$VECTOR_PATH" ]]; then
        local expanded_vector
        expanded_vector=$(pirna_normalize_vector_index_prefix "$(expand_path "$VECTOR_PATH")")
        sed -i "s|vector_42ab_index: .*|vector_42ab_index: \"$expanded_vector\"|" "$temp_config"
        sed -i "s|vector_42ab_fasta: .*|vector_42ab_fasta: \"${expanded_vector}.fa\"|" "$temp_config"
        echo "Override: Using vector path: $expanded_vector" >&2
    fi
    
    if [[ -n "$ADAPTER_PATH" ]]; then
        local expanded_adapter=$(expand_path "$ADAPTER_PATH")
        sed -i "s|adapters_file: .*|adapters_file: \"$expanded_adapter\"|" "$temp_config"
        echo "Override: Using adapter path: $expanded_adapter" >&2
    fi
    
    echo "$temp_config"
}

# Function to ensure FastQC 0.11.3 Apptainer image is built (when using Apptainer)
ensure_fastqc_container() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_fastqc.sh"
    if [[ -x "$ensure_script" ]]; then
        "$ensure_script"
    else
        echo "Warning: ensure_fastqc.sh not found at $ensure_script, FastQC container may not be available" >&2
    fi
}

# Function to ensure Cutadapt 1.8.3 Apptainer image is built (original version, for ARM64)
ensure_cutadapt_container() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_cutadapt.sh"
    if [[ -x "$ensure_script" ]]; then
        "$ensure_script"
    else
        echo "Warning: ensure_cutadapt.sh not found at $ensure_script, Cutadapt container may not be available" >&2
    fi
}

# Function to ensure single pipeline container is built
ensure_pipeline_container() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_pipeline_container.sh"
    if [[ -f "$ensure_script" ]]; then
        bash "$ensure_script"
    else
        echo "Error: ensure_pipeline_container.sh not found at $ensure_script" >&2
        exit 1
    fi
}

# Function to ensure patched Bowtie 1.0.1-nh Apptainer image is built (when using Apptainer)
ensure_bowtie_container() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_bowtie.sh"
    if [[ -x "$ensure_script" ]]; then
        "$ensure_script"
    else
        echo "Warning: ensure_bowtie.sh not found at $ensure_script, Bowtie container may not be available" >&2
    fi
}

# Function to build samtools 0.1.8 from source (original pipeline version)
# Needed when pre-built x86 binary segfaults on ARM64; keeps version fidelity
ensure_samtools_018() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_samtools_018.sh"
    if [[ -x "$ensure_script" ]]; then
        "$ensure_script"
    else
        echo "Warning: ensure_samtools_018.sh not found at $ensure_script" >&2
    fi
}

# Function to build samtools 0.1.16 from source (for rmdup - removed in modern samtools)
# Needed when pre-built x86 binary segfaults on ARM64 (e.g. under Box64)
ensure_samtools_016() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local ensure_script="$script_dir/Shared/Scripts/shell/ensure_samtools_016.sh"
    if [[ -x "$ensure_script" ]]; then
        "$ensure_script"
    else
        echo "Warning: ensure_samtools_016.sh not found at $ensure_script" >&2
    fi
}

# Function to run snakemake (in pipeline container or host conda)
run_snakemake() {
    local workflow_dir=$1
    local command=$2
    shift 2

    local script_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Use project-local temp dir so tools (bamCompare, deepTools, etc.) avoid filling root /tmp
    local project_tmp="$script_root/.tmp"
    mkdir -p "$project_tmp"
    export TMPDIR="$project_tmp"

    # Create temporary config if path overrides or genome version are provided
    local temp_config=""
    if [[ -n "$GENOME_PATH" || -n "$INDEX_PATH" || -n "$DATASET_PATH" || -n "$VECTOR_PATH" || -n "${PIRNA_MULTI_VECTOR_TSV:-}" || -n "$ADAPTER_PATH" || -n "$GENOME_VERSION" ]]; then
        temp_config=$(create_temp_config "$workflow_dir")
        echo "Using temporary config with overrides: $temp_config" >&2
    fi

    local config_override=""
    if [[ -n "$temp_config" && -f "$temp_config" ]]; then
        config_override="--configfile $(basename "$temp_config")"
    fi

    # Use pipeline container when available (Apptainer only). Override: PIRNA_PIPELINE_SIF or --pipeline-sif.
    SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$SCRIPT_ROOT/containers/pirna_pipeline.sif}"
    APPTAINER_CMD="apptainer"
    [[ "${APPTAINER_SUDO:-0}" == "1" ]] && APPTAINER_CMD="sudo apptainer"
    USE_PIPELINE_CONTAINER=false
    if [[ -f "$PIPELINE_SIF" ]] && $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
        USE_PIPELINE_CONTAINER=true
    fi

    if [[ "$USE_PIPELINE_CONTAINER" == "true" ]]; then
        echo "Running in pipeline container..."
        echo "Pipeline image: $(readlink -f "$PIPELINE_SIF" 2>/dev/null || echo "$PIPELINE_SIF")"
        [[ "${APPTAINER_SUDO:-0}" == "1" ]] && echo "(using sudo for Apptainer)"
        echo "Directory: ${workflow_dir}"
        echo "Command: ${command}"
        echo ""
        local abs_project="$(cd "$SCRIPT_ROOT" && pwd)"
        local abs_workflow="$(cd "$abs_project/$workflow_dir" 2>/dev/null && pwd || echo "$abs_project/$workflow_dir")"
        # Container uses project temp dir (project/.tmp bind-mounted as /work/.tmp)
        export APPTAINERENV_TMPDIR=/work/.tmp
        # Bind-mount project. If Shared/DataFiles/genomes is a symlink outside the project (e.g. to
        # /mnt/data/...), bind the symlink's mount root so the path resolves inside the container.
        local bind_opts="-B $abs_project:/work"
        local genomes_path="$abs_project/Shared/DataFiles/genomes"
        if [[ -L "$genomes_path" ]]; then
            local target
            target=$(readlink -f "$genomes_path" 2>/dev/null || true)
            if [[ -n "$target" && -d "$target" && "$target" != "$abs_project"/* ]]; then
                # Extract mount root (e.g. /mnt/data from /mnt/data/Projects/.../genomes)
                local mount_root
                case "$target" in
                    /mnt/*) mount_root="$(echo "$target" | cut -d/ -f1-3)" ;;  # /mnt/data
                    /data|/data/*) mount_root="/data" ;;
                    /home|/home/*) mount_root="/home" ;;
                    *) mount_root="$(echo "$target" | cut -d/ -f1-3)" ;;  # /media/disk etc.
                esac
                if [[ -d "$mount_root" ]]; then
                    bind_opts="$bind_opts -B $mount_root:$mount_root"
                fi
            fi
        fi
        # Use APPTAINERENV_ to pass env vars (avoids -e parsing issues that can confuse Snakemake/Apptainer)
        export APPTAINERENV_PIPELINE_CONTAINER=1
        export APPTAINERENV_SAMTOOLS_018=/opt/pipeline/samtools-0.1.8/samtools
        export APPTAINERENV_SAMTOOLS_016=/opt/pipeline/samtools-0.1.16/samtools
        # Java defaults for headless servers; keep user overrides if already set
        : "${APPTAINERENV_JAVA_TOOL_OPTIONS:=-Djava.awt.headless=true}"
        : "${APPTAINERENV__JAVA_OPTIONS:=-Xshare:off -Djava.io.tmpdir=/work/.tmp -Djava.awt.headless=true}"
        export APPTAINERENV_JAVA_TOOL_OPTIONS
        export APPTAINERENV__JAVA_OPTIONS
        $APPTAINER_CMD exec \
                $bind_opts \
                "$PIPELINE_SIF" \
                bash -c "cd /work/${workflow_dir} && ${command} ${config_override}"
    else
        # With --use-apptainer, the pipeline SIF is mandatory; do not run Snakemake on host Conda.
        if [[ "${USE_APPTAINER:-false}" == "true" ]]; then
            local ensure_script="$script_root/Shared/Scripts/shell/ensure_pipeline_container.sh"
            echo "Error: --use-apptainer requires a working pipeline image at ${PIPELINE_SIF}." >&2
            if [[ -f "$ensure_script" ]]; then
                bash "$ensure_script" || true
            else
                echo "Error: missing helper script: ${ensure_script}" >&2
            fi
            exit 1
        fi
        echo "Activating snakemake_env..."
        echo "Running in directory: ${workflow_dir}"
        echo "Command: ${command}"
        echo ""

        conda run --no-capture-output -n snakemake_env bash -c "
            cd '${workflow_dir}'
            alias sm='snakemake'
            ${command} ${config_override}
        "
    fi

    if [[ -n "$temp_config" && -f "$temp_config" ]]; then
        rm -f "$temp_config"
        echo "Cleaned up temporary config file" >&2
    fi
}

# Parse cores option and other flags
CORES=""
EXTRA_FLAGS=""
CORES_SPECIFIED=false
USE_APPTAINER=false
USE_APPTAINER_SUDO=false
USE_DEFAULTS=false
CLEAN_BEFORE_RUN=false

# Path override variables
GENOME_PATH=""
INDEX_PATH=""
DATASET_PATH=""
VECTOR_PATH=""
PIRNA_MULTI_VECTOR_TSV=""
ADAPTER_PATH=""
GENOME_VERSION=""
GENOME_SPECIES=""

# Parse all arguments first - collect positional args separately
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --cores)
            if [[ $# -lt 2 ]]; then
                echo "Error: --cores requires a value" >&2
                exit 1
            fi
            CORES="$2"
            CORES_SPECIFIED=true
            shift 2
            ;;
        --rerun-incomplete)
            EXTRA_FLAGS="${EXTRA_FLAGS} --rerun-incomplete"
            shift
            ;;
        --clean)
            CLEAN_BEFORE_RUN=true
            shift
            ;;
        --genome-path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --genome-path requires a value" >&2
                exit 1
            fi
            GENOME_PATH="$2"
            shift 2
            ;;
        --index-path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --index-path requires a value" >&2
                exit 1
            fi
            INDEX_PATH="$2"
            shift 2
            ;;
        --dataset-path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --dataset-path requires a value" >&2
                exit 1
            fi
            DATASET_PATH="$2"
            shift 2
            ;;
        --vector-path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --vector-path requires a value" >&2
                exit 1
            fi
            VECTOR_PATH="$2"
            shift 2
            ;;
        --adapter-path)
            if [[ $# -lt 2 ]]; then
                echo "Error: --adapter-path requires a value" >&2
                exit 1
            fi
            ADAPTER_PATH="$2"
            shift 2
            ;;
        --genome-version)
            if [[ $# -lt 2 ]]; then
                echo "Error: --genome-version requires a value" >&2
                exit 1
            fi
            GENOME_VERSION="$2"
            shift 2
            ;;
        --use-apptainer)
            USE_APPTAINER=true
            shift
            ;;
        --pipeline-sif)
            if [[ $# -lt 2 ]]; then
                echo "Error: --pipeline-sif requires a path to pirna_pipeline.sif" >&2
                exit 1
            fi
            PIRNA_PIPELINE_SIF="$2"
            export PIRNA_PIPELINE_SIF
            shift 2
            ;;
        --use-sudo)
            USE_APPTAINER_SUDO=true
            shift
            ;;
        --defaults)
            USE_DEFAULTS=true
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Parse workflow and command from positional arguments
WORKFLOW=${POSITIONAL_ARGS[0]:-}
COMMAND=${POSITIONAL_ARGS[1]:-run}

# Convert numeric workflow options and aliases
case "$WORKFLOW" in
    1|chip)
        WORKFLOW="chip-seq"
        ;;
    2|pirna|pirna-seq)
        WORKFLOW="pirna-seq"
        ;;
    4|totalrna|totalrna-seq)
        WORKFLOW="totalrna-seq"
        ;;
esac

# Handle help aliases before interactive prompts
if [[ "$WORKFLOW" == "help" || "$WORKFLOW" == "--help" || "$WORKFLOW" == "-h" ]]; then
    show_usage
    exit 0
fi

# If no workflow specified, interactively select one and configure paths
if [[ "$COMMAND" == "help" ]]; then
    :
elif [[ -z "$WORKFLOW" ]]; then
    select_workflow_and_paths
    COMMAND="run"  # Default to run when interactively selected
elif [[ -z "$GENOME_VERSION" && -z "$GENOME_PATH" && -z "$INDEX_PATH" && -z "$DATASET_PATH" && -z "$VECTOR_PATH" && -z "$ADAPTER_PATH" ]]; then
    # Workflow specified but no paths/config provided
    if [[ "$USE_DEFAULTS" == "true" ]]; then
        # Use defaults: dm6 genome, config.yaml paths, no prompting
        GENOME_VERSION="dm6"
        GENOME_SPECIES="drosophila"
        echo "Using defaults: genome=dm6, paths from config.yaml" >&2
        echo "" >&2
    else
    # Prompt for genome version and paths
    WORKFLOW_SAVED="$WORKFLOW"
    # Call just the path configuration part (genome version + paths)
    echo "=== Genome Version Configuration ===" >&2
    echo "Specify the genome version for this workflow." >&2
    echo "Common options: dm6, dm3 (Drosophila), hg38, hg19 (Human), mm10, mm9 (Mouse), ce11 (C. elegans)" >&2
    echo "" >&2
    
    # Genome version
    read -p "Genome version [default: dm6]: " genome_version_input >&2
    if [[ -n "$genome_version_input" ]]; then
        GENOME_VERSION="$genome_version_input"
        echo "Using genome version: $GENOME_VERSION" >&2
    else
        GENOME_VERSION="dm6"
        echo "Using default genome version: dm6" >&2
    fi
    echo "" >&2
    
    # Determine species from genome version
    case "$GENOME_VERSION" in
        dm*|BDGP*)
            GENOME_SPECIES="drosophila"
            ;;
        hg*|GRCh*)
            GENOME_SPECIES="human"
            ;;
        mm*|GRCm*)
            GENOME_SPECIES="mouse"
            ;;
        ce*)
            GENOME_SPECIES="celegans"
            ;;
        *)
            read -p "Species name for $GENOME_VERSION (e.g., drosophila, human, mouse): " species_input >&2
            GENOME_SPECIES="${species_input:-drosophila}"
            echo "Using species: $GENOME_SPECIES" >&2
            ;;
    esac
    
    echo "" >&2
    echo "=== Path Configuration (optional) ===" >&2
    echo "You can override the default paths from config.yaml files." >&2
    echo "Press Enter to use defaults, or provide custom paths:" >&2
    echo "" >&2
    
    # Get default paths from config files
    config_file=""
    case "$WORKFLOW_SAVED" in
        chip-seq) config_file="CHIP-seq/config.yaml" ;;
        pirna-seq) config_file="piRNA-seq/config.yaml" ;;
        *) config_file="totalRNA-seq/config.yaml" ;;
    esac
    
    # Genome path - check for existence before suggesting
    default_genome=""
    if [[ -n "$GENOME_VERSION" ]]; then
        default_genome="./Shared/DataFiles/genomes/${GENOME_VERSION}.fa"
        if [[ ! -f "$(expand_path "$default_genome")" ]]; then
            echo "⚠️  Warning: $default_genome does not exist. You may need to provide the correct path." >&2
        fi
    elif [[ "$WORKFLOW_SAVED" == "chip-seq" ]]; then
        default_genome=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*dm6_fasta\s*:' | sed -E 's/^\s*dm6_fasta\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_genome" ]]; then
            default_genome=$(echo "$default_genome" | sed 's|^\.\./Shared|./Shared|')
        fi
        if [[ -n "$default_genome" ]] && [[ ! -f "$(expand_path "$default_genome")" ]]; then
            alt_path="./Shared/DataFiles/genomes/dm6.fa"
            if [[ -f "$(expand_path "$alt_path")" ]]; then
                default_genome="$alt_path"
            fi
        fi
    else
        default_genome="./Shared/DataFiles/genomes/dm6.fa"
        if [[ ! -f "$(expand_path "$default_genome")" ]]; then
            default_genome=$(grep -E '^\s*dm6_fasta\s*:' "$config_file" | sed -E 's/^\s*dm6_fasta\s*:\s*//; s/^"//; s/"$//' | head -1) || default_genome="./Shared/DataFiles/genomes/dm6.fa"
            default_genome=$(echo "$default_genome" | sed 's|^\.\./Shared|./Shared|')
        fi
    fi
    read -p "Genome FASTA file path [default: $default_genome]: " genome_input >&2
    if [[ -n "$genome_input" ]]; then
        GENOME_PATH="$genome_input"
        echo "Using custom genome path: $GENOME_PATH" >&2
    fi
    echo "" >&2
    
    # Index path
    default_index=""
    if [[ -n "$GENOME_VERSION" && ( "$WORKFLOW_SAVED" == "chip-seq" || "$WORKFLOW_SAVED" == "pirna-seq" ) ]]; then
        default_index="./Shared/DataFiles/genomes/bowtie-indexes/${GENOME_VERSION}"
        if [[ ! -d "$(expand_path "$default_index")" ]] && [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]]; then
            echo "ℹ️  Note: Index directory $default_index not found. Indexes will be built if needed." >&2
        fi
    elif [[ "$WORKFLOW_SAVED" == "chip-seq" || "$WORKFLOW_SAVED" == "pirna-seq" ]]; then
        default_index=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*dm6_bowtie_index\s*:' | sed -E 's/^\s*dm6_bowtie_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_index" ]]; then
            default_index=$(echo "$default_index" | sed 's|^\.\./Shared|./Shared|')
        fi
        if [[ -n "$default_index" ]] && [[ ! -d "$(expand_path "$default_index")" ]] && [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]]; then
            alt_path="./Shared/DataFiles/genomes/bowtie-indexes/dm6"
            if [[ -d "$(expand_path "$alt_path")" ]] || [[ -f "$(expand_path "${alt_path}.1.ebwt")" ]]; then
                default_index="$alt_path"
            fi
        fi
    elif [[ -n "$GENOME_VERSION" && "$WORKFLOW_SAVED" == "totalrna-seq" ]]; then
        rrna_species=""
        case "$GENOME_SPECIES" in
            drosophila) rrna_species="dmel" ;;
            human) rrna_species="hsap" ;;
            mouse) rrna_species="mmus" ;;
            celegans) rrna_species="cele" ;;
            *) rrna_species="dmel" ;;
        esac
        default_index="./Shared/DataFiles/genomes/rrna/${rrna_species}_rRNA_unit"
        if [[ ! -f "$(expand_path "${default_index}.1.ebwt")" ]] && [[ ! -f "$(expand_path "${default_index}.fa")" ]]; then
            echo "ℹ️  Note: rRNA index ${default_index} not found. Index will be built if source file exists." >&2
        fi
    else
        default_index=$(grep -E '^\s*rrna_index\s*:' "$config_file" | sed -E 's/^\s*rrna_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_index" ]]; then
            default_index=$(echo "$default_index" | sed 's|^\.\./Shared|./Shared|')
        fi
        if [[ -z "$default_index" ]]; then
            default_index="./Shared/DataFiles/genomes/rrna/dmel_rRNA_unit"
        fi
    fi
    read -p "Bowtie index directory path [default: $default_index]: " index_input >&2
    if [[ -n "$index_input" ]]; then
        INDEX_PATH="$index_input"
        echo "Using custom index path: $INDEX_PATH" >&2
    fi
    echo "" >&2
    
    # Dataset path
    default_dataset=""
    if [[ "$WORKFLOW_SAVED" == "chip-seq" ]]; then
        default_dataset=$(grep -A 10 "input_data:" "$config_file" | grep -E '^\s*data_dir\s*:' | sed -E 's/^\s*data_dir\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/chip-seq/chip_inputs"
        read -p "Input dataset directory path [default: $default_dataset]: " dataset_input >&2
    elif [[ "$WORKFLOW_SAVED" == "pirna-seq" ]]; then
        default_dataset=$(grep -A 10 "sample:" "$config_file" | grep -E '^\s*fastq\s*:' | sed -E 's/^\s*fastq\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/pirna-seq/pirna_sample.fastq"
        read -p "Input FASTQ file path [default: $default_dataset]: " dataset_input >&2
    else
        default_dataset=$(grep -E '^\s*fastq_file\s*:' "$config_file" | sed -E 's/^\s*fastq_file\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_dataset" ]]; then
            default_dataset=$(echo "$default_dataset" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_dataset" ]] && default_dataset="./Shared/DataFiles/datasets/totalrna-seq/all.50mers.fastq"
        read -p "Input FASTQ file path [default: $default_dataset]: " dataset_input >&2
    fi
    if [[ -n "$dataset_input" ]]; then
        DATASET_PATH="$dataset_input"
        echo "Using custom dataset path: $DATASET_PATH" >&2
    fi
    echo "" >&2
    
    # Vector path(s)
    default_vector=""
    if [[ "$WORKFLOW_SAVED" == "chip-seq" || "$WORKFLOW_SAVED" == "pirna-seq" ]]; then
        default_vector=$(grep -A 20 "references:" "$config_file" | grep -E '^\s*(vector_42ab_index|vector_index)\s*:' | sed -E 's/^\s*(vector_42ab_index|vector_index)\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_vector" ]]; then
            default_vector=$(echo "$default_vector" | sed 's|^\.\./Shared|./Shared|')
        fi
        if [[ -z "$default_vector" ]]; then
            if [[ "$WORKFLOW_SAVED" == "pirna-seq" ]]; then
                default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UASG"
            else
                default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG"
            fi
        fi
    else
        default_vector=$(grep -E '^\s*vector_index\s*:' "$config_file" | sed -E 's/^\s*vector_index\s*:\s*//; s/^"//; s/"$//' | head -1)
        if [[ -n "$default_vector" ]]; then
            default_vector=$(echo "$default_vector" | sed 's|^\.\./Shared|./Shared|')
        fi
        [[ -z "$default_vector" ]] && default_vector="./Shared/DataFiles/genomes/YichengVectors/42AB_UBIG"
    fi
    if [[ "$WORKFLOW_SAVED" == "pirna-seq" ]]; then
        prompt_pirna_vector_paths "$default_vector"
    elif [[ "$WORKFLOW_SAVED" == "chip-seq" ]]; then
        echo "Bowtie index prefix (path without .fa; trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
    else
        echo "Bowtie index prefix (path without .fa; trailing .fa is stripped)." >&2
        read -p "Vector index prefix [default: $default_vector]: " vector_input >&2
        if [[ -n "$vector_input" ]]; then
            VECTOR_PATH=$(pirna_normalize_vector_index_prefix "$(expand_path "$vector_input")")
            echo "Using custom vector index prefix: $VECTOR_PATH" >&2
        fi
    fi
    echo "" >&2
    
    # Adapter path
    default_adapter=$(grep -E '^\s*adapters_file\s*:' "$config_file" | sed -E 's/^\s*adapters_file\s*:\s*//; s/^"//; s/"$//' | head -1)
    if [[ -n "$default_adapter" ]]; then
        default_adapter=$(echo "$default_adapter" | sed 's|^\.\./Shared|./Shared|')
    fi
    [[ -z "$default_adapter" ]] && default_adapter="./Shared/DataFiles/genomes/AllAdaptors.fa"
    read -p "Adapter sequences file path [default: $default_adapter]: " adapter_input >&2
    if [[ -n "$adapter_input" ]]; then
        ADAPTER_PATH="$adapter_input"
        echo "Using custom adapter path: $ADAPTER_PATH" >&2
    fi
    echo "" >&2
    fi  # end else (non-defaults path prompt)
fi

# Validate workflow
case "$WORKFLOW" in
    chip-seq)
        WORKFLOW_DIR="CHIP-seq"
        ;;
    pirna-seq)
        WORKFLOW_DIR="piRNA-seq"
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

# piRNA-seq uses pinned tools from the pipeline Apptainer image (or host PATH); no Snakemake conda envs.
SM_CONDA_FLAGS=""
if [[ "$WORKFLOW_DIR" != "piRNA-seq" ]]; then
    SM_CONDA_FLAGS="--use-conda --conda-frontend mamba "
fi

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
    if [[ "$USE_DEFAULTS" == "true" ]]; then
        CORES=$(get_optimal_cores)
        echo "Using $CORES cores (default for system load)." >&2
        echo "" >&2
    else
        CORES=$(prompt_cores)
        echo "Using $CORES cores for execution." >&2
        echo "" >&2
    fi
elif [[ -z "$CORES" ]]; then
    CORES=8  # Default fallback
fi

# Check input files before running workflows (unless it's help, status, clean, unlock, or check-inputs)
if [[ "$COMMAND" != "help" && "$COMMAND" != "status" && "$COMMAND" != "clean" && "$COMMAND" != "unlock" && "$COMMAND" != "check-inputs" ]]; then
    check_input_files "$WORKFLOW_DIR"
fi

# Build samtools 0.1.8 from source for CHIP-seq (needed when no containers;
# x86 pre-built binary segfaults on ARM64)
if [[ "$WORKFLOW" == "chip-seq" && ("$COMMAND" == "run" || "$COMMAND" == "run-force" || "$COMMAND" == "fix-incomplete" || "$COMMAND" == "setup" || "$COMMAND" == "dryrun") ]]; then
    ensure_samtools_018
    ensure_samtools_016
fi

# When using Apptainer, verify the pipeline container is available.
# IMPORTANT: Never trigger a build automatically (many servers/HPC disallow builds).
if [[ "$USE_APPTAINER" == "true" && ("$COMMAND" == "run" || "$COMMAND" == "run-force" || "$COMMAND" == "fix-incomplete" || "$COMMAND" == "setup" || "$COMMAND" == "dryrun") ]]; then
    [[ "$USE_APPTAINER_SUDO" == "true" ]] && export APPTAINER_SUDO=1
    ensure_pipeline_container
fi

# Do not auto-build individual tool containers. With --use-apptainer, run_snakemake requires
# the pipeline SIF (see ensure_pipeline_container) and does not fall back to host Conda.

# Build container flags (Apptainer only)
CONTAINER_FLAGS=""
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$USE_APPTAINER" == "true" ]]; then
    [[ "$USE_APPTAINER_SUDO" == "true" ]] && export APPTAINER_SUDO=1
    # Pipeline container already ensured above for run/setup/dryrun/etc.; run_snakemake re-checks
    # for unlock/status and still errors if the SIF is unusable (no Conda fallback).
    # When running inside pipeline container, do NOT pass --use-apptainer to Snakemake
    # (all tools are already in the container; rules with container: None would trigger Snakemake to spawn sub-containers incorrectly)
    PIPELINE_SIF="${PIRNA_PIPELINE_SIF:-$SCRIPT_ROOT/containers/pirna_pipeline.sif}"
    APPTAINER_CMD="apptainer"
    [[ "${APPTAINER_SUDO:-0}" == "1" ]] && APPTAINER_CMD="sudo apptainer"
    if [[ -f "$PIPELINE_SIF" ]] && $APPTAINER_CMD exec "$PIPELINE_SIF" snakemake --version &>/dev/null; then
        CONTAINER_FLAGS=""   # Inside pipeline container: no per-rule containers
    else
        CONTAINER_FLAGS="--use-apptainer"   # Outside: Snakemake runs rules in individual containers
    fi
fi

# Auto-unlock if there's a stale lock (before any run commands)
if [[ "$COMMAND" == "run" || "$COMMAND" == "run-force" || "$COMMAND" == "dryrun" || "$COMMAND" == "fix-incomplete" ]]; then
    auto_unlock_if_safe "$WORKFLOW_DIR"
fi

# Optional non-interactive cleanup before run commands
if [[ "$CLEAN_BEFORE_RUN" == "true" && ( "$COMMAND" == "run" || "$COMMAND" == "run-force" ) ]]; then
    echo "Pre-run cleanup enabled (--clean): removing $WORKFLOW_DIR/results" >&2
    rm -rf "$WORKFLOW_DIR/results"
    echo "" >&2
fi

# Check for existing outputs before running destructive commands
FORCE_RERUN=false
if [[ "$COMMAND" == "run" || "$COMMAND" == "run-force" ]] && [[ "$CLEAN_BEFORE_RUN" != "true" ]]; then
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
        if [[ "$WORKFLOW_DIR" == "piRNA-seq" ]]; then
            echo "piRNA-seq: no Snakemake conda envs (use pipeline Apptainer for pinned FastQC/cutadapt/Bowtie/samtools/deepTools)."
        else
            run_snakemake "$WORKFLOW_DIR" "snakemake ${SM_CONDA_FLAGS}--conda-create-envs-only all $CONTAINER_FLAGS"
        fi
        echo "Setup completed successfully!"
        ;;
    dryrun)
        echo "Performing dry run for $WORKFLOW..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all ${SM_CONDA_FLAGS}--cores $CORES --dry-run $CONTAINER_FLAGS"
        ;;
    run)
        if [[ "$FORCE_RERUN" == "true" ]]; then
            echo "Force running $WORKFLOW workflow (all steps)..."
            echo "Note: Cleaning up any incomplete file metadata first..."
            run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata ${SM_CONDA_FLAGS}$CONTAINER_FLAGS" 2>/dev/null || true
            START_TIME=$(date +%s)
            run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --rerun-incomplete ${SM_CONDA_FLAGS}--cores $CORES $CONTAINER_FLAGS $EXTRA_FLAGS"
        else
            echo "Running $WORKFLOW workflow..."
            START_TIME=$(date +%s)
            # Try regular run first, if it fails with incomplete files, suggest fix-incomplete
            if ! run_snakemake "$WORKFLOW_DIR" "snakemake all ${SM_CONDA_FLAGS}--cores $CORES $CONTAINER_FLAGS $EXTRA_FLAGS"; then
                echo ""
                echo "❌ Workflow failed. This might be due to incomplete files from a previous run."
                echo "💡 Try running: $0 $WORKFLOW fix-incomplete"
                echo "   This will clean up incomplete files and resume the workflow."
                exit 1
            fi
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
        echo "Note: Cleaning up any incomplete file metadata first..."
        run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata ${SM_CONDA_FLAGS}$CONTAINER_FLAGS" 2>/dev/null || true
        START_TIME=$(date +%s)
        run_snakemake "$WORKFLOW_DIR" "snakemake all --forceall --rerun-incomplete ${SM_CONDA_FLAGS}--cores $CORES $CONTAINER_FLAGS $EXTRA_FLAGS"
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Workflow completed successfully!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
        ;;
    fix-incomplete)
        echo "Fixing incomplete files for $WORKFLOW workflow..."
        echo "Step 1: Attempting to clean up metadata for incomplete files..."
        # Try to cleanup metadata - this might fail if no specific files are provided, that's OK
        run_snakemake "$WORKFLOW_DIR" "snakemake --cleanup-metadata ${SM_CONDA_FLAGS}$CONTAINER_FLAGS || true" 2>/dev/null || true
        echo ""
        echo "Step 2: Re-running workflow with incomplete file recovery..."
        START_TIME=$(date +%s)
        run_snakemake "$WORKFLOW_DIR" "snakemake all --rerun-incomplete ${SM_CONDA_FLAGS}--cores $CORES $CONTAINER_FLAGS $EXTRA_FLAGS"
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        echo ""
        echo "=================================="
        echo "Incomplete files fixed and workflow completed!"
        echo "Total execution time: $(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))"
        echo "=================================="
        ;;
    check-inputs)
        echo "Validating input files for $WORKFLOW workflow..."
        echo ""
        check_input_files "$WORKFLOW_DIR"
        ;;
    unlock)
        echo "Unlocking $WORKFLOW workflow directory..."
        run_snakemake "$WORKFLOW_DIR" "snakemake --unlock ${SM_CONDA_FLAGS}$CONTAINER_FLAGS"
        echo "Workflow directory unlocked successfully!"
        ;;
    status)
        echo "Checking $WORKFLOW workflow status..."
        run_snakemake "$WORKFLOW_DIR" "snakemake all ${SM_CONDA_FLAGS}--dry-run --quiet $CONTAINER_FLAGS"
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
