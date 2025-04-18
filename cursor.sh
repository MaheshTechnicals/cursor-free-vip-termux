#!/bin/bash
################################################################################
#                                                                              #
#         🚀 Cursor AI Editor Installer & Uninstaller 🚀                        #
#                                                                              #
#                  ✨ Author: Mahesh Technicals ✨                              #
#                  🌟 Version: 3.0                                            #
#                  📌 Modern & Stylish UI with Error Handling                  #
#                                                                              #
################################################################################

# Define variables
APP_NAME="Cursor"
APP_VERSION="0.48.6"  # Default version, will be updated by fetch_download_urls
ARCH=$(uname -m)
APPIMAGE_URL=""
VERSION_JSON_URL="https://raw.githubusercontent.com/oslook/cursor-ai-downloads/refs/heads/main/version-history.json"

# Initialize default URLs based on architecture (these will be updated later)
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
elif [[ "$ARCH" == "x86_64" ]]; then
    APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
else
    echo -e "\e[31m[ERROR] Unsupported architecture: $ARCH\e[0m"
    # We'll handle this properly later
fi

# Determine the actual user's home directory even when run with sudo
if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
    ACTUAL_HOME=$(eval echo ~$SUDO_USER)
else
    ACTUAL_HOME=$HOME
fi

INSTALL_DIR="/opt/cursor"
DESKTOP_FILE="/usr/share/applications/cursor.desktop"
SYMLINK_PATH="/usr/local/bin/cursor"
TEMP_DIR="/tmp/cursor-installer"
CONFIG_FILE="$ACTUAL_HOME/.config/Cursor/User/globalStorage/storage.json"

# Colors for UI feedback
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BLUE="\e[34m"
MAGENTA="\e[35m"
BOLD="\e[1m"
RESET="\e[0m"

# Function to print text without centering
print_text() {
    echo -e "$1"
}

