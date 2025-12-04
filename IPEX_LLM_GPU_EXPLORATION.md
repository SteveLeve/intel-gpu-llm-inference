# IPEX-LLM GPU Acceleration Exploration

**Date**: 2025-12-04
**Hardware**: Intel Core i7-1185G7 + Iris Xe Graphics (TigerLake-LP GT2)
**Ollama Version**: 0.13.1
**Status**: Exploration phase - **NOT RECOMMENDED** for implementation

---

## Executive Summary

Explored enabling Intel GPU acceleration for Ollama via IPEX-LLM (Intel Extension for PyTorch). **Conclusion: GPU acceleration unlikely to provide benefit on integrated Iris Xe graphics based on existing OpenVINO GPU testing.**

### Key Finding
**Previous OpenVINO GPU testing (documented in CLAUDE.md) demonstrated NO meaningful performance advantage:**
- Llama 3.1 8B: **4.50 tok/s (Ollama CPU)** vs 4.3 tok/s (OpenVINO GPU)
- GPU load times: **70x slower** (15.4s vs 0.22s)
- Similar technology stack: Both use Intel Level Zero + OpenCL drivers

### Recommendation
**Stick with current Ollama CPU setup** - proven fast, simple, reliable.

---

## Hardware Verification

### System Check (2025-12-04)
```bash
$ lspci | grep -i vga
0000:00:02.0 VGA compatible controller: Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics] (rev 01)

$ ls -la /dev/dri/
crw-rw----+ 1 root video  226,   1 Dec  3 13:19 card1
crw-rw----+ 1 root render 226, 128 Dec  2 09:19 renderD128

$ groups
steve-leve ... render  # ✓ GPU access confirmed

$ clinfo -l
Platform #0: Intel(R) OpenCL Graphics
 `-- Device #0: Intel(R) Iris(R) Xe Graphics  # ✓ OpenCL functional
