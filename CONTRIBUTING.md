# Contributing to Intel GPU LLM Inference

Thank you for your interest in contributing! This project aims to help Intel Xe GPU users run local LLMs efficiently.

## 🎯 Project Goals

- Provide simple setup scripts for Intel GPU LLM inference on Linux
- Demonstrate OpenVINO performance benefits over CPU-only inference
- Support common business laptops with Intel Xe integrated graphics
- Maintain clear documentation for non-expert users

## 🐛 Reporting Issues

When reporting issues, please include:

- **Hardware**: GPU model (e.g., Intel Iris Xe, Arc A770)
- **OS**: Distribution and kernel version (`uname -r`)
- **Setup**: Which scripts you ran
- **Error**: Full error messages and relevant logs

```bash
# Helpful diagnostic commands
lspci | grep -i vga
ls -la /dev/dri/
python -c "import openvino_genai; print(openvino_genai.__version__)"
```

## 🔧 Contributing Code

### Areas for Contribution

1. **New Model Support**: Add tested model configurations
2. **Performance Optimizations**: Improve benchmark accuracy
3. **Documentation**: Fix typos, add examples, improve clarity
4. **Hardware Support**: Test on different Intel GPU generations
5. **Bug Fixes**: Address issues in setup scripts

### Development Setup

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/intel-gpu-llm-inference.git
cd intel-gpu-llm-inference

# Initialize submodule
git submodule update --init --recursive

# Run setup
./setup-intel-gpu-llm.sh
```

### Code Style

- **Shell Scripts**: Follow existing formatting, use `shellcheck` if possible
- **Python**: PEP 8 style, type hints appreciated
- **Documentation**: Clear, concise, with working examples

### Testing Your Changes

Before submitting:

```bash
# Test setup scripts (in a clean environment if possible)
./setup-intel-gpu-llm.sh

# Test inference
source activate-intel-gpu.sh
python test-inference.py --model phi3 --prompt "Test prompt"

# Test benchmark
./benchmark.py --openvino-model phi3_mini_ir --llama-model models/phi3.gguf
```

## 📝 Documentation Contributions

- Update README.md for new features
- Add examples to BENCHMARK_GUIDE.md for new workflows
- Document tested hardware configurations
- Improve troubleshooting section

## 🧪 Hardware Testing

If you test on new hardware, please share:

- GPU model and generation
- Performance results (tokens/sec)
- Any required modifications
- Driver versions used

## 📋 Pull Request Process

1. **Fork** the repository
2. **Create a branch** for your feature (`git checkout -b feature/amazing-feature`)
3. **Test** your changes thoroughly
4. **Commit** with clear messages (`git commit -m 'Add support for model X'`)
5. **Push** to your fork (`git push origin feature/amazing-feature`)
6. **Open a Pull Request** with:
   - Clear description of changes
   - Testing methodology
   - Hardware tested on
   - Any breaking changes

## ✅ Checklist for PRs

- [ ] Code tested on Intel Xe GPU
- [ ] Documentation updated if needed
- [ ] No hardcoded paths or credentials
- [ ] Scripts remain idempotent (can be run multiple times)
- [ ] Error messages are helpful
- [ ] Changes are backward compatible (or noted)

## 🤝 Community Guidelines

- Be respectful and constructive
- Help others troubleshoot issues
- Share performance results and configurations
- Document your hardware setup when reporting results

## 📮 Contact

- **Issues**: Use GitHub Issues for bugs/features
- **Discussions**: Use GitHub Discussions for questions
- **Security**: Report security issues privately via GitHub Security Advisories

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for helping make Intel GPU LLM inference accessible to everyone!** 🚀
