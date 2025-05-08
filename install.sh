#!/bin/bash
set -e  # Exit immediately if any command fails

# Configuration
REPO_URL="https://github.com/EDJINEDJA/fixerr"
TMP_DIR=$(mktemp -d)  # Create temporary directory
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/fixerr"
DEFAULT_MODEL="phi"  # Default LLM model to use

# Color codes (disabled if output is not a terminal)
RED=''
GREEN=''
YELLOW=''
NC=''
if [ -t 1 ]; then  # Check if output is a terminal
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'  # No Color
fi

# Cleanup function to remove temp files
cleanup() {
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT  # Ensure cleanup runs on exit

# Error handling function
fail() {
    echo "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check system requirements
check_requirements() {
    echo "${YELLOW}Checking system requirements...${NC}"
    
    # Verify curl is installed
    if ! command -v curl >/dev/null 2>&1; then
        fail "curl is required but not installed."
    fi
    
    # Verify sudo access
    if ! sudo -v >/dev/null 2>&1; then
        fail "sudo access is required"
    fi
}

# Install Ollama if missing
install_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo "${YELLOW}Installing Ollama...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh || fail "Failed to install Ollama"
    fi
}

# Install Python if missing
install_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "${YELLOW}Installing Python...${NC}"
        # Detect OS and use appropriate package manager
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip || fail "Failed to install Python"
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y python3 python3-pip || fail "Failed to install Python"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if ! command -v brew >/dev/null 2>&1; then
                fail "Install Homebrew first: https://brew.sh"
            fi
            brew install python || fail "Failed to install Python"
        else
            fail "Unsupported OS"
        fi
    fi
}

# Download and install FixErr
install_fixerr() {
    echo "${YELLOW}Downloading FixErr...${NC}"
    
    # Download required files individually
    for file in bin/fixerr src/llm/analyzer.py; do
        mkdir -p "$(dirname "${TMP_DIR}/${file}")"
        curl -fsSL "${REPO_URL}/raw/main/${file}" -o "${TMP_DIR}/${file}" || fail "Failed to download ${file}"
    done
    
    echo "${YELLOW}Installing...${NC}"
    # Create installation directories
    sudo mkdir -p "$INSTALL_DIR" "$LIB_DIR" || fail "Failed to create directories"
    # Install main executable
    sudo install -m 755 "${TMP_DIR}/bin/fixerr" "$INSTALL_DIR/" || fail "Failed to install binary"
    # Install library files
    sudo cp -r "${TMP_DIR}/src" "$LIB_DIR/" || fail "Failed to install library"
}

main() {
    echo "${GREEN}Starting FixErr installation...${NC}"
    check_requirements
    install_ollama
    install_python
    install_fixerr
    
    echo "${GREEN}Installation complete!${NC}"
    echo "Try running: fixerr <your_script>"
    
    # Check if command is available in PATH
    if ! command -v fixerr >/dev/null 2>&1; then
        echo "${YELLOW}Note: You may need to add /usr/local/bin to your PATH${NC}"
    fi
}

# Run main function
main