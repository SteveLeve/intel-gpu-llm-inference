---
name: Bug Report
about: Report a bug or issue with the Intel GPU LLM setup
title: '[BUG] '
labels: bug
assignees: ''
---

## 🐛 Bug Description

A clear and concise description of what the bug is.

## 🖥️ Hardware & Environment

- **GPU Model**: [e.g., Intel Iris Xe Graphics]
- **CPU**: [e.g., Intel Core i7-1165G7]
- **RAM**: [e.g., 16GB]
- **OS**: [e.g., Ubuntu 22.04]
- **Kernel Version**: [output of `uname -r`]

## 📋 Steps to Reproduce

1. Run script '...'
2. Execute command '...'
3. See error

## ❌ Error Output

```
Paste error messages or logs here
```

## ✅ Expected Behavior

What you expected to happen.

## 📸 Additional Context

Add any other context, screenshots, or diagnostic output:

```bash
# GPU detection
lspci | grep -i vga

# Device files
ls -la /dev/dri/

# User groups
groups

# OpenVINO version (if installed)
python -c "import openvino_genai; print(openvino_genai.__version__)"
```
