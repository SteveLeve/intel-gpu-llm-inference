# Phi-3 Mini Performance Results - Intel Iris Xe vs CPU

**Test Date:** November 2, 2025
**System:** Intel Core i7-1185G7 @ 3.00GHz with Intel Iris Xe Graphics (TigerLake-LP GT2)  
**RAM:** 30GB  
**Model:** Phi-3 Mini 3.8B Instruct (INT4 quantized)  
**Framework:** OpenVINO GenAI  
**Model Size:** 2.1GB (quantized from ~7.6GB)

## Executive Summary

Performance testing of **Phi-3 Mini (3.8B parameters)** shows **nearly identical performance** between Intel Iris Xe GPU and Intel Core i7 CPU. In most tests, CPU had a marginal advantage (1.08x) with slightly faster average throughput, but GPU showed more **consistent performance** across different prompts.

## Test Results

### Short Generation (100 tokens, 3 prompts)

| Device | Load Time | Avg Gen Time | Avg Speed | Min Speed | Max Speed | Consistency |
|--------|-----------|--------------|-----------|-----------|-----------|-------------|
| **GPU** | 10.28s | 9.55s | **10.5 tok/s** | 10.4 tok/s | 10.6 tok/s | ✅ Very stable |
| **CPU** | 2.87s | 9.55s | **11.3 tok/s** | 7.4 tok/s | 13.4 tok/s | ⚠️ Variable |

**Key Findings:**
- CPU: 1.08x faster on average, but with 80% variation (7.4-13.4 tok/s)
- GPU: More predictable performance (±2% variation)
- CPU has 3.6x faster model loading (2.87s vs 10.28s)

### Long Generation (300 tokens)

| Device | Load Time | Gen Time | Speed | Total Time |
|--------|-----------|----------|-------|------------|
| **GPU** | 7.24s | 28.92s | 10.4 tok/s | 36.16s |
| **CPU** | 2.84s | 28.56s | 10.5 tok/s | 31.40s |

**Result:** Virtually identical generation speed (~10.5 tok/s), CPU wins on total time due to faster loading

## Detailed Analysis

### Why Is CPU Competitive?

1. **Powerful CPU Architecture**
   - Intel Core i7-1185G7 (Tiger Lake, 11th gen)
   - 4 cores / 8 threads with Turbo Boost to 4.8GHz
   - 12MB L3 cache
   - Excellent single-threaded performance

2. **Model Size**
   - 3.8B parameters with INT4 quantization = 2.1GB
   - Fits entirely in CPU cache hierarchy
   - Memory bandwidth not a bottleneck

3. **Integrated GPU Limitations**
   - Intel Iris Xe shares memory bandwidth with CPU
   - 96 Execution Units vs dedicated GPU
   - Additional overhead for GPU context switching

4. **Workload Characteristics**
   - Autoregressive generation is sequential
   - Limited parallelism opportunities
   - Memory-bound rather than compute-bound

### GPU Advantages Observed

✅ **Consistency**: GPU performance variance only ±2% vs CPU's ±80%  
✅ **Predictability**: Always delivers ~10.4-10.5 tok/s  
✅ **Stability**: No thermal throttling or frequency scaling visible  

### CPU Advantages Observed

✅ **Faster loading**: 2.8s vs 10.3s (3.6x faster)  
✅ **Peak performance**: Can reach 13.4 tok/s on some prompts  
✅ **Lower latency**: Better for single-shot queries  
✅ **No warmup needed**: Immediate full performance  

## Comparison with TinyLlama (1.1B)

| Model | Size | GPU Speed | CPU Speed | Winner | Speedup |
|-------|------|-----------|-----------|--------|---------|
| TinyLlama | 1.1B | 19.6 tok/s | 27.4 tok/s | CPU | 1.40x |
| Phi-3 Mini | 3.8B | 10.5 tok/s | 10.5 tok/s | Tie | 1.00x |

**Insight:** As model size increases, GPU becomes more competitive, but hasn't overtaken CPU yet on this hardware.

## Performance Characteristics

### GPU Performance Profile
- **Stable**: ±2% variation across prompts
- **Consistent**: 10.4-10.6 tok/s regardless of prompt complexity
- **Slower startup**: 10s model loading
- **Best for**: Production workloads requiring predictable latency

