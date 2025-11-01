# Getting Started with Intel GPU LLM Inference

Welcome! This guide will help you get running in under 15 minutes.

## ✅ Before You Start

### Check Your Hardware

```bash
# Verify you have Intel Xe Graphics
lspci | grep -i vga

# Look for:
# - "Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics]"
# - "Intel Corporation AlderLake-P Integrated Graphics"
# - "Intel Corporation DG2 [Arc A770]"
# - Or similar Intel Xe/Arc GPU
```

### System Requirements

- **OS**: Ubuntu 22.04+ or similar Debian-based Linux
- **Kernel**: 5.15+ (check with `uname -r`)
- **RAM**: 8GB+ recommended
- **Storage**: ~5GB for environment + models

## 🚀 Installation (One Command)

```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/intel-gpu-llm-inference.git
cd intel-gpu-llm-inference
git submodule update --init --recursive
./setup-intel-gpu-llm.sh
```

**Important**: If the script adds you to the `render` group, you must **log out and back in** for GPU access to work.

## 🎯 Run Your First Model (Quickstart)

After setup completes (or after logging back in):

```bash
./quickstart-example.sh
```

This will:
1. Download TinyLlama-1.1B (~600MB)
2. Convert it to OpenVINO IR format
3. Run a test inference on your Intel GPU
4. Show you the response time

**Expected output**: You should see a response generated in 1-3 seconds, proving your GPU is working!

## 📊 Understanding Performance

### CPU vs GPU Comparison

Once quickstart works, try a performance comparison:

```bash
# Setup CPU inference for comparison
./setup-llama-cpp.sh

# Download GGUF model for CPU testing
mkdir -p models
cd models
wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf
cd ..

# Run benchmark
source activate-intel-gpu.sh
./benchmark.py \
  --openvino-model tinyllama_ir \
  --llama-model models/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf \
  --prompt "Write a short story about robots"
```

**What to expect**: On typical Intel Xe integrated GPUs, you should see **2-3x faster** inference compared to CPU-only.

## 🎓 Next Steps

### Try Different Models

```bash
# Activate environment
source activate-intel-gpu.sh

# Download Phi-3 Mini (3.8B parameters, higher quality)
optimum-cli export openvino \
  --model microsoft/Phi-3-mini-4k-instruct \
  phi3_mini_ir \
  --weight-format int4

# Test it
python test-inference.py \
  --model-path phi3_mini_ir \
  --prompt "Explain quantum computing" \
  --stream
```

### Explore the Tools

- **`test-inference.py`**: Test any OpenVINO model with custom prompts
- **`test-models.sh`**: Interactive menu for common models
- **`benchmark.py`**: Detailed performance comparisons
- **`BENCHMARK_GUIDE.md`**: Complete benchmarking workflow

## 🔧 Troubleshooting

### GPU Not Detected

```bash
# Check device files (should see renderD128 or similar)
ls -la /dev/dri/

# Verify you're in render group
groups | grep render

# If not, add yourself and log out/in
sudo usermod -aG render $USER
```

### "No GPU found" Error

```bash
# Check OpenCL detection
clinfo -l

# Should show Intel GPU. If not, reinstall drivers:
sudo apt update
sudo apt install --reinstall intel-opencl-icd intel-level-zero-gpu
```

### Slow Performance

- **First run is slower**: Model compilation happens on first inference
- **Check thermal throttling**: Use `intel_gpu_top` to monitor
- **Try smaller models**: Start with TinyLlama before trying 7B+ models
- **Reduce max_tokens**: Use `--max-tokens 50` for testing

### Import Errors

```bash
# Make sure environment is activated
source activate-intel-gpu.sh

# Verify installation
python -c "import openvino_genai; print('OK')"

# If fails, reinstall
pip install --force-reinstall openvino-genai
```

## 📚 Learn More

- **README.md**: Full feature documentation
- **BENCHMARK_GUIDE.md**: Performance testing methodology
- **CONTRIBUTING.md**: How to contribute or report issues
- [OpenVINO Documentation](https://docs.openvino.ai/)
- [Intel GPU Drivers](https://dgpu-docs.intel.com/)

## 💬 Getting Help

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/intel-gpu-llm-inference/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/intel-gpu-llm-inference/discussions)
- **Hardware Reports**: Use the Hardware Test Report issue template

## ✨ Success Checklist

- [ ] Setup script completed without errors
- [ ] Added to `render` group and logged back in
- [ ] `quickstart-example.sh` runs successfully
- [ ] GPU inference completes in 1-5 seconds
- [ ] Can activate environment with `source activate-intel-gpu.sh`
- [ ] Ready to try other models!

---

**Having issues?** Open an issue with:
- Your GPU model (`lspci | grep -i vga`)
- OS and kernel (`uname -a`)
- Complete error output

We're here to help! 🚀
