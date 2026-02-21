# Container Known Issues

**Purpose:** Document known issues with the pipeline container (`containers/pipeline.def`). This container is shared across multiple pipelines (CHIP-seq, totalRNA-seq, and planned piRNA-seq, Fusion Reads, RIP-seq, etc.).

---

## EBSeq Build Failure (RSEM Optional Component)

### What is EBSeq?

EBSeq is an R package for RNA-seq differential expression analysis. RSEM can optionally build EBSeq integration via `make ebseq`, which provides the `rsem-for-ebseq-*` scripts. These are used for downstream differential expression with EBSeq, not for the core RSEM quantification steps.

### Impact on Current Pipelines

**No impact.** The current totalRNA-seq Snakefile uses only:

- `rsem-prepare-reference`
- `rsem-calculate-expression`

EBSeq and `rsem-for-ebseq-*` are **not used** by any existing pipeline rules. The failure does not affect RSEM quantification.

### Build Failure Details

During container build, `make ebseq` (around line 121 in `pipeline.def`) can fail due to:

1. **blockmodeling (R package):** Fortran 2018 compatibility issues in `opt_par_ss_com.f90`.
2. **KernSmooth:** Linker error `cannot find -lblas` — the BLAS library is not found during compilation.

### Mitigation Options

**Option A (current):** Accept the failure. Core RSEM functionality (`make` and `make install`) succeeds; `make ebseq` is optional. If the build fails on `make ebseq`, the container can still be used for all current pipelines.

**Option B (skip EBSeq):** Remove or comment out `make ebseq` in the container definition. This eliminates the failure and has no effect on current workflows.

**Option C (fix EBSeq, if ever required):** If a future pipeline needs EBSeq/`rsem-for-ebseq-*`:

1. Install `libblas-dev` (or equivalent) before the RSEM build to resolve KernSmooth's `-lblas` linker error.
2. Investigate blockmodeling Fortran 2018 compatibility (e.g., compiler flags or package version pinning).

### Location in Container Definition

- `containers/pipeline.def` — line ~121: `make ebseq`

---

## Unprivileged Apptainer Execution Fails

### Symptoms

- `apptainer exec` fails with: `Could not write info to setgroups: Permission denied` or `Error while waiting event for user namespace mappings: no event received`
- `--fakeroot` fails with: `Failed to create mount namespace: mount namespace requires privileges`
- `sudo apptainer exec` works

### Cause

Some systems (e.g., Ubuntu on ARM64, certain kernel/configs) prevent unprivileged user namespace operations needed for Apptainer to run containers without root.

### Workaround

Use `--use-sudo` when running the workflow:

```bash
./run_workflow.sh 1 run --use-apptainer --use-sudo --defaults
```

This runs Apptainer with `sudo` for the pipeline container. You may be prompted for your password when the workflow starts.

---

## Adding New Pipelines

When adding pipelines that use this shared container:

1. **Check this document** for known issues before assuming a tool or feature is available.
2. **Verify tool usage** — if a step fails, confirm whether that tool/feature is actually used by your Snakefile.
3. **Update this document** when new issues are discovered or when fixes are applied.

---

## Related Documentation

- [TOOL_VERSION_RESEARCH_2021_ARM64.md](../TOOL_VERSION_RESEARCH_2021_ARM64.md) — tool versions and ARM64 notes
- [CONTAINER_STRATEGY_ANALYSIS.md](../CONTAINER_STRATEGY_ANALYSIS.md) — Docker vs Apptainer strategy