```

**Result**: Hardware is **technically supported** but unlikely to benefit from GPU acceleration.

### Installed Intel Packages
```bash
ii  intel-opencl-icd                    25.40.35563.7-1~24.04~ppa1  # GPU compute runtime
ii  level-zero                          1.16.15-881~22.04           # oneAPI Level Zero
ii  intel-oneapi-runtime-dpcpp-cpp      2025.3.1-760               # SYCL runtime
ii  intel-oneapi-runtime-opencl         2025.3.1-760               # OpenCL runtime
```

**Status**: Runtime components present, but **oneAPI Base Toolkit NOT installed** (missing `/opt/intel/oneapi/setvars.sh`).

---

## IPEX-LLM Overview

### What is IPEX-LLM?
Intel Extension for PyTorch - Large Language Models. Provides optimized inference for Intel CPUs and GPUs.

**Ollama Integration**: Custom IPEX-LLM-optimized Ollama binary that can leverage Intel GPUs.

### Technology Stack
- **oneAPI Base Toolkit**: Intel's unified programming model
- **Level Zero**: Low-level GPU interface
- **SYCL**: Cross-platform abstraction layer
- **IPEX**: PyTorch optimizations for Intel hardware

### Supported Hardware
- **Discrete GPUs**: Intel Arc A-series (A770, A750, A380)
- **Integrated GPUs**: Iris Xe (11th-13th gen), UHD Graphics (select models)

**Note**: Iris Xe is supported, but integrated GPUs have fundamental limitations for LLM workloads.

---

## Why GPU Likely Won't Help (Technical Analysis)

### 1. Existing Empirical Evidence
Your comprehensive OpenVINO testing already proved this:

| Model | Framework | Device | Speed | Load Time |
|-------|-----------|--------|-------|-----------|
| Llama 3.1 8B | Ollama | CPU | **4.50 tok/s** | **0.22s** |
| Llama 3.1 8B | OpenVINO | GPU | 4.3 tok/s | 15.4s |
| Llama 3.1 8B | OpenVINO | CPU | 3.4 tok/s | 6.1s |

**Interpretation**: GPU was **5% slower** than Ollama CPU, with **70x slower load times**.

### 2. Integrated GPU Architectural Limitations

**Memory Bottleneck**:
- Iris Xe shares system RAM (no dedicated VRAM)
- Memory bandwidth: ~50 GB/s (shared with CPU)
- LLM inference is **memory-bound**, not compute-bound
- GPU compute advantage negated by memory bandwidth limit

**Resource Competition**:
- CPU and GPU compete for same memory bus
- OS/background processes reduce available bandwidth
- No performance isolation

**Thermal/Power Constraints**:
- Integrated GPUs throttle under sustained load
- Share TDP budget with CPU cores
- Cannot sustain peak performance

### 3. Technology Stack Overlap
IPEX-LLM uses the **same driver stack** as your OpenVINO setup:
- Intel OpenCL drivers (intel-opencl-icd)
- Level Zero runtime
- Same GPU compute interface

**Implication**: If OpenVINO GPU didn't help, IPEX-LLM GPU likely won't either.

---

## Installation Requirements (If Pursued)

### Full Setup Would Require:

1. **oneAPI Base Toolkit** (~3GB download)
   ```bash
   wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/...
   sudo sh oneapi-basekit-*.sh
   ```

2. **IPEX-LLM for Ollama** (Conda environment)
   ```bash
   conda create -n llm-ollama python=3.11
   conda activate llm-ollama
   pip install ipex-llm[xpu] --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/
   ```

3. **Environment Configuration**
   ```bash
   export no_proxy=localhost,127.0.0.1
   export ZES_ENABLE_SYSMAN=1
   export OLLAMA_NUM_GPU=999
   source /opt/intel/oneapi/setvars.sh
   export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1  # Optional, sometimes helps
   ```

4. **Run IPEX-LLM Ollama Binary**
   ```bash
   ./ollama serve  # IPEX-LLM custom binary
   ollama run llama3.1:8b-instruct-q4_0 "Test prompt"
   ```

**Estimated Setup Time**: 1-2 hours
**Disk Space**: ~5GB (toolkit + Python packages)
**Complexity**: High (environment management, driver compatibility)

---

## Performance Expectations

### Realistic Prediction (Based on Existing Data)

| Metric | Current (Ollama CPU) | Predicted (IPEX-LLM GPU) |
|--------|---------------------|---------------------------|
| **Speed** | 4.50 tok/s | 3.5-4.5 tok/s |
| **Load Time** | 0.22s | 5-15s |
| **Setup Complexity** | Low (single binary) | High (toolkit + env) |
| **Reliability** | Excellent | Unknown (driver issues?) |

**Expected Outcome**: No improvement or slight degradation.

### Why Discrete GPUs Perform Better
- **Dedicated VRAM**: 8-16GB of high-bandwidth memory (500+ GB/s)
- **Memory isolation**: No competition with CPU
- **Higher TDP**: Sustained performance without throttling
- **Optimized for compute**: Tensor cores, matrix units

**Arc A770 Example**: Would likely see 2-3x speedup over CPU for 8B models.

---

## Scientific Value of Testing

### Why You Might Still Want to Test

1. **Documentation completeness**: Add IPEX-LLM data to your comprehensive benchmark suite
2. **Community value**: Few public benchmarks for Iris Xe + IPEX-LLM + Ollama
3. **Verify hypothesis**: Scientifically confirm GPU provides no benefit
4. **Future reference**: If you upgrade to Arc GPU, setup already familiar

### Recommended Test Methodology

If pursuing:
1. Install IPEX-LLM with full environment
2. Run Llama 3.1 8B with identical prompts (100 tokens)
3. Test with/without `SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS`
4. Compare: speed (tok/s), load time, memory usage
5. Document in `IPEX_LLM_PERFORMANCE_RESULTS.md`

**Control**: Use existing Ollama CPU baseline (4.50 tok/s, 0.22s load)

---

## References

1. **IPEX-LLM Ollama Quickstart**
   https://github.com/intel/ipex-llm/blob/main/docs/mddocs/Quickstart/llama3_llamacpp_ollama_quickstart.md
   - Environment variables: `ZES_ENABLE_SYSMAN=1`, `OLLAMA_NUM_GPU=999`
   - Requires oneAPI toolkit with `setvars.sh`
   - Conda-based Python environment

2. **Intel Builders Guide** (PDF - not extracted)
   https://builders.intel.com/docs/networkbuilders/running-ollama-with-open-webui-on-intel-hardware-platform-1742810910.pdf
   - Likely covers end-to-end setup with Open WebUI
   - Could not extract text (binary PDF format)

3. **Existing Project Documentation**
   - `CLAUDE.md`: Project overview with performance matrix
   - `COMPREHENSIVE_PERFORMANCE_COMPARISON.md`: Full 12-config benchmark
   - OpenVINO GPU testing: Established baseline proving GPU provides no benefit

---

## Decision Matrix

| Factor | Ollama CPU (Current) | IPEX-LLM GPU |
|--------|----------------------|--------------|
| **Performance** | ⭐⭐⭐⭐⭐ Proven fast | ⭐⭐ Likely no improvement |
| **Setup** | ⭐⭐⭐⭐⭐ Simple | ⭐⭐ Complex (toolkit + env) |
| **Reliability** | ⭐⭐⭐⭐⭐ Rock solid | ⭐⭐⭐ Potential driver issues |
| **Load Times** | ⭐⭐⭐⭐⭐ 0.22s | ⭐⭐ 5-15s expected |
| **Documentation** | ⭐⭐⭐⭐⭐ Complete | ⭐ Would add data point |

**Recommendation**: **Stick with Ollama CPU** unless testing for scientific documentation purposes.

---

## Conclusion

**Final Assessment**: Your hardware is supported, drivers are functional, but **GPU acceleration is unlikely to provide meaningful benefit** on integrated Iris Xe graphics.

**Rationale**:
1. Empirical evidence from OpenVINO testing shows no GPU advantage
2. Integrated GPU architectural limitations (shared memory bandwidth)
3. High setup complexity vs. negligible expected benefit
4. Current Ollama CPU setup is already optimal for this hardware

**If Future Hardware Upgrade**: Discrete Intel Arc GPU (A770/A750) would make IPEX-LLM GPU acceleration worthwhile (2-3x speedup expected).

**Current Best Practice**: Continue using Ollama CPU with proven 4.50 tok/s performance.
