#!/bin/bash

# Script to test popular LLM models on Intel GPU with OpenVINO GenAI
# Models: Phi-3 Mini (3.8B), Mistral 7B, Llama 3 8B

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/openvino_env"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}Virtual environment not found. Run ./setup-intel-gpu-llm.sh first${NC}"
    exit 1
fi

# Activate environment
source "$VENV_DIR/bin/activate"

echo -e "${GREEN}=== Intel GPU Model Testing ===${NC}\n"

# Function to convert and test a model
test_model() {
    local model_name=$1
    local model_id=$2
    local output_dir=$3
    local test_prompt=$4
    
    echo -e "${YELLOW}Testing: $model_name${NC}"
    echo -e "${BLUE}Model ID: $model_id${NC}"
    echo ""
    
    # Check if model already converted
    if [ -d "$output_dir" ]; then
        echo -e "${GREEN}✓ Model already converted at: $output_dir${NC}"
    else
        echo "Converting model to OpenVINO IR format..."
        echo "This may take several minutes..."
        optimum-cli export openvino --model "$model_id" "$output_dir" --weight-format int4
        echo -e "${GREEN}✓ Conversion complete${NC}"
    fi
    
    echo ""
    echo "Running inference on GPU..."
    echo "Prompt: $test_prompt"
    echo "---"
    
    python3 << EOF
import openvino_genai as ov_genai
import time

try:
    # Initialize pipeline
    start_load = time.time()
    pipe = ov_genai.LLMPipeline("$output_dir", "GPU")
    load_time = time.time() - start_load
    
    # Generate response
    start_gen = time.time()
    response = pipe.generate("$test_prompt", max_new_tokens=100)
    gen_time = time.time() - start_gen
    
    print(response)
    print("\n---")
    print(f"Model load time: {load_time:.2f}s")
    print(f"Generation time: {gen_time:.2f}s")
    
except Exception as e:
    print(f"Error: {e}")
    print("Trying CPU fallback...")
    pipe = ov_genai.LLMPipeline("$output_dir", "CPU")
    response = pipe.generate("$test_prompt", max_new_tokens=100)
    print(response)
EOF
    
    echo ""
    echo -e "${GREEN}Test complete for $model_name${NC}"
    echo "================================================"
    echo ""
}

# Display menu
echo "Select models to test:"
echo "1) Phi-3 Mini (3.8B) - Recommended for testing"
echo "2) Mistral 7B - Requires ~8GB RAM"
echo "3) Llama 3 8B - Requires ~10GB RAM"
echo "4) Test all models"
echo "5) Exit"
echo ""
read -p "Enter choice [1-5]: " choice

case $choice in
    1)
        test_model "Phi-3 Mini (3.8B)" \
            "microsoft/Phi-3-mini-4k-instruct" \
            "phi3_mini_ir" \
            "Explain quantum computing in simple terms."
        ;;
    2)
        test_model "Mistral 7B" \
            "mistralai/Mistral-7B-Instruct-v0.2" \
            "mistral_7b_ir" \
            "Write a short poem about artificial intelligence."
        ;;
    3)
        echo -e "${YELLOW}Note: Llama 3 requires Hugging Face authentication${NC}"
        echo "Make sure you've run: huggingface-cli login"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            test_model "Llama 3 8B" \
                "meta-llama/Meta-Llama-3-8B-Instruct" \
                "llama3_8b_ir" \
                "What are the three laws of robotics?"
        fi
        ;;
    4)
        test_model "Phi-3 Mini (3.8B)" \
            "microsoft/Phi-3-mini-4k-instruct" \
            "phi3_mini_ir" \
            "Explain quantum computing in simple terms."
        
        test_model "Mistral 7B" \
            "mistralai/Mistral-7B-Instruct-v0.2" \
            "mistral_7b_ir" \
            "Write a short poem about artificial intelligence."
        
        echo -e "${YELLOW}Skipping Llama 3 (requires authentication)${NC}"
        echo "To test Llama 3, run: huggingface-cli login"
        echo "Then run this script and select option 3"
        ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo -e "${GREEN}=== All tests complete ===${NC}"
deactivate
