# Cursor AI Editor Installer for Android & Linux | The Ultimate Setup Tool

<p align="center">
  <img src="logo.jpg" alt="Cursor AI Editor - AI-powered code editor for Android and Linux" width="200">
</p>

> The most comprehensive installer script for Cursor AI Editor on Android devices (via Termux) and Linux systems - bringing the revolutionary AI-powered code editor to mobile developers and Linux users alike (supports both ARM64 & x86_64).

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform: Android & Linux](https://img.shields.io/badge/Platform-Android%20%26%20Linux-brightgreen)](https://github.com/MaheshTechnicals/cursor-installer)
[![Architecture: ARM64 & x86_64](https://img.shields.io/badge/Architecture-ARM64%20%26%20x86__64-blue)](https://github.com/MaheshTechnicals/cursor-installer)
[![Bash Script](https://img.shields.io/badge/Language-Bash-green.svg)](https://github.com/MaheshTechnicals/cursor-installer)

## 📋 Table of Contents
- [Overview](#overview)
- [Key Features](#key-features)
- [Android Installation Guide](#android-installation-guide)
- [Linux Installation Guide](#linux-installation-guide)
- [Command Line Reference](#command-line-reference)
- [System Requirements](#system-requirements)
- [Status Information](#status-information)
- [Enhanced Privacy Controls](#enhanced-privacy-controls)
- [Troubleshooting Guide](#troubleshooting-guide)
- [Copyright and License](#copyright-and-license)
- [About the Developer](#about-the-developer)

## Overview

This installer provides a seamless way to set up [Cursor AI Editor](https://cursor.sh) on Android devices (via Termux) and Linux systems. Cursor is the cutting-edge AI-powered code editor that enhances developer productivity with intelligent code completion, debugging assistance, and GitHub Copilot integration. Now you can enjoy professional coding with AI assistance directly on your Android phone or tablet!

## Key Features

- 📱 **Android-First Design**: Specially optimized for Android devices using Termux
- 🚀 **One-Click Installation**: Install Cursor AI Editor with a single command
- 🔄 **Zero-Downtime Updates**: Update to the latest version without losing your settings
- 🧹 **Complete Uninstallation**: Fully remove Cursor with all configurations when no longer needed
- 🔒 **Enhanced Privacy Controls**: Reset request IDs and telemetry with a single click
- 📊 **Real-Time Status Monitoring**: View installation status and version information
- ⚙️ **Cross-Platform Compatibility**: Works on both Android (ARM64) and Linux (x86_64)
- 🔧 **Automatic Dependency Management**: Intelligent detection and installation of required dependencies

## Android Installation Guide

### Setting Up Termux (Prerequisite)

1. Install [Termux from F-Droid](https://f-droid.org/en/packages/com.termux/) (recommended) or Google Play

2. Install a Linux distribution on your Android device using one of these guides:
   
   - **Kali Linux (Option 1)**: [How to Install Kali Linux on Android (No Root) 2025](https://maheshtechnicals.com/how-to-install-kali-linux-on-android-no-root-2024/)
   
   - **Ubuntu (Option 2, Recommended)**: [How to Install Ubuntu 24.04 on Android Without Root](https://maheshtechnicals.com/how-to-install-ubuntu-24-04-on-android-without-root/)

### Installing Cursor on Android

Once you're in the Linux environment (Kali or Ubuntu):

1. Download the installer script:
   ```bash
   wget https://raw.githubusercontent.com/MaheshTechnicals/cursor-free-vip-termux/refs/heads/main/cursor.sh
   ```

2. Make it executable:
   ```bash
   chmod +x cursor.sh
   ```

3. Run the installer with sudo (for proper system-wide installation):
   ```bash
   sudo bash cursor.sh
   ```

4. Follow the on-screen instructions to complete the installation.

> **Note:** If you get "sudo: command not found", install it first with: `apt update && apt install sudo`

## Linux Installation Guide

### Quick Install Method

For fast installation with interactive menu:

```bash
sudo bash cursor.sh
```

### Command Line Reference

```
Usage: cursor.sh [OPTION]

Options:
  -i, --install     Install Cursor AI Editor with automatic dependency resolution
  -u, --uninstall   Completely remove Cursor AI Editor from your system
  -p, --update      Update to the latest Cursor AI Editor version
  -r, --reset-ids   Reset Cursor telemetry & request IDs for enhanced privacy
  -a, --about       Show detailed information about Cursor AI Editor
  -h, --help        Display this comprehensive help message
```

#### Practical Examples

Install Cursor AI Editor directly:
```bash
sudo bash cursor.sh -i
```

Reset your request IDs for improved privacy (no root required):
```bash
bash cursor.sh -r
```

## System Requirements

### For Android:
- **Device**: Any Android phone or tablet with ARM64 architecture
- **Android Version**: Android 7.0 or higher recommended
- **App**: Termux with proot-distro and Ubuntu installed
- **Storage**: Minimum 1GB free space recommended
- **RAM**: 3GB or more for optimal performance

### For Linux:
- **Operating System**: Any modern Linux distribution (Ubuntu, Debian, Fedora, Arch, CentOS, etc.)
- **Permissions**: Root access (for installation/uninstallation operations)
- **Dependencies**: Automatically managed (wget, grep, sed, awk)
- **Architecture**: ARM64 or x86_64 processor
- **Storage**: Minimum 500MB free disk space recommended

## Status Information

The installer features an innovative status dashboard that displays:
- Application identification with name verification
- Currently installed version with update availability check
- Latest available version from official repositories
- Color-coded status indicators for better visibility

## Enhanced Privacy Controls

Maintain control over your data with advanced privacy features:

```bash
bash cursor.sh -r
```

This command:
- Resets all telemetry identifiers
- Creates secure backups of your original configuration
- Generates new randomized identifiers
- Preserves your editor settings and preferences

## Troubleshooting Guide

### Android-Specific Issues:
1. **Termux Errors**: Ensure you have the latest Termux from F-Droid
2. **proot-distro Issues**: Try `pkg reinstall proot-distro` if encountering problems
3. **Space Limitations**: Android users may need to clear space or use external storage
4. **Performance**: Close background apps for better performance on Android devices

### General Issues:
1. **Permission Errors**: Ensure you have appropriate root privileges when needed
2. **Network Issues**: Verify internet connectivity for downloading application files
3. **Architecture Compatibility**: Confirm your device architecture is supported (ARM64 or x86_64)
4. **Dependency Problems**: The script will automatically install required dependencies

## Copyright and License

This script is provided under the MIT License - free to use, modify and distribute.

## About the Developer

Developed with ❤️ by Mahesh Technicals  
Version: 3.0

---

## 💖 Support The Project

If you find this tool helpful and want to support my work, please consider buying me a coffee!

<a href="https://www.paypal.com/paypalme/Varma161" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>

- **UPI:** `maheshtechnicals@apl`

---

<p align="center">
  <sub>© 2025 Mahesh Technicals. All rights reserved.</sub>
</p>
