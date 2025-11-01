#!/bin/bash

# Complete Intel GPU LLM Setup Script
# Supports OpenVINO GenAI for Intel Xe Graphics
# For Ubuntu 22.04+ with Intel TigerLake/Alderlake GPUs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Intel GPU LLM Setup Script ===${NC}"
echo -e "${BLUE}Using OpenVINO GenAI for Intel Xe Graphics${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Do not run this script as root. It will prompt for sudo when needed.${NC}"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/openvino_env"

# Check for Intel GPU
echo -e "${YELLOW}[1/7] Checking for Intel GPU...${NC}"
if lspci | grep -i "VGA.*Intel" > /dev/null; then
    GPU_NAME=$(lspci | grep -i "VGA.*Intel" | cut -d: -f3)
    echo -e "${GREEN}✓ Found Intel GPU:${NC}$GPU_NAME"
else
    echo -e "${RED}✗ No Intel GPU detected. This script is for Intel Xe graphics only.${NC}"
    exit 1
fi

# Check for /dev/dri
echo -e "\n${YELLOW}[2/7] Checking GPU device files...${NC}"
if [ -d "/dev/dri" ] && [ -e "/dev/dri/renderD128" ]; then
    echo -e "${GREEN}✓ GPU device files present${NC}"
else
    echo -e "${RED}✗ GPU device files missing. Check kernel drivers.${NC}"
    exit 1
fi

# Check if user is in render group
echo -e "\n${YELLOW}[3/7] Checking user permissions...${NC}"
if groups | grep -q "render"; then
    echo -e "${GREEN}✓ User is in render group${NC}"
else
    echo -e "${YELLOW}! User not in render group. Adding...${NC}"
    sudo usermod -aG render $USER
    echo -e "${GREEN}✓ User added to render group${NC}"
    echo -e "${YELLOW}  Note: You'll need to log out and back in for this to take effect${NC}"
fi

# Check Intel GPU drivers
echo -e "\n${YELLOW}[4/7] Checking Intel GPU compute runtime...${NC}"
if dpkg -l | grep -q "intel-level-zero-gpu\|intel-opencl-icd"; then
    echo -e "${GREEN}✓ Intel compute runtime packages installed${NC}"
    dpkg -l | grep -E "intel-level-zero-gpu|intel-opencl-icd|libze1" | awk '{print "  - " $2 " " $3}'
else
    echo -e "${YELLOW}! Intel compute runtime not found. Installing...${NC}"
    
    if [ ! -f "/etc/apt/sources.list.d/intel-gpu-jammy.list" ]; then
        echo "Adding Intel GPU repository..."
        wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | \
            gpg --dearmor | sudo tee /usr/share/keyrings/intel-graphics.gpg > /dev/null
        echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy client" | \
            sudo tee /etc/apt/sources.list.d/intel-gpu-jammy.list
        sudo apt update -qq
    fi
    
    sudo apt install -y intel-opencl-icd intel-level-zero-gpu level-zero
    echo -e "${GREEN}✓ Intel compute runtime installed${NC}"
fi

# Setup Python virtual environment
echo -e "\n${YELLOW}[5/7] Setting up Python virtual environment...${NC}"
if [ -d "$VENV_DIR" ]; then
    echo -e "${BLUE}Found existing virtual environment at: $VENV_DIR${NC}"
    read -p "Remove and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing old environment..."
        rm -rf "$VENV_DIR"
        echo -e "${GREEN}✓ Old environment removed${NC}"
    else
        echo "Using existing environment..."
    fi
fi

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✓ Virtual environment created${NC}"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Upgrade pip
echo -e "\n${YELLOW}[6/7] Installing OpenVINO GenAI...${NC}"
echo "Upgrading pip..."
pip install --upgrade pip -qq

# Install OpenVINO GenAI
echo "Installing openvino-genai (this may take a few minutes)..."
if pip show openvino-genai &> /dev/null; then
    echo -e "${GREEN}✓ openvino-genai already installed${NC}"
    pip show openvino-genai | grep -E "Name:|Version:"
else
    pip install openvino-genai optimum-intel[openvino]
    echo -e "${GREEN}✓ openvino-genai installed${NC}"
fi

# Verify installation
echo -e "\n${YELLOW}[7/7] Verifying installation...${NC}"
if python3 -c "import openvino_genai; print(f'OpenVINO GenAI version: {openvino_genai.__version__}')" 2>/dev/null; then
    echo -e "${GREEN}✓ OpenVINO GenAI import successful${NC}"
else
    echo -e "${RED}✗ Failed to import openvino_genai${NC}"
    exit 1
fi

# Check GPU detection
echo -e "\nTesting GPU detection..."
python3 << 'EOF'
import subprocess
import sys

try:
    # Test clinfo
    result = subprocess.run(['clinfo', '-l'], capture_output=True, text=True, timeout=5)
    if 'Intel' in result.stdout:
        print("✓ Intel GPU visible to OpenCL")
    else:
        print("⚠ No Intel GPU found in OpenCL")
        print(result.stdout)
except FileNotFoundError:
    print("⚠ clinfo not installed (optional)")
except Exception as e:
    print(f"⚠ Could not check GPU: {e}")
EOF

echo -e "\n${GREEN}=== Setup Complete ===${NC}\n"

# Create activation helper script
cat > "$SCRIPT_DIR/activate-intel-gpu.sh" << 'ACTIVATE_EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/openvino_env/bin/activate"
echo "OpenVINO environment activated!"
echo "Python: $(which python)"
echo "Run 'deactivate' to exit the environment"
ACTIVATE_EOF

chmod +x "$SCRIPT_DIR/activate-intel-gpu.sh"

echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Activate the environment: ${BLUE}source openvino_env/bin/activate${NC}"
echo -e "   Or use the helper: ${BLUE}source activate-intel-gpu.sh${NC}"
echo ""
echo -e "2. Download a model (example with TinyLlama):"
echo -e "   ${BLUE}optimum-cli export openvino --model TinyLlama/TinyLlama-1.1B-Chat-v1.0 tinyllama_ir${NC}"
echo ""
echo -e "3. Test with Python:"
echo -e '   python3 -c "import openvino_genai as ov_genai; pipe = ov_genai.LLMPipeline(\"tinyllama_ir\", \"GPU\"); print(pipe.generate(\"What is AI?\", max_new_tokens=50))"'
echo ""
echo -e "${YELLOW}Note:${NC} If you were added to render group, log out/in first for GPU access"
echo ""

deactivate 2>/dev/null || true
