#!/bin/sh
set -e  # Exit immediately if any command fails

# Configuration
REPO_OWNER="EDJINEDJA"
REPO_NAME="fixerr"
BRANCH="main"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
TMP_DIR=$(mktemp -d -t fixerr-XXXXXXXXXX)  # Create secure temporary directory
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/fixerr"
DEFAULT_MODEL="phi"  # Default LLM model to use

# Color codes (fallback to no color if output is not a terminal)
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

# Cleanup function
cleanup() {
    if [ -d "${TMP_DIR}" ]; then
        rm -rf "${TMP_DIR}" || echo "Warning: Failed to clean up temp directory"
    fi
}
trap cleanup EXIT INT TERM

# Error handling
fail() {
    echo "${RED}Error: $1${NC}" >&2
    exit 1
}

# Check URL exists
check_url() {
    if ! curl --output /dev/null --silent --head --fail "$1"; then
        fail "File not found: $1"
    fi
}

# Check system requirements
check_requirements() {
    echo "${YELLOW}Checking system requirements...${NC}"
    
    # Verify curl
    if ! command -v curl >/dev/null 2>&1; then
        fail "curl is required but not installed."
    fi
    
    # Verify sudo
    if ! command -v sudo >/dev/null 2>&1 || ! sudo -v >/dev/null 2>&1; then
        fail "sudo access is required"
    fi
}

# Install Ollama
install_ollama() {
    if ! command -v ollama >/dev/null 2>&1; then
        echo "${YELLOW}Installing Ollama...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh || fail "Failed to install Ollama"
        
        # Add user to ollama group
        if ! groups | grep -q ollama; then
            sudo usermod -aG ollama "$(whoami)" && \
            echo "${YELLOW}You may need to log out and back in for Ollama permissions${NC}"
        fi
    fi
}

# Install Python
install_python() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "${YELLOW}Installing Python...${NC}"
        
        if [ -f /etc/debian_version ]; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip || \
            fail "Failed to install Python"
        elif [ -f /etc/redhat-release ]; then
            sudo yum install -y python3 python3-pip || \
            fail "Failed to install Python"
        elif [ "$(uname)" = "Darwin" ]; then
            if ! command -v brew >/dev/null 2>&1; then
                fail "Homebrew required. Install from https://brew.sh"
            fi
            brew install python || fail "Failed to install Python"
        else
            fail "Unsupported OS"
        fi
    fi
}

# Download file with validation
download_file() {
    relative_path=$1
    dest_path=$2
    url="${RAW_URL}/${relative_path}"
    
    echo "${YELLOW}Downloading ${relative_path}...${NC}"
    check_url "${url}"
    
    mkdir -p "$(dirname "${dest_path}")" || fail "Cannot create directory"
    
    if ! curl -fsSL "${url}" -o "${dest_path}"; then
        fail "Failed to download ${relative_path}"
    fi
    
    if [ ! -s "${dest_path}" ]; then
        fail "Downloaded file is empty: ${relative_path}"
    fi
    
    echo "${GREEN}✓ Downloaded ${relative_path}${NC}"
}

# Install FixErr
install_fixerr() {
    echo "${YELLOW}Installing FixErr...${NC}"
    
    # Download files
    download_file "bin/fixerr" "${TMP_DIR}/bin/fixerr"
    download_file "src/llm/analyzer.py" "${TMP_DIR}/src/llm/analyzer.py"
    
    # Set executable permissions
    chmod +x "${TMP_DIR}/bin/fixerr" || fail "Cannot set executable permissions"
    
    # Install files
    sudo mkdir -p "${INSTALL_DIR}" "${LIB_DIR}" || fail "Cannot create directories"
    sudo install -m 755 "${TMP_DIR}/bin/fixerr" "${INSTALL_DIR}/" || fail "Installation failed"
    sudo cp -r "${TMP_DIR}/src" "${LIB_DIR}/" || fail "Library installation failed"
    
    # Verify installation
    if ! command -v fixerr >/dev/null 2>&1; then
        echo "${YELLOW}Warning: fixerr command not found in PATH${NC}"
    fi
}

main() {
    echo "\n${GREEN}Starting FixErr installation...${NC}"
    
    check_requirements
    install_ollama
    install_python
    install_fixerr
    
    echo "\n${GREEN}Installation complete!${NC}"
    echo "Try running: ${GREEN}fixerr <your_script>${NC}"
    
    if ! command -v fixerr >/dev/null 2>&1; then
        echo "\n${YELLOW}Note: You may need to add /usr/local/bin to your PATH:${NC}"
        echo "export PATH=\"/usr/local/bin:\$PATH\""
    fi
}

main