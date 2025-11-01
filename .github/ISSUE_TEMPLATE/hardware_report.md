---
name: Hardware Test Report
about: Share performance results from your Intel GPU
title: '[HARDWARE] '
labels: hardware, performance
assignees: ''
---

## 🖥️ Hardware Configuration

- **GPU Model**: [e.g., Intel Iris Xe Graphics, Intel Arc A770]
- **GPU Generation**: [e.g., Tiger Lake, Alder Lake, DG2]
- **CPU**: [e.g., Intel Core i7-1185G7]
- **RAM**: [e.g., 16GB LPDDR4x]
- **Laptop/Desktop Model**: [e.g., Dell XPS 13 9310, Custom Desktop]
- **OS**: [e.g., Ubuntu 22.04.3 LTS]
- **Kernel Version**: [output of `uname -r`]

## 📊 Performance Results

### Model Tested

- **Model Name**: [e.g., Phi-3 Mini 4K Instruct]
- **Model Size**: [e.g., 3.8B parameters]
- **Quantization**: [e.g., INT4]

### Benchmark Results

**OpenVINO (Intel GPU)**:
- Tokens/second: 
- First token latency: 
- Average token latency: 

**llama.cpp (CPU)**:
- Tokens/second: 
- First token latency: 
- Average token latency: 

**Performance Gain**: [e.g., 2.3x faster on GPU]

### Benchmark Command

```bash
./benchmark.py --openvino-model ... --llama-model ...
```

## ✅ Setup Status

- [ ] Setup completed successfully
- [ ] GPU detected properly
- [ ] OpenVINO inference working
- [ ] llama.cpp comparison working
- [ ] No thermal throttling during tests

## 📝 Additional Notes

Any observations, issues, or recommendations for others with similar hardware:

- Driver versions used:
- Special configuration needed:
- Stability notes:
