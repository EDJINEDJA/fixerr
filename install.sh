#!/bin/sh
# FixErr Installation Script
# POSIX-compliant installer compatible with all standard Unix shells
# Usage: curl -fsSL https://raw.githubusercontent.com/oblo/fixerr/main/install.sh | sh

set -e  # Exit immediately if any command fails

# ----------------------------
# CONFIGURATION SECTION
# ----------------------------

# Repository information - CHANGE THESE if using a different repo
REPO_OWNER="EDJINEDJA"              # GitHub username or organization
REPO_NAME="fixerr"             # Repository name
BRANCH="main"                  # Branch containing the files

# Installation paths
INSTALL_DIR="/usr/local/bin"   # Where to install the main executable
LIB_DIR="/usr/local/lib/fixerr" # Where to install library files

# ----------------------------
# INITIALIZATION SECTION
# ----------------------------

# Create temporary directory (works on both Linux and BSD systems)
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'fixerr') || {
    echo "ERROR: Failed to create temporary directory" >&2
    exit 1
}

# Cleanup function to remove temp files
cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true  # Silently fail if delete fails
}
trap cleanup EXIT INT TERM  # Ensure cleanup runs on script exit

# ----------------------------
# ERROR HANDLING SECTION
# ----------------------------

# Unified error handling function
fail() {
    echo "ERROR: $1" >&2
    echo "Installation failed. Please check:" >&2
    echo "1. The repository exists at https://github.com/$REPO_OWNER/$REPO_NAME" >&2
    echo "2. The files exist in the $BRANCH branch" >&2
    exit 1
}

# ----------------------------
# DEPENDENCY CHECK SECTION
# ----------------------------

# Verify system has required dependencies
check_deps() {
    # Check for curl (required for downloads)
    if ! command -v curl >/dev/null; then
        fail "curl is required but not installed. Install with:
        Linux: sudo apt-get install curl
        MacOS: brew install curl"
    fi

    # Check for sudo (unless already root)
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null; then
        fail "sudo is required for installation"
    fi
}

# ----------------------------
# DOWNLOAD SECTION
# ----------------------------

# Secure file download with verification
download_verified() {
    file_path="$1"  # Relative path in repository
    dest_path="$2"  # Full destination path
    url="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/$file_path"
    
    echo "Downloading $file_path..."
    
    # First verify the URL exists
    if ! curl --head --silent --fail "$url" >/dev/null; then
        fail "File not found at: $url
        Please verify:
        1. The repository is public
        2. The file exists in the $BRANCH branch
        3. The path is correct"
    fi
    
    # Download with 3 retry attempts
    for i in 1 2 3; do
        if curl -fsSL "$url" -o "$dest_path"; then
            # Verify file was downloaded and has content
            if [ -s "$dest_path" ]; then
                chmod +x "$dest_path" 2>/dev/null || true  # Try to make executable if appropriate
                return 0  # Success
            fi
        fi
        sleep 1  # Wait before retry
    done
    
    fail "Failed to download $file_path after 3 attempts"
}

# ----------------------------
# INSTALLATION SECTION
# ----------------------------

# Main installation function
install() {
    echo "Starting FixErr installation..."
    
    # Verify system dependencies
    check_deps
    
    # Download required files
    download_verified "bin/fixerr" "$TMP_DIR/fixerr"          # Main executable
    download_verified "src/llm/analyzer.py" "$TMP_DIR/analyzer.py"  # LLM analyzer
    
    # Create installation directories
    if ! sudo mkdir -p "$LIB_DIR"; then
        fail "Cannot create library directory $LIB_DIR"
    fi
    
    # Install main executable
    if ! sudo install -m 755 "$TMP_DIR/fixerr" "$INSTALL_DIR/fixerr"; then
        fail "Cannot install main executable"
    fi
    
    # Install analyzer library
    if ! sudo install -m 644 "$TMP_DIR/analyzer.py" "$LIB_DIR/analyzer.py"; then
        fail "Cannot install analyzer"
    fi
    
    # Verify installation succeeded
    if command -v fixerr >/dev/null; then
        echo "SUCCESS: FixErr installed successfully!"
        echo "Try it with: fixerr <your_script>"
    else
        echo "WARNING: Installation completed but 'fixerr' not found in PATH"
        echo "You may need to add /usr/local/bin to your PATH:"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
}

# ----------------------------
# EXECUTION SECTION
# ----------------------------

# Run the installation process
install