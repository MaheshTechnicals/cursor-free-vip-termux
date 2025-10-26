#!/bin/bash
################################################################################
#                                                                              #
#                 🚀 Cursor AI Editor Installer & Uninstaller 🚀                 #
#                                                                              #
#                        ✨ Author: Mahesh Technicals ✨                         #
#                        🌟 Version: 3.9 (DEB Edition) 🌟                       #
#                📌 Modern & Stylish UI with Error Handling                #
#                                                                              #
################################################################################

# Define variables
APP_NAME="Cursor"
APP_VERSION="0.0.0" # Default version, will be updated by fetch_download_urls
ARCH=$(uname -m)
DEB_URL=""

# API endpoints for fetching version and download URL
API_URL_BASE="https://www.cursor.com/api/download?releaseTrack=stable"
API_URL=""

# Set the correct API endpoint based on architecture
if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    API_URL="${API_URL_BASE}&platform=linux-arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
    API_URL="${API_URL_BASE}&platform=linux-x64"
else
    echo -e "\e[31m[ERROR] Unsupported architecture: $ARCH\e[0m"
    # Exit if architecture is unsupported early on
    exit 1
fi

# Determine the actual user's home directory even when run with sudo
if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
    ACTUAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    # Fallback if getent fails
    if [ -z "$ACTUAL_HOME" ]; then
        ACTUAL_HOME=$(eval echo ~$SUDO_USER)
    fi
else
    ACTUAL_HOME=$HOME
fi

# Paths are now managed by the .deb package
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
        # Strip ANSI codes for length calculation
        local stripped_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        line_length=${#stripped_line}
        if [[ $line_length -gt $max_length ]]; then
            max_length=$line_length
        fi
    done

    # Add padding for box borders
    max_length=$((max_length + 8))
    # Ensure minimum width for short messages
    [[ $max_length -lt 30 ]] && max_length=30

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
         local stripped_line=$(echo -e "$line" | sed 's/\x1b\[[0-9;]*m//g')
        local padding=$((max_length - ${#stripped_line} - 2))
        # Ensure padding is not negative
        [[ $padding -lt 0 ]] && padding=0
        local right_padding=$((padding / 2))
        local left_padding=$((padding - right_padding))

        local padded_line="${CYAN}${BOLD}║${RESET}"
        for ((i=0; i<left_padding; i++)); do
            padded_line+=" "
        done

        padded_line+="$line" # Use original line with colors

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

# Function to check if this is a Debian-based system
check_deb_system() {
    if ! command -v apt &> /dev/null && ! command -v apt-get &> /dev/null; then
        print_text "${RED}${BOLD}[ERROR] This installer only supports Debian-based systems (like Ubuntu, Debian, Mint).${RESET}"
        print_text "${RED}${BOLD}[ERROR] Package managers 'apt' or 'apt-get' not found.${RESET}"
        return 1
    fi
    if ! command -v dpkg &> /dev/null; then
        print_text "${RED}${BOLD}[ERROR] 'dpkg' command not found. This system might not be fully Debian-compatible.${RESET}"
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

    # This script now ONLY supports apt/apt-get
    if ! check_deb_system; then
        print_text "${RED}${BOLD}[ERROR] Cannot install dependencies on a non-Debian system.${RESET}"
        return 1
    fi

    # Try to install dependencies with sudo if we're not already root
    local use_sudo=""
    if [[ $EUID -ne 0 ]]; then
        use_sudo="sudo"
        print_text "${YELLOW}${BOLD}[INFO] Not running as root, will use sudo for installations${RESET}"
    fi

    # FIX: Use `env` to set DEBIAN_FRONTEND correctly with sudo
    if command -v apt &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using apt package manager...${RESET}"
        $use_sudo env DEBIAN_FRONTEND=noninteractive apt update -qq && $use_sudo env DEBIAN_FRONTEND=noninteractive apt install -y "${missing_deps[@]}"
    elif command -v apt-get &> /dev/null; then
        print_text "${BLUE}${BOLD}[INFO] Using apt-get package manager...${RESET}"
        $use_sudo env DEBIAN_FRONTEND=noninteractive apt-get update -qq && $use_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_deps[@]}"
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
        print_text "${YELLOW}Please install them manually and run the script again.${RESET}"
        print_text "${YELLOW}Press Enter to continue...${RESET}"
        read -r
        return 1
    fi

    print_text "${GREEN}${BOLD}[SUCCESS] All dependencies installed successfully!${RESET}"

    # Special verification for jq
    if ! command -v jq &> /dev/null; then
        print_text "${YELLOW}${BOLD}[WARNING] jq still not found after installation attempts.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Will try one more alternative method...${RESET}"

        if command -v python3 &> /dev/null || command -v python &> /dev/null; then
            if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
                print_text "${BLUE}${BOLD}[INFO] Attempting to install jq via pip...${RESET}"
                # If pip needs sudo, it will likely ask for password here
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
        print_text "                For Debian/Ubuntu: ${BOLD}apt install ${missing_deps[*]}${RESET}"
        return 1
    fi

    if [[ ${#missing_optional[@]} -gt 0 ]]; then
        print_text "${YELLOW}${BOLD}[WARNING] Some optional dependencies are missing: ${missing_optional[*]}${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] These are not required but recommended for better functionality:${RESET}"
        print_text "                For Debian/Ubuntu: ${BOLD}apt install ${missing_optional[*]}${RESET}"
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
        "${CYAN}${BOLD}Version 3.9 (DEB Edition)${RESET}"
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
    cd / || true # Go back to root before removing temp dir
    rm -rf "$TEMP_DIR"
}

# Function to check if Cursor is already installed
check_installation() {
    # Check for the specific "installed" status.
    if dpkg -s cursor 2>/dev/null | grep -q "^Status: install ok installed"; then
        print_text "${YELLOW}${BOLD}[WARNING] Cursor is already installed.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Would you like to reinstall? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            print_text "${YELLOW}${BOLD}[INFO] Installation aborted.${RESET}"
            return 1
        fi
        print_text "${YELLOW}${BOLD}[INFO] Proceeding with reinstallation...${RESET}"
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

    if [[ -z "$API_URL" ]]; then
        print_text "${RED}${BOLD}[ERROR] Unsupported architecture: $ARCH. Cannot fetch version.${RESET}"
        return 1
    fi

    # Check if curl or wget is available
    if command -v curl &> /dev/null; then
        # Added -L flag to follow redirects
        local response=$(curl -sL --connect-timeout 10 --max-time 15 "$API_URL")
    elif command -v wget &> /dev/null; then
        # wget follows redirects by default
        local response=$(wget --timeout=10 --tries=2 -qO- "$API_URL")
    else
        print_text "${RED}${BOLD}[ERROR] Neither curl nor wget is available. Please install one of them.${RESET}"
        return 1
    fi

    # Check if we got a valid response
    if [[ -z "$response" ]]; then
        print_text "${RED}${BOLD}[ERROR] Failed to get a response from version server.${RESET}"
        return 1
    fi
    # Check if response looks like JSON
    if ! echo "$response" | grep -q '{.*}'; then
        print_text "${RED}${BOLD}[ERROR] Invalid response received from API (not JSON).${RESET}"
        print_text "${RED}Response: $response${RESET}"
        return 1
    fi


    # Check if jq is available for JSON parsing
    if command -v jq &> /dev/null; then
        # Parse JSON using jq
        APP_VERSION=$(echo "$response" | jq -r '.version')
        DEB_URL=$(echo "$response" | jq -r '.debUrl')
    else
        # Fallback to grep and sed if jq is not available
        print_text "${YELLOW}${BOLD}[WARNING] jq not found. Using fallback method for JSON parsing.${RESET}"
        APP_VERSION=$(echo "$response" | grep -o '"version":"[^"]*"' | head -1 | sed 's/"version":"//;s/"//')
        DEB_URL=$(echo "$response" | grep -o '"debUrl":"[^"]*"' | head -1 | sed 's/"debUrl":"//;s/"//')
    fi

    # Verify that we got valid values
    if [[ -z "$APP_VERSION" || "$APP_VERSION" == "null" || -z "$DEB_URL" || "$DEB_URL" == "null" ]]; then
        print_text "${RED}${BOLD}[ERROR] Failed to parse version information from API.${RESET}"
        print_text "${RED}Raw Response: $response${RESET}"
        # Make sure DEB_URL is empty if parsing failed
        DEB_URL=""
        return 1
    else
        print_text "${GREEN}${BOLD}[SUCCESS] Found latest version: ${APP_VERSION}${RESET}"
    fi

    return 0
}

# Function to install Cursor
install_cursor() {
    display_header

    # This installer is for .deb packages only
    if ! check_deb_system; then
        print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
        read -r
        return 1
    fi

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
        # FIX: Use `env` to set DEBIAN_FRONTEND correctly with sudo
        $use_sudo env DEBIAN_FRONTEND=noninteractive apt update && $use_sudo env DEBIAN_FRONTEND=noninteractive apt install -y jq

        # Check if jq is now available
        if ! command -v jq &> /dev/null; then
            print_text "${YELLOW}${BOLD}[WARNING] Could not install jq automatically.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] The script will continue, but some features may not work properly.${RESET}"
            print_text "${YELLOW}${BOLD}[INFO] Please install jq manually using your package manager.${RESET}"
        else
            print_text "${GREEN}${BOLD}[SUCCESS] Successfully installed jq!${RESET}"
        fi
    fi

    # After all dependencies are satisfied, proceed with installation
    print_text "${GREEN}${BOLD}[SUCCESS] All dependencies are satisfied. Proceeding with installation...${RESET}"

    check_installation
    if [ $? -eq 1 ]; then
        return
    fi
    create_temp_dir
    # Ensure cleanup happens even if the script exits unexpectedly
    trap cleanup EXIT INT TERM

    # Fetch latest version and download URLs
    if ! fetch_download_urls; then
        print_text "${RED}${BOLD}[ERROR] Could not fetch download information. Installation aborted.${RESET}"
        # Cleanup is handled by trap
        return 1
    fi

    if [[ -z "$DEB_URL" ]]; then
         print_text "${RED}${BOLD}[ERROR] Could not determine download URL. Installation aborted.${RESET}"
         # Cleanup is handled by trap
         return 1
    fi

    print_text "${BLUE}${BOLD}[1/3]${RESET} ${YELLOW}Downloading Cursor AI Editor v${APP_VERSION} for ${ARCH}...${RESET}"
    wget -q --timeout=60 --tries=3 --show-progress -O Cursor.deb "$DEB_URL" || {
        print_text "${RED}${BOLD}[ERROR] Download failed. Please check your internet connection.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] You can try downloading the file manually from:${RESET}"
        print_text "${CYAN}$DEB_URL${RESET}"
        # Cleanup is handled by trap
        return 1
    }

    print_text "${BLUE}${BOLD}[2/3]${RESET} ${YELLOW}Installing .deb package (non-interactive mode)...${RESET}" # Updated text

    # FIX: Use `env` to correctly set DEBIAN_FRONTEND for the apt/dpkg command
    # Use apt install to handle dependencies automatically
    if ! $use_sudo env DEBIAN_FRONTEND=noninteractive apt install -y ./Cursor.deb; then
         print_text "${RED}${BOLD}[ERROR] Failed to install .deb package using 'apt install'.${RESET}"
         print_text "${YELLOW}${BOLD}[INFO] Trying fallback with 'dpkg -i' and 'apt --fix-broken install'...${RESET}"
         # Run dpkg non-interactively if possible
         $use_sudo env DEBIAN_FRONTEND=noninteractive dpkg -i ./Cursor.deb || $use_sudo env DEBIAN_FRONTEND=noninteractive apt --fix-broken install -y # Fixed here too

         # Final check
         if ! dpkg -s cursor 2>/dev/null | grep -q "^Status: install ok installed"; then
            print_text "${RED}${BOLD}[ERROR] Installation failed even with fallback. Please try installing manually.${RESET}"
            # Cleanup is handled by trap
            return 1
         fi
         print_text "${GREEN}${BOLD}[SUCCESS] Installed using fallback method.${RESET}"
    fi


    print_text "${BLUE}${BOLD}[3/3]${RESET} ${YELLOW}Applying '--no-sandbox' flag to desktop launcher...${RESET}"
    local desktop_file="/usr/share/applications/cursor.desktop"

    if [ -f "$desktop_file" ]; then
        # Use grep -q to check if the flag already exists
        if ! grep -q -- '--no-sandbox' "$desktop_file"; then
             # Make sure the Exec lines are exactly as expected before replacing
             # Use a temporary file for sed to avoid issues with sudo and redirection
             local temp_sed_script=$(mktemp)
             echo "s|^Exec=/usr/share/cursor/cursor.*|Exec=/usr/share/cursor/cursor --no-sandbox %F|" > "$temp_sed_script"
             echo "s|^Exec=/usr/share/cursor/cursor --new-window.*|Exec=/usr/share/cursor/cursor --no-sandbox --new-window %F|" >> "$temp_sed_script"

             if $use_sudo sed -i -f "$temp_sed_script" "$desktop_file"; then
                 # Refresh the desktop database
                 $use_sudo update-desktop-database &> /dev/null || true
                 print_text "${GREEN}${BOLD}[SUCCESS] Desktop file patched.${RESET}"
             else
                 print_text "${RED}${BOLD}[ERROR] Failed to patch desktop file with sed.${RESET}"
             fi
             rm -f "$temp_sed_script"
        else
             print_text "${YELLOW}${BOLD}[INFO] '--no-sandbox' flag already present in desktop file. Skipping patch.${RESET}"
        fi
    else
        print_text "${YELLOW}${BOLD}[WARNING] Could not find $desktop_file to modify.${RESET}"
    fi


    # Cleanup is handled by trap
    trap - EXIT INT TERM # Disable trap as we finished successfully

    cleanup # Perform manual cleanup now

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
    print_text "  ${BOLD}• From terminal:${RESET} Run ${BOLD}cursor${RESET}"
    echo
}

# Function to check if Cursor is installed
is_cursor_installed() {
    # Check for the specific "installed" status.
    if ! dpkg -s cursor 2>/dev/null | grep -q "^Status: install ok installed"; then
        # Don't print error if it's just a check, only if it's expected to be installed
        # print_text "${RED}${BOLD}[ERROR] Cursor is not installed on this system.${RESET}"
        return 1
    fi
    return 0
}

# Function to display message if not installed (used by uninstall/update)
check_if_installed_and_error() {
     if ! is_cursor_installed; then
        # Check if remnants exist
        if dpkg -s cursor 2>/dev/null | grep -q "^Status: deinstall ok config-files"; then
             print_text "${YELLOW}${BOLD}[INFO] Cursor package is removed, but configuration files remain.${RESET}"
             return 2 # Special return code for remnants
        else
             print_text "${RED}${BOLD}[ERROR] Cursor is not installed on this system.${RESET}"
             return 1 # Not installed at all
        fi
     fi
     return 0 # Is installed
}


# Function to uninstall Cursor
uninstall_cursor() {
    display_header

    # This installer is for .deb packages only
    if ! check_deb_system; then
        print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
        read -r
        return 1
    fi

    local use_sudo=""
    if [[ $EUID -ne 0 ]]; then
        use_sudo="sudo"
    fi

    local install_status
    check_if_installed_and_error
    install_status=$?

    if [[ $install_status -eq 1 ]]; then
         # Truly not installed
         print_text "${YELLOW}${BOLD}[INFO] Nothing to uninstall.${RESET}"
         return
    elif [[ $install_status -eq 2 ]]; then
         # Remnants exist
         print_text "${YELLOW}${BOLD}Do you want to purge these remnants? (y/n):${RESET} "
         echo -n ""
         read -r purge_choice
         if [[ "$purge_choice" != "y" && "$purge_choice" != "Y" ]]; then
             print_text "${YELLOW}${BOLD}[INFO] Cleanup aborted.${RESET}"
             return
         fi
         # Proceed to purge
    else
        # Is installed
        print_text "${RED}${BOLD}WARNING: Uninstalling Cursor AI Editor${RESET}"
        print_text "${YELLOW}This will remove the 'cursor' package and its system configuration files.${RESET}"
        print_text "${YELLOW}${BOLD}Are you sure you want to continue? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
            print_text "${YELLOW}${BOLD}[INFO] Uninstallation aborted.${RESET}"
            return
        fi
    fi


    print_text "${BLUE}${BOLD}[1/2]${RESET} ${YELLOW}Purging 'cursor' package...${RESET}"
    # FIX: Use `env` to set DEBIAN_FRONTEND correctly with sudo
    if ! $use_sudo env DEBIAN_FRONTEND=noninteractive apt purge -y cursor; then
         print_text "${RED}${BOLD}[ERROR] Failed to purge cursor package.${RESET}"
         # Attempt to continue with autoremove anyway
    fi


    print_text "${BLUE}${BOLD}[2/2]${RESET} ${YELLOW}Cleaning up dependencies...${RESET}"
    $use_sudo env DEBIAN_FRONTEND=noninteractive apt autoremove -y

    echo
    # Check final status
    if ! dpkg -s cursor &> /dev/null; then
         print_text "${GREEN}${BOLD}Cursor AI Editor has been successfully purged!${RESET}"
    else
         print_text "${YELLOW}${BOLD}[WARNING] 'apt purge' completed, but dpkg still reports the package. Manual check might be needed.${RESET}"
    fi


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

    # This installer is for .deb packages only
    if ! check_deb_system; then
        print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
        read -r
        return 1
    fi

    local install_status
    check_if_installed_and_error
    install_status=$?

    if [[ $install_status -ne 0 ]]; then
        # Not installed or only remnants exist
        print_text "${YELLOW}${BOLD}[INFO] Cursor is not fully installed.${RESET}"
        print_text "${YELLOW}${BOLD}[INFO] Would you like to install it now? (y/n):${RESET} "
        echo -n ""
        read -r choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_cursor
        fi
        return
    fi

    print_text "${YELLOW}${BOLD}[INFO] Checking for updates...${RESET}"

    # Fetch latest version info
    if ! fetch_download_urls; then
         print_text "${RED}${BOLD}[ERROR] Could not check for updates.${RESET}"
         return 1
    fi

    # Get installed version
    local installed_version=""
    local full_installed_version=""
    # Check for the specific "installed" status.
    if dpkg -s cursor 2>/dev/null | grep -q "^Status: install ok installed"; then
        full_installed_version=$(dpkg -s cursor | grep '^Version:' | awk '{ print $2 }')
        # Extract only the base version number (before the hyphen)
        installed_version=$(echo "$full_installed_version" | cut -d'-' -f1)
    else
        # This case should ideally not be reached due to the check at the start
        print_text "${RED}${BOLD}[ERROR] Could not determine installed version unexpectedly.${RESET}"
        installed_version="unknown"
    fi

    print_text "${CYAN}${BOLD}[INFO] Installed version: ${BOLD}$installed_version${RESET}"
    print_text "${CYAN}${BOLD}[INFO] Latest version:    ${BOLD}$APP_VERSION${RESET}" # Aligned output

    # Compare base versions
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

    # The installation function handles updates automatically
    install_cursor
}

# Function to show about information
show_about() {
    display_header

    # Fetch latest version info if not already fetched
    if [[ "$APP_VERSION" == "0.0.0" ]]; then
        fetch_download_urls > /dev/null 2>&1 || true # Ignore errors here, just display defaults
    fi
    local display_version="$APP_VERSION"
    [[ "$display_version" == "0.0.0" ]] && display_version="[Fetching failed]"


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
    print_text "  • ${CYAN}Script version: 3.9 (DEB Edition)${RESET}"
    print_text "  • ${CYAN}Author: Mahesh Technicals${RESET}"
    print_text "  • ${CYAN}Latest App version: ${display_version}${RESET}" # Show version or fallback
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
    print_text "  ${CYAN}-i, --install${RESET}   Install Cursor AI Editor"
    print_text "  ${CYAN}-u, --uninstall${RESET} Uninstall Cursor AI Editor"
    print_text "  ${CYAN}-p, --update${RESET}    Update Cursor AI Editor"
    print_text "  ${CYAN}-r, --reset-ids${RESET} Reset Cursor telemetry & request IDs"
    print_text "  ${CYAN}-a, --about${RESET}     Show information about Cursor"
    print_text "  ${CYAN}-h, --help${RESET}      Display this help message"
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
    # Use grep -oP for lookbehind/lookahead if available for more robustness
    if grep -oP '.*' <<< "" &> /dev/null; then
         grep -oP "(?<=\"$key\": *\")[^\"]*" "$file" | tr -d '\n ' || \
         grep -o "\"$key\": *\"[^\"]*\"" "$file" | cut -d'"' -f4 | tr -d '\n ' # Fallback
    else
         grep -o "\"$key\": *\"[^\"]*\"" "$file" | cut -d'"' -f4 | tr -d '\n '
    fi

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
    # Using a known-good structure might overwrite other user settings,
    # but is safer than trying to parse/modify potentially broken JSON without robust tools.
    cat > "$CONFIG_FILE" << EOF
{
  "telemetry.machineId": "${new_machine_id}",
  "telemetry.macMachineId": "${new_mac_id}",
  "telemetry.devDeviceId": "${new_device_id}",
  "telemetry.sqmId": "",
  "backupWorkspaces": {
    "workspaces": [],
    "folders": [],
    "emptyWindows": []
  },
  "profileAssociations": {
    "workspaces": {},
    "emptyWindows": {}
  },
  "theme": "vs-dark",
  "themeBackground": "#1a1a1a",
  "windowsState": {
    "openedWindows": []
  }
}
EOF
# Simplified the structure slightly to reduce potential issues if user file is very different

    # Verify it's valid JSON
    local json_valid=false
    if command -v jq >/dev/null 2>&1; then
        if jq '.' "$CONFIG_FILE" > /dev/null 2>&1; then
            json_valid=true
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json; json.load(open('$CONFIG_FILE'))" > /dev/null 2>&1; then
            json_valid=true
        fi
    else
        # Cannot verify, assume ok
        json_valid=true
    fi

    if [ "$json_valid" = false ]; then
        print_text "${RED}${BOLD}[ERROR] Created JSON file is invalid. This is unexpected.${RESET}"
        if [ -f "${CONFIG_FILE}.original" ]; then
            print_text "${YELLOW}${BOLD}Restoring original file...${RESET}"
            cp "${CONFIG_FILE}.original" "$CONFIG_FILE"
        fi
        return 1
    fi


    # Get the new IDs for display (re-read from the potentially formatted file)
    new_machine_id=$(get_clean_id "telemetry.machineId" "$CONFIG_FILE")
    new_mac_id=$(get_clean_id "telemetry.macMachineId" "$CONFIG_FILE")
    new_device_id=$(get_clean_id "telemetry.devDeviceId" "$CONFIG_FILE")

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
        chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$CONFIG_FILE"
        if [ -f "${CONFIG_FILE}.original" ]; then
            chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "${CONFIG_FILE}.original"
        fi
        print_text "${YELLOW}${BOLD}[INFO] Fixed file ownership for regular user.${RESET}"
    fi

    # Display backup message based on which backup exists
    if [ -f "${CONFIG_FILE}.original" ]; then # Check for .original first as it's the true original
        print_text "${YELLOW}Original config saved to: ${CONFIG_FILE}.original${RESET}"
    elif [ -f "${CONFIG_FILE}.bak" ]; then
        print_text "${YELLOW}Previous config backup saved to: ${CONFIG_FILE}.bak${RESET}"
    fi


    print_text "${GREEN}${BOLD}Please restart Cursor for changes to take effect.${RESET}"

    local reset_content=(
        "${MAGENTA}${BOLD}REQUEST IDs RESET COMPLETE${RESET}"
    )
    print_box "${reset_content[@]}"
    return 0
}

# Function to reset request IDs (attempts modification, falls back to overwrite)
reset_request_ids() {
    display_header

    # Make sure the config directory exists
    local config_dir=$(dirname "$CONFIG_FILE")
    if [ ! -d "$config_dir" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Config directory not found. Trying to create: $config_dir${RESET}"
        # If running as root, create for the actual user
        if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
            sudo -u "$SUDO_USER" mkdir -p "$config_dir" || {
                 print_text "${RED}${BOLD}[ERROR] Failed to create config directory.${RESET}"
                 return 1
            }
        else
             mkdir -p "$config_dir" || {
                 print_text "${RED}${BOLD}[ERROR] Failed to create config directory.${RESET}"
                 return 1
             }
        fi
    fi

    # If config file doesn't exist, create a new one
    if [ ! -f "$CONFIG_FILE" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Config file not found. Creating a new one with reset IDs.${RESET}"
        # Directly use fix_storage_json which creates the file
        fix_storage_json
        return $? # Return status of fix_storage_json
    fi

    # Check if we have write permission
    local needs_sudo_check=false
    if [ ! -w "$CONFIG_FILE" ]; then
         if [ "$EUID" -eq 0 ]; then
              # Root doesn't have direct write access? Check ownership.
              local file_owner=$(stat -c '%U' "$CONFIG_FILE")
              if [ "$file_owner" != "root" ]; then
                   print_text "${YELLOW}${BOLD}[WARNING] Config file is not owned by root. Trying to proceed...${RESET}"
                   # We might still be able to write via sudo's privileges
              else
                    print_text "${RED}${BOLD}[ERROR] Root user cannot write to $CONFIG_FILE. Check permissions.${RESET}"
                    return 1
              fi
         else
              # Regular user without write access
              print_text "${RED}${BOLD}[ERROR] No write permission for $CONFIG_FILE${RESET}"
              print_text "${YELLOW}${BOLD}You may need to run this command with sudo ('sudo $0 -r') or change file permissions ('chmod u+w $CONFIG_FILE').${RESET}"
              return 1
         fi
         needs_sudo_check=true # Need sudo for modification attempts
    fi

    print_text "${BLUE}${BOLD}[INFO] Reading current telemetry IDs...${RESET}"

    # Use a temporary file for modification attempts
    local tmp_file=$(mktemp)
    cp "$CONFIG_FILE" "$tmp_file"

    # Try a special direct method for the specific storage.json format first as it's safer
    # Check if it has the specific keys we expect fix_storage_json to create
    if grep -q '"backupWorkspaces"' "$tmp_file" && grep -q '"profileAssociations"' "$tmp_file" && grep -q '"windowsState"' "$tmp_file"; then
        print_text "${YELLOW}${BOLD}[INFO] Config file structure looks standard. Using overwrite method.${RESET}"
        fix_storage_json # This handles backup and permissions
        rm -f "$tmp_file" # Clean up temp file
        return $?
    fi

    # If not the standard structure, attempt modification
    print_text "${YELLOW}${BOLD}[INFO] Config file structure differs. Attempting modification...${RESET}"

    # Create backup of original file - only if no backup already exists
    if [ ! -f "${CONFIG_FILE}.bak" ] && [ ! -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Creating backup of original file...${RESET}"
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak" 2>/dev/null || true

        # Fix backup file ownership if running as root
        if [ "$SUDO_USER" ] && [ "$EUID" -eq 0 ]; then
            chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "${CONFIG_FILE}.bak" 2>/dev/null || true
        fi
    elif [ -f "${CONFIG_FILE}.bak" ] || [ -f "${CONFIG_FILE}.original" ]; then
        print_text "${YELLOW}${BOLD}[INFO] Backup already exists, skipping backup creation...${RESET}"
    fi

    # Generate new IDs
    print_text "${BLUE}${BOLD}[INFO] Generating new IDs...${RESET}"
    local new_machine_id=$(generate_hex_string 64)
    local new_mac_id=$(generate_hex_string 64)
    local new_device_id=$(generate_uuid)

    # Read original file content again for display
    local file_content=$(cat "$tmp_file")

    # Extract current IDs using grep and sed
    local current_machine_id=$(echo "$file_content" | grep -o '"telemetry.machineId"[^"]*"[^"]*"' | sed 's/"telemetry.machineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
    local current_mac_id=$(echo "$file_content" | grep -o '"telemetry.macMachineId"[^"]*"[^"]*"' | sed 's/"telemetry.macMachineId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ')
    local current_device_id=$(echo "$file_content" | grep -o '"telemetry.devDeviceId"[^"]*"[^"]*"' | sed 's/"telemetry.devDeviceId".*: *"\([^"]*\)".*/\1/' | tr -d '\n ,')

    # Use sed to replace the values - handle multiline and preserve structure
    print_text "${BLUE}${BOLD}[INFO] Updating telemetry IDs in temporary file...${RESET}"

    # Use different delimiters for sed to avoid issues with slashes in IDs/paths
    sed -i.sedbak "s|\(\"telemetry.machineId\": *\)\"[^\"]*\"|\1\"$new_machine_id\"|g" "$tmp_file"
    sed -i.sedbak "s|\(\"telemetry.macMachineId\": *\)\"[^\"]*\"|\1\"$new_mac_id\"|g" "$tmp_file"
    sed -i.sedbak "s|\(\"telemetry.devDeviceId\": *\)\"[^\"]*\"|\1\"$new_device_id\"|g" "$tmp_file"
    rm -f "$tmp_file.sedbak" 2>/dev/null

    # Add keys if they don't exist (basic attempt, might break JSON if file is complex)
    if ! grep -q '"telemetry.machineId"' "$tmp_file"; then
         # Add near the beginning, assuming simple JSON object
         sed -i '2i\ \ "telemetry.machineId": "'$new_machine_id'",' "$tmp_file"
    fi
     if ! grep -q '"telemetry.macMachineId"' "$tmp_file"; then
         sed -i '2i\ \ "telemetry.macMachineId": "'$new_mac_id'",' "$tmp_file"
    fi
     if ! grep -q '"telemetry.devDeviceId"' "$tmp_file"; then
         sed -i '2i\ \ "telemetry.devDeviceId": "'$new_device_id'",' "$tmp_file"
         # Attempt to remove trailing comma if we added the last key
         sed -i '$ s/,$//' "$tmp_file"
    fi


    # Verify the temporary file is valid JSON before overwriting
    local json_valid=false
    if command -v jq >/dev/null 2>&1; then
        if jq '.' "$tmp_file" > /dev/null 2>&1; then
            json_valid=true
        fi
    elif command -v python3 >/dev/null 2>&1; then
        if python3 -c "import json; json.load(open('$tmp_file'))" > /dev/null 2>&1; then
            json_valid=true
        fi
    else
        print_text "${YELLOW}${BOLD}[WARNING] Cannot validate JSON structure. Proceeding with potentially invalid file.${RESET}"
        json_valid=true # Cannot verify, assume ok and proceed carefully
    fi


    local success=false
    if [ "$json_valid" = true ]; then
        # Overwrite original file
        print_text "${BLUE}${BOLD}[INFO] Applying changes...${RESET}"
        # Use cat and redirection, potentially with sudo
        if [ "$needs_sudo_check" = true ] || [ "$EUID" -eq 0 ]; then
            cat "$tmp_file" | sudo tee "$CONFIG_FILE" > /dev/null || {
                 print_text "${RED}${BOLD}[ERROR] Failed to write changes to $CONFIG_FILE even with sudo.${RESET}"
                 rm -f "$tmp_file"
                 return 1
            }
            # Fix ownership after tee with sudo
             if [ "$SUDO_USER" ]; then
                 sudo chown "$SUDO_USER:$(id -gn "$SUDO_USER")" "$CONFIG_FILE"
             fi

        else
            cat "$tmp_file" > "$CONFIG_FILE" || {
                 print_text "${RED}${BOLD}[ERROR] Failed to write changes to $CONFIG_FILE.${RESET}"
                 rm -f "$tmp_file"
                 return 1
            }
        fi
        success=true
    else
        print_text "${RED}${BOLD}[ERROR] Modification resulted in invalid JSON. Changes not applied.${RESET}"
        print_text "${YELLOW}${BOLD}Your original file is preserved.${RESET}"
        if [ -f "${CONFIG_FILE}.bak" ]; then
            print_text "${YELLOW}A backup was created at: ${CONFIG_FILE}.bak${RESET}"
        fi
        success=false
    fi

    rm -f "$tmp_file" # Clean up temp file

    # Display results
    echo
    if [ "$success" = true ]; then
        print_text "${GREEN}${BOLD}✅ Telemetry IDs have been reset!${RESET}"
    else
        print_text "${RED}${BOLD}❌ Failed to reset telemetry IDs.${RESET}"
    fi

    echo
    print_text "${CYAN}${BOLD}Old Values (approximate):${RESET}"
    print_text "${YELLOW}Machine ID:    ${RESET}${current_machine_id:-[Not Found]}"
    print_text "${YELLOW}Mac ID:        ${RESET}${current_mac_id:-[Not Found]}"
    print_text "${YELLOW}Device ID:     ${RESET}${current_device_id:-[Not Found]}"
    echo
    print_text "${CYAN}${BOLD}New Values:${RESET}"
    print_text "${GREEN}Machine ID:    ${RESET}${new_machine_id}"
    print_text "${GREEN}Mac ID:        ${RESET}${new_mac_id}"
    print_text "${GREEN}Device ID:     ${RESET}${new_device_id}"
    echo

    if [ -f "${CONFIG_FILE}.bak" ]; then
        print_text "${YELLOW}Backup saved to: ${CONFIG_FILE}.bak${RESET}"
    fi

    if [ "$success" = true ]; then
        print_text "${GREEN}${BOLD}Please restart Cursor for changes to take effect.${RESET}"
    fi

    local reset_content=(
        "${MAGENTA}${BOLD}REQUEST IDs RESET COMPLETE${RESET}"
    )
    print_box "${reset_content[@]}"

    # Return success/failure based on whether changes were applied
     if [ "$success" = true ]; then return 0; else return 1; fi

}


# Function to display status table
display_status_table() {
    # Get installed version if available
    local installed_version="Not installed yet"
    local full_installed_version=""
    # Check for the specific "installed" status.
    if dpkg -s cursor 2>/dev/null | grep -q "^Status: install ok installed"; then
        full_installed_version=$(dpkg -s cursor | grep '^Version:' | awk '{ print $2 }')
        # Extract only the base version number (before the hyphen)
        installed_version=$(echo "$full_installed_version" | cut -d'-' -f1)
    fi

    # Fetch latest version
    # Only fetch if APP_VERSION hasn't been set yet or failed previously
    if [[ "$APP_VERSION" == "0.0.0" ]]; then
        fetch_download_urls > /dev/null 2>&1 || true # Try to fetch, ignore errors for display
    fi

    local latest_version="$APP_VERSION"
    # If fetching failed, show placeholder
    [[ "$latest_version" == "0.0.0" ]] && latest_version="[Fetching failed]"


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
        value_padding=$(( value_padding < 0 ? 0 : value_padding )) # Ensure not negative
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
    if [[ "$installed_version" == "Not installed yet" ]]; then
        version_color=$RED
    fi

    installed_row+="${CYAN}${BOLD}║${RESET} ${version_color}$installed_version${RESET}"
    local value_padding=$((col2_width - ${#installed_version} - 1))
    value_padding=$(( value_padding < 0 ? 0 : value_padding )) # Ensure not negative
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
     value_padding=$(( value_padding < 0 ? 0 : value_padding )) # Ensure not negative
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
            reset_request_ids # Let the function handle permission checks/prompts
            ask_main_menu
            ;;
        *)
            # All other commands require root
            check_root || exit 1

            case "$1" in
                -i|--install)
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

# Fetch the latest version information at startup (silently)
fetch_download_urls > /dev/null 2>&1 || true

# Main menu loop
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
                continue # Go back to menu if root check fails
            fi

            # Check if it's a debian system
            if ! check_deb_system; then
                print_text "${YELLOW}Press Enter to return to the main menu...${RESET}"
                read -r
                continue # Go back to menu if not Debian
            fi

            case "$choice" in
                1)
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
            # Reset Request ID handles its own permission checks/prompts
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
            read -r # Wait for user input before showing menu again
            ;;
    esac
done
