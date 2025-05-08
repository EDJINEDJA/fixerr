#!/bin/bash
set -euo pipefail

# Configuration
REPO_URL="https://github.com/oblo/fixerr"
TMP_DIR=$(mktemp -d)
INSTALL_DIR="/usr/local/bin"
LIB_DIR="/usr/local/lib/fixerr"
DEFAULT_MODEL="phi"  # Modèle LLM par défaut

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Fonction de nettoyage
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT

fail() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

check_requirements() {
    echo -e "${YELLOW}Checking system requirements...${NC}"
    
    # Vérifier curl
    if ! command -v curl &> /dev/null; then
        fail "curl is required but not installed. Please install curl first."
    fi
    
    # Vérifier les permissions sudo
    if ! sudo -v; then
        fail "sudo access is required for installation"
    fi
}

install_ollama() {
    if ! command -v ollama &> /dev/null; then
        echo -e "${YELLOW}Installing Ollama...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh || fail "Failed to install Ollama"
        
        # Ajouter l'utilisateur au groupe ollama
        sudo usermod -aG ollama $(whoami) || true
        echo -e "${YELLOW}You may need to logout and login again for Ollama permissions${NC}"
    fi
}

install_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${YELLOW}Installing Python...${NC}"
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get update && sudo apt-get install -y python3 python3-pip || fail "Failed to install Python"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            if ! command -v brew &> /dev/null; then
                fail "Homebrew required. Install from https://brew.sh/"
            fi
            brew install python || fail "Failed to install Python"
        else
            fail "Unsupported OS: $OSTYPE"
        fi
    fi
}

download_model() {
    echo -e "${YELLOW}Downloading LLM model ($DEFAULT_MODEL)...${NC}"
    ollama pull $DEFAULT_MODEL || echo -e "${YELLOW}Warning: Failed to pull model, you can manually run: ollama pull $DEFAULT_MODEL${NC}"
}

install_fixerr() {
    echo -e "${YELLOW}Downloading FixErr...${NC}"
    
    # Clone minimal du dépôt (seulement les fichiers nécessaires)
    git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$TMP_DIR" || fail "Failed to download FixErr"
    cd "$TMP_DIR"
    git sparse-checkout set bin src/llm install.sh || fail "Failed to setup sparse checkout"
    
    # Vérification des fichiers
    if [ ! -f "bin/fixerr" ]; then
        fail "Missing fixerr executable in downloaded files"
    fi
    
    if [ ! -d "src/llm" ]; then
        fail "Missing LLM analyzer in downloaded files"
    fi
    
    echo -e "${YELLOW}Installing FixErr...${NC}"
    sudo mkdir -p "$INSTALL_DIR" "$LIB_DIR" || fail "Failed to create installation directories"
    sudo install -m 755 "bin/fixerr" "$INSTALL_DIR/" || fail "Failed to install main executable"
    sudo cp -r "src/" "$LIB_DIR/" || fail "Failed to install library files"
    
    # Vérifier l'installation
    if ! command -v fixerr &> /dev/null; then
        echo -e "${YELLOW}Warning: fixerr command not found in PATH${NC}"
        echo -e "${YELLOW}You may need to add /usr/local/bin to your PATH${NC}"
    fi
}

main() {
    echo -e "\n${GREEN}Starting FixErr installation...${NC}"
    
    check_requirements
    install_ollama
    install_python
    download_model
    install_fixerr
    
    echo -e "\n${GREEN}Installation complete!${NC}"
    echo -e "Try running: ${GREEN}fixerr <your_script>${NC}"
    
    # Message final
    echo -e "\n${YELLOW}Note: You may need to restart your terminal or run:${NC}"
    echo -e "source ~/.bashrc  # or ~/.zshrc depending on your shell"
}

main