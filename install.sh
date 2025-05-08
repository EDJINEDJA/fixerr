#!/bin/sh
# FixErr Installation Script
# POSIX-compliant installer compatible with all standard Unix shells
# Provides robust error handling and clear user feedback
# Usage: curl -fsSL https://raw.githubusercontent.com/oblo/fixerr/main/install.sh | sh

set -e  # Exit immediately if any command fails

# ----------------------------
# CONFIGURATION
# ----------------------------
REPO_OWNER="EDJINEDJA"            # GitHub username or organization
REPO_NAME="fixerr"           # Repository name
BRANCH="main"                # Default branch to use
INSTALL_DIR="/usr/local/bin" # Installation directory for main executable
LIB_DIR="/usr/local/lib/fixerr" # Installation directory for libraries

# ----------------------------
# INITIALIZATION
# ----------------------------

# Create secure temporary directory (works on Linux/macOS/BSD)
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'fixerr-install') || {
    echo "ERROR: Failed to create temporary directory" >&2
    exit 1
}

# Cleanup function to remove temp files
cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || echo "WARNING: Failed to clean up temp directory" >&2
}
trap cleanup EXIT INT TERM  # Ensure cleanup runs on exit

# ----------------------------
# ERROR HANDLING
# ----------------------------

# Unified error reporting function
fail() {
    echo "ERROR: $1" >&2
    echo "TROUBLESHOOTING:" >&2
    echo "1. Verify repository exists: https://github.com/$REPO_OWNER/$REPO_NAME" >&2
    echo "2. Check files exist in $BRANCH branch:" >&2
    echo "   - bin/fixerr (main executable)" >&2
    echo "   - src/llm/analyzer.py (LLM analyzer)" >&2
    echo "3. Ensure repository is public" >&2
    echo "4. Check network connectivity" >&2
    exit 1
}

# ----------------------------
# DEPENDENCY VERIFICATION
# ----------------------------

verify_dependencies() {
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        fail "curl is required but not found. Install with:
        Linux: sudo apt-get install curl
        macOS: brew install curl"
    fi

    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        fail "git is required but not found. Install with:
        Linux: sudo apt-get install git
        macOS: brew install git"
    fi

    # Verify sudo access if not root
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
        fail "sudo access is required for installation"
    fi
}

# ----------------------------
# REPOSITORY CLONING
# ----------------------------

clone_repository() {
    echo "Cloning FixErr repository from $BRANCH branch..."
    if ! git clone -b "$BRANCH" --depth 1 \
        "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TMP_DIR" 2>/dev/null; then
        fail "Failed to clone repository. Possible causes:
        - Repository doesn't exist
        - Branch '$BRANCH' doesn't exist
        - Network issues
        - Repository is private"
    fi
}

# ----------------------------
# FILE VERIFICATION
# ----------------------------

verify_files() {
    echo "Verifying required files..."
    
    # Check main executable exists and is executable
    if [ ! -f "$TMP_DIR/bin/fixerr" ]; then
        fail "Missing main executable: bin/fixerr"
    fi
    
    if [ ! -x "$TMP_DIR/bin/fixerr" ]; then
        fail "Main executable is not executable. Run: chmod +x bin/fixerr"
    fi

    # Check LLM analyzer exists
    if [ ! -f "$TMP_DIR/src/llm/analyzer.py" ]; then
        fail "Missing LLM analyzer: src/llm/analyzer.py"
    fi
}

# ----------------------------
# INSTALLATION PROCESS
# ----------------------------

perform_installation() {
    echo "Installing FixErr system-wide..."
    
    # Create installation directories
    if ! sudo mkdir -p "$INSTALL_DIR" "$LIB_DIR"; then
        fail "Failed to create installation directories"
    fi
    
    # Install main executable
    if ! sudo install -m 755 "$TMP_DIR/bin/fixerr" "$INSTALL_DIR/"; then
        fail "Failed to install main executable"
    fi
    
    # Install library files
    if ! sudo cp -r "$TMP_DIR/src" "$LIB_DIR/"; then
        fail "Failed to install library files"
    fi
    
    # Set permissions for library files (644 = rw-r--r--)
    if ! sudo find "$LIB_DIR" -type f -exec chmod 644 {} \; 2>/dev/null; then
        echo "WARNING: Could not set library file permissions" >&2
    fi
}

# ----------------------------
# POST-INSTALLATION VERIFICATION
# ----------------------------

verify_installation() {
    echo "Verifying installation..."
    
    if command -v fixerr >/dev/null 2>&1; then
        echo "SUCCESS: FixErr installed successfully!"
        echo "Usage: fixerr <your_script>"
    else
        echo "WARNING: Installation completed but 'fixerr' not found in PATH"
        echo "You may need to add /usr/local/bin to your PATH:"
        echo "  export PATH=\"/usr/local/bin:\$PATH\""
        echo "Or restart your terminal session"
    fi
}

# ----------------------------
# MAIN EXECUTION FLOW
# ----------------------------

main() {
    echo "Starting FixErr installation process..."
    
    verify_dependencies
    clone_repository
    verify_files
    perform_installation
    verify_installation
    
    echo "Installation process completed."
}

main