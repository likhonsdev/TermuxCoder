#!/usr/bin/env bash
#
# TermuxCoder Installation Script
# This script installs TermuxCoder and its dependencies.
#

set -e

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
PURPLE="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# Print colored text
print_color() {
    echo -e "${1}${2}${RESET}"
}

# Print section header
print_header() {
    print_color "$BLUE" "\n==== $1 ===="
}

# Print error and exit
die() {
    print_color "$RED" "ERROR: $1" >&2
    exit 1
}

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Get OS information
get_os() {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    else
        # Fall back to uname
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    
    # Detect Termux
    if command_exists termux-info; then
        OS="Termux"
        VER=$(termux-info | grep "Termux version" | cut -d":" -f2 | xargs)
    fi
}

# Install dependencies based on OS
install_dependencies() {
    print_header "Installing Dependencies"
    
    case $OS in
        Termux)
            print_color "$CYAN" "Installing Termux dependencies..."
            pkg update -y
            pkg install -y python curl jq git figlet lolcat
            pip install requests
            ;;
        Ubuntu|Debian|Mint|Pop|Kali)
            print_color "$CYAN" "Installing dependencies for $OS..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip curl jq git figlet lolcat
            pip3 install requests
            ;;
        Fedora|CentOS|RHEL)
            print_color "$CYAN" "Installing dependencies for $OS..."
            sudo dnf install -y python3 python3-pip curl jq git figlet
            sudo pip3 install lolcat requests
            ;;
        Arch|Manjaro)
            print_color "$CYAN" "Installing dependencies for $OS..."
            sudo pacman -Sy --noconfirm python python-pip curl jq git figlet
            sudo pip install lolcat requests
            ;;
        macOS|Darwin)
            print_color "$CYAN" "Installing dependencies for macOS..."
            if ! command_exists brew; then
                die "Homebrew is required but not installed. Please install Homebrew first: https://brew.sh"
            fi
            brew install python curl jq git figlet
            pip3 install lolcat requests
            ;;
        *)
            print_color "$YELLOW" "Unsupported OS: $OS. You may need to manually install the following dependencies:"
            echo "- Python 3"
            echo "- pip (Python package manager)"
            echo "- curl"
            echo "- jq"
            echo "- git"
            echo "- figlet (optional)"
            echo "- lolcat (optional)"
            echo "- requests (Python package)"
            ;;
    esac
    
    print_color "$GREEN" "✓ Dependencies installed successfully."
}

# Check for required dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing_deps=()
    
    # Check for required tools
    if ! command_exists python3 && ! command_exists python; then
        missing_deps+=("Python 3")
    fi
    
    if ! command_exists curl; then
        missing_deps+=("curl")
    fi
    
    if ! command_exists jq; then
        missing_deps+=("jq")
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_color "$YELLOW" "Missing dependencies: ${missing_deps[*]}"
        # Get OS information
        get_os
        print_color "$CYAN" "Detected OS: $OS $VER"
        
        # Ask to install dependencies
        read -p "Do you want to install missing dependencies? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_dependencies
        else
            die "Cannot continue without required dependencies. Please install them manually."
        fi
    else
        print_color "$GREEN" "✓ All required dependencies are installed."
        
        # Check for optional dependencies
        if ! command_exists figlet; then
            print_color "$YELLOW" "Optional: figlet is not installed. It's used for fancy headers."
        fi
        
        if ! command_exists lolcat; then
            print_color "$YELLOW" "Optional: lolcat is not installed. It's used for colorful output."
        fi
    fi
    
    # Check for Python requests module
    if python3 -c "import requests" 2>/dev/null || python -c "import requests" 2>/dev/null; then
        print_color "$GREEN" "✓ Python requests module is installed."
    else
        print_color "$YELLOW" "Python requests module is missing."
        read -p "Do you want to install it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command_exists pip3; then
                pip3 install requests
            elif command_exists pip; then
                pip install requests
            else
                die "Cannot install 'requests' module. pip is not available."
            fi
        else
            die "Cannot continue without required Python module 'requests'."
        fi
    fi
}

