#!/bin/bash

# Setup script for llama.cpp with CPU-only inference
# Used for performance comparison against Intel GPU (OpenVINO)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LLAMA_DIR="$SCRIPT_DIR/llama.cpp"
BUILD_DIR="$LLAMA_DIR/build"

echo -e "${GREEN}=== llama.cpp CPU Setup ===${NC}\n"

# Check if llama.cpp directory exists
if [ ! -d "$LLAMA_DIR" ]; then
    echo -e "${YELLOW}llama.cpp not found. Cloning repository...${NC}"
    git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_DIR"
    cd "$LLAMA_DIR"
else
    echo -e "${GREEN}✓ llama.cpp directory found${NC}"
    cd "$LLAMA_DIR"
    
    # Update if needed
    read -p "Update llama.cpp to latest version? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Pulling latest changes..."
        git pull
    fi
fi

# Check build dependencies
echo -e "\n${YELLOW}Checking build dependencies...${NC}"
MISSING_DEPS=()

if ! command -v cmake &> /dev/null; then
    MISSING_DEPS+=("cmake")
fi

if ! command -v make &> /dev/null; then
    MISSING_DEPS+=("build-essential")
fi

if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
    echo -e "${YELLOW}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    echo "Installing..."
    sudo apt update
    sudo apt install -y "${MISSING_DEPS[@]}"
fi

echo -e "${GREEN}✓ Dependencies satisfied${NC}"

# Build llama.cpp
echo -e "\n${YELLOW}Building llama.cpp...${NC}"
if [ -d "$BUILD_DIR" ]; then
    echo "Removing old build directory..."
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

echo "Compiling (this may take a few minutes)..."
cmake --build . --config Release -j$(nproc)

echo -e "${GREEN}✓ Build complete${NC}"

# Create symlinks for easy access
echo -e "\n${YELLOW}Creating convenience scripts...${NC}"

cat > "$SCRIPT_DIR/llama-run" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/llama.cpp/build/bin/llama-cli" "$@"
EOF

chmod +x "$SCRIPT_DIR/llama-run"

cat > "$SCRIPT_DIR/llama-convert" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/llama.cpp"
exec python3 convert_hf_to_gguf.py "$@"
EOF

chmod +x "$SCRIPT_DIR/llama-convert"

echo -e "${GREEN}✓ Created helper scripts:${NC}"
echo "  - ./llama-run (runs llama-cli)"
echo "  - ./llama-convert (converts models to GGUF)"

# Test the build
echo -e "\n${YELLOW}Testing build...${NC}"
if [ -f "$BUILD_DIR/bin/llama-cli" ]; then
    "$BUILD_DIR/bin/llama-cli" --version 2>&1 | head -5 || true
    echo -e "${GREEN}✓ llama-cli executable working${NC}"
else
    echo -e "${YELLOW}⚠ llama-cli not found in expected location${NC}"
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"
echo "Next steps:"
echo "1. Download GGUF models or convert HuggingFace models"
echo "   Example: ./llama-convert microsoft/Phi-3-mini-4k-instruct"
echo ""
echo "2. Run inference:"
echo "   ./llama-run -m models/model.gguf -p \"Your prompt here\""
echo ""
echo "3. Run performance comparison:"
echo "   ./benchmark.py --compare"
echo ""
