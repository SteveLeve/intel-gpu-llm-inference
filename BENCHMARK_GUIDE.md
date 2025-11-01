# Performance Benchmarking Guide

Complete guide for comparing Intel GPU (OpenVINO) vs CPU (llama.cpp) inference performance.

## 🎯 Quick Comparison Workflow

### 1. Setup Both Backends

```bash
# Setup Intel GPU (OpenVINO)
./setup-intel-gpu-llm.sh

# Setup CPU inference (llama.cpp)
./setup-llama-cpp.sh
```

### 2. Prepare Models

You need the **same model in two formats**:
- **OpenVINO IR** format for GPU inference
- **GGUF** format for llama.cpp CPU inference

#### Option A: Start with HuggingFace Model

```bash
# Activate OpenVINO environment
source activate-intel-gpu.sh

# Convert to OpenVINO IR (for GPU)
optimum-cli export openvino \
  --model microsoft/Phi-3-mini-4k-instruct \
  phi3_mini_ir \
  --weight-format int4

# Convert to GGUF (for CPU)
./llama-convert microsoft/Phi-3-mini-4k-instruct \
  --outtype q4_0 \
  --outfile models/phi3-mini-q4.gguf
```

#### Option B: Download Pre-converted Models

```bash
# OpenVINO IR models (convert yourself as above)

# GGUF models from HuggingFace
cd models
wget https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf
# Or use huggingface-cli:
# huggingface-cli download microsoft/Phi-3-mini-4k-instruct-gguf Phi-3-mini-4k-instruct-q4.gguf --local-dir .
```

### 3. Run Benchmark Comparison

```bash
source activate-intel-gpu.sh

./benchmark.py \
  --openvino-model phi3_mini_ir \
  --llama-model models/phi3-mini-q4.gguf \
  --prompt "Explain quantum computing in simple terms" \
  --max-tokens 100
```

## 📊 Understanding Benchmark Output

### Sample Output

```
==================================================================
Backend: OPENVINO_GPU
Model: phi3_mini_ir
==================================================================
Load Time:            2.34s
Inference Time:       8.52s
Total Time:          10.86s
Tokens/Second:       11.7
Output Tokens:        100
==================================================================

==================================================================
Backend: LLAMA_CPP
Model: phi3-mini-q4
==================================================================
Load Time:            1.12s
Inference Time:      15.23s
Total Time:          16.35s
Tokens/Second:        6.6
Output Tokens:        100
==================================================================

==================================================================
PERFORMANCE COMPARISON
==================================================================

Backend              Load (s)     Inference (s)   Tokens/s     Total (s)    
----------------------------------------------------------------------
openvino_gpu         2.34         8.52            11.7         10.86        
llama_cpp            1.12         15.23           6.6          16.35        

==================================================================
SPEEDUP ANALYSIS
==================================================================
Throughput: openvino_gpu is 1.77x compared to llama_cpp
Time saved: 33.6% faster
```

### Key Metrics

- **Load Time**: Time to load model into memory
- **Inference Time**: Actual generation time
- **Tokens/Second**: Generation speed (higher is better)
- **Speedup**: How much faster GPU is vs CPU

## 🔬 Advanced Benchmarking

### Test Multiple Prompts

```bash
# Short prompt
./benchmark.py -o phi3_mini_ir -l models/phi3-mini-q4.gguf \
  -p "What is AI?" -t 50

# Medium prompt  
./benchmark.py -o phi3_mini_ir -l models/phi3-mini-q4.gguf \
  -p "Write a detailed explanation of machine learning" -t 200

# Long generation
./benchmark.py -o phi3_mini_ir -l models/phi3-mini-q4.gguf \
  -p "Write a comprehensive essay on artificial intelligence" -t 500
```

### Compare Multiple Backends

```bash
# GPU vs CPU vs CPU-optimized
./benchmark.py --compare \
  --openvino-model phi3_mini_ir \
  --llama-model models/phi3-mini-q4.gguf
  
# This tests:
# 1. OpenVINO GPU
# 2. OpenVINO CPU (for reference)
# 3. llama.cpp CPU
```

### Run Multiple Iterations

```bash
# Average over 5 runs for more accurate results
./benchmark.py \
  --openvino-model phi3_mini_ir \
  --llama-model models/phi3-mini-q4.gguf \
  --runs 5 \
  --output benchmark_results.json
```

