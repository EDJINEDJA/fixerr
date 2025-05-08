#!/bin/bash
set -e

install_dependencies() {
    echo "Checking dependencies..."
    
    # Install Ollama if missing
    if ! command -v ollama &> /dev/null; then
        echo "Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    # Install Python if missing
    if ! command -v python3 &> /dev/null; then
        echo "Installing Python..."
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y python3
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install python
        fi
    fi
    
    # Download default model
    echo "Downloading LLM model..."
    ollama pull phi
}

install_cli() {
    echo "Installing fixerr..."
    INSTALL_DIR="/usr/local/bin"
    LIB_DIR="/usr/local/lib/fixerr"
    
    sudo mkdir -p $INSTALL_DIR $LIB_DIR
    sudo cp bin/fixerr $INSTALL_DIR/
    sudo cp -r src/ $LIB_DIR/
    sudo chmod +x $INSTALL_DIR/fixerr
    
    echo "Installation complete!"
    echo "Try: fixerr <your_script>"
}

main() {
    install_dependencies
    install_cli
}

main