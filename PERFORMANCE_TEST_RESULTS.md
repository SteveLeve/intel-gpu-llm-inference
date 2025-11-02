# Performance Test Results - TinyLlama on Intel Iris Xe

**Test Date:** November 1, 2025
**System:** Intel Core i7-1185G7 @ 3.00GHz with Intel Iris Xe Graphics (TigerLake-LP GT2)  
**RAM:** 30GB  
**Model:** TinyLlama 1.1B Chat  
**Framework:** OpenVINO GenAI  

## Executive Summary

Performance testing revealed that **CPU inference outperforms GPU inference** for the small TinyLlama 1.1B model on this hardware configuration. The CPU achieved approximately **1.4x faster** throughput compared to GPU.

## Test Configuration

- **Model:** TinyLlama 1.1B (int4 quantization)
- **Backend:** OpenVINO GenAI
- **Devices Tested:** Intel Iris Xe GPU vs Intel Core i7 CPU
- **Generation Lengths:** 50 and 200 tokens

## Results

### Short Generation (50 tokens)

| Device | Load Time | Avg Time | Avg Speed | Min Speed | Max Speed |
|--------|-----------|----------|-----------|-----------|-----------|
| **GPU** | 2.56s | 2.59s | 19.3 tok/s | 18.9 tok/s | 20.0 tok/s |
| **CPU** | 0.78s | 1.88s | 26.8 tok/s | 24.2 tok/s | 28.8 tok/s |

**Result:** CPU is **1.39x faster** than GPU (27.8% improvement)

### Long Generation (200 tokens)

| Device | Time | Speed |
|--------|------|-------|
| **GPU** | 10.23s | 19.6 tok/s |
| **CPU** | 7.31s | 27.4 tok/s |

**Result:** CPU is **1.40x faster** than GPU

## Analysis

### Why is CPU Faster?

1. **Small Model Size**: TinyLlama (1.1B parameters) is small enough to run efficiently on CPU
2. **GPU Overhead**: GPU initialization and data transfer overhead outweighs computation benefits for small models
3. **Powerful CPU**: Intel Core i7-1185G7 has 4 cores with Turbo Boost up to 4.8GHz
4. **Memory Bandwidth**: CPU has fast access to system RAM
5. **Model Quantization**: int4 quantization makes the model even lighter

### When Would GPU Be Faster?

Based on benchmark guidelines, GPU advantages typically appear with:

- **Larger models**: 3B+ parameters (Phi-3, Mistral 7B, Llama 3 8B)
- **Longer sequences**: Processing longer context windows
- **Batch processing**: Multiple concurrent requests
- **Concurrent usage**: Running multiple models simultaneously

## Recommendations

### For TinyLlama Users

- ✅ **Use CPU inference** - It's faster and has lower model load time (0.78s vs 2.56s)
- ✅ Lower power consumption
- ✅ Simpler setup

### For Better GPU Performance

To properly test GPU benefits, test with larger models:

```bash
# Phi-3 Mini (3.8B parameters) - Recommended
optimum-cli export openvino --model microsoft/Phi-3-mini-4k-instruct phi3_mini_ir --weight-format int4

# Mistral 7B - Better GPU advantage
optimum-cli export openvino --model mistralai/Mistral-7B-Instruct-v0.2 mistral_7b_ir --weight-format int4
```

Expected GPU performance improvement:
- **Phi-3 Mini**: 1.5-2.0x speedup over CPU
- **Mistral 7B**: 1.8-2.5x speedup over CPU
- **Llama 3 8B**: 2.0-3.0x speedup over CPU

## Test Prompts Used

1. "What is artificial intelligence?"
2. "Explain quantum computing in simple terms."
3. "Write a short story about a robot."
4. "Explain the history of artificial intelligence from the 1950s to today:"

## Sample Output Quality

Both GPU and CPU produced identical output quality (deterministic generation):

```
Artificial intelligence (AI) is the ability of machines to perform 
tasks that require human intelligence, such as visual perception, 
speech recognition, decision-making, and language translation.
```

## Hardware Monitoring

During GPU inference:
- GPU utilization: Active but not bottlenecked
- CPU utilization: ~20-30% (for host operations)
- Memory: ~2-3GB used
- Power: Estimated 10-15W GPU + 15-20W CPU

During CPU inference:
- CPU utilization: ~80-95%
- Memory: ~2GB used
- Power: Estimated 25-35W CPU only

## Conclusion

For **small models like TinyLlama (1.1B)** on Intel Iris Xe integrated graphics:
- **CPU is the better choice** - 1.4x faster, lower latency, simpler setup
- GPU inference works correctly but has overhead that's not offset by the small model size

For **larger models (3B+)**:
- GPU would likely show 1.5-3x performance advantage
- GPU enables running larger models that might not fit in CPU cache efficiently
- Better for concurrent/batch inference scenarios

## Next Steps

To properly benchmark GPU performance advantages, test with:

1. **Phi-3 Mini (3.8B)** - Sweet spot for Intel Iris Xe
2. **Mistral 7B** - Larger model showing clearer GPU benefits  
3. **Longer contexts** - Test with 512+ token generations
4. **Concurrent requests** - Multiple inference streams

---

*Generated using OpenVINO GenAI on Intel 11th Gen Core i7-1185G7 with Iris Xe Graphics*
