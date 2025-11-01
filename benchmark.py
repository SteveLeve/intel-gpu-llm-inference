#!/usr/bin/env python3
"""
Performance benchmark script comparing OpenVINO GPU vs llama.cpp CPU inference
Measures tokens/second, latency, and model load times
"""

import argparse
import json
import subprocess
import time
import sys
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import Optional, List
import statistics

# Try to import OpenVINO GenAI
try:
    import openvino_genai as ov_genai
    OPENVINO_AVAILABLE = True
except ImportError:
    OPENVINO_AVAILABLE = False
    print("Warning: OpenVINO GenAI not available. Install with: source activate-intel-gpu.sh")


@dataclass
class BenchmarkResult:
    """Results from a single benchmark run"""
    backend: str  # "openvino_gpu", "openvino_cpu", "llama_cpp"
    model_name: str
    model_path: str
    prompt: str
    prompt_tokens: int
    response: str
    output_tokens: int
    load_time_s: float
    inference_time_s: float
    tokens_per_second: float
    first_token_latency_s: Optional[float] = None
    total_time_s: Optional[float] = None
    
    def to_dict(self):
        return asdict(self)


class OpenVINOBenchmark:
    """Benchmark OpenVINO GenAI on GPU or CPU"""
    
    def __init__(self, model_dir: Path, device: str = "GPU"):
        self.model_dir = model_dir
        self.device = device
        self.pipe = None
    
    def run(self, prompt: str, max_tokens: int = 100) -> BenchmarkResult:
        """Run benchmark with OpenVINO"""
        # Load model
        start_load = time.time()
        self.pipe = ov_genai.LLMPipeline(str(self.model_dir), self.device)
        load_time = time.time() - start_load
        
        # Generate
        start_gen = time.time()
        response = self.pipe.generate(prompt, max_new_tokens=max_tokens)
        inference_time = time.time() - start_gen
        
        total_time = load_time + inference_time
        tokens_per_sec = max_tokens / inference_time if inference_time > 0 else 0
        
        return BenchmarkResult(
            backend=f"openvino_{self.device.lower()}",
            model_name=self.model_dir.name,
            model_path=str(self.model_dir),
            prompt=prompt,
            prompt_tokens=len(prompt.split()),  # Rough estimate
            response=response,
            output_tokens=max_tokens,
            load_time_s=load_time,
            inference_time_s=inference_time,
            tokens_per_second=tokens_per_sec,
            total_time_s=total_time
        )


class LlamaCppBenchmark:
    """Benchmark llama.cpp CPU inference"""
    
    def __init__(self, model_path: Path):
        self.model_path = model_path
        self.llama_cli = Path(__file__).parent / "llama.cpp" / "build" / "bin" / "llama-cli"
        
        if not self.llama_cli.exists():
            raise FileNotFoundError(
                f"llama-cli not found at {self.llama_cli}\n"
                "Run: ./setup-llama-cpp.sh"
            )
    
    def run(self, prompt: str, max_tokens: int = 100) -> BenchmarkResult:
        """Run benchmark with llama.cpp"""
        cmd = [
            str(self.llama_cli),
            "-m", str(self.model_path),
            "-p", prompt,
            "-n", str(max_tokens),
            "--no-display-prompt",
            "-ngl", "0",  # CPU only
            "--log-disable",
        ]
        
        start = time.time()
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300
        )
        total_time = time.time() - start
        
        if result.returncode != 0:
            raise RuntimeError(f"llama.cpp failed: {result.stderr}")
        
        # Parse output
        output = result.stdout
        response = output.strip()
        
        # Extract timing info from stderr if available
        stderr = result.stderr
        load_time = 0.0
        inference_time = total_time
        
        # Try to parse llama.cpp timing output
        for line in stderr.split('\n'):
            if 'load time' in line.lower():
                try:
                    load_time = float(line.split()[-2])
                except (ValueError, IndexError):
                    pass
            if 'sample time' in line.lower():
                try:
                    inference_time = float(line.split()[-2])
                except (ValueError, IndexError):
                    pass
        
        tokens_per_sec = max_tokens / inference_time if inference_time > 0 else 0
        
        return BenchmarkResult(
            backend="llama_cpp",
            model_name=self.model_path.stem,
            model_path=str(self.model_path),
            prompt=prompt,
            prompt_tokens=len(prompt.split()),
            response=response,
            output_tokens=max_tokens,
            load_time_s=load_time,
            inference_time_s=inference_time,
            tokens_per_second=tokens_per_sec,
            total_time_s=total_time
        )


def print_result(result: BenchmarkResult):
    """Pretty print benchmark result"""
    print(f"\n{'='*70}")
    print(f"Backend: {result.backend.upper()}")
    print(f"Model: {result.model_name}")
    print(f"{'='*70}")
    print(f"Load Time:       {result.load_time_s:>8.2f}s")
    print(f"Inference Time:  {result.inference_time_s:>8.2f}s")
    print(f"Total Time:      {result.total_time_s:>8.2f}s")
    print(f"Tokens/Second:   {result.tokens_per_second:>8.1f}")
    print(f"Output Tokens:   {result.output_tokens:>8d}")
    print(f"{'='*70}")
    print(f"\nResponse Preview:")
    print(f"{result.response[:200]}..." if len(result.response) > 200 else result.response)
    print()


