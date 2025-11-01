#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/openvino_env/bin/activate"
echo "OpenVINO environment activated!"
echo "Python: $(which python)"
echo "Run 'deactivate' to exit the environment"
