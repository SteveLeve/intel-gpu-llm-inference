# Quick Performance Reference

> **TL;DR**: On Intel i7-1185G7 + Iris Xe, CPU equals or beats GPU for models ≤ 4B parameters.

## Test Results at a Glance

| Model | GPU | CPU | Winner |
|-------|-----|-----|--------|
| TinyLlama 1.1B | 19.6 tok/s | 27.4 tok/s | **CPU 1.4x** ⚡ |
| Phi-3 Mini 3.8B | 10.5 tok/s | 10.5 tok/s | **Tie** 🤝 |

## When to Use What

### Use CPU 💻
- Models ≤ 4B params
- Interactive queries
- Fast model loading needed
- Development/testing

### Use GPU 🎮
- Models 7B+ params
- Batch inference
- Production consistency
- CPU busy with other tasks

## Quick Commands

```bash
# Test GPU
source activate-intel-gpu.sh
python3 -c "import openvino_genai as ov_genai; pipe = ov_genai.LLMPipeline('phi3_mini_ir', 'GPU'); print(pipe.generate('Hello', max_new_tokens=50))"

# Test CPU  
python3 -c "import openvino_genai as ov_genai; pipe = ov_genai.LLMPipeline('phi3_mini_ir', 'CPU'); print(pipe.generate('Hello', max_new_tokens=50))"
```

## Full Reports

- **PERFORMANCE_TEST_RESULTS.md** - TinyLlama detailed results
- **PHI3_PERFORMANCE_RESULTS.md** - Phi-3 Mini detailed results  
- **PERFORMANCE_COMPARISON_SUMMARY.md** - Complete analysis

---
*Tested on Intel Core i7-1185G7 + Iris Xe, November 2024*
