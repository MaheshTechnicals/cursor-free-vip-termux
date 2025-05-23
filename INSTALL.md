# Detailed Installation Instructions

This document provides comprehensive installation instructions for Cursor AI Editor on both Android and Linux platforms.

## Android Installation (with Termux)

### Step 1: Install Termux

1. Download and install Termux from [F-Droid](https://f-droid.org/en/packages/com.termux/) (recommended) or Google Play Store.

### Step 2: Install Linux on Android

Choose one of the following options to install a Linux distribution on your Android device:

#### Option 1: Install Kali Linux
Follow this detailed guide: [How to Install Kali Linux on Android (No Root) 2025](https://maheshtechnicals.com/how-to-install-kali-linux-on-android-no-root-2024/)

#### Option 2: Install Ubuntu (Recommended)
Follow this detailed guide: [How to Install Ubuntu 24.04 on Android Without Root](https://maheshtechnicals.com/how-to-install-ubuntu-24-04-on-android-without-root/)

### Step 3: Install Cursor AI Editor

Once you're in your Linux environment (Kali or Ubuntu):

1. Download the installer script:
   ```bash
   wget https://raw.githubusercontent.com/MaheshTechnicals/cursor-installer/main/cursor.sh
   ```

2. Make the script executable:
   ```bash
   chmod +x cursor.sh
   ```

3. Run the installer:
   
   If you are in Ubuntu/Kali as a regular user (recommended):
   ```bash
   sudo bash cursor.sh
   ```
   
   If you are already in a root shell (e.g., if you used `sudo -i` or logged in as root):
   ```bash
   bash cursor.sh
   ```

4. Follow the on-screen instructions from the interactive menu.

> **Note**: Using `sudo` is important for proper installation as Cursor needs system-wide access. If you get "command not found" for sudo, you may need to install it first with: `apt update && apt install sudo`

### Step 4: Starting Cursor on Android

After installation, you'll need to run Cursor from within your Linux environment:

1. Launch Cursor (no sudo needed for launching):
   ```bash
   cursor --no-sandbox
   ```

## Linux Installation

### Step 1: Download the installer script

```bash
wget https://raw.githubusercontent.com/MaheshTechnicals/cursor-installer/main/cursor.sh
```

### Step 2: Make the script executable

```bash
chmod +x cursor.sh
```

### Step 3: Run the installer with sudo

```bash
sudo bash cursor.sh
```

### Step 4: Follow the interactive menu

Choose option 1 to install Cursor AI Editor, or use any of the other options as needed.

### Alternative: Direct installation with command-line option

```bash
sudo bash cursor.sh -i
```

## Troubleshooting

### Common Issues on Android

1. **"sudo: command not found" error**: Install sudo first:
   ```bash
   apt update && apt install sudo
   ```

2. **Permission denied errors**: Make sure you're using sudo for installation commands.

3. **Installation fails**: Ensure you have enough free space (at least 1GB recommended).

4. **Black screen when launching**: Try running with the `--no-sandbox` flag.

5. **Performance issues**: Close background apps to free up memory.

### Common Issues on Linux

1. **Permission errors**: Make sure you're using `sudo` for installation and uninstallation.

2. **Missing dependencies**: The script should handle these automatically, but if it fails, try manually installing: `sudo apt install wget grep sed awk`.

3. **Cursor doesn't launch**: Make sure the symbolic link was created by checking `which cursor`.

For additional help, please [open an issue](https://github.com/MaheshTechnicals/cursor-installer/issues/new) on the GitHub repository. 