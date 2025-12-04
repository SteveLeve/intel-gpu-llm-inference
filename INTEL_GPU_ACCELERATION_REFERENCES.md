# Intel GPU Acceleration References

**Last Updated**: 2025-12-04
**Purpose**: Quick reference for Intel GPU acceleration methods for LLM inference

---

## Overview: Three Acceleration Approaches

| Method | Best For | Complexity | Status in Project |
|--------|----------|------------|-------------------|
| **OpenVINO GenAI** | Mistral 7B (9.5 tok/s) | Medium | ✓ Tested, documented |
| **IPEX-LLM + Ollama** | Discrete Arc GPUs | High | ✗ Not implemented |
| **Ollama Native** | All models (simplicity) | Low | ✓ Current best practice |

---

## 1. OpenVINO GenAI (Already Implemented)

### What It Is
Intel's AI inference toolkit with optimized runtimes for CPU/GPU.

### Status in This Project
✓ **Fully tested and documented**
- Setup script: `setup-intel-gpu-llm.sh`
- Test script: `test-inference.py`
- Benchmark: `benchmark.py`
- Results: `COMPREHENSIVE_PERFORMANCE_COMPARISON.md`

### Key Findings
- **Mistral 7B**: Best performance (9.5 tok/s CPU, 9.4 tok/s GPU)
- **Llama 3.1 8B**: Ollama faster (4.50 tok/s vs 3.4-4.3 tok/s)
- **GPU provides no benefit** on Iris Xe integrated graphics

### Installation
```bash
./setup-intel-gpu-llm.sh
source activate-intel-gpu.sh
```

### Documentation
- Official: https://docs.openvino.ai/
- GitHub: https://github.com/openvinotoolkit/openvino.genai
- Project docs: See `CLAUDE.md`, `*_PERFORMANCE_RESULTS.md`

---

## 2. IPEX-LLM for Ollama (Explored, Not Recommended)

### What It Is
Intel Extension for PyTorch with custom Ollama binary for GPU acceleration.

### Status in This Project
✗ **Explored but not implemented**
- Documentation: `IPEX_LLM_GPU_EXPLORATION.md`
- Conclusion: Unlikely to improve performance on Iris Xe
- Reason: Same driver stack as OpenVINO, which showed no GPU benefit

### When It Makes Sense
- **Discrete Intel Arc GPUs**: A770, A750, A380 (2-3x speedup expected)
- **Higher RAM systems**: 32GB+ for large models
- **Production inference servers**: Worth setup complexity

### Installation (If Pursued)
```bash
# 1. Install oneAPI Base Toolkit (~3GB)
wget https://registrationcenter-download.intel.com/akdlm/IRC_NAS/.../l_BaseKit_*.sh
sudo sh l_BaseKit_*.sh

# 2. Create conda environment
conda create -n llm-ollama python=3.11
conda activate llm-ollama
pip install ipex-llm[xpu] --extra-index-url https://pytorch-extension.intel.com/release-whl/stable/xpu/us/

# 3. Download IPEX-LLM Ollama binary
# (Follow https://github.com/intel/ipex-llm/blob/main/docs/mddocs/Quickstart/llama3_llamacpp_ollama_quickstart.md)

# 4. Set environment variables
export no_proxy=localhost,127.0.0.1
export ZES_ENABLE_SYSMAN=1
export OLLAMA_NUM_GPU=999
source /opt/intel/oneapi/setvars.sh
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1  # Optional, test both ways

# 5. Run
./ollama serve
ollama run llama3.1:8b "Test prompt"
```

### Environment Variables Explained
- `ZES_ENABLE_SYSMAN=1`: Enable GPU telemetry/monitoring
- `OLLAMA_NUM_GPU=999`: Force GPU usage (999 = use all available)
- `SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1`: Performance tuning (sometimes helps, sometimes hurts - test both)
- `no_proxy=localhost,127.0.0.1`: Prevent proxy interference with local Ollama server

### Documentation
- **Primary Source**: https://github.com/intel/ipex-llm/blob/main/docs/mddocs/Quickstart/llama3_llamacpp_ollama_quickstart.md
- **Intel Builders Guide**: https://builders.intel.com/docs/networkbuilders/running-ollama-with-open-webui-on-intel-hardware-platform-1742810910.pdf
- **IPEX-LLM Main**: https://github.com/intel/ipex-llm

### Hardware Requirements
- **Supported GPUs**:
  - Discrete: Arc A770, A750, A380
  - Integrated: Iris Xe (11th-13th gen), select UHD Graphics
- **Drivers**: Level Zero 1.16+, OpenCL runtime
- **RAM**: 16GB+ (32GB+ recommended for 13B+ models)
- **OS**: Ubuntu 22.04+, Windows 10/11

---

## 3. Ollama Native (Current Best Practice)

### What It Is
Standard Ollama with CPU inference - simple, fast, reliable.

### Status in This Project
✓ **Primary recommendation**
- Version: 0.13.1
- Setup: Single binary install
- Models: Qwen3-VL 8B, Llama 3.1 8B, GPT-OSS 20B

### Performance (This Hardware)
- **Qwen3-VL 8B**: 5.14 tok/s, 1.88s load
- **Llama 3.1 8B**: 4.50 tok/s, 0.22s load
- **GPT-OSS 20B**: 6.67 tok/s, 7.07s load

### Why It's Best
1. **Simplest setup**: Single command install
2. **Proven performance**: Matches or beats GPU on Iris Xe
3. **Ultra-fast load times**: 0.22s vs 5-15s for GPU
4. **No driver complexity**: Just works
5. **Extensive model library**: `ollama pull` for 1000+ models

### Installation
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull llama3.1:8b-instruct-q4_0
ollama run llama3.1:8b "Test prompt"
```

### Documentation
- Official site: https://ollama.com/
- GitHub: https://github.com/ollama/ollama
- Model library: https://ollama.com/library
- Project docs: See `CLAUDE.md`

---

## Driver Stack Comparison

All three methods use the **same underlying Intel GPU drivers**:

```
┌─────────────────────────────────┐
│   OpenVINO  │  IPEX-LLM │ Ollama│  ← Application Layer
├─────────────────────────────────┤
│      Intel oneAPI Toolkit       │  ← Abstraction Layer (SYCL, DPC++)
├─────────────────────────────────┤
│   Level Zero  │  OpenCL Runtime │  ← GPU Interface
├─────────────────────────────────┤
│     Intel GPU Kernel Driver     │  ← Kernel Space
├─────────────────────────────────┤
│   Intel Iris Xe / Arc Hardware  │  ← Hardware
└─────────────────────────────────┘
```

**Implication**: If GPU doesn't help with OpenVINO, it likely won't help with IPEX-LLM (same drivers, same memory bottleneck).

---

## Quick Decision Guide

### When to Use OpenVINO
- ✓ You want **maximum speed for Mistral 7B** (9.5 tok/s)
- ✓ You need **model conversion** from HuggingFace
- ✓ You're comfortable with **Python environments**
- ✓ You want to **experiment with quantization** (int4, int8)

### When to Use IPEX-LLM
- ✓ You have a **discrete Arc GPU** (A770, A750, A380)
- ✓ You need **production inference server** with GPU scaling
- ✓ Setup complexity is acceptable for **2-3x speedup**
- ✗ **NOT recommended for Iris Xe integrated graphics**

### When to Use Ollama Native (Recommended)
- ✓ You want **simplicity** (5 minutes to first inference)
- ✓ You want **fast model switching** (0.22s load times)
- ✓ You want **competitive performance** (4.5-6.67 tok/s for 8-20B models)
- ✓ You value **reliability** over marginal speed gains
- ✓ You have **integrated GPU** (Iris Xe, UHD Graphics)

---

## Hardware-Specific Recommendations

### Intel Core i7-1185G7 + Iris Xe (This System)
**Recommendation**: **Ollama CPU**
- Proven: 4.50 tok/s for Llama 3.1 8B
- GPU provides no benefit (tested with OpenVINO)
- Ultra-fast load times (0.22s)

### Intel Core i5-12600K + Arc A750 (Hypothetical)
**Recommendation**: **IPEX-LLM + Ollama** or **OpenVINO**
- Discrete GPU changes the equation (dedicated VRAM, high bandwidth)
- Expected: 2-3x speedup over CPU
- Worth setup complexity

### Intel Core i9-13900K (CPU-only)
**Recommendation**: **Ollama CPU**
- 24 cores provide excellent CPU inference
- No GPU needed for strong performance
- Keep it simple

---

## Performance Expectations by Hardware

### Integrated GPU (Iris Xe, UHD Graphics)
| Model Size | CPU (Ollama) | GPU (IPEX/OpenVINO) | Recommendation |
|-----------|--------------|---------------------|----------------|
| 1B | 25+ tok/s | ~25 tok/s | CPU (no benefit) |
| 7-8B | 4-6 tok/s | 3-5 tok/s | CPU (no benefit) |
| 13B | 2-3 tok/s | 2-3 tok/s | CPU (no benefit) |
| 20B (MoE) | 5-7 tok/s | Untested | CPU (proven) |

### Discrete GPU (Arc A770)
| Model Size | CPU (Ollama) | GPU (IPEX-LLM) | Recommendation |
|-----------|--------------|----------------|----------------|
| 1B | 25+ tok/s | 50+ tok/s | GPU (2x speedup) |
| 7-8B | 4-6 tok/s | 10-15 tok/s | GPU (2-3x speedup) |
| 13B | 2-3 tok/s | 6-8 tok/s | GPU (3x speedup) |
| 20B+ | 1-2 tok/s | 3-5 tok/s | GPU (2-3x speedup) |

**Note**: Arc A770 has 16GB VRAM, 560 GB/s bandwidth - fundamentally different than shared RAM.

---

## Troubleshooting Common Issues

### GPU Not Detected
```bash
# Check GPU device
lspci | grep -i vga
ls -la /dev/dri/

# Verify permissions
groups | grep render  # Must be in render group
sudo usermod -aG render $USER  # If missing, then logout/login

# Test OpenCL
clinfo -l
```

### oneAPI Not Found
```bash
# Search for setvars.sh
find /opt/intel -name "setvars.sh" 2>/dev/null

# Install if missing
# Download from: https://www.intel.com/content/www/us/en/developer/tools/oneapi/base-toolkit-download.html
```

### Slow GPU Performance
```bash
# Toggle immediate command lists
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1  # Try with
unset SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS     # and without

# Verify GPU is actually being used
export ONEAPI_DEVICE_SELECTOR=level_zero:0  # Force GPU 0
```

### Memory Errors
```bash
# Reduce context size for large models
ollama run llama3.1:8b --context-length 2048  # Default is 4096

# Check available RAM
free -h
```

---

## Additional Resources

### Intel Documentation
- oneAPI Toolkit: https://www.intel.com/content/www/us/en/developer/tools/oneapi/overview.html
- OpenVINO Docs: https://docs.openvino.ai/
- IPEX Documentation: https://intel.github.io/intel-extension-for-pytorch/

### Community
- Ollama Discord: https://discord.gg/ollama
- Intel DevCloud (free GPU testing): https://www.intel.com/content/www/us/en/developer/tools/devcloud/overview.html
- r/LocalLLaMA: https://reddit.com/r/LocalLLaMA

### Benchmarking
- LLM Benchmarks: https://huggingface.co/spaces/HuggingFaceH4/open_llm_leaderboard
- Hardware comparisons: https://www.reddit.com/r/LocalLLaMA/wiki/index

---

## Summary Table

| Aspect | OpenVINO | IPEX-LLM | Ollama Native |
|--------|----------|----------|---------------|
| **Setup Time** | 30 min | 1-2 hours | 5 min |
| **Complexity** | Medium | High | Low |
| **GPU Support** | ✓ Yes | ✓ Yes | ✗ CPU only |
| **Iris Xe Benefit** | ✗ None proven | ✗ None expected | N/A |
| **Arc GPU Benefit** | ✓ Likely 2x | ✓ Likely 2-3x | N/A |
| **Model Library** | Manual convert | Manual convert | ✓ Extensive |
| **Load Times** | 3-15s | 5-15s | 0.2-7s |
| **Best Use Case** | Mistral 7B max speed | Arc GPU production | Everyday use |
| **Status in Project** | ✓ Tested | ✗ Not implemented | ✓ Primary method |

**Recommendation for this hardware**: **Ollama Native** - proven, simple, fast.

---

## Future Considerations

### If Upgrading Hardware
- **Intel Arc A770**: IPEX-LLM or OpenVINO GPU becomes worthwhile (2-3x speedup)
- **More RAM (64GB+)**: Can run larger models (30B+) comfortably on CPU
- **AMD/NVIDIA GPU**: Different ecosystem (ROCm/CUDA) - Ollama supports natively

### Emerging Technologies
- **Intel Gaudi 3**: Data center AI accelerators (not consumer hardware)
- **Lunar Lake iGPU**: Next-gen integrated graphics with improved AI performance
- **OpenVINO Model Zoo**: Pre-optimized models may improve integrated GPU performance

### Monitoring Intel Updates
- Watch: https://github.com/intel/ipex-llm for Ollama integration improvements
- Watch: https://github.com/ollama/ollama for native Intel GPU support
- Subscribe: Intel AI Builders newsletter for toolkit updates

---

**Last Updated**: 2025-12-04
**Hardware Tested**: Intel Core i7-1185G7 + Iris Xe Graphics
**Primary Recommendation**: Ollama Native CPU (4.5-6.67 tok/s, simple, reliable)
