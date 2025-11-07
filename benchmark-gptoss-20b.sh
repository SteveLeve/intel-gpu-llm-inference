#!/bin/bash
# Benchmark script for GPT-OSS 20B comparing OpenVINO GPU, CPU, and Ollama

set -e

MODEL_DIR="gpt_oss_20b_ir"
PROMPT="Explain the concept of machine learning in simple terms that a beginner can understand."
MAX_TOKENS=100

echo "======================================================================"
echo "GPT-OSS 20B Performance Benchmark"
echo "======================================================================"
echo ""
echo "Model: openai/gpt-oss-20b"
echo "Prompt: $PROMPT"
echo "Max tokens: $MAX_TOKENS"
echo ""

# Check if model is converted
if [ ! -d "$MODEL_DIR" ]; then
    echo "Error: Model directory $MODEL_DIR not found"
    echo "Run conversion first: source activate-intel-gpu.sh && python test-inference.py --model gptoss20b --convert-only"
    exit 1
fi

# Activate OpenVINO environment
source activate-intel-gpu.sh

echo "======================================================================"
echo "Test 1/3: OpenVINO GPU Performance"
echo "======================================================================"
echo ""
python test-inference.py \
    --model gptoss20b \
    --device GPU \
    --prompt "$PROMPT" \
    --max-tokens $MAX_TOKENS
echo ""

echo "======================================================================"
echo "Test 2/3: OpenVINO CPU Performance"
echo "======================================================================"
echo ""
python test-inference.py \
    --model gptoss20b \
    --device CPU \
    --prompt "$PROMPT" \
    --max-tokens $MAX_TOKENS
echo ""

echo "======================================================================"
echo "Test 3/3: Ollama Baseline (CPU)"
echo "======================================================================"
echo ""
echo "Prompt: $PROMPT"
echo "------------------------------------------------------------"
time ollama run gpt-oss:20b "$PROMPT" --verbose
echo ""

echo "======================================================================"
echo "Benchmark Complete!"
echo "======================================================================"
echo ""
echo "Summary:"
echo "- OpenVINO GPU results saved above"
echo "- OpenVINO CPU results saved above"
echo "- Ollama baseline results saved above"
echo ""
echo "Compare the tokens/sec and load times to determine which is fastest."
