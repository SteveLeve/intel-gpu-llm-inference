#!/bin/bash

# Git setup script for Intel GPU LLM project
# Handles llama.cpp as submodule and cleans up generated files

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}=== Git Repository Setup ===${NC}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if git repo is initialized
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    echo -e "${GREEN}✓ Git repository initialized${NC}"
fi

# Check current status
echo -e "\n${YELLOW}Current status:${NC}"
if [ -d "llama.cpp/.git" ]; then
    echo "✓ llama.cpp is a git repository"
else
    echo "✗ llama.cpp is not a git repository"
fi

# Handle llama.cpp as submodule
echo -e "\n${YELLOW}Handling llama.cpp repository...${NC}"
if [ -d "llama.cpp" ] && [ -d "llama.cpp/.git" ]; then
    echo "Converting llama.cpp to git submodule..."
    
    # Get current commit
    cd llama.cpp
    CURRENT_COMMIT=$(git rev-parse HEAD)
    echo "Current llama.cpp commit: $CURRENT_COMMIT"
    cd ..
    
    # Remove from tracking but keep files
    rm -rf llama.cpp
    
    # Add as submodule
    git submodule add https://github.com/ggerganov/llama.cpp.git llama.cpp
    
    echo -e "${GREEN}✓ llama.cpp added as submodule${NC}"
else
    if [ ! -d "llama.cpp" ]; then
        echo "llama.cpp not found, adding as submodule..."
        git submodule add https://github.com/ggerganov/llama.cpp.git llama.cpp
        echo -e "${GREEN}✓ llama.cpp added as submodule${NC}"
    fi
fi

# Update .gitignore to explicitly exclude llama.cpp build
echo -e "\n${YELLOW}Updating .gitignore...${NC}"
if ! grep -q "llama.cpp/build" .gitignore; then
    cat >> .gitignore << 'EOF'

# llama.cpp build artifacts
llama.cpp/build/
llama-run
llama-convert

EOF
    echo -e "${GREEN}✓ .gitignore updated${NC}"
else
    echo "✓ .gitignore already configured"
fi

# Show what will be committed
echo -e "\n${YELLOW}Files to be tracked in git:${NC}"
git status --short | grep -v "openvino_env\|tinyllama_ir\|models/" || echo "Clean"

echo -e "\n${YELLOW}Files being ignored:${NC}"
ls -d tinyllama_ir openvino_env models 2>/dev/null || echo "No ignored directories present"

echo -e "\n${GREEN}=== Repository Structure ===${NC}"
echo "
Tracked files (will be in git):
  ✓ All .sh setup scripts
  ✓ All .py test/benchmark scripts  
  ✓ README.md and BENCHMARK_GUIDE.md
  ✓ .gitignore
  ✓ llama.cpp/ (as submodule)

Ignored files (not in git):
  ✗ openvino_env/ (Python virtual environment)
  ✗ tinyllama_ir/ (converted models)
  ✗ models/ (GGUF models)
  ✗ *_ir/ (any OpenVINO IR models)
  ✗ llama.cpp/build/ (build artifacts)
"

echo -e "${GREEN}=== Next Steps ===${NC}"
echo "
1. Review status:
   git status

2. Add your files:
   git add .gitignore README.md BENCHMARK_GUIDE.md
   git add *.sh *.py
   git submodule add https://github.com/ggerganov/llama.cpp.git llama.cpp

3. Make initial commit:
   git commit -m 'Initial commit: Intel GPU LLM inference framework'

4. Add remote (if you have one):
   git remote add origin YOUR_REPO_URL
   git branch -M main
   git push -u origin main

5. Initialize submodule (for clones):
   git submodule init
   git submodule update
"

echo -e "${YELLOW}Would you like to see the full status now? (y/N):${NC} "
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git status
fi
