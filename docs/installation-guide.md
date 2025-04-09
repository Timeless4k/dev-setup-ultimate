# Installation Guide

This guide provides detailed instructions for installing and setting up the Ultimate Development Environment Setup Script on different platforms.

## WSL (Windows Subsystem for Linux)

### Prerequisites

1. **Install WSL on Windows**
   - Open PowerShell as Administrator and run:
   ```powershell
   wsl --install
   ```
   - Reboot your computer when prompted
   - After reboot, a Ubuntu window will open to finalize installation

2. **Update WSL Ubuntu**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

### Installation

1. **Download the script**
   ```bash
   curl -o setup.sh https://raw.githubusercontent.com/username/dev-setup/main/setup.sh
   ```
   
   Or create it manually:
   ```bash
   nano setup.sh
   ```
   - Paste the script content
   - Press Ctrl+O to save, then Ctrl+X to exit

2. **Make the script executable**
   ```bash
   chmod +x setup.sh
   ```

3. **Run the script**
   ```bash
   ./setup.sh
   ```

4. **For Windows-specific features**
   
   When using modules that require Windows access (like Browser Optimizer):
   
   ```powershell
   # In PowerShell (run as Administrator)
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Path to the PowerShell script in WSL
   PowerShell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\yourusername\scripts\productivity\browser_privacy_setup.ps1"
   ```

## Ubuntu/Debian Linux

### Prerequisites

1. **Update your system**
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install curl**
   ```bash
   sudo apt install -y curl
   ```

### Installation

1. **Download the script**
   ```bash
   curl -o setup.sh https://raw.githubusercontent.com/username/dev-setup/main/setup.sh
   ```

2. **Make the script executable**
   ```bash
   chmod +x setup.sh
   ```

3. **Run the script**
   ```bash
   ./setup.sh
   ```

## macOS

### Prerequisites

1. **Install Homebrew** (if not already installed)
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Update Homebrew**
   ```bash
   brew update
   ```

### Installation

1. **Download the script**
   ```bash
   curl -o setup.sh https://raw.githubusercontent.com/username/dev-setup/main/setup.sh
   ```

2. **Make the script executable**
   ```bash
   chmod +x setup.sh
   ```

3. **Run the script**
   ```bash
   ./setup.sh
   ```

4. **Note for macOS users**
   
   Some features are optimized for Linux/WSL environments. The script will adapt to macOS where possible, but certain modules (like the Windows-specific optimizers) won't be applicable.

## Customization Before Installation

Before running the script, you may want to customize it for your specific needs:

1. **Edit the configuration section**
   ```bash
   nano setup.sh
   ```

2. **Modify these variables at the top of the script**
   ```bash
   # ======= Configuration (Edit these variables) =======
   DEFAULT_USERNAME="YourName"
   DEFAULT_EMAIL="your.email@example.com"
   DEFAULT_GITHUB_USERNAME="YourGitHubUsername"
   
   # Paths
   HOME_DIR="$HOME"
   SCRIPTS_DIR="$HOME_DIR/scripts"
   CONFIG_DIR="$SCRIPTS_DIR/config"
   PROJECTS_DIR="$HOME_DIR/Projects"
   DEFAULT_BACKUP_DIR="/path/to/backups"
   
   # Project folders to create
   PROJECTS=("your-project-1" "your-project-2" "web-projects" "experiments")
   ```

3. **Save the changes** (Ctrl+O, then Ctrl+X in nano)

## Post-Installation

After installation, you should:

1. **Restart your terminal** to apply shell changes

2. **Configure Git** (if not done during installation)
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

3. **Set up SSH keys for GitHub** (if needed)
   ```bash
   ssh-keygen -t ed25519 -C "your.email@example.com"
   cat ~/.ssh/id_ed25519.pub
   ```
   - Copy the output and add it to your GitHub account

4. **Test installed tools** to ensure everything is working properly
   ```bash
   # Test Node.js
   node --version
   
   # Test Python
   python3 --version
   
   # Test Docker
   docker --version
   ```

5. **Explore available commands**
   
   The script adds several useful aliases. Try:
   ```bash
   # List all aliases
   alias
   
   # Try some of the custom commands
   task help
   organize
   backup
   ```

## Uninstallation

If you need to uninstall or start over:

1. **Remove created directories**
   ```bash
   rm -rf ~/scripts
   ```

2. **Remove installed packages** (optional, varies by module used)
   
   This will depend on which modules you installed. For example:
   ```bash
   # Remove databases
   sudo apt remove postgresql postgresql-contrib mongodb-org redis-server
   
   # Remove Docker
   sudo apt remove docker docker-engine docker.io containerd runc
   ```

3. **Reset configurations** (optional)
   ```bash
   rm -f ~/.zshrc ~/.bash_aliases
   ```