def compare_results(results: List[BenchmarkResult]):
    """Compare multiple benchmark results"""
    if len(results) < 2:
        print("Need at least 2 results to compare")
        return
    
    print(f"\n{'='*70}")
    print("PERFORMANCE COMPARISON")
    print(f"{'='*70}\n")
    
    # Create comparison table
    print(f"{'Backend':<20} {'Load (s)':<12} {'Inference (s)':<15} {'Tokens/s':<12} {'Total (s)':<12}")
    print("-" * 70)
    
    for r in results:
        print(f"{r.backend:<20} {r.load_time_s:<12.2f} {r.inference_time_s:<15.2f} "
              f"{r.tokens_per_second:<12.1f} {r.total_time_s:<12.2f}")
    
    # Calculate speedup
    if len(results) == 2:
        baseline = results[1]  # Usually CPU
        test = results[0]      # Usually GPU
        
        speedup = baseline.tokens_per_second / test.tokens_per_second
        time_improvement = (baseline.total_time_s - test.total_time_s) / baseline.total_time_s * 100
        
        print(f"\n{'='*70}")
        print("SPEEDUP ANALYSIS")
        print(f"{'='*70}")
        print(f"Throughput: {test.backend} is {speedup:.2f}x compared to {baseline.backend}")
        print(f"Time saved: {abs(time_improvement):.1f}% {'faster' if time_improvement > 0 else 'slower'}")
        print()


def save_results(results: List[BenchmarkResult], output_file: Path):
    """Save results to JSON file"""
    data = {
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
        "results": [r.to_dict() for r in results]
    }
    
    with open(output_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Results saved to: {output_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Benchmark LLM inference: OpenVINO GPU vs llama.cpp CPU",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Compare OpenVINO GPU vs llama.cpp CPU
  ./benchmark.py --openvino-model phi3_mini_ir --llama-model models/phi3-mini.gguf
  
  # Test only OpenVINO GPU
  ./benchmark.py --openvino-model phi3_mini_ir --gpu-only
  
  # Custom prompt and token count
  ./benchmark.py --openvino-model phi3_mini_ir --prompt "Tell me a story" --max-tokens 200
  
  # Save results to file
  ./benchmark.py --compare --output results.json
        """
    )
    
    parser.add_argument("--openvino-model", "-o",
                       help="Path to OpenVINO IR model directory")
    
    parser.add_argument("--llama-model", "-l",
                       help="Path to llama.cpp GGUF model file")
    
    parser.add_argument("--prompt", "-p",
                       default="Explain artificial intelligence in simple terms.",
                       help="Prompt for generation")
    
    parser.add_argument("--max-tokens", "-t",
                       type=int,
                       default=100,
                       help="Maximum tokens to generate")
    
    parser.add_argument("--gpu-only",
                       action="store_true",
                       help="Only test OpenVINO GPU (no CPU comparison)")
    
    parser.add_argument("--compare",
                       action="store_true",
                       help="Compare OpenVINO GPU vs CPU vs llama.cpp")
    
    parser.add_argument("--output", "-f",
                       type=Path,
                       help="Save results to JSON file")
    
    parser.add_argument("--runs", "-r",
                       type=int,
                       default=1,
                       help="Number of benchmark runs (for averaging)")
    
    args = parser.parse_args()
    
    results = []
    
    # OpenVINO GPU benchmark
    if args.openvino_model and OPENVINO_AVAILABLE:
        model_dir = Path(args.openvino_model)
        if not model_dir.exists():
            print(f"Error: OpenVINO model not found: {model_dir}")
            print("Convert a model first with: optimum-cli export openvino ...")
            sys.exit(1)
        
        print(f"Benchmarking OpenVINO GPU with {model_dir.name}...")
        try:
            bench = OpenVINOBenchmark(model_dir, device="GPU")
            result = bench.run(args.prompt, args.max_tokens)
            results.append(result)
            print_result(result)
        except Exception as e:
            print(f"Error running OpenVINO GPU: {e}")
    
    # OpenVINO CPU benchmark (for comparison)
    if args.compare and args.openvino_model and OPENVINO_AVAILABLE:
        print(f"Benchmarking OpenVINO CPU with {model_dir.name}...")
        try:
            bench = OpenVINOBenchmark(model_dir, device="CPU")
            result = bench.run(args.prompt, args.max_tokens)
            results.append(result)
            print_result(result)
        except Exception as e:
            print(f"Error running OpenVINO CPU: {e}")
    
    # llama.cpp benchmark
    if args.llama_model:
        model_path = Path(args.llama_model)
        if not model_path.exists():
            print(f"Error: llama.cpp model not found: {model_path}")
            print("Download or convert a GGUF model first")
            sys.exit(1)
        
        print(f"Benchmarking llama.cpp CPU with {model_path.name}...")
        try:
            bench = LlamaCppBenchmark(model_path)
            result = bench.run(args.prompt, args.max_tokens)
            results.append(result)
            print_result(result)
        except Exception as e:
            print(f"Error running llama.cpp: {e}")
    
    # Compare results
    if len(results) > 1:
        compare_results(results)
    
    # Save results
    if args.output:
        save_results(results, args.output)
    
    if not results:
        print("No benchmarks run. Specify --openvino-model and/or --llama-model")
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
