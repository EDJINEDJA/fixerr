#!/bin/sh
# FixErr Installation Script
# POSIX-compliant installer that works with any standard Unix shell
# Usage: curl -fsSL https://raw.githubusercontent.com/oblo/fixerr/main/install.sh | sh

set -e  # Exit immediately if any command fails

# ----------------------------
# CONFIGURATION (MODIFY THESE IF NEEDED)
# ----------------------------
REPO_OWNER="EDJINEDJA"           # GitHub username or organization name
REPO_NAME="fixerr"          # Repository name
BRANCH="main"               # Branch containing the installation files
INSTALL_DIR="/usr/local/bin" # Where to install the main executable
LIB_DIR="/usr/local/lib/fixerr" # Where to install library files

# ----------------------------
# INITIALIZATION
# ----------------------------

# Create secure temporary directory (works on both Linux and BSD)
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
    echo "1. Verify the repository exists: https://github.com/$REPO_OWNER/$REPO_NAME" >&2
    echo "2. Check the files exist in the $BRANCH branch:" >&2
    echo "   - bin/fixerr" >&2
    echo "   - src/llm/analyzer.py" >&2
    echo "3. Ensure the repository is public" >&2
    exit 1
}

# ----------------------------
# DEPENDENCY CHECKS
# ----------------------------

# Verify system has required tools installed
check_dependencies() {
    # Check for curl (required for downloads)
    if ! command -v curl >/dev/null 2>&1; then
        fail "curl is required but not found. Please install curl first:
        Linux: sudo apt-get install curl
        macOS: brew install curl"
    fi

    # Check for git (we'll use it for reliable cloning)
    if ! command -v git >/dev/null 2>&1; then
        fail "git is required but not found. Please install git first"
    fi

    # Check for sudo unless running as root
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
        fail "sudo is required for installation"
    fi
}

# ----------------------------
# FILE DOWNLOAD
# ----------------------------

# Clone repository securely instead of using raw downloads
clone_repository() {
    echo "Cloning FixErr repository..."
    if ! git clone -b "$BRANCH" --depth 1 \
        "https://github.com/$REPO_OWNER/$REPO_NAME.git" "$TMP_DIR" 2>/dev/null; then
        fail "Failed to clone repository. Check:
        - Repository exists: https://github.com/$REPO_OWNER/$REPO_NAME
        - Branch '$BRANCH' exists
        - Network connectivity"
    fi
}

# Verify required files exist
verify_files() {
    echo "Verifying installation files..."
    
    # List of required files with relative paths
    REQUIRED_FILES="bin/fixerr src/llm/analyzer.py"
    
    for file in $REQUIRED_FILES; do
        if [ ! -f "$TMP_DIR/$file" ]; then
            fail "Missing required file: $file
            Expected path in repository: $file"
        fi
        
        # Special check for main executable
        if [ "$file" = "bin/fixerr" ]; then
            if [ ! -x "$TMP_DIR/$file" ]; then
                fail "Main executable is not executable: $file
                Run: chmod +x $file"
            fi
        fi
    done
}

# ----------------------------
# INSTALLATION
# ----------------------------

perform_installation() {
    echo "Installing FixErr..."
    
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
    
    # Set correct permissions for library files
    if ! sudo find "$LIB_DIR" -type f -exec chmod 644 {} \;; then
        echo "WARNING: Could not set library file permissions" >&2
    fi
}

# ----------------------------
# POST-INSTALLATION VERIFICATION
# ----------------------------

verify_installation() {
    echo "Verifying installation..."
    
    # Check main executable is in PATH
    if ! command -v fixerr >/dev/null 2>&1; then
        echo "WARNING: 'fixerr' command not found in PATH" >&2
        echo "You may need to add /usr/local/bin to your PATH:" >&2
        echo "  export PATH=\"/usr/local/bin:\$PATH\"" >&2
    else
        echo "SUCCESS: FixErr installed successfully!"
        echo "Try it with: fixerr <your_script>"
    fi
}

# ----------------------------
# MAIN INSTALLATION FLOW
# ----------------------------

main() {
    echo "Starting FixErr installation..."
    
    check_dependencies
    clone_repository
    verify_files
    perform_installation
    verify_installation
}

main