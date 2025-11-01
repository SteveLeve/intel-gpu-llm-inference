#!/bin/bash

# Script to setup Intel GPU support for Ollama
# For Intel Xe Graphics (TigerLake, Alderlake, etc.)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Ollama Intel GPU Setup Script ===${NC}\n"

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Do not run this script as root. It will prompt for sudo when needed.${NC}"
    exit 1
fi

# Check for Intel GPU
echo -e "${YELLOW}[1/6] Checking for Intel GPU...${NC}"
if lspci | grep -i "VGA.*Intel" > /dev/null; then
    GPU_NAME=$(lspci | grep -i "VGA.*Intel" | cut -d: -f3)
    echo -e "${GREEN}✓ Found Intel GPU:${NC}$GPU_NAME"
else
    echo -e "${RED}✗ No Intel GPU detected. This script is for Intel Xe graphics only.${NC}"
    exit 1
fi

# Check for /dev/dri
echo -e "\n${YELLOW}[2/6] Checking GPU device files...${NC}"
if [ -d "/dev/dri" ] && [ -e "/dev/dri/renderD128" ]; then
    echo -e "${GREEN}✓ GPU device files present${NC}"
    ls -la /dev/dri/renderD*
else
    echo -e "${RED}✗ GPU device files missing. Check kernel drivers.${NC}"
    exit 1
fi

# Check if user is in render group
echo -e "\n${YELLOW}[3/6] Checking user permissions...${NC}"
if groups | grep -q "render"; then
    echo -e "${GREEN}✓ User is in render group${NC}"
else
    echo -e "${YELLOW}! User not in render group. Adding...${NC}"
    sudo usermod -aG render $USER
    echo -e "${GREEN}✓ User added to render group${NC}"
    echo -e "${YELLOW}  Note: You'll need to log out and back in for this to take effect${NC}"
fi

# Add Intel oneAPI repository
echo -e "\n${YELLOW}[4/6] Setting up Intel oneAPI repository...${NC}"
if [ -f "/etc/apt/sources.list.d/oneAPI.list" ]; then
    echo -e "${GREEN}✓ Intel oneAPI repository already configured${NC}"
else
    echo "Adding Intel GPG key..."
    wget -q -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
        gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
    
    echo "Adding repository..."
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
        sudo tee /etc/apt/sources.list.d/oneAPI.list > /dev/null
    
    echo -e "${GREEN}✓ Repository added${NC}"
fi

# Update package lists
echo -e "\n${YELLOW}[5/6] Installing Intel oneAPI runtime...${NC}"
echo "Updating package lists..."
sudo apt update -qq

# Check if already installed
if dpkg -l | grep -q "intel-oneapi-runtime-dpcpp-cpp"; then
    echo -e "${GREEN}✓ Intel oneAPI runtime already installed${NC}"
else
    echo "Installing intel-oneapi-runtime-dpcpp-cpp (this may take a few minutes)..."
    sudo apt install -y intel-oneapi-runtime-dpcpp-cpp
    echo -e "${GREEN}✓ Intel oneAPI runtime installed${NC}"
fi

# Verify Ollama is installed
echo -e "\n${YELLOW}[6/6] Configuring and restarting Ollama...${NC}"
if ! command -v ollama &> /dev/null; then
    echo -e "${RED}✗ Ollama is not installed. Please install Ollama first.${NC}"
    exit 1
fi

# Check Ollama service configuration
if [ -f "/etc/systemd/system/ollama.service.d/override.conf" ]; then
    if grep -q "OLLAMA_INTEL_GPU=1" /etc/systemd/system/ollama.service.d/override.conf; then
        echo -e "${GREEN}✓ Ollama Intel GPU environment variable already set${NC}"
    else
        echo -e "${YELLOW}! OLLAMA_INTEL_GPU not found in override.conf${NC}"
        echo -e "  You may want to add it manually"
    fi
fi

# Restart Ollama service
echo "Restarting Ollama service..."
sudo systemctl restart ollama
sleep 3

# Verify GPU detection
echo -e "\n${GREEN}=== Verification ===${NC}"
echo "Checking GPU detection in Ollama logs..."
echo ""

GPU_LOG=$(journalctl -u ollama --no-pager -n 50 | grep "inference compute" | tail -1)

if echo "$GPU_LOG" | grep -q "Intel"; then
    echo -e "${GREEN}✓✓✓ SUCCESS! Intel GPU detected by Ollama ✓✓✓${NC}"
    echo "$GPU_LOG"
elif echo "$GPU_LOG" | grep -q "cpu"; then
    echo -e "${RED}✗ Ollama is still using CPU only${NC}"
    echo "$GPU_LOG"
    echo ""
    echo -e "${YELLOW}Troubleshooting tips:${NC}"
    echo "1. Ensure you've logged out and back in (for render group)"
    echo "2. Check logs: journalctl -u ollama --no-pager -n 100"
    echo "3. Verify Level Zero: clinfo -l"
    echo "4. Check environment: systemctl cat ollama"
else
    echo -e "${YELLOW}! Unable to determine GPU status from logs${NC}"
    echo "Recent Ollama logs:"
    journalctl -u ollama --no-pager -n 20
fi

echo -e "\n${GREEN}=== Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. If you just added your user to the render group, log out and log back in"
echo "2. Test with: ollama run llama3.2:1b"
echo "3. Monitor GPU usage with: intel_gpu_top (if installed)"
echo ""