### Save Results for Analysis

```bash
# Benchmark and save to JSON
./benchmark.py \
  --openvino-model mistral_7b_ir \
  --llama-model models/mistral-7b-q4.gguf \
  --output results/mistral_benchmark_$(date +%Y%m%d_%H%M%S).json
```

## 📈 Expected Performance

### Typical Results (Intel Iris Xe)

| Model | Backend | Tokens/sec | Speedup vs CPU |
|-------|---------|------------|----------------|
| Phi-3 Mini (3.8B) | OpenVINO GPU | 10-15 | 1.5-2.0x |
| Phi-3 Mini (3.8B) | llama.cpp CPU | 6-8 | baseline |
| Mistral 7B | OpenVINO GPU | 5-8 | 1.3-1.8x |
| Mistral 7B | llama.cpp CPU | 3-5 | baseline |
| Llama 3 8B | OpenVINO GPU | 4-7 | 1.4-1.9x |
| Llama 3 8B | llama.cpp CPU | 2-4 | baseline |

**Notes:**
- Results vary based on:
  - System RAM speed
  - CPU performance
  - GPU thermal state
  - Model quantization level
  - Context length

## 🎨 Recommended Test Suite

### Quick Test (Phi-3 Mini)
```bash
# Best for initial testing
source activate-intel-gpu.sh
optimum-cli export openvino --model microsoft/Phi-3-mini-4k-instruct phi3_mini_ir --weight-format int4
# Download GGUF from HuggingFace or convert with llama-convert

./benchmark.py -o phi3_mini_ir -l models/phi3-mini-q4.gguf -t 100
```

### Medium Test (Mistral 7B)
```bash
# Good balance of size and performance
optimum-cli export openvino --model mistralai/Mistral-7B-Instruct-v0.2 mistral_7b_ir --weight-format int4
# Get GGUF from HuggingFace

./benchmark.py -o mistral_7b_ir -l models/mistral-7b-q4.gguf -t 150
```

### Comprehensive Test (Llama 3 8B)
```bash
# Largest model, most representative
huggingface-cli login
optimum-cli export openvino --model meta-llama/Meta-Llama-3-8B-Instruct llama3_8b_ir --weight-format int4
# Get GGUF from HuggingFace

./benchmark.py --compare -o llama3_8b_ir -l models/llama3-8b-q4.gguf -t 200 --runs 3
```

## 🐛 Troubleshooting

### GPU Not Faster Than CPU?

1. **Check GPU is being used:**
   ```bash
   # Monitor GPU during inference
   intel_gpu_top
   ```

2. **Thermal throttling:**
   ```bash
   # Check temperatures
   sensors
   ```

3. **Try different quantization:**
   ```bash
   # INT8 instead of INT4
   optimum-cli export openvino --model MODEL_NAME output_dir --weight-format int8
   ```

### llama.cpp Performance Issues?

1. **Use quantized models:**
   - Q4_0 or Q4_K_M for best speed
   - Q8 for better quality but slower

2. **Check CPU utilization:**
   ```bash
   htop  # Should see high CPU usage during inference
   ```

### Model Conversion Fails?

1. **Disk space:**
   ```bash
   df -h  # Need 10-20GB free for large models
   ```

2. **Memory:**
   ```bash
   free -h  # Need at least 16GB for 7B models
   ```

## 📝 Reporting Results

When sharing benchmark results, include:

1. **Hardware:**
   - CPU model: `lscpu | grep "Model name"`
   - GPU model: `lspci | grep VGA`
   - RAM: `free -h`

2. **Software:**
   - OS version: `lsb_release -a`
   - Kernel: `uname -r`
   - OpenVINO version: Check in benchmark output

3. **Test details:**
   - Model name and size
   - Quantization level
   - Prompt and token count
   - Number of runs

4. **Results:**
   - Save JSON output: `--output results.json`
   - Screenshot of comparison table

## 🎯 Best Practices

1. **Warm up:** Run inference once before benchmarking to load drivers
2. **Consistent testing:** Use same prompt and token count for comparison
3. **Multiple runs:** Average 3-5 runs for reliable results
4. **Cool down:** Let GPU cool between runs if testing repeatedly
5. **Close applications:** Minimize background processes during benchmarking

---

For questions or issues, refer to the main [README.md](README.md) or open an issue.