# Function to print a box aligned to the left
print_box() {
    local content=("$@")
    local max_length=0
    local line_length
    
    # Find the longest line
    for line in "${content[@]}"; do
        line_length=${#line}
        if [[ $line_length -gt $max_length ]]; then
            max_length=$line_length
        fi
    done
    
    # Add padding for box borders
    max_length=$((max_length + 8))
    
    # Create top border
    local top_border="${CYAN}${BOLD}╔"
    for ((i=0; i<max_length-2; i++)); do
        top_border+="═"
    done
    top_border+="╗${RESET}"
    
    # Create bottom border
    local bottom_border="${CYAN}${BOLD}╚"
    for ((i=0; i<max_length-2; i++)); do
        bottom_border+="═"
    done
    bottom_border+="╝${RESET}"
    
    # Print box
    echo -e "$top_border"
    
    for line in "${content[@]}"; do
        local padding=$((max_length - ${#line} - 2))
        local right_padding=$((padding / 2))
        local left_padding=$((padding - right_padding))
        
        local padded_line="${CYAN}${BOLD}║${RESET}"
        for ((i=0; i<left_padding; i++)); do
            padded_line+=" "
        done
        
        padded_line+="$line"
        
        for ((i=0; i<right_padding; i++)); do
            padded_line+=" "
        done
        padded_line+="${CYAN}${BOLD}║${RESET}"
        
        echo -e "$padded_line"
    done
    
    echo -e "$bottom_border"
}

# Function to check root permissions
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_text "${RED}${BOLD}[ERROR] This script requires root privileges.${RESET}"
        print_text "${YELLOW}Please run with: ${BOLD}sudo $0${RESET}"
        print_text "${YELLOW}Press Enter to continue...${RESET}"
        read -r
        return 1
    fi
    return 0
}

# Function to install missing dependencies
install_dependencies() {
    local missing_deps=("$@")
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        return 0
    fi
    
    print_text "${YELLOW}${BOLD}[INFO] Installing missing dependencies: ${missing_deps[*]}${RESET}"
    
    # Try to install dependencies with sudo if we're not already root
    local use_sudo=""
    if [[ $EUID -ne 0 ]]; then
        use_sudo="sudo"
        print_text "${YELLOW}${BOLD}[INFO] Not running as root, will use sudo for installations${RESET}"
    fi
    
    # Detect package manager
    if command -v apt &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using apt package manager...${RESET}"
        $use_sudo apt update -qq && $use_sudo apt install -y "${missing_deps[@]}"
    elif command -v apt-get &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using apt-get package manager...${RESET}"
        $use_sudo apt-get update -qq && $use_sudo apt-get install -y "${missing_deps[@]}"
    elif command -v dnf &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using dnf package manager...${RESET}"
        $use_sudo dnf install -y "${missing_deps[@]}"
    elif command -v yum &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using yum package manager...${RESET}"
        $use_sudo yum install -y "${missing_deps[@]}"
    elif command -v pacman &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using pacman package manager...${RESET}"
        $use_sudo pacman -Sy --noconfirm "${missing_deps[@]}"
    elif command -v zypper &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using zypper package manager...${RESET}"
        $use_sudo zypper install -y "${missing_deps[@]}"
    elif command -v pkg &> /dev/null; then 
        print_text "${BLUE}${BOLD}[INFO] Using pkg package manager (FreeBSD)...${RESET}"
        $use_sudo pkg install -y "${missing_deps[@]}"
    elif command -v apk &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using apk package manager (Alpine)...${RESET}"
        $use_sudo apk add "${missing_deps[@]}"
    elif command -v proot &> /dev/null || [[ -n "$ANDROID_ROOT" ]] || [[ -n "$TERMUX_VERSION" ]]; then
        # Special case for Termux/PRoot environments
        print_text "${BLUE}${BOLD}[INFO] Detected Termux/PRoot environment...${RESET}"
        if command -v pkg &> /dev/null; then
            # First update package lists
            pkg update
            # Install packages one by one to better handle errors
            for dep in "${missing_deps[@]}"; do
                print_text "${YELLOW}${BOLD}[INFO] Installing $dep...${RESET}"
                if ! pkg install -y "$dep"; then
                    # If jq fails to install with pkg, try with pip
                    if [[ "$dep" == "jq" ]]; then
                        print_text "${YELLOW}${BOLD}[INFO] Trying alternative installation method for jq...${RESET}"
                        pkg install -y python-pip
                        pip install jq
                    fi
                fi
            done
        elif command -v apt &> /dev/null; then
            apt update
            for dep in "${missing_deps[@]}"; do
                apt install -y "$dep"
                # If jq fails to install with apt, try with pip
                if [[ "$dep" == "jq" ]] && ! command -v jq &> /dev/null; then
                    print_text "${YELLOW}${BOLD}[INFO] Trying alternative installation method for jq...${RESET}"
                    apt install -y python-pip
                    pip install jq
                fi
            done
        else
            print_text "${RED}${BOLD}[ERROR] Could not find a suitable package manager in Termux.${RESET}"
            print_text "${YELLOW}Please install the following dependencies manually: ${missing_deps[*]}${RESET}"
            print_text "${YELLOW}Press Enter to continue...${RESET}"
            read -r
            return 1
        fi
    else
        print_text "${RED}${BOLD}[ERROR] Could not detect package manager. Please install the following dependencies manually: ${missing_deps[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] For most common distributions:${RESET}"
        print_text "       Debian/Ubuntu: ${BOLD}apt install ${missing_deps[*]}${RESET}"
        print_text "       Fedora/RHEL: ${BOLD}dnf install ${missing_deps[*]}${RESET}"
        print_text "       Arch Linux: ${BOLD}pacman -S ${missing_deps[*]}${RESET}"
        print_text "       Alpine: ${BOLD}apk add ${missing_deps[*]}${RESET}"
        print_text "${YELLOW}Press Enter to continue...${RESET}"
        read -r
        return 1
    fi
    
    # Verify installation
    local still_missing=()
    for dep in "${missing_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            still_missing+=("$dep")
        fi
    done
    
    if [[ ${#still_missing[@]} -gt 0 ]]; then
        print_text "${RED}${BOLD}[ERROR] Failed to install some dependencies: ${still_missing[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Attempting to install with alternative package names...${RESET}"
        
        # Second attempt with alternative package names
        local alt_packages=()
        for dep in "${still_missing[@]}"; do
            case "$dep" in
                jq)
                    if command -v apt &> /dev/null || command -v apt-get &> /dev/null; then
                        alt_packages+=("jq" "libjq1" "libjq-dev")
                    elif command -v dnf &> /dev/null || command -v yum &> /dev/null; then
                        alt_packages+=("jq" "jq-devel")
                    elif command -v pacman &> /dev/null; then
                        alt_packages+=("jq")
                    elif command -v apk &> /dev/null; then
                        alt_packages+=("jq")
                    else
                        alt_packages+=("jq")
                    fi
                    ;;
                wget)
                    alt_packages+=("wget" "wget2")
                    ;;
                *)
                    alt_packages+=("$dep")
                    ;;
            esac
        done
        
        # Try to install alternative packages
        if command -v apt &> /dev/null || command -v apt-get &> /dev/null; then
            $use_sudo apt install -y "${alt_packages[@]}" || $use_sudo apt-get install -y "${alt_packages[@]}"
        elif command -v dnf &> /dev/null; then
            $use_sudo dnf install -y "${alt_packages[@]}"
        elif command -v pacman &> /dev/null; then
            $use_sudo pacman -S --noconfirm "${alt_packages[@]}"
        fi
        
        # Re-check if still missing
        still_missing=()
        for dep in "${missing_deps[@]}"; do
            if ! command -v "$dep" &> /dev/null; then
                still_missing+=("$dep")
            fi
        done
        
        if [[ ${#still_missing[@]} -gt 0 ]]; then
            print_text "${RED}${BOLD}[ERROR] Still failed to install some dependencies: ${still_missing[*]}${RESET}"
            print_text "${YELLOW}Please install them manually and run the script again.${RESET}"
            print_text "${YELLOW}Press Enter to continue...${RESET}"
            read -r
            return 1
        fi
    fi
    
    print_text "${GREEN}${BOLD}[SUCCESS] All dependencies installed successfully!${RESET}"
    
    # Special verification for jq
    if ! command -v jq &> /dev/null; then
        print_text "${YELLOW}${BOLD}[WARNING] jq still not found after installation attempts.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Will try one more alternative method...${RESET}"
        
        # Try to install jq via npm if node is available
        if command -v node &> /dev/null || command -v nodejs &> /dev/null; then
            if command -v npm &> /dev/null; then
                print_text "${BLUE}${BOLD}[INFO] Attempting to install jq via npm...${RESET}"
                $use_sudo npm install -g node-jq
                # Create a symlink if node-jq was installed but jq command is not available
                if [ -f "$(npm root -g)/node-jq/bin/jq" ] && ! command -v jq &> /dev/null; then
                    $use_sudo ln -sf "$(npm root -g)/node-jq/bin/jq" /usr/local/bin/jq
                fi
            fi
        # Try to install via pip if python is available
        elif command -v python3 &> /dev/null || command -v python &> /dev/null; then
            if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
                print_text "${BLUE}${BOLD}[INFO] Attempting to install jq via pip...${RESET}"
                $use_sudo pip install jq || $use_sudo pip3 install jq
            fi
        fi
        
        # Final check if jq is available
        if ! command -v jq &> /dev/null; then
            print_text "${YELLOW}${BOLD}[WARNING] Could not install jq automatically.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] The script will continue, but some features may not work properly.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] For better functionality, please install jq manually later.${RESET}"
        else
            print_text "${GREEN}${BOLD}[SUCCESS] Successfully installed jq using alternative method!${RESET}"
        fi
    fi
    
    return 0
}

# Function to check dependencies
check_dependencies() {
    local deps=("wget" "grep" "sed" "awk" "jq")
    local optional_deps=("xxd" "python3" "curl")
    local missing_deps=()
    local missing_optional=()
    
    print_text "${YELLOW}${BOLD}[INFO] Checking dependencies...${RESET}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_optional+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_text "${RED}${BOLD}[ERROR] Missing required dependencies: ${missing_deps[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Please install them using your package manager.${RESET}"
        print_text "       For Debian/Ubuntu: ${BOLD}apt install ${missing_deps[*]}${RESET}"
        print_text "       For Fedora/RHEL: ${BOLD}dnf install ${missing_deps[*]}${RESET}"
        print_text "       For Arch Linux: ${BOLD}pacman -S ${missing_deps[*]}${RESET}"
        return 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_text "${YELLOW}${BOLD}[WARNING] Some optional dependencies are missing: ${missing_optional[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] These are not required but recommended for better functionality:${RESET}"
        print_text "       For Debian/Ubuntu: ${BOLD}apt install ${missing_optional[*]}${RESET}"
    fi
    
    print_text "${GREEN}${BOLD}[SUCCESS] All required dependencies are satisfied!${RESET}"
    return 0
}

# Enhanced check_dependencies function that returns the missing dependencies for auto-install
check_and_get_missing_dependencies() {
    local deps=("wget" "grep" "sed" "awk" "jq")
    local optional_deps=("xxd" "python3" "curl")
    local missing_deps=()
    local missing_optional=()
    
    print_text "${YELLOW}${BOLD}[INFO] Checking dependencies...${RESET}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_optional+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_text "${YELLOW}${BOLD}[INFO] Missing required dependencies: ${missing_deps[*]}${RESET}"
        print_text "${BLUE}${BOLD}[INFO] Will attempt to install automatically...${RESET}"
        echo "${missing_deps[@]}"
        return 1
    fi
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_text "${YELLOW}${BOLD}[WARNING] Some optional dependencies are missing: ${missing_optional[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] These are recommended but not required. They will not be installed automatically.${RESET}"
        # Skipping prompt for optional dependencies to avoid blocking the installation
        # echo "${missing_optional[@]}"
        # return 2
    fi
    
    print_text "${GREEN}${BOLD}[SUCCESS] All required dependencies are satisfied!${RESET}"
    return 0
}

# Function to display stylish header
display_header() {
    clear
    local content=(
        ""
        "${CYAN}${BOLD}Cursor AI Editor${RESET}"
        "${CYAN}${BOLD}Installation & Management${RESET}"
        ""
        "${CYAN}${BOLD}by Mahesh Technicals${RESET}"
        "${CYAN}${BOLD}Version 3.0${RESET}"
        ""
    )
    
    print_box "${content[@]}"
    echo
}

# Function to create temporary directory
create_temp_dir() {
    print_text "${YELLOW}${BOLD}[INFO] Creating temporary directory...${RESET}"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR" || {
        print_text "${RED}${BOLD}[ERROR] Failed to create or access temporary directory.${RESET}"
        return 1
    }
    return 0
}

# Function to clean up temporary files
cleanup() {
    print_text "${YELLOW}${BOLD}[INFO] Cleaning up temporary files...${RESET}"
    cd / || true
    rm -rf "$TEMP_DIR"
}

# Function to check if Cursor is already installed
check_installation() {
    if [[ -d "$INSTALL_DIR" ]]; then
        print_text "${YELLOW}${BOLD}[WARNING] Cursor is already installed at $INSTALL_DIR${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Would you like to reinstall? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            print_text "${YELLOW}${BOLD}[INFO] Installation aborted.${RESET}"
            return 1
        fi
        print_text "${YELLOW}${BOLD}[INFO] Removing existing installation...${RESET}"
        rm -rf "$INSTALL_DIR"
    fi
    return 0
}

# Function to show progress animation
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    
    echo -n ""
    
    while ps -p "$pid" &> /dev/null; do
        local temp=${spinstr#?}
        printf " ${CYAN}${BOLD}[%c]${RESET}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b"
    done
    printf "         \b\b\b\b\b\b\b\b\b"
}

# Function to fetch latest version and download URLs
fetch_download_urls() {
    print_text "${YELLOW}${BOLD}[INFO] Fetching latest version information...${RESET}"
    
    # Check if curl or wget is available
    if command -v curl &> /dev/null; then
        local response=$(curl -s --connect-timeout 10 --max-time 15 "$VERSION_JSON_URL")
    elif command -v wget &> /dev/null; then
        local response=$(wget --timeout=10 --tries=2 -qO- "$VERSION_JSON_URL")
    else
        print_text "${RED}${BOLD}[ERROR] Neither curl nor wget is available. Please install one of them.${RESET}"
        # Use default values instead of exiting
        APP_VERSION="0.48.6"
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
        elif [[ "$ARCH" == "x86_64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
        else
            print_text "${RED}${BOLD}[ERROR] Unsupported architecture: $ARCH${RESET}"
            return 1
        fi
        return 0
    fi
    
    # Check if we got a valid response
    if [[ -z "$response" ]]; then
        print_text "${RED}${BOLD}[ERROR] Failed to get a response from version server.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Falling back to default version...${RESET}"
        APP_VERSION="0.48.6"
        
        # Set architecture-specific URL (fallback)
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
        elif [[ "$ARCH" == "x86_64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
        fi
        return 0
    fi
    
    # Check if jq is available for JSON parsing
    if command -v jq &> /dev/null; then
        # Parse JSON using jq
        APP_VERSION=$(echo "$response" | jq -r '.versions[0].version')
        local linux_arm64_url=$(echo "$response" | jq -r '.versions[0].platforms["linux-arm64"]')
        local linux_x64_url=$(echo "$response" | jq -r '.versions[0].platforms["linux-x64"]')
        
        # Set architecture-specific URL
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            APPIMAGE_URL="$linux_arm64_url"
        elif [[ "$ARCH" == "x86_64" ]]; then
            APPIMAGE_URL="$linux_x64_url"
        else
            print_text "${RED}${BOLD}[ERROR] Unsupported architecture: $ARCH${RESET}"
            # Use default values
            APP_VERSION="0.48.6"
            if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
                APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
            elif [[ "$ARCH" == "x86_64" ]]; then
                APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
            fi
            return 1
        fi
    else
        # Fallback to grep and sed if jq is not available
        print_text "${YELLOW}${BOLD}[WARNING] jq not found. Using fallback method for JSON parsing.${RESET}"
        APP_VERSION=$(echo "$response" | grep -o '"version":"[^"]*"' | head -1 | sed 's/"version":"//;s/"//')
        
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            APPIMAGE_URL=$(echo "$response" | grep -o '"linux-arm64":"[^"]*"' | head -1 | sed 's/"linux-arm64":"//;s/"//')
        elif [[ "$ARCH" == "x86_64" ]]; then
            APPIMAGE_URL=$(echo "$response" | grep -o '"linux-x64":"[^"]*"' | head -1 | sed 's/"linux-x64":"//;s/"//')
        else
            print_text "${RED}${BOLD}[ERROR] Unsupported architecture: $ARCH${RESET}"
            # Use default values
            APP_VERSION="0.48.6"
            if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
                APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
            elif [[ "$ARCH" == "x86_64" ]]; then
                APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
            fi
            return 1
        fi
    fi
    
    # Verify that we got valid values
    if [[ -z "$APP_VERSION" || -z "$APPIMAGE_URL" ]]; then
        print_text "${RED}${BOLD}[ERROR] Failed to fetch version information.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Falling back to default version...${RESET}"
        APP_VERSION="0.48.6"
        
        # Set architecture-specific URL (fallback)
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/arm64/Cursor-${APP_VERSION}-aarch64.AppImage"
        elif [[ "$ARCH" == "x86_64" ]]; then
            APPIMAGE_URL="https://downloads.cursor.com/production/1649e229afdef8fd1d18ea173f063563f1e722ef/linux/x64/Cursor-${APP_VERSION}-x86_64.AppImage"
        fi
    else
        print_text "${GREEN}${BOLD}[SUCCESS] Found latest version: ${APP_VERSION}${RESET}"
    fi
    
    return 0
}

# Function to install Cursor
install_cursor() {
    display_header
    
    # Define sudo usage if not running as root
    local use_sudo=""
    if [[ $EUID -ne 0 ]]; then
        use_sudo="sudo"
        print_text "${YELLOW}${BOLD}[INFO] Not running as root, will use sudo for installations${RESET}"
    fi
    
    # Check for missing dependencies first
    print_text "${YELLOW}${BOLD}[INFO] Checking for dependencies...${RESET}"
    local deps=("wget" "grep" "sed" "awk" "jq")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        # Install required missing dependencies
        print_text "${YELLOW}${BOLD}[INFO] Installing required dependencies: ${missing_deps[*]}${RESET}"
        if ! install_dependencies "${missing_deps[@]}"; then
            print_text "${RED}${BOLD}[ERROR] Failed to install required dependencies. Installation aborted.${RESET}"
            print_text "${YELLOW}Please install them manually and try again.${RESET}"
            print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
            read -r
            return 1
        fi
    fi
    
    # Also check for optional dependencies and install them
    print_text "${YELLOW}${BOLD}[INFO] Checking for optional dependencies...${RESET}"
    local optional_deps=("xxd" "python3" "curl")
    local missing_optional=()
    
    for dep in "${optional_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_optional+=("$dep")
        fi
    done
    
    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_text "${YELLOW}${BOLD}[INFO] Installing optional dependencies: ${missing_optional[*]}${RESET}"
        install_dependencies "${missing_optional[@]}"
        # Continue even if optional dependencies fail
    fi
    
    # After all dependencies are installed, check specifically for jq
    if ! command -v jq &> /dev/null; then
        print_text "${YELLOW}${BOLD}[INFO] jq installation not detected. Trying direct installation methods...${RESET}"
        
        # Try different methods based on detected package managers
        if command -v apt &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using apt package manager...${RESET}"
            $use_sudo apt update && $use_sudo apt install -y jq
        elif command -v apt-get &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using apt-get package manager...${RESET}"
            $use_sudo apt-get update && $use_sudo apt-get install -y jq
        elif command -v dnf &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using dnf package manager...${RESET}"
            $use_sudo dnf install -y jq
        elif command -v yum &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using yum package manager...${RESET}"
            $use_sudo yum install -y jq
        elif command -v pacman &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using pacman package manager...${RESET}"
            $use_sudo pacman -Sy --noconfirm jq
        elif command -v pkg &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using pkg package manager...${RESET}"
            pkg update && pkg install -y jq
        elif command -v apk &> /dev/null; then
            print_text "${BLUE}${BOLD}[INFO] Using apk package manager...${RESET}"
            $use_sudo apk add jq
        else
            # Fallback to manual method for Termux PRoot
            if [[ -d "/data/data/com.termux" ]] || [[ -n "$TERMUX_VERSION" ]]; then
                print_text "${BLUE}${BOLD}[INFO] Detected Termux environment...${RESET}"
                pkg update && pkg install -y jq || {
                    apt update && apt install -y jq
                }
                
                # If still not installed, try downloading a pre-built binary
                if ! command -v jq &> /dev/null; then
                    print_text "${YELLOW}${BOLD}[INFO] Package installation failed. Trying to download pre-built binary...${RESET}"
                    
                    # Create bin directory if it doesn't exist
                    mkdir -p "$HOME/bin"
                    
                    # Download pre-built jq binary for ARM
                    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
                        wget -q --timeout=30 --tries=3 -O "$HOME/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux-arm64" || \
                        curl -L --connect-timeout 30 -o "$HOME/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux-arm64"
                    else # Assume x86_64
                        wget -q --timeout=30 --tries=3 -O "$HOME/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64" || \
                        curl -L --connect-timeout 30 -o "$HOME/bin/jq" "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
                    fi
                    
                    # Make it executable
                    chmod +x "$HOME/bin/jq"
                    
                    # Add to PATH if not already there
                    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
                        export PATH="$HOME/bin:$PATH"
                    fi
                    
                    # Create .bashrc if it doesn't exist
                    if [ ! -f "$HOME/.bashrc" ]; then
                        touch "$HOME/.bashrc"
                    fi
                    
                    # Add to .bashrc if not already there
                    if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.bashrc"; then
                        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
                    fi
                fi
            fi
        fi
        
        # Check if jq is now available
        if ! command -v jq &> /dev/null; then
            print_text "${YELLOW}${BOLD}[WARNING] Could not install jq automatically.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] The script will continue, but some features may not work properly.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] Please install jq manually using your package manager.${RESET}"
        else
            print_text "${GREEN}${BOLD}[SUCCESS] Successfully installed jq!${RESET}"
        fi
    fi
    
    # After all dependencies are installed, proceed with installation
    print_text "${GREEN}${BOLD}[SUCCESS] All dependencies are satisfied. Proceeding with installation...${RESET}"
    
    check_installation
    if [ $? -eq 1 ]; then
        return
    fi
    create_temp_dir
    
    # Fetch latest version and download URLs
    fetch_download_urls
    
    print_text "${BLUE}${BOLD}[1/4]${RESET} ${YELLOW}Downloading Cursor AI Editor v${APP_VERSION} for ${ARCH}...${RESET}"
    wget -q --timeout=30 --tries=3 --show-progress -O Cursor.AppImage "$APPIMAGE_URL" || {
        print_text "${RED}${BOLD}[ERROR] Download failed. Please check your internet connection.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] You can try downloading the file manually from:${RESET}"
        print_text "${CYAN}$APPIMAGE_URL${RESET}"
        cleanup
        return 1
    }
    
    print_text "${BLUE}${BOLD}[2/4]${RESET} ${YELLOW}Making AppImage executable...${RESET}"
    chmod +x Cursor.AppImage || {
        print_text "${RED}${BOLD}[ERROR] Failed to set executable permissions.${RESET}"
        cleanup
        return
    }
    
    print_text "${BLUE}${BOLD}[3/4]${RESET} ${YELLOW}Extracting AppImage...${RESET}"
    ./Cursor.AppImage --appimage-extract > /dev/null 2>&1 &
    extraction_pid=$!
    
    # Add a timeout for extraction (120 seconds)
    local timeout=120
    local start_time=$(date +%s)
    local current_time=0
    local elapsed_time=0
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    
    echo -n ""
    
    while ps -p "$extraction_pid" &> /dev/null; do
        local temp=${spinstr#?}
        printf " ${CYAN}${BOLD}[%c]${RESET}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b"
        
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -gt $timeout ]; then
            print_text "${RED}${BOLD}[ERROR] Extraction timed out after $timeout seconds.${RESET}"
            kill -9 $extraction_pid 2>/dev/null || true
            cleanup
            return 1
        fi
    done
    printf "         \b\b\b\b\b\b\b\b\b"
    
    if [[ ! -d "squashfs-root" ]]; then
        print_text "${RED}${BOLD}[ERROR] Extraction failed.${RESET}"
        cleanup
        return 1
    fi
    
    print_text "${BLUE}${BOLD}[4/4]${RESET} ${YELLOW}Installing Cursor system-wide...${RESET}"
    mkdir -p "$INSTALL_DIR"
    cp -r squashfs-root/* "$INSTALL_DIR/" || {
        print_text "${RED}${BOLD}[ERROR] Failed to copy files to installation directory.${RESET}"
        cleanup
        return
    }
    
    # Create symbolic link
    ln -sf "$INSTALL_DIR/AppRun" "$SYMLINK_PATH" || {
        print_text "${RED}${BOLD}[WARNING] Failed to create symbolic link. You may need to run Cursor using full path.${RESET}"
    }
    
    # Create desktop entry
    print_text "${YELLOW}${BOLD}[INFO] Creating desktop shortcut...${RESET}"
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Cursor
Comment=The AI-powered Code Editor
GenericName=Text Editor
Exec=cursor --no-sandbox %F
Icon=$INSTALL_DIR/co.anysphere.cursor.png
Type=Application
StartupNotify=true
StartupWMClass=Cursor
Categories=TextEditor;Development;IDE;Utility;
MimeType=text/plain;application/x-cursor-workspace;
Actions=new-empty-window;
Keywords=cursor;code;editor;programming;developer;ai;
X-AppImage-Version=$APP_VERSION

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=cursor --no-sandbox --new-window %F
Icon=$INSTALL_DIR/co.anysphere.cursor.png
EOF
    
    chmod +x "$INSTALL_DIR/AppRun"
    chmod +x "$DESKTOP_FILE"
    update-desktop-database &> /dev/null || true
    
    cleanup
    
    # Installation complete
    echo
    print_text "${GREEN}${BOLD}Cursor AI Editor v${APP_VERSION} installed successfully!${RESET}"
    
    local completion_content=(
        ""
        "${MAGENTA}${BOLD}INSTALLATION COMPLETE${RESET}"
        ""
    )
    print_box "${completion_content[@]}"
    
    echo
    print_text "${CYAN}[INFO] You can launch Cursor:${RESET}"
    print_text "  ${BOLD}• From application menu:${RESET} Search for 'Cursor'"
    print_text "  ${BOLD}• From terminal:${RESET} Run ${BOLD}cursor --no-sandbox${RESET}"
    echo
    print_text "${YELLOW}Note: The --no-sandbox flag is required for running as root.${RESET}"
    print_text "${YELLOW}For better security, consider running as non-root user.${RESET}"
}

# Function to check if Cursor is installed
is_cursor_installed() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_text "${RED}${BOLD}[ERROR] Cursor is not installed on this system.${RESET}"
        return 1
    fi
    return 0
}

# Function to uninstall Cursor
uninstall_cursor() {
    display_header
    
    if ! is_cursor_installed; then
        print_text "${YELLOW}${BOLD}[INFO] Would you like to force removal of any residual files? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return
        fi
    else
        print_text "${RED}${BOLD}WARNING: Uninstalling Cursor AI Editor${RESET}"
        print_text "${YELLOW}This will remove Cursor and all its data from your system.${RESET}"
        print_text "${YELLOW}${BOLD}Are you sure you want to continue? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            print_text "${YELLOW}${BOLD}[INFO] Uninstallation aborted.${RESET}"
            return
        fi
    fi
    
    print_text "${BLUE}${BOLD}[1/3]${RESET} ${YELLOW}Removing installation directory...${RESET}"
    rm -rf "$INSTALL_DIR"
    
    print_text "${BLUE}${BOLD}[2/3]${RESET} ${YELLOW}Removing symbolic link...${RESET}"
    rm -f "$SYMLINK_PATH"
    
    print_text "${BLUE}${BOLD}[3/3]${RESET} ${YELLOW}Removing desktop shortcut...${RESET}"
    rm -f "$DESKTOP_FILE"
    update-desktop-database &> /dev/null || true
    
    echo
    print_text "${GREEN}${BOLD}Cursor AI Editor has been successfully removed!${RESET}"
    
    local uninstall_content=(
        ""
        "${MAGENTA}${BOLD}UNINSTALLATION COMPLETE${RESET}"
        ""
    )
    print_box "${uninstall_content[@]}"
}

# Function to update Cursor
update_cursor() {
    display_header
    
    if ! is_cursor_installed; then
        print_text "${YELLOW}${BOLD}[INFO] Would you like to install Cursor instead? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_cursor
        fi
        return
    fi
    
    print_text "${YELLOW}${BOLD}[INFO] Checking for updates...${RESET}"
    
    # Fetch latest version info
    fetch_download_urls
    
    # Get installed version
    local installed_version=""
    if [[ -f "$INSTALL_DIR/version" ]]; then
        installed_version=$(cat "$INSTALL_DIR/version" 2>/dev/null)
    else
        installed_version=$(grep -oP 'X-AppImage-Version=\K.*' "$DESKTOP_FILE" 2>/dev/null || echo "unknown")
    fi
    
    print_text "${CYAN}${BOLD}[INFO] Installed version: ${BOLD}$installed_version${RESET}"
    print_text "${CYAN}${BOLD}[INFO] Latest version: ${BOLD}$APP_VERSION${RESET}"
    
    if [[ "$installed_version" == "$APP_VERSION" ]]; then
        print_text "${GREEN}${BOLD}[SUCCESS] You already have the latest version installed!${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Would you like to reinstall anyway? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            return
        fi
    fi
    
    # Directly install the latest version (overwrite existing installation)
    print_text "${YELLOW}${BOLD}[INFO] Updating Cursor AI Editor from v$installed_version to v$APP_VERSION...${RESET}"
    
    # Create temporary directory for downloading new version
    create_temp_dir || return 1
    
    print_text "${BLUE}${BOLD}[1/4]${RESET} ${YELLOW}Downloading Cursor AI Editor v${APP_VERSION} for ${ARCH}...${RESET}"
    wget -q --timeout=30 --tries=3 --show-progress -O Cursor.AppImage "$APPIMAGE_URL" || {
        print_text "${RED}${BOLD}[ERROR] Download failed. Please check your internet connection.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] You can try downloading the file manually from:${RESET}"
        print_text "${CYAN}$APPIMAGE_URL${RESET}"
        cleanup
        return 1
    }
    
    print_text "${BLUE}${BOLD}[2/4]${RESET} ${YELLOW}Making AppImage executable...${RESET}"
    chmod +x Cursor.AppImage || {
        print_text "${RED}${BOLD}[ERROR] Failed to set executable permissions.${RESET}"
        cleanup
        return 1
    }
    
    print_text "${BLUE}${BOLD}[3/4]${RESET} ${YELLOW}Extracting AppImage...${RESET}"
    ./Cursor.AppImage --appimage-extract > /dev/null 2>&1 &
    extraction_pid=$!
    
    # Add a timeout for extraction (120 seconds)
    local timeout=120
    local start_time=$(date +%s)
    local current_time=0
    local elapsed_time=0
    local delay=0.1
    local spinstr='⣾⣽⣻⢿⡿⣟⣯⣷'
    
    echo -n ""
    
    while ps -p "$extraction_pid" &> /dev/null; do
        local temp=${spinstr#?}
        printf " ${CYAN}${BOLD}[%c]${RESET}  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b\b\b\b"
        
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        
        if [ $elapsed_time -gt $timeout ]; then
            print_text "${RED}${BOLD}[ERROR] Extraction timed out after $timeout seconds.${RESET}"
            kill -9 $extraction_pid 2>/dev/null || true
            cleanup
            return 1
        fi
    done
    printf "         \b\b\b\b\b\b\b\b\b"
    
    if [[ ! -d "squashfs-root" ]]; then
        print_text "${RED}${BOLD}[ERROR] Extraction failed.${RESET}"
        cleanup
        return 1
    fi
    
    print_text "${BLUE}${BOLD}[4/4]${RESET} ${YELLOW}Installing new version...${RESET}"
    
    # Backup existing desktop file if it has custom modifications
    if [[ -f "$DESKTOP_FILE" ]]; then
        cp "$DESKTOP_FILE" "$DESKTOP_FILE.bak" 2>/dev/null
    fi
    
    # Replace installation files
    rm -rf "$INSTALL_DIR"/* || {
        print_text "${RED}${BOLD}[ERROR] Could not clean installation directory. Check permissions.${RESET}"
        cleanup
        return 1
    }
    
    cp -r squashfs-root/* "$INSTALL_DIR/" || {
        print_text "${RED}${BOLD}[ERROR] Failed to copy files to installation directory.${RESET}"
        cleanup
        return 1
    }
    
    # Ensure the symbolic link is updated
    ln -sf "$INSTALL_DIR/AppRun" "$SYMLINK_PATH" || {
        print_text "${RED}${BOLD}[WARNING] Failed to update symbolic link.${RESET}"
    }
    
    # Update desktop entry
    print_text "${YELLOW}${BOLD}[INFO] Updating desktop shortcut...${RESET}"
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=Cursor
Comment=The AI-powered Code Editor
GenericName=Text Editor
Exec=cursor --no-sandbox %F
Icon=$INSTALL_DIR/co.anysphere.cursor.png
Type=Application
StartupNotify=true
StartupWMClass=Cursor
Categories=TextEditor;Development;IDE;Utility;
MimeType=text/plain;application/x-cursor-workspace;
Actions=new-empty-window;
Keywords=cursor;code;editor;programming;developer;ai;
X-AppImage-Version=$APP_VERSION

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=cursor --no-sandbox --new-window %F
Icon=$INSTALL_DIR/co.anysphere.cursor.png
EOF
    
    chmod +x "$INSTALL_DIR/AppRun"
    chmod +x "$DESKTOP_FILE"
    update-desktop-database &> /dev/null || true
    
    cleanup
    
    # Update complete
    echo
    print_text "${GREEN}${BOLD}Cursor AI Editor successfully updated to v${APP_VERSION}!${RESET}"
    
    local update_content=(
        ""
        "${MAGENTA}${BOLD}UPDATE COMPLETE${RESET}"
        ""
    )
    print_box "${update_content[@]}"
}

# Function to show about information
show_about() {
    display_header
    
    # Fetch latest version info
    fetch_download_urls
    
    print_text "${CYAN}${BOLD}About Cursor AI Editor${RESET}"
    print_text "${CYAN}────────────────────${RESET}"
    echo
    print_text "${YELLOW}Cursor is an AI-first code editor that helps you write better code faster.${RESET}"
    print_text "${YELLOW}It combines the power of VS Code with AI code assistance.${RESET}"
    echo
    print_text "${BOLD}Features:${RESET}"
    print_text "  • ${CYAN}AI code completions and suggestions${RESET}"
    print_text "  • ${CYAN}Intelligent code understanding${RESET}"
    print_text "  • ${CYAN}Quick refactoring and bug fixing${RESET}"
    print_text "  • ${CYAN}Documentation generation${RESET}"
    print_text "  • ${CYAN}Built-in AI chat for coding assistance${RESET}"
    print_text "  • ${CYAN}Request ID reset for privacy${RESET}"
    echo
    print_text "${BOLD}Installer Information:${RESET}"
    print_text "  • ${CYAN}Script version: 3.0${RESET}"
    print_text "  • ${CYAN}Author: Mahesh Technicals${RESET}"
    print_text "  • ${CYAN}App version: $APP_VERSION${RESET}"
    print_text "  • ${CYAN}Architecture: $ARCH${RESET}"
    echo
    print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
    echo -n ""
    read -r
}

# Function to show help
show_help() {
    print_text "${CYAN}${BOLD}Usage:${RESET} $0 [OPTION]"
    echo
    print_text "${BOLD}Options:${RESET}"
    print_text "  ${CYAN}-i, --install${RESET}    Install Cursor AI Editor"
    print_text "  ${CYAN}-u, --uninstall${RESET}  Uninstall Cursor AI Editor"
    print_text "  ${CYAN}-p, --update${RESET}     Update Cursor AI Editor"
    print_text "  ${CYAN}-r, --reset-ids${RESET}  Reset Cursor telemetry & request IDs"
    print_text "  ${CYAN}-a, --about${RESET}      Show information about Cursor"
    print_text "  ${CYAN}-h, --help${RESET}       Display this help message"
    echo
    print_text "${YELLOW}If no option is provided, the interactive menu will be displayed.${RESET}"
}

# Function to show task completion and ask about returning to main menu
ask_main_menu() {
    echo
    print_text "${GREEN}${BOLD}Task completed successfully!${RESET}"
    echo
    print_text "${YELLOW}Do you want to return to the main menu? (y/n): ${RESET}"
    echo -n ""
    read -r menu_choice
    if [[ "$menu_choice" != "y" && "$menu_choice" != "Y" ]]; then
        clear
        print_text "${GREEN}${BOLD}Thank you for using the Cursor AI Editor installer!${RESET}"
        print_text "${CYAN}Goodbye!${RESET}"
        exit 0
    fi
}

# Function to generate random hexadecimal string of specified length
generate_hex_string() {
    local length=$1
    
    # Try using xxd if available
    if command -v xxd &>/dev/null; then
        # Ensure we get exactly the requested length with no newlines
        head -c $((length/2)) /dev/urandom | xxd -p | tr -d '\n' | head -c $length
        return
    fi
    
    # Fallback to openssl if available
    if command -v openssl &>/dev/null; then
        # Ensure we get exactly the requested length with no newlines
        openssl rand -hex $((length/2)) | tr -d '\n' | head -c $length
        return
    fi
    
    # Last fallback method using built-in bash/date/random
    local result=""
    local chars="0123456789abcdef"
    for ((i=0; i<length; i++)); do
        local rand=$(( RANDOM % 16 ))
        result+=${chars:$rand:1}
    done
    # Ensure exact length
    echo -n "$result" | tr -d '\n' | head -c $length
}

# Function to generate UUID v4
generate_uuid() {
    # Try using uuidgen if available
    if command -v uuidgen &>/dev/null; then
        uuidgen | tr -d '\n'
        return
    fi
    
    # Fallback to Python if available
    if command -v python3 &>/dev/null; then
        python3 -c 'import uuid; print(uuid.uuid4(), end="")' | tr -d '\n'
        return
    fi
    
    # Fallback to custom implementation
    local hex=$(generate_hex_string 32)
    local uuid="${hex:0:8}-${hex:8:4}-4${hex:13:3}-${hex:16:4}-${hex:20:12}"
    echo -n "$uuid" | tr -d '\n'
}

# Function to extract a clean ID value from the configuration file
get_clean_id() {
    local key=$1
    local file=$2
    grep -o "\"$key\": *\"[^\"]*\"" "$file" | cut -d'"' -f4 | tr -d '\n '
}

# Function to directly fix and update the storage.json file
fix_storage_json() {
    # Make a backup first - only if no backup exists
    if [ ! -f "${CONFIG_FILE}.bak" ] && [ ! -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Creating backup of original file...${RESET}"
        cp "$CONFIG_FILE" "${CONFIG_FILE}.original" 2>/dev/null || true
    else
        print_text "${YELLOW}${BOLD}[INFO] Backup already exists, skipping backup creation...${RESET}"
    fi
    
    # Generate new IDs
    local new_machine_id=$(generate_hex_string 64)
    local new_mac_id=$(generate_hex_string 64)
    local new_device_id=$(generate_uuid)
    
    print_text "${BLUE}${BOLD}[INFO] Creating fixed JSON with new IDs...${RESET}"
    
    # Create a new storage.json file directly
    cat > "$CONFIG_FILE" << EOF
{
  "telemetry.machineId": "${new_machine_id}",
  "telemetry.macMachineId": "${new_mac_id}",
  "telemetry.devDeviceId": "${new_device_id}",
  "telemetry.sqmId": "",
  "backupWorkspaces": {
    "workspaces": [],
    "folders": [
      {
        "folderUri": "file://${HOME}/Downloads"
      }
    ],
    "emptyWindows": [
      {
        "backupFolder": "1743309163731"
      }
    ]
  },
  "profileAssociations": {
    "workspaces": {
      "file://${HOME}/Downloads": "__default__profile__"
    },
    "emptyWindows": {}
  },
  "windowControlHeight": 35,
  "theme": "vs-dark",
  "themeBackground": "#1a1a1a",
  "windowSplash": {
    "zoomLevel": 0,
    "baseTheme": "vs-dark",
    "colorInfo": {
      "foreground": "rgba(204, 204, 204, 0.87)",
      "background": "#1a1a1a",
      "editorBackground": "#1a1a1a",
      "titleBarBackground": "#141414",
      "titleBarBorder": "rgba(255, 255, 255, 0.05)",
      "activityBarBackground": "#141414",
      "sideBarBackground": "#141414",
      "sideBarBorder": "rgba(255, 255, 255, 0.05)",
      "statusBarBackground": "#141414",
      "statusBarBorder": "rgba(255, 255, 255, 0.05)",
      "statusBarNoFolderBackground": "#141414"
    },
    "layoutInfo": {
      "sideBarSide": "left",
      "editorPartMinWidth": 220,
      "titleBarHeight": 35,
      "activityBarWidth": 0,
      "sideBarWidth": 256,
      "statusBarHeight": 22,
      "windowBorder": false
    }
  },
  "windowsState": {
    "lastActiveWindow": {
      "backupPath": "${HOME}/.config/Cursor/Backups/1743309163731",
      "uiState": {
        "mode": 0,
        "x": 0,
        "y": 63,
        "width": 1440,
        "height": 657
      }
    },
    "openedWindows": []
  }
}
EOF
    
    # Verify it's valid JSON
    if command -v python3 >/dev/null 2>&1; then
        if ! python3 -c "import json; json.load(open('$CONFIG_FILE'))" 2>/dev/null; then
            print_text "${RED}${BOLD}[ERROR] Created JSON file is invalid. This is unexpected.${RESET}"
            if [ -f "${CONFIG_FILE}.original" ]; then
                print_text "${YELLOW}${BOLD}Restoring original file...${RESET}"
                cp "${CONFIG_FILE}.original" "$CONFIG_FILE"
            fi
            return 1
        fi
    fi
    
    # Get the new IDs for display
    local new_machine_id=$(get_clean_id "telemetry.machineId" "$CONFIG_FILE")
    local new_mac_id=$(get_clean_id "telemetry.macMachineId" "$CONFIG_FILE")
    local new_device_id=$(get_clean_id "telemetry.devDeviceId" "$CONFIG_FILE")
    
    # Display results
    echo
    print_text "${GREEN}${BOLD}✅ Telemetry IDs have been reset using specialized method!${RESET}"
    echo
    print_text "${CYAN}${BOLD}New Values:${RESET}"
    print_text "${GREEN}Machine ID:    ${RESET}${new_machine_id}"
    print_text "${GREEN}Mac ID:        ${RESET}${new_mac_id}"
    print_text "${GREEN}Device ID:     ${RESET}${new_device_id}"
    echo
    
    # Fix permissions if running as root
    if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
        chown $SUDO_USER:$(id -gn $SUDO_USER) "$CONFIG_FILE"
        if [ -f "${CONFIG_FILE}.original" ]; then
            chown $SUDO_USER:$(id -gn $SUDO_USER) "${CONFIG_FILE}.original"
        fi
        print_text "${YELLOW}${BOLD}[INFO] Fixed file ownership for regular user.${RESET}"
    fi
    
    # Display backup message based on which backup exists
    if [ -f "${CONFIG_FILE}.bak" ]; then
        print_text "${YELLOW}Backup saved to: ${CONFIG_FILE}.bak${RESET}"
    elif [ -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}Backup saved to: ${CONFIG_FILE}.original${RESET}"
    fi
    
    print_text "${GREEN}${BOLD}Please restart Cursor for changes to take effect.${RESET}"
    
    local reset_content=(
        "${MAGENTA}${BOLD}REQUEST IDs RESET COMPLETE${RESET}"
    )
    print_box "${reset_content[@]}"
    return 0
}

# Function to reset request IDs
reset_request_ids() {
    display_header
    
    # Make sure the config directory exists
    local config_dir=$(dirname "$CONFIG_FILE")
    if [ ! -d "$config_dir" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Creating config directory: $config_dir${RESET}"
        mkdir -p "$config_dir"
    fi
    
    # If config file doesn't exist, create a new one
    if [ ! -f "$CONFIG_FILE" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Config file not found. Creating a new one.${RESET}"
        touch "$CONFIG_FILE"
        echo "{}" > "$CONFIG_FILE"
    fi
    
    # Check if we have write permission
    if [ ! -w "$CONFIG_FILE" ]; then
        print_text "${RED}${BOLD}[ERROR] No write permission for $CONFIG_FILE${RESET}"
        print_text "${YELLOW}${BOLD}You may need to run this command with sudo or change file permissions.${RESET}"
        return 1
    fi
    
    print_text "${BLUE}${BOLD}[INFO] Reading current telemetry IDs...${RESET}"
    
    # Try a special direct method for the specific storage.json format
    if grep -q "Downloads" "$CONFIG_FILE"; then
        print_text "${YELLOW}${BOLD}[INFO] Using specialized method for storage.json${RESET}"
        fix_storage_json
        return 0
    fi
    
    # Create backup of original file - only if no backup already exists
    if [ -f "$CONFIG_FILE" ] && [ ! -f "${CONFIG_FILE}.bak" ] && [ ! -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Creating backup of original file...${RESET}"
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" 2>/dev/null || true
        
        # Fix backup file ownership if running as root
        if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
            chown $SUDO_USER:$(id -gn $SUDO_USER) "${CONFIG_FILE}.bak" 2>/dev/null || true
        fi
    elif [ -f "${CONFIG_FILE}.bak" ] || [ -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Backup already exists, skipping backup creation...${RESET}"
    fi
    
    # Generate new IDs
    print_text "${BLUE}${BOLD}[INFO] Generating new IDs...${RESET}"
    local new_machine_id=$(generate_hex_string 64)
    local new_mac_id=$(generate_hex_string 64)
    local new_device_id=$(generate_uuid)
    
    # Read original file
    local file_content=$(cat "$CONFIG_FILE")
    
    # Extract current IDs using grep and sed
    local current_machine_id=$(echo "$file_content" | grep -o '"telemetry.machineId"[^"]*"[^"]*"' | sed 's/"telemetry.machineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
    local current_mac_id=$(echo "$file_content" | grep -o '"telemetry.macMachineId"[^"]*"[^"]*"' | sed 's/"telemetry.macMachineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
    local current_device_id=$(echo "$file_content" | grep -o '"telemetry.devDeviceId"[^"]*"[^"]*"' | sed 's/"telemetry.devDeviceId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ,')
    
    # Use sed to replace the values - handle multiline and preserve structure
    print_text "${BLUE}${BOLD}[INFO] Updating telemetry IDs...${RESET}"
    
    # Create a temporary file for processing
    local tmp_file=$(mktemp)
    
    # If jq is available, use it for safer JSON manipulation
    if command -v jq >/dev/null 2>&1; then
        # First fix any issues with the JSON format
        # Replace line breaks and fix missing quotes in the original file
        cat "$CONFIG_FILE" | tr -d '\n' | sed 's/\([a-f0-9]*\)"/\1"/g' > "$tmp_file"
        
        # Now use jq to update the values
        jq --arg mid "$new_machine_id" --arg mmid "$new_mac_id" --arg did "$new_device_id" \
           '.["telemetry.machineId"] = $mid | .["telemetry.macMachineId"] = $mmid | .["telemetry.devDeviceId"] = $did' \
           "$tmp_file" > "${tmp_file}.new"
        
        if [ -s "${tmp_file}.new" ]; then
            cat "${tmp_file}.new" > "$CONFIG_FILE"
            rm -f "${tmp_file}.new"
        else
            print_text "${RED}${BOLD}[ERROR] JSON processing failed with jq.${RESET}"
        fi
    else
        # Manual method if jq is not available
        # Fix JSON format issues first
        cat "$CONFIG_FILE" | tr -d '\n' | sed 's/\([a-f0-9]*\)"/\1"/g' > "$tmp_file"
        
        # Replace the telemetry IDs
        sed -i.sedbak "s|\"telemetry.machineId\": *\"[^\"]*\"|\"telemetry.machineId\": \"$new_machine_id\"|g" "$tmp_file"
        sed -i.sedbak "s|\"telemetry.macMachineId\": *\"[^\"]*\"|\"telemetry.macMachineId\": \"$new_mac_id\"|g" "$tmp_file"
        sed -i.sedbak "s|\"telemetry.devDeviceId\": *\"[^\"]*\"|\"telemetry.devDeviceId\": \"$new_device_id\"|g" "$tmp_file"
        
        # Add proper formatting to make the JSON readable
        if command -v python3 >/dev/null 2>&1; then
            python3 -c "
import json
try:
    with open('$tmp_file', 'r') as f:
        data = json.load(f)
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(data, f, indent=2)
    print('Successfully formatted JSON')
except Exception as e:
    print(f'Error: {str(e)}')
" >/dev/null 2>&1 || {
                # If python fails, just use the sed-processed file
                cat "$tmp_file" > "$CONFIG_FILE"
            }
        else
            # Without python, just use the sed-processed file
            cat "$tmp_file" > "$CONFIG_FILE"
        fi
    fi
    
    rm -f "$tmp_file" "$tmp_file.sedbak" 2>/dev/null
    
    # Verify the values were updated
    if [ -f "$CONFIG_FILE" ]; then
        local updated_content=$(cat "$CONFIG_FILE")
        local updated_machine_id=$(echo "$updated_content" | grep -o '"telemetry.machineId"[^"]*"[^"]*"' | sed 's/"telemetry.machineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
        local updated_mac_id=$(echo "$updated_content" | grep -o '"telemetry.macMachineId"[^"]*"[^"]*"' | sed 's/"telemetry.macMachineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
        local updated_device_id=$(echo "$updated_content" | grep -o '"telemetry.devDeviceId"[^"]*"[^"]*"' | sed 's/"telemetry.devDeviceId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ,')
        
        local success=true
        if [ -z "$updated_machine_id" ] || [ "$updated_machine_id" != "$new_machine_id" ]; then
            success=false
        fi
        if [ -z "$updated_mac_id" ] || [ "$updated_mac_id" != "$new_mac_id" ]; then
            success=false
        fi
        if [ -z "$updated_device_id" ] || [ "$updated_device_id" != "$new_device_id" ]; then
            success=false
        fi
        
        # Last resort - if all else fails, create a minimal JSON with just the telemetry IDs
        if [ "$success" = false ]; then
            print_text "${YELLOW}${BOLD}[WARNING] Failed to update IDs while preserving other settings.${RESET}"
            print_text "${YELLOW}${BOLD}Using fallback method with minimal settings.${RESET}"
            
            # Create minimal JSON with just the telemetry IDs
            cat > "$CONFIG_FILE" << EOF
{
  "telemetry.machineId": "$new_machine_id",
  "telemetry.macMachineId": "$new_mac_id",
  "telemetry.devDeviceId": "$new_device_id"
}
EOF
            
            print_text "${YELLOW}${BOLD}[WARNING] Other settings may have been lost.${RESET}"
            
            # Fix permissions if running as root
            if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
                chown $SUDO_USER:$(id -gn $SUDO_USER) "$CONFIG_FILE"
                print_text "${YELLOW}${BOLD}[INFO] Fixed file ownership for regular user.${RESET}"
            fi
            
            # Update message to reflect whether a new backup was created or an existing one exists
            if [ -f "${CONFIG_FILE}.bak" ]; then
                if [ "$(find "${CONFIG_FILE}.bak" -mmin -2)" ]; then
                    print_text "${YELLOW}${BOLD}A backup of your original file was saved to ${CONFIG_FILE}.bak${RESET}"
                else
                    print_text "${YELLOW}${BOLD}Your original settings can be found in the existing backup at ${CONFIG_FILE}.bak${RESET}"
                fi
            elif [ -f "${CONFIG_FILE}.original" ]; then
                print_text "${YELLOW}${BOLD}Your original settings can be found in the backup at ${CONFIG_FILE}.original${RESET}"
            fi
            
            success=true
        fi
        
        # Display results
        echo
        if [ "$success" = true ]; then
            print_text "${GREEN}${BOLD}✅ Telemetry IDs have been reset!${RESET}"
        else
            print_text "${RED}${BOLD}❌ Failed to reset telemetry IDs.${RESET}"
        fi
        
        echo
        print_text "${CYAN}${BOLD}Old Values:${RESET}"
        print_text "${YELLOW}Machine ID:    ${RESET}${current_machine_id:-[Not Found]}"
        print_text "${YELLOW}Mac ID:        ${RESET}${current_mac_id:-[Not Found]}"
        print_text "${YELLOW}Device ID:     ${RESET}${current_device_id:-[Not Found]}"
        echo
        print_text "${CYAN}${BOLD}New Values:${RESET}"
        print_text "${GREEN}Machine ID:    ${RESET}${new_machine_id}"
        print_text "${GREEN}Mac ID:        ${RESET}${new_mac_id}"
        print_text "${GREEN}Device ID:     ${RESET}${new_device_id}"
        echo
        
        print_text "${YELLOW}Backup saved to: ${CONFIG_FILE}.bak${RESET}"
        print_text "${GREEN}${BOLD}Please restart Cursor for changes to take effect.${RESET}"
        
        local reset_content=(
            "${MAGENTA}${BOLD}REQUEST IDs RESET COMPLETE${RESET}"
        )
        print_box "${reset_content[@]}"
    else
        print_text "${RED}${BOLD}[ERROR] Configuration file disappeared during processing.${RESET}"
        if [ -f "${CONFIG_FILE}.bak" ]; then
            print_text "${YELLOW}${BOLD}Restoring backup...${RESET}"
            cp "${CONFIG_FILE}.bak" "$CONFIG_FILE"
        fi
        return 1
    fi
}

# Function to display status table
display_status_table() {
    # Get installed version if available
    local installed_version="Not installed yet"
    if [[ -d "$INSTALL_DIR" ]]; then
        if [[ -f "$INSTALL_DIR/version" ]]; then
            installed_version=$(cat "$INSTALL_DIR/version" 2>/dev/null)
        else
            installed_version=$(grep -oP 'X-AppImage-Version=\K.*' "$DESKTOP_FILE" 2>/dev/null || echo "Unknown")
        fi
    fi

    # Fetch latest version
    if [[ -z "$APP_VERSION" || "$APP_VERSION" == "0.48.6" ]]; then
        fetch_download_urls > /dev/null 2>&1
    fi
    
    local latest_version="$APP_VERSION"
    
    # Set table dimensions and styles
    local name="Cursor AI Editor"
    local table_width=60
    local col1_width=20
    local col2_width=$((table_width - col1_width - 4))  # -4 for borders and spacing
    
    # Create top border
    local top_border="${CYAN}${BOLD}╔"
    for ((i=0; i<col1_width; i++)); do
        top_border+="═"
    done
    top_border+="╦"
    for ((i=0; i<col2_width; i++)); do
        top_border+="═"
    done
    top_border+="╗${RESET}"
    
    # Create middle border
    local mid_border="${CYAN}${BOLD}╠"
    for ((i=0; i<col1_width; i++)); do
        mid_border+="═"
    done
    mid_border+="╬"
    for ((i=0; i<col2_width; i++)); do
        mid_border+="═"
    done
    mid_border+="╣${RESET}"
    
    # Create bottom border
    local bottom_border="${CYAN}${BOLD}╚"
    for ((i=0; i<col1_width; i++)); do
        bottom_border+="═"
    done
    bottom_border+="╩"
    for ((i=0; i<col2_width; i++)); do
        bottom_border+="═"
    done
    bottom_border+="╝${RESET}"
    
    # Print table header
    echo -e "$top_border"
    
    # Print table title
    local title="STATUS INFORMATION"
    local padding=$(( (table_width - ${#title} - 2) / 2 ))
    local right_padding=$padding
    if (( (table_width - ${#title} - 2) % 2 != 0 )); then
        right_padding=$((padding + 1))
    fi
    
    local title_row="${CYAN}${BOLD}║${RESET}"
    for ((i=0; i<padding; i++)); do
        title_row+=" "
    done
    title_row+="${BOLD}${MAGENTA}${title}${RESET}"
    for ((i=0; i<right_padding; i++)); do
        title_row+=" "
    done
    title_row+="${CYAN}${BOLD}║${RESET}"
    
    echo -e "$title_row"
    echo -e "$mid_border"
    
    # Print Name row
    local name_row="${CYAN}${BOLD}║${RESET} ${BOLD}Name${RESET}"
    local name_padding=$((col1_width - 4))
    for ((i=0; i<name_padding; i++)); do
        name_row+=" "
    done
    name_row+="${CYAN}${BOLD}║${RESET} ${GREEN}$name${RESET}"
    local value_padding=$((col2_width - ${#name} - 1))
    for ((i=0; i<value_padding; i++)); do
        name_row+=" "
    done
    name_row+="${CYAN}${BOLD}║${RESET}"
    echo -e "$name_row"
    
    # Print Installed Version row
    echo -e "$mid_border"
    local installed_row="${CYAN}${BOLD}║${RESET} ${BOLD}Installed Version${RESET}"
    local installed_padding=$((col1_width - 17))
    for ((i=0; i<installed_padding; i++)); do
        installed_row+=" "
    done
    
    # Color for installed version (red if not installed)
    local version_color=$GREEN
    if [[ "$installed_version" == "Not installed yet" || "$installed_version" == "Unknown" ]]; then
        version_color=$RED
    fi
    
    installed_row+="${CYAN}${BOLD}║${RESET} ${version_color}$installed_version${RESET}"
    local value_padding=$((col2_width - ${#installed_version} - 1))
    for ((i=0; i<value_padding; i++)); do
        installed_row+=" "
    done
    installed_row+="${CYAN}${BOLD}║${RESET}"
    echo -e "$installed_row"
    
    # Print Latest Version row
    echo -e "$mid_border"
    local latest_row="${CYAN}${BOLD}║${RESET} ${BOLD}Latest Version${RESET}"
    local latest_padding=$((col1_width - 14))
    for ((i=0; i<latest_padding; i++)); do
        latest_row+=" "
    done
    latest_row+="${CYAN}${BOLD}║${RESET} ${YELLOW}$latest_version${RESET}"
    local value_padding=$((col2_width - ${#latest_version} - 1))
    for ((i=0; i<value_padding; i++)); do
        latest_row+=" "
    done
    latest_row+="${CYAN}${BOLD}║${RESET}"
    echo -e "$latest_row"
    
    # Print table footer
    echo -e "$bottom_border"
    echo
}

# Process command line arguments
if [[ $# -gt 0 ]]; then    
    case "$1" in
        -r|--reset-ids)
            # Reset IDs doesn't necessarily need root access
            if [ -f "$CONFIG_FILE" ] && [ ! -w "$CONFIG_FILE" ]; then
                print_text "${RED}${BOLD}[ERROR] No write permission for the Cursor config file.${RESET}"
                print_text "${YELLOW}${BOLD}You may need to run with sudo:${RESET} sudo $0 $1"
                print_text "${YELLOW}Or change permissions:${RESET} chmod u+w $CONFIG_FILE"
                exit 1
            fi
            reset_request_ids
            ask_main_menu
            ;;
        *)
            # All other commands require root
            check_root || exit 1
            
            case "$1" in
                -i|--install)
                    # Call the install_cursor function which handles dependency checks and installation
                    install_cursor
                    ask_main_menu
                    ;;
                -u|--uninstall)
                    uninstall_cursor
                    ask_main_menu
                    ;;
                -p|--update)
                    update_cursor
                    ask_main_menu
                    ;;
                -a|--about)
                    show_about
                    ask_main_menu
                    ;;
                -h|--help)
                    show_help
                    ask_main_menu
                    ;;
                *)
                    echo -e "${RED}[ERROR] Unknown option: $1${RESET}"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
    esac
fi

# Fetch the latest version information at startup
fetch_download_urls > /dev/null 2>&1 || true

# Main menu
while true; do
    display_header
    
    # Display status table
    display_status_table
    
    echo -e "${CYAN}Select an option:${RESET}"
    echo
    echo -e "1) ${GREEN}Install${RESET} Cursor AI Editor"
    echo -e "2) ${RED}Uninstall${RESET} Cursor AI Editor"
    echo -e "3) ${BLUE}Update${RESET} Cursor AI Editor"
    echo -e "4) ${MAGENTA}Reset Request ID${RESET}"
    echo -e "5) ${YELLOW}About${RESET} Cursor AI Editor"
    echo -e "6) ${MAGENTA}Help${RESET}"
    echo -e "7) ${CYAN}Exit${RESET}"
    echo
    
    # Input prompt
    echo -n -e "${CYAN}Enter your choice [1-7]:${RESET} "
    read -r choice
    
    case "$choice" in
        1|2|3)
            # Options that require root access
            if ! check_root; then
                continue
            fi
            
            case "$choice" in
                1)
                    # Call the install_cursor function which handles dependency checks and installation
                    install_cursor
                    ask_main_menu
                    ;;
                2)
                    uninstall_cursor
                    ask_main_menu
                    ;;
                3)
                    update_cursor
                    ask_main_menu
                    ;;
            esac
            ;;
        4)
            # Reset Request ID does not need root
            # But it needs write access to the config file
            if [ -f "$CONFIG_FILE" ] && [ ! -w "$CONFIG_FILE" ]; then
                print_text "${RED}${BOLD}[ERROR] No write permission for the Cursor config file.${RESET}"
                print_text "${YELLOW}${BOLD}You may need to run with sudo:${RESET} sudo $0"
                print_text "${YELLOW}Or change permissions:${RESET} chmod u+w $CONFIG_FILE"
                echo
                print_text "${YELLOW}Press Enter to continue...${RESET}"
                read -r
                continue
            fi
            
            reset_request_ids
            ask_main_menu
            ;;
        5)
            show_about
            ask_main_menu
            ;;
        6)
            clear
            show_help
            ask_main_menu
            ;;
        7)
            clear
            print_text "${GREEN}${BOLD}Thank you for using the Cursor AI Editor installer!${RESET}"
            print_text "${CYAN}Goodbye!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}${BOLD}[ERROR] Invalid option!${RESET}"
            echo -e "${YELLOW}Press Enter to continue...${RESET}"
            echo -n ""
            read -r
            ;;
    esac
done
