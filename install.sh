#!/bin/sh
# POSIX-compliant installer script for FixErr
# Compatible with all standard Unix shells (sh, dash, bash, etc.)

set -e  # Exit immediately if any command fails

# Configuration - modify these if needed
REPO_OWNER="EDJINEDJA"
REPO_NAME="fixerr"
BRANCH="main"
INSTALL_DIR="/usr/local/bin"  # Where to install the main executable
LIB_DIR="/usr/local/lib/fixerr"  # Where to install library files

# Create temporary directory (works on both Linux and BSD)
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'fixerr-install') || {
    echo "Error: Failed to create temporary directory" >&2
    exit 1
}

# Cleanup function to remove temp files
cleanup() {
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR" || echo "Warning: Could not remove temp directory" >&2
    fi
}
trap cleanup EXIT INT TERM  # Ensure cleanup runs on exit

# Error handling function
fail() {
    echo "Error: $1" >&2
    exit 1
}

# Check for required dependencies
check_dependencies() {
    # Check for curl
    if ! command -v curl >/dev/null 2>&1; then
        fail "curl is required but not found. Please install curl first."
    fi

    # Check for sudo
    if ! command -v sudo >/dev/null 2>&1; then
        fail "sudo is required but not found. Please install sudo or run as root."
    fi
}

# Download a file with validation
download_file() {
    file_path="$1"  # Relative path in repository
    dest_path="$2"  # Full destination path
    url="https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$BRANCH/$file_path"

    echo "Downloading $file_path..."
    
    # Create parent directory if needed
    mkdir -p "$(dirname "$dest_path")" || fail "Cannot create directory for $file_path"
    
    # Download the file
    if ! curl -fsSL "$url" -o "$dest_path"; then
        fail "Failed to download $file_path from $url"
    fi
    
    # Verify the file was downloaded and has content
    if [ ! -s "$dest_path" ]; then
        fail "Downloaded file is empty: $file_path"
    fi
}

# Main installation function
install_fixerr() {
    echo "Starting FixErr installation..."
    
    check_dependencies
    
    # Download required files
    download_file "bin/fixerr" "$TMP_DIR/bin/fixerr"
    download_file "src/llm/analyzer.py" "$TMP_DIR/src/llm/analyzer.py"
    
    # Set executable permission
    chmod +x "$TMP_DIR/bin/fixerr" || fail "Cannot set executable permissions"
    
    # Create installation directories
    sudo mkdir -p "$INSTALL_DIR" "$LIB_DIR" || fail "Cannot create installation directories"
    
    # Install main executable
    sudo install -m 755 "$TMP_DIR/bin/fixerr" "$INSTALL_DIR/" || fail "Failed to install main executable"
    
    # Install library files
    sudo cp -r "$TMP_DIR/src" "$LIB_DIR/" || fail "Failed to install library files"
    
    echo "Installation complete!"
    echo "You can now use: fixerr <your_script>"
    
    # Check if the command is in PATH
    if ! command -v fixerr >/dev/null 2>&1; then
        echo "Note: If 'fixerr' is not found, you may need to add /usr/local/bin to your PATH"
        echo "Try running: export PATH=\"/usr/local/bin:\$PATH\""
    fi
}

# Run the installation
install_fixerr