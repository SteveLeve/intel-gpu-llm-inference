# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Intel GPU LLM inference toolkit that enables local LLM inference on Intel Xe Graphics (Iris Xe, Arc) using OpenVINO GenAI. The project includes setup scripts, benchmarking tools, and performance comparison utilities for running LLMs on Intel integrated GPUs.

**Key Findings** (based on Intel Core i7-1185G7 + Iris Xe testing):
- **GPU provides NO meaningful advantage** over CPU on integrated Intel Iris Xe
- **Framework performance is model-specific:** Mistral 7B favors OpenVINO (1.6x faster), Llama 3.1 8B favors Ollama (1.3x faster)
- **Recommended setup:** Ollama on CPU for simplicity and competitive performance
- **Best all-around model:** Qwen3-VL 8B via Ollama (5.14 tok/s + vision capabilities)
- **Best large model:** GPT-OSS 20B via Ollama (6.67 tok/s, surprisingly faster than 8B models due to sparse MoE)

## Architecture

### Triple Backend System

The project supports three inference backends for performance comparison:

1. **Ollama (CPU)** ⭐ **Recommended**
   - Simplest setup (single binary install)
   - Best performance for 8B models (Llama 3.1, Qwen3-VL)
   - Uses GGUF Q4_0 quantization
   - Ultra-fast model loading (0.22s for Llama 3.1 8B)
   - Extensive model library via `ollama pull`

2. **OpenVINO GenAI (GPU/CPU)**
   - Best for Mistral 7B (1.6x faster than Ollama)
   - Uses OpenVINO IR format (optimized intermediate representation)
   - Supports both GPU and CPU devices
   - Models converted with `optimum-cli` and quantized to int4
   - Complex setup but maximum speed for select models

3. **llama.cpp (CPU)**
   - Baseline for CPU-only performance comparison
   - Uses GGUF model format
   - Built as git submodule in `llama.cpp/`
   - Compiled wrapper scripts: `llama-run`, `llama-convert`

### Python Environment

All OpenVINO work happens in an isolated virtual environment:
- Location: `openvino_env/` (git-ignored)
- Activation: `source activate-intel-gpu.sh`
- Key packages: `openvino-genai`, `optimum-intel[openvino]`

### Model Storage

- **Ollama models:** Managed by Ollama in `~/.ollama/models/` (automatic)
- **OpenVINO IR models:** `*_ir/` directories (git-ignored, ~15GB per 8B model)
- **llama.cpp GGUF models:** `models/` directory (git-ignored)
- **HuggingFace cache:** `~/.cache/huggingface/hub/` (used during OpenVINO conversion)

## Common Commands

### Initial Setup

```bash
# RECOMMENDED: Install Ollama (simplest, best for 8B models)
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen3-vl:8b-instruct      # Best all-around model
ollama pull llama3.1:8b-instruct-q4_0 # Best tool calling
ollama pull mistral:7b-instruct-q4_0  # Speed fallback

# OPTIONAL: Setup OpenVINO + Intel GPU drivers (for maximum Mistral 7B speed)
./setup-intel-gpu-llm.sh

# OPTIONAL: Setup llama.cpp for CPU comparison
./setup-llama-cpp.sh

# If OpenVINO added you to render group, log out and back in, then:
source activate-intel-gpu.sh
```

### Model Conversion

```bash
# Must activate environment first
source activate-intel-gpu.sh

# Convert from HuggingFace to OpenVINO IR (for GPU)
optimum-cli export openvino \
  --model microsoft/Phi-3-mini-4k-instruct \
  phi3_mini_ir \
  --weight-format int4

# Convert to GGUF (for CPU comparison)
./llama-convert microsoft/Phi-3-mini-4k-instruct \
  --outtype q4_0 \
  --outfile models/phi3-mini-q4.gguf
```

### Testing