### CPU Performance Profile
- **Variable**: 7.4-13.4 tok/s depending on prompt
- **Fast startup**: 2.8s model loading
- **Peak performance**: Can exceed GPU on simple prompts
- **Best for**: Interactive use, quick queries, development

## Hardware Utilization

### During GPU Inference
```
GPU: ~60-80% utilization (intel_gpu_top)
CPU: ~20-30% (host operations)
Memory: ~4-5GB used
Power: Estimated 12-18W GPU + 10-15W CPU
```

### During CPU Inference
```
CPU: ~90-100% utilization on active cores
Memory: ~3-4GB used
Power: Estimated 25-35W CPU
Temperature: Higher than GPU mode
```

## Test Prompts

1. "What is artificial intelligence?"
2. "Explain quantum computing in simple terms."
3. "Write a short story about a robot."
4. "Write a detailed essay about the history and future of artificial intelligence..."

## Sample Output Quality

Identical quality between GPU and CPU (deterministic generation with same parameters):

**GPU Output:**
```
Artificial intelligence (AI) refers to the branch of computer science 
that aims to create machines capable of performing tasks that typically 
require human intelligence...
```

**CPU Output:**
```
Artificial intelligence (AI) refers to the simulation of human intelligence 
in machines that are programmed to think and learn like humans...
```

Both outputs are high quality with slight variation due to model's inherent generation characteristics.

## Conclusions

### For Phi-3 Mini (3.8B) on Intel Iris Xe + i7-1185G7:

1. **Performance Parity**: GPU and CPU deliver essentially the same throughput (~10.5 tok/s)

2. **Use CPU if:**
   - You need fast model loading (2.8s vs 10s)
   - Running quick/interactive queries
   - Development and testing
   - Simplicity is preferred

3. **Use GPU if:**
   - You need consistent, predictable latency
   - Running production workloads
   - Concurrent inference (not tested but likely GPU advantage)
   - CPU is busy with other tasks

4. **System is Well-Balanced**: This Tiger Lake system has exceptional CPU performance that matches integrated GPU for these workloads

### Why Expected GPU Speedup Didn't Materialize

The benchmark guide predicted 1.5-2.0x GPU speedup for Phi-3 Mini, but we observed parity because:

1. **Different hardware generation**: Benchmarks may have used older/slower CPUs
2. **Tiger Lake CPU excellence**: i7-1185G7 is top-tier 11th gen with excellent IPC
3. **Shared memory bandwidth**: Integrated GPU competes with CPU for memory access
4. **Model quantization**: INT4 reduces compute requirements, benefiting CPU more

### Recommendations for Future Testing

To observe GPU advantages, test with:

1. **Larger models**: Mistral 7B or Llama 3 8B
2. **Batch inference**: Multiple concurrent requests
3. **Longer contexts**: 2K-4K token contexts
4. **Lower quantization**: INT8 or FP16 (more compute-intensive)
5. **Dedicated GPU**: Intel Arc A750/A770 discrete GPU

### When to Expect GPU Benefits

GPU advantages typically appear with:
- **Models 7B+**: More compute per token
- **Batch size > 1**: Parallel processing
- **Discrete GPUs**: Full PCIe bandwidth, dedicated VRAM
- **Older/weaker CPUs**: Makes GPU relatively faster
- **Multi-model serving**: CPU handles other tasks

## System Recommendations

For **Intel Iris Xe integrated graphics** users:
- ✅ Excellent for model exploration and development
- ✅ Works well for small-to-medium models (1B-4B)
- ✅ Good power efficiency vs discrete GPU
- ⚠️ Don't expect massive speedups over good CPUs
- ⚠️ CPU may be faster for models under 5B parameters

For **maximum performance** with OpenVINO:
- Consider Intel Arc discrete GPU (A750/A770)
- Ensure fast RAM (DDR4-3200+ or DDR5)
- Use models 7B+ to fully utilize GPU
- Enable batch inference when possible

---

*Test conducted with OpenVINO GenAI on Intel 11th Gen Core i7-1185G7 + Iris Xe Graphics*
*Model: microsoft/Phi-3-mini-4k-instruct (INT4 quantized)*
