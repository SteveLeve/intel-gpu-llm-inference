#!/usr/bin/env python3
"""
Test script for running inference on Intel GPU with OpenVINO GenAI
Supports: Phi-3 Mini, Mistral 7B, Llama 3 8B
"""

import argparse
import time
import sys
from pathlib import Path

try:
    import openvino_genai as ov_genai
except ImportError:
    print("Error: openvino_genai not found")
    print("Run: source activate-intel-gpu.sh")
    sys.exit(1)


# Model configurations
MODELS = {
    "phi3": {
        "name": "Phi-3 Mini (3.8B)",
        "huggingface_id": "microsoft/Phi-3-mini-4k-instruct",
        "output_dir": "phi3_mini_ir",
        "description": "Microsoft's small but capable model, great for testing"
    },
    "mistral": {
        "name": "Mistral 7B Instruct",
        "huggingface_id": "mistralai/Mistral-7B-Instruct-v0.2",
        "output_dir": "mistral_7b_ir",
        "description": "Popular open-source 7B model with good performance"
    },
    "llama3": {
        "name": "Llama 3 8B Instruct",
        "huggingface_id": "meta-llama/Meta-Llama-3-8B-Instruct",
        "output_dir": "llama3_8b_ir",
        "description": "Meta's Llama 3, requires HuggingFace authentication"
    },
    "qwen2vl": {
        "name": "Qwen2-VL 7B Instruct",
        "huggingface_id": "Qwen/Qwen2-VL-7B-Instruct",
        "output_dir": "qwen2_vl_7b_ir",
        "description": "Qwen2 vision-language model (7B), supports both text and images"
    },
    "llama31": {
        "name": "Llama 3.1 8B Instruct",
        "huggingface_id": "meta-llama/Llama-3.1-8B-Instruct",
        "output_dir": "llama31_8b_ir",
        "description": "Meta's Llama 3.1 8B, tested with Ollama for comparison"
    }
}


def download_and_convert(model_key):
    """Download and convert model to OpenVINO IR format"""
    model_info = MODELS[model_key]
    output_dir = Path(model_info["output_dir"])
    
    if output_dir.exists():
        print(f"✓ Model already converted: {output_dir}")
        return output_dir
    
    print(f"\nConverting {model_info['name']}...")
    print(f"Source: {model_info['huggingface_id']}")
    print("This may take several minutes...\n")
    
    import subprocess
    cmd = [
        "optimum-cli", "export", "openvino",
        "--model", model_info["huggingface_id"],
        str(output_dir),
        "--weight-format", "int4"
    ]
    
    try:
        subprocess.run(cmd, check=True)
        print(f"✓ Conversion complete: {output_dir}")
        return output_dir
    except subprocess.CalledProcessError as e:
        print(f"✗ Conversion failed: {e}")
        return None


def run_inference(model_dir, prompt, device="GPU", max_tokens=100, stream=False):
    """Run inference with the specified model"""
    print(f"\nLoading model from: {model_dir}")
    print(f"Device: {device}")
    
    try:
        # Load model
        start_load = time.time()
        pipe = ov_genai.LLMPipeline(str(model_dir), device)
        load_time = time.time() - start_load
        print(f"✓ Model loaded in {load_time:.2f}s\n")
        
        # Generate
        print(f"Prompt: {prompt}")
        print("-" * 60)
        
        start_gen = time.time()
        
        if stream:
            # Streaming generation
            def stream_callback(text):
                print(text, end='', flush=True)
            
            config = ov_genai.GenerationConfig()
            config.max_new_tokens = max_tokens
            pipe.generate(prompt, config, stream_callback)
            print()  # New line after streaming
        else:
            # Regular generation
            response = pipe.generate(prompt, max_new_tokens=max_tokens)
            print(response)
        
        gen_time = time.time() - start_gen
        tokens_per_sec = max_tokens / gen_time if gen_time > 0 else 0
        
        print("-" * 60)
        print(f"Generation time: {gen_time:.2f}s")
        print(f"Speed: ~{tokens_per_sec:.1f} tokens/sec")
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        if device == "GPU":
            print("\nTrying CPU fallback...")
            return run_inference(model_dir, prompt, device="CPU", max_tokens=max_tokens)
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Test LLM inference on Intel GPU with OpenVINO",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test Phi-3 Mini (recommended for first test)
  python test-inference.py --model phi3 --prompt "Explain quantum computing"
  
  # Test Mistral 7B with streaming
  python test-inference.py --model mistral --prompt "Write a poem" --stream
  
  # Test on CPU instead of GPU
  python test-inference.py --model phi3 --device CPU --prompt "Hello"
  
  # Convert model without running inference
  python test-inference.py --model llama3 --convert-only

Available models:
  phi3     - Phi-3 Mini (3.8B) - Best for testing
  mistral  - Mistral 7B Instruct
  llama3   - Llama 3 8B Instruct (requires HF auth)
  qwen2vl  - Qwen2-VL 7B Instruct (vision-language model)
        """
    )
    
    parser.add_argument("--model", "-m", 
                       choices=MODELS.keys(),
                       required=True,
                       help="Model to test")
    
    parser.add_argument("--prompt", "-p",
                       default="Explain artificial intelligence in simple terms.",
                       help="Prompt for generation")
    
    parser.add_argument("--device", "-d",
                       choices=["GPU", "CPU"],
                       default="GPU",
                       help="Device to use (default: GPU)")
    
    parser.add_argument("--max-tokens", "-t",
                       type=int,
                       default=100,
                       help="Maximum tokens to generate (default: 100)")
    
    parser.add_argument("--stream", "-s",
                       action="store_true",
                       help="Enable streaming output")
    
    parser.add_argument("--convert-only",
                       action="store_true",
                       help="Only convert model, don't run inference")
    
    parser.add_argument("--list-models",
                       action="store_true",
                       help="List available models and exit")
    
    args = parser.parse_args()
    
    # List models
    if args.list_models:
        print("\nAvailable models:\n")
        for key, info in MODELS.items():
            print(f"  {key:10} - {info['name']}")
            print(f"             {info['description']}")
            print(f"             HF: {info['huggingface_id']}\n")
        return
    
    # Show model info
    model_info = MODELS[args.model]
    print(f"\n{'='*60}")
    print(f"Testing: {model_info['name']}")
    print(f"{'='*60}")
    print(f"Description: {model_info['description']}")
    
    # Convert model
    model_dir = download_and_convert(args.model)
    if not model_dir:
        sys.exit(1)
    
    if args.convert_only:
        print("\n✓ Conversion complete (--convert-only specified)")
        return
    
    # Run inference
    success = run_inference(
        model_dir,
        args.prompt,
        device=args.device,
        max_tokens=args.max_tokens,
        stream=args.stream
    )
    
    if not success:
        sys.exit(1)
    
    print(f"\n{'='*60}")
    print("✓ Test complete")
    print(f"{'='*60}\n")


if __name__ == "__main__":
    main()
