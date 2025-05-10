#!/bin/sh
# FixErr Installation Script
# Usage: curl -fsSL https://raw.githubusercontent.com/EDJINEDJA/fixerr/main/install.sh | sh

# Exit immediately if any command fails
set -e

# ----------------------------
# CONFIGURATION
# ----------------------------
REPO_OWNER="EDJINEDJA"           
REPO_NAME="fixerr"           
BRANCH="main"                
INSTALL_DIR="/usr/local/bin" 
LIB_DIR="/usr/local/lib/fixerr"

# ----------------------------
# INITIALIZATION
# ----------------------------

# Create secure temporary directory with improved compatibility
TMP_DIR=$( (mktemp -d 2>/dev/null || mktemp -d -t 'fixerr') ) || {
    echo "ERROR: Failed to create temporary directory" >&2
    exit 1
}

# Cleanup function
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR" || echo "WARNING: Could not remove temp directory" >&2
    fi
}
trap cleanup EXIT INT TERM HUP

# ----------------------------
# ERROR HANDLING
# ----------------------------

fail() {
    echo "ERROR: $1" >&2
    echo "TROUBLESHOOTING:" >&2
    echo "1. Verify files exist in repository:" >&2
    echo "   - bin/fixerr (executable)" >&2
    echo "   - src/llm/analyzer.py" >&2
    echo "2. Check repository visibility: https://github.com/$REPO_OWNER/$REPO_NAME" >&2
    echo "3. Ensure branch '$BRANCH' exists" >&2
    exit 1
}

# ----------------------------
# DEPENDENCY VERIFICATION
# ----------------------------

verify_dependencies() {
    # Check for curl with better error message
    if ! command -v curl >/dev/null 2>&1; then
        echo "curl is required but not found." >&2
        echo "Install using:" >&2
        echo "  Ubuntu/Debian: sudo apt-get install curl" >&2
        echo "  RHEL/CentOS: sudo yum install curl" >&2
        echo "  macOS: brew install curl" >&2
        exit 1
    fi

    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        fail "git is required but not found"
    fi

    # Verify sudo access if not root
    if [ "$(id -u)" -ne 0 ] && ! sudo -v >/dev/null 2>&1; then
        fail "sudo access is required for installation"
    fi
}

# ----------------------------
# REPOSITORY CLONING
# ----------------------------

clone_repository() {
    echo "Cloning FixErr repository..."
    if ! git clone -b "$BRANCH" --depth 1 --single-branch \
        "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TMP_DIR" 2>/dev/null; then
        fail "Failed to clone repository. Common issues:
        - Repository doesn't exist or is private
        - Branch '$BRANCH' doesn't exist
        - Network connectivity problems"
    fi
}

# ----------------------------
# FILE VERIFICATION
# ----------------------------

verify_files() {
    echo "Verifying installation files..."
    
    # Check main executable
    if [ ! -f "$TMP_DIR/bin/fixerr" ]; then
        echo "Expected file path: $TMP_DIR/bin/fixerr" >&2
        fail "Main executable not found in repository"
    fi
    
    # Verify executable permissions
    if [ ! -x "$TMP_DIR/bin/fixerr" ]; then
        if ! chmod +x "$TMP_DIR/bin/fixerr"; then
            fail "Cannot set executable permissions on bin/fixerr"
        fi
    fi

    # Check analyzer file
    if [ ! -f "$TMP_DIR/src/llm/analyzer.py" ]; then
        echo "Expected file path: $TMP_DIR/src/llm/analyzer.py" >&2
        fail "LLM analyzer not found in repository"
    fi
}

# ----------------------------
# INSTALLATION PROCESS
# ----------------------------

perform_installation() {
    echo "Installing FixErr..."
    
    # Create directories with improved error handling
    for dir in "$INSTALL_DIR" "$LIB_DIR"; do
        if ! sudo mkdir -p "$dir"; then
            fail "Failed to create directory: $dir"
        fi
    done
    
    # Install main executable
    if ! sudo install -v -m 755 "$TMP_DIR/bin/fixerr" "$INSTALL_DIR/"; then
        fail "Failed to install main executable"
    fi
    
    # Install library files with verbose output
    if ! sudo cp -vr "$TMP_DIR/src" "$LIB_DIR/"; then
        fail "Failed to install library files"
    fi
    
    # Set permissions for library files
    if ! sudo find "$LIB_DIR" -type f -exec chmod 644 {} \; 2>/dev/null; then
        echo "WARNING: Could not set library file permissions" >&2
    fi
}

# ----------------------------
# POST-INSTALLATION
# ----------------------------

verify_installation() {
    echo "Verifying installation..."
    
    if command -v fixerr >/dev/null 2>&1; then
        echo "SUCCESS: FixErr installed successfully!"
        echo "Try it with: fixerr <your_script>"
    else
        echo "WARNING: Installation completed but 'fixerr' not found in PATH" >&2
        echo "Add to your PATH:" >&2
        echo "  echo 'export PATH=\"/usr/local/bin:\$PATH\"' >> ~/.bashrc" >&2
        echo "  source ~/.bashrc" >&2
    fi
}

# ----------------------------
# MAIN EXECUTION
# ----------------------------

main() {
    echo "Starting FixErr installation..."
    
    verify_dependencies
    clone_repository
    verify_files
    perform_installation
    verify_installation
    
    echo "Installation process completed successfully"
}

main