```bash
# OLLAMA (Recommended - Simple & Fast)
ollama run qwen3-vl:8b-instruct "Your prompt"
ollama run llama3.1:8b-instruct-q4_0 "Your prompt"
time ollama run mistral:7b-instruct-q4_0 "Your prompt" --verbose  # With timing

# OPENVINO (For benchmarking)
source activate-intel-gpu.sh
python test-inference.py --model phi3 --prompt "Your prompt"
python test-inference.py --model mistral --stream --prompt "Write a story"
python test-inference.py --model llama31 --device GPU --prompt "Test"
python test-inference.py --model llama31 --device CPU --prompt "Test"

# Interactive model testing menu
./test-models.sh
```

### Benchmarking

```bash
# Compare GPU vs CPU performance
./benchmark.py \
  --openvino-model phi3_mini_ir \
  --llama-model models/phi3-mini-q4.gguf \
  --prompt "Explain quantum computing" \
  --max-tokens 100

# GPU-only benchmark
./benchmark.py --openvino-model phi3_mini_ir --gpu-only

# Full comparison with results saved to JSON
./benchmark.py --compare \
  --openvino-model mistral_7b_ir \
  --llama-model models/mistral-7b-q4.gguf \
  --output results.json
```

### Diagnostics

```bash
# Check GPU detection
lspci | grep -i vga
ls -la /dev/dri/

# Verify user permissions
groups | grep render

# Check OpenCL availability
clinfo -l

# Monitor GPU usage
intel_gpu_top  # (requires: sudo apt install intel-gpu-tools)
```

## Code Structure

### Main Scripts

- `test-inference.py` - Single model testing with OpenVINO
  - Supports: Phi-3 Mini (3.8B), Mistral 7B, Llama 3 8B, Llama 3.1 8B, Qwen2-VL 7B
  - Auto-downloads and converts models on first run
  - See `MODELS` dict at line 21 for model configurations
  - Note: Llama 3.1 requires HuggingFace authentication (`huggingface-cli login`)

- `benchmark.py` - Performance comparison framework
  - `OpenVINOBenchmark` class (line 46): GPU/CPU inference
  - `LlamaCppBenchmark` class (line 84): CPU baseline
  - `BenchmarkResult` dataclass (line 27): Standard metrics
  - Outputs: tokens/sec, latency, load times

- `setup-intel-gpu-llm.sh` - OpenVINO + driver installation
  - Checks Intel GPU presence (line 29)
  - Adds Intel GPU apt repository (line 66)
  - Installs: intel-opencl-icd, intel-level-zero-gpu
  - Creates Python venv and installs packages
  - Generates `activate-intel-gpu.sh` helper

- `setup-llama-cpp.sh` - Builds llama.cpp from submodule
  - Updates git submodule
  - Runs cmake build with CPU optimizations
  - Creates wrapper scripts in project root

### Important Files

- `.gitmodules` - llama.cpp submodule reference
- `activate-intel-gpu.sh` - Auto-generated venv activation helper
- `quickstart-example.sh` - End-to-end demo script

## Development Workflow

### Adding New Model Support

1. Add model config to `test-inference.py` in `MODELS` dict (line 21)
2. Specify: HuggingFace ID, output directory, description
3. Test conversion: `python test-inference.py --model <key> --convert-only`
4. Run inference: `python test-inference.py --model <key> --prompt "Test"`
5. Document results in markdown file

### Running Performance Tests

1. Convert model to both formats (OpenVINO IR + GGUF)
2. Run benchmark with consistent prompt and token count
3. Document hardware: `lspci | grep -i vga`, `uname -r`
4. Record results in `*_PERFORMANCE_RESULTS.md`
5. Update `PERFORMANCE_COMPARISON_SUMMARY.md`

### Model Quantization

OpenVINO models use `--weight-format int4` by default for better performance on integrated GPUs. llama.cpp uses Q4_0 quantization for fair comparison.

## Key Requirements

- **Hardware**: Intel Xe Graphics (TigerLake/Alderlake+)
- **OS**: Ubuntu 22.04+ or compatible Debian-based distros
- **User Permissions**: Must be in `render` group for GPU access
- **Python**: 3.8+ (for OpenVINO GenAI)
- **Git Submodules**: Must initialize with `git submodule update --init --recursive`

## Troubleshooting

### GPU Not Detected
- Verify `/dev/dri/renderD128` exists
- Check `groups` includes `render` (may need logout/login)
- Run `clinfo -l` to verify OpenCL runtime

### OpenVINO Import Errors
- Ensure venv is activated: `source activate-intel-gpu.sh`
- Reinstall: `pip install --force-reinstall openvino-genai`

### llama.cpp Build Issues
- Ensure submodule is initialized: `git submodule update --init --recursive`
- Re-run: `./setup-llama-cpp.sh`
- Check `llama.cpp/build/bin/llama-cli` exists

## Performance Expectations

Based on comprehensive testing with Intel Core i7-1185G7 + Iris Xe Graphics:

### Complete Performance Matrix (12 configurations tested)

| Model | Framework | Device | Speed | Load Time | Recommendation |
|-------|-----------|--------|-------|-----------|----------------|
| **GPT-OSS 20B** | **Ollama** | **CPU** | **6.67 tok/s** | 7.07s | **Best large model** 💎 |
| **Qwen3-VL 8B** | **Ollama** | **CPU** | **5.14 tok/s** | 1.88s | **Best all-around** 🏆 |
| **Llama 3.1 8B** | **Ollama** | **CPU** | **4.50 tok/s** | 0.22s | **Best tool calling** ⭐ |
| Llama 3.1 8B | OpenVINO | GPU | 4.3 tok/s | 15.4s | Not recommended |
| Llama 3.1 8B | OpenVINO | CPU | 3.4 tok/s | 6.1s | Not recommended |
| **Mistral 7B** | **OpenVINO** | **CPU** | **9.5 tok/s** | 3.5s | **Max speed (7B)** ⚡ |
| Mistral 7B | OpenVINO | GPU | 9.4 tok/s | 10.4s | Tied with CPU |
| Mistral 7B | Ollama | CPU | 5.86 tok/s | ~3s | Good alternative |
| Phi-3 Mini 3.8B | OpenVINO | GPU/CPU | 10.5 tok/s | 2.9-10.3s | Development |
| TinyLlama 1.1B | OpenVINO | CPU | 27.4 tok/s | 0.8s | Testing only |

### Key Insights

1. **GPU provides NO meaningful advantage** on Intel Iris Xe integrated graphics
   - CPU equals or beats GPU for all models tested
   - GPU has significantly longer load times (10-15s vs 0.2-6s)

2. **Framework performance is model-specific:**
   - **Mistral 7B:** OpenVINO wins (9.5 tok/s vs 5.86 tok/s Ollama, 1.6x faster)
   - **Llama 3.1 8B:** Ollama wins (4.50 tok/s vs 3.4-4.3 tok/s OpenVINO, 1.3x faster)
   - Different models are optimized differently for each framework

3. **Large models can be surprisingly fast:**
   - **GPT-OSS 20B:** Faster than 8B models (6.67 tok/s) due to sparse MoE architecture
   - Only 3.6B active parameters per inference (out of 21B total)
   - MXFP4 quantization enables efficient inference
   - **Note:** OpenVINO conversion requires 64GB+ RAM (not feasible on 30GB system)

4. **Recommended setup for this hardware:**
   - **Large model/reasoning:** GPT-OSS 20B via Ollama (6.67 tok/s, excellent reasoning)
   - **Primary:** Qwen3-VL 8B via Ollama (vision + text, fast, simple)
   - **Tool calling:** Llama 3.1 8B via Ollama (best-in-class function calling)
   - **Maximum speed:** Mistral 7B via OpenVINO CPU (if setup complexity acceptable)

5. **Avoid:**
   - GPU inference (no benefit, longer load times)
   - Dense 14B+ models (memory pressure, expect 3-3.5 tok/s)

📊 **Full analysis:** See `COMPREHENSIVE_PERFORMANCE_COMPARISON.md` for detailed results and methodology.
