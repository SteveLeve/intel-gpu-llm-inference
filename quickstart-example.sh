#!/bin/bash
# Quickstart Example: Download and test TinyLlama on Intel GPU
# This is a complete working example for first-time users

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "===================================="
echo "Intel GPU LLM Quickstart Example"
echo "===================================="
echo ""
echo "This script will:"
echo "1. Activate OpenVINO environment"
echo "2. Download and convert TinyLlama-1.1B"
echo "3. Run a test inference on Intel GPU"
echo ""

# Check if setup has been run
if [ ! -d "openvino_env" ]; then
    echo "❌ Error: OpenVINO environment not found"
    echo ""
    echo "Please run setup first:"
    echo "  ./setup-intel-gpu-llm.sh"
    exit 1
fi

# Activate environment
echo "📦 Activating OpenVINO environment..."
source openvino_env/bin/activate

# Check if TinyLlama is already converted
if [ -d "tinyllama_ir" ]; then
    echo "✅ TinyLlama model already converted (tinyllama_ir/)"
else
    echo ""
    echo "📥 Downloading and converting TinyLlama-1.1B-Chat (INT4)..."
    echo "   This may take 5-10 minutes on first run..."
    echo ""
    
    optimum-cli export openvino \
        --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 \
        tinyllama_ir \
        --weight-format int4
    
    echo ""
    echo "✅ Model converted successfully!"
fi

echo ""
echo "🚀 Running inference test on Intel GPU..."
echo "   Prompt: 'Explain artificial intelligence in one sentence.'"
echo ""

# Run inference
python3 << 'EOF'
import openvino_genai as ov_genai
import sys

try:
    print("Initializing pipeline on Intel GPU...")
    pipe = ov_genai.LLMPipeline("tinyllama_ir", "GPU")
    
    print("\n" + "="*60)
    prompt = "Explain artificial intelligence in one sentence."
    print(f"Prompt: {prompt}")
    print("="*60 + "\n")
    
    response = pipe.generate(prompt, max_new_tokens=50)
    print(response)
    
    print("\n" + "="*60)
    print("✅ Inference completed successfully on Intel GPU!")
    print("="*60)
    
except Exception as e:
    print(f"\n❌ Error: {e}", file=sys.stderr)
    print("\nTroubleshooting tips:", file=sys.stderr)
    print("  - Ensure you're in the 'render' group: groups | grep render", file=sys.stderr)
    print("  - Check GPU visibility: ls -la /dev/dri/", file=sys.stderr)
    print("  - Verify drivers: lspci | grep -i vga", file=sys.stderr)
    sys.exit(1)
EOF

echo ""
echo "🎉 Success! Your Intel GPU is working with OpenVINO."
echo ""
echo "Next steps:"
echo "  - Try other models: python test-inference.py --help"
echo "  - Run benchmarks: ./benchmark.py --help"
echo "  - Read full guide: less README.md"
echo ""