# Clone repository
clone_repo() {
    print_header "Installing TermuxCoder"
    
    # Determine installation directory
    if [ "$OS" = "Termux" ]; then
        INSTALL_DIR="$HOME/TermuxCoder"
    else
        INSTALL_DIR="$HOME/.termuxcoder"
    fi
    
    # Check if directory already exists
    if [ -d "$INSTALL_DIR" ]; then
        print_color "$YELLOW" "TermuxCoder is already installed at $INSTALL_DIR"
        read -p "Do you want to update it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cd "$INSTALL_DIR"
            if [ -d ".git" ]; then
                print_color "$CYAN" "Updating from git repository..."
                git pull
            else
                print_color "$YELLOW" "Not a git repository. Reinstalling..."
                cd ..
                rm -rf "$INSTALL_DIR"
                git clone https://github.com/likhonsdev/TermuxCoder.git "$INSTALL_DIR"
            fi
        else
            print_color "$CYAN" "Keeping existing installation."
        fi
    else
        print_color "$CYAN" "Cloning TermuxCoder repository..."
        git clone https://github.com/likhonsdev/TermuxCoder.git "$INSTALL_DIR"
    fi
    
    # Make scripts executable
    cd "$INSTALL_DIR"
    chmod +x termuxcoder.sh
    chmod +x bin/*.sh
    
    print_color "$GREEN" "✓ TermuxCoder installed successfully at $INSTALL_DIR"
}

# Set up symlink to PATH
setup_path() {
    print_header "Setting up PATH"
    
    # Determine binary directory
    if [ "$OS" = "Termux" ]; then
        BIN_DIR="$PREFIX/bin"
    else
        BIN_DIR="$HOME/.local/bin"
        mkdir -p "$BIN_DIR"
    fi
    
    # Create symlink
    SYMLINK="$BIN_DIR/termuxcoder"
    ln -sf "$INSTALL_DIR/termuxcoder.sh" "$SYMLINK"
    chmod +x "$SYMLINK"
    
    print_color "$GREEN" "✓ Created symlink at $SYMLINK"
    
    # Check if BIN_DIR is in PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_color "$YELLOW" "$BIN_DIR is not in your PATH. You may need to add it manually."
        
        # Determine shell rc file
        RC_FILE=""
        if [ -f "$HOME/.bashrc" ]; then
            RC_FILE="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            RC_FILE="$HOME/.zshrc"
        fi
        
        if [ -n "$RC_FILE" ]; then
            read -p "Do you want to add $BIN_DIR to your PATH in $RC_FILE? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$RC_FILE"
                print_color "$GREEN" "✓ Added $BIN_DIR to PATH in $RC_FILE"
                print_color "$YELLOW" "Please restart your terminal or run 'source $RC_FILE' to apply the changes."
            fi
        fi
    else
        print_color "$GREEN" "✓ $BIN_DIR is already in your PATH."
    fi
}

# Configure API key
configure_api_key() {
    print_header "Configuration"
    
    read -p "Do you want to configure your Google AI Studio API key now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        "$INSTALL_DIR/termuxcoder.sh" setup
    else
        print_color "$YELLOW" "You can set up your API key later by running 'termuxcoder setup'."
    fi
}

# Display completion message
completion_message() {
    print_header "Installation Complete"
    
    print_color "$GREEN" "TermuxCoder has been successfully installed!"
    print_color "$CYAN" "To get started, run: termuxcoder help"
    
    if [ "$OS" = "Termux" ]; then
        echo "
Examples:
    termuxcoder ask \"Write a Python script to download YouTube videos\"
    termuxcoder plan \"Create a Flutter app for expense tracking\"
    termuxcoder fix buggy_code.py
        "
    fi
    
    print_color "$YELLOW" "Note: If termuxcoder command is not found, you may need to restart your terminal or add $BIN_DIR to your PATH."
}

# Main installation process
main() {
    print_color "$BOLD$CYAN" "
 _____                               _____          _           
|_   _|                             / ____|        | |          
  | | ___ _ __ _ __ ___  _   ___  _| |     ___   __| | ___ _ __ 
  | |/ _ \\ '__| '_ \` _ \\| | | \\ \\/ / |    / _ \\ / _\` |/ _ \\ '__|
  | |  __/ |  | | | | | | |_| |>  <| |___| (_) | (_| |  __/ |   
  |_|\\___|_|  |_| |_| |_|\\__,_/_/\\_\\\\_____\\___/ \\__,_|\\___|_|   
                                                                 
    "
    print_color "$BOLD" "Gemini-powered terminal AI coding assistant\n"
    
    # Get OS information
    get_os
    print_color "$CYAN" "Detected OS: $OS $VER"
    
    # Check dependencies
    check_dependencies
    
    # Clone repository
    clone_repo
    
    # Set up PATH
    setup_path
    
    # Configure API key
    configure_api_key
    
    # Show completion message
    completion_message
}

# Run the main function
main
