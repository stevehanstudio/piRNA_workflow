# Tool Version Research: 2021-Era Versions for ARM64

**Date:** February 2026  
**Context:** Match original [Luo_2025_piRNA](https://github.com/Peng-He-Lab/Luo_2025_piRNA) pipeline tool versions (repo last updated ~2021) and support ARM64.

---

## 1. MACS2 – Why Are We Using It?

**Short answer: We are not.** MACS2 is **not used** in the current CHIP-seq workflow.

- **`envs/macs2-2.1.0.yaml`** exists and is listed in README as "for peak calling"
- **No rule in `CHIP-seq/Snakefile`** references MACS2; the env is orphaned
- **Original ChIP-seq.md** does not use MACS2; it uses **bamCompare** (deepTools) for ChIP-vs-Input enrichment tracks

**Recommendation:** Remove the MACS2 env or keep it only if you plan to add peak calling later. The original pipeline does not perform peak calling; it focuses on enrichment visualization.

---

## 2. deepTools 2.4.2 (Original: deepTools-2.4.2_develop)

| Aspect | Details |
|--------|---------|
| **Original** | deepTools-2.4.2_develop, Python 2.7 site-packages |
| **Our version** | deepTools 3.5.4 (Python 3.11) |
| **2021-era release** | 2.4.x was ~2018–2019; 2.5.x in 2020; 3.0 in 2018 |
| **Source** | https://github.com/deeptools/deepTools |
| **ARM64 executables** | No pre-built binaries; Python package only |
| **Conda aarch64** | deepTools 2.x not in bioconda for linux-aarch64; 3.x available |
| **Build from source** | `pip install deeptools==2.4.2` – needs Python 2.7 or early Python 3; C extensions may fail on Python 3.7+ |

**Options:**
- **A)** Use a Python 2.7 or 3.6 env and `pip install deeptools==2.4.2` (may require patching)
- **B)** Run deepTools 2.4.2 in a Docker container (Python 2.7 base)
- **C)** Stay on deepTools 3.5.4 and accept behavioral differences (bamCompare/bamCoverage interface changed between 2.x and 3.x)

**Effort:** Medium–high; Python 2 / old deps are brittle.

---

## 3. STAR

| Aspect | Details |
|--------|---------|
| **Original** | No explicit version in totalRNA-seq.md |
| **2021-era versions** | 2.7.7a (Jan 2021), 2.7.8a (Feb 2021), 2.7.9a (May 2021) |
| **Source** | https://github.com/alexdobin/STAR |
| **ARM64 executables** | None; official binaries are x86-64 only |
| **Conda aarch64** | `conda install star` – newer versions may have aarch64 in bioconda |
| **Build from source** | `cd source && make STAR` – C++ code, uses SIMD (AVX2 by default) |
| **ARM64 build** | STAR 2.7.9a+ includes [SIMDe](https://github.com/simd-everywhere/simde) for non-AVX architectures; use `make STAR CXXFLAGS_SIMD=sse` or equivalent for ARM |

**Options:**
- **A)** Try bioconda STAR on ARM64; pin version (e.g. 2.7.9a) if available
- **B)** Build from source: `git clone`, checkout tag `2.7.9a`, `make STAR` (may need `CXXFLAGS_SIMD` for ARM)

**Effort:** Low if conda works; medium if source build needed.

---

## 4. RSEM

| Aspect | Details |
|--------|---------|
| **Original** | No explicit version in totalRNA-seq.md |
| **2021-era version** | v1.3.3 (Feb 2020) – closest to 2021 |
| **Source** | https://github.com/deweylab/RSEM |
| **ARM64 executables** | No pre-built binaries |
| **Conda aarch64** | RSEM in bioconda; aarch64 support unknown for older versions |
| **Build from source** | `make` – needs C++, Perl, R, Python; standard build |

**Options:**
- **A)** Try `conda install rsem` on ARM64; pin `rsem=1.3.3` if available
- **B)** Build from source: clone, `make`, `make ebseq` (optional), `make install`

**Effort:** Low–medium; Perl/R deps are common.

---

## 5. MACS2 (If Peak Calling Is Added)

| Aspect | Details |
|--------|---------|
| **Version** | 2.1.0 (or newer) |
| **Conda aarch64** | **Available** – bioconda has MACS2 for linux-aarch64 |
| **Build from source** | Not needed; conda sufficient |

**Recommendation:** If you add peak calling, use `conda install macs2=2.1.0`; ARM64 support exists.

---

## Summary: What Needs to Be Done

| Tool | In Original? | 2021-Era Version | ARM64 Path | Effort |
|------|--------------|------------------|------------|--------|
| **MACS2** | No | N/A | Remove or leave unused | Trivial |
| **deepTools** | Yes (bamCompare, bamCoverage) | 2.4.2 | Container or pip + old Python | Medium–high |
| **STAR** | Yes (totalRNA-seq) | 2.7.9a | Conda or source build | Low–medium |
| **RSEM** | Yes (totalRNA-seq) | 1.3.3 | Conda or source build | Low–medium |

---

## Recommended Order of Work

1. **MACS2:** Remove `macs2-2.1.0.yaml` reference from README or delete env if not needed.
2. **STAR:** Pin version in `star.yaml` (e.g. `star=2.7.9`); test on ARM64. If conda fails, add `ensure_star.sh` to build from source.
3. **RSEM:** Pin `rsem=1.3.3` in `rsem.yaml`; test on ARM64. Add source build script if needed.
4. **deepTools:** Decide whether strict 2.4.2 reproducibility is required:
   - If yes: add Dockerfile for deepTools 2.4.2 (Python 2.7) and use container
   - If no: keep 3.5.4 and document known differences

---

## References

- [Luo_2025_piRNA ChIP-seq.md](https://github.com/Peng-He-Lab/Luo_2025_piRNA/blob/main/ChIP-seq.md)
- [Luo_2025_piRNA totalRNA-seq.md](https://github.com/Peng-He-Lab/Luo_2025_piRNA/blob/main/totalRNA-seq.md)
- [deepTools GitHub](https://github.com/deeptools/deepTools)
- [STAR GitHub](https://github.com/alexdobin/STAR)
- [RSEM GitHub](https://github.com/deweylab/RSEM)
