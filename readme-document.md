# Ultimate Development Environment Setup Script - Documentation

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Features](#features)
- [Module Details](#module-details)
  - [1. Full Development Environment Setup](#1-full-development-environment-setup)
  - [2. Browser & Privacy Optimizer](#2-browser--privacy-optimizer)
  - [3. AI Modeling Workspace Generator](#3-ai-modeling-workspace-generator)
  - [4. Clean Slate Windows Configuration](#4-clean-slate-windows-configuration)
  - [5. Downloads Organizer](#5-downloads-organizer)
  - [6. Dotfiles Syncer](#6-dotfiles-syncer)
  - [7. System Backup](#7-system-backup)
  - [8. Academic Project Tracker](#8-academic-project-tracker)
  - [9. Configure All Tools](#9-configure-all-tools)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Frequently Asked Questions](#frequently-asked-questions)

## Overview

This script provides a modular, comprehensive solution for setting up a complete development environment. It automates the installation and configuration of tools, libraries, and productivity enhancements for development work across multiple domains including web development, data science, cloud computing, and academic projects.

The script detects your platform (WSL, Linux, or macOS) and adapts accordingly, making it versatile for different development environments.

## Prerequisites

- **Operating System**: Ubuntu/Debian-based Linux, WSL (Windows Subsystem for Linux), or macOS
- **Sudo Access**: Administrator privileges to install system packages
- **Bash Shell**: The script is designed to run in a bash environment
- **Internet Connection**: Required for downloading packages and tools

## Quick Start

1. **Download the script**:
   ```bash
   curl -o setup.sh https://raw.githubusercontent.com/YourUsername/dev-setup/main/setup.sh
   ```

2. **Make the script executable**:
   ```bash
   chmod +x setup.sh
   ```

3. **Run the script**:
   ```bash
   ./setup.sh
   ```

4. **Select your desired setup option** from the interactive menu

## Features

- **Modular Design**: Choose which components to set up
- **Cross-Platform**: Works on WSL, Linux, and macOS with platform-specific adaptations
- **Comprehensive Logging**: Detailed logs of all actions for troubleshooting
- **Error Handling**: Robust error handling with retry mechanisms
- **Visual Feedback**: Color-coded output for better readability
- **Customizable**: Easily modified for personal preferences

## Module Details

### 1. Full Development Environment Setup

This module installs and configures a complete development environment with:

- **Essential Tools**: Build tools, version control, and terminal utilities
- **Shell Enhancement**: Zsh with Oh My Zsh, plugins, and themes
- **Web Development**: Node.js, npm, and global packages
- **Data Science & ML**: Python packages for data analysis and machine learning
- **Databases**: PostgreSQL, MongoDB, Redis, and SQLite
- **Containerization**: Docker and Docker Compose
- **Kubernetes**: kubectl and minikube
- **Cloud Tools**: AWS, Azure, and Google Cloud CLIs
- **IDE Configuration**: VS Code extensions and settings

**Usage**:
```
Select option 1 from the main menu
```

**Notes**:
- Installation may take 15-30 minutes depending on your internet speed
- Some tools will prompt for user input during installation

### 2. Browser & Privacy Optimizer

This module optimizes your browser setup with privacy-focused configurations:

- Installs Brave and Chrome browsers
- Disables Microsoft Edge bloat features
- Sets up browser defaults for privacy
- Provides links to install essential privacy and developer extensions
- Configures Windows privacy settings

**Usage**:
```
Select option 2 from the main menu
```

**Notes**:
- This feature works best on Windows with WSL
- Some configurations require manual confirmation

### 3. AI Modeling Workspace Generator

Creates a structured project environment specifically for AI/ML work:

- Sets up standard project directories (data, models, notebooks, etc.)
- Creates virtual environment with essential libraries
- Installs Jupyter with dedicated kernel
- Adds template notebooks and utility scripts
- Optionally downloads starter datasets

**Usage**:
```
Select option 3 from the main menu
```

**Example dataset options**:
- MNIST (handwritten digits)
- CIFAR-10 (images)
- Iris (classification)
- Boston Housing (regression)

### 4. Clean Slate Windows Configuration

Optimizes Windows for development work:

- Disables hibernation and telemetry
- Configures Explorer settings for development
- Sets up power management optimized for development
- Installs and configures PowerToys with FancyZones
- Enables dark mode

**Usage**:
```
Select option 4 from the main menu
```

**Notes**:
- Requires running a PowerShell script as Administrator in Windows
- Some settings may require a restart to take effect

### 5. Downloads Organizer

Creates an automated system to keep your Downloads folder organized:

- Sorts downloads by file type into categorized folders
- Automatically moves new downloads to appropriate folders
- Configurable cleanup of old temporary files
- Can be scheduled to run automatically

**Usage**:
```
Select option 5 from the main menu
```

**Organization categories**:
- Installers (exe, msi, etc.)
- Images (jpg, png, etc.)
- Documents (pdf, docx, etc.)
- Archives (zip, rar, etc.)

### 6. Dotfiles Syncer

Sets up a system to backup and synchronize your configuration files:

- Creates a Git repository for your dotfiles
- Backs up and restores configuration files
- Syncs settings across multiple machines
- Handles VS Code settings and snippets
- Includes scheduled backups

**Usage**:
```
Select option 6 from the main menu
```

**Sync targets include**:
- Shell configurations (.zshrc, .bashrc)
- Git configuration
- Editor settings
- Custom aliases and functions

### 7. System Backup

Implements a comprehensive backup solution:

- Backs up projects, code, and configurations
- Supports encrypted backups for sensitive data
- Creates scheduled backups (daily, weekly, or monthly)
- Handles retention policies
- Generates restore scripts for each backup

**Usage**:
```
Select option 7 from the main menu
```

**Backup destinations**:
- Local directories
- Network drives
- Cloud storage (via mounted drives)

### 8. Academic Project Tracker

Creates a system to manage academic assignments and deadlines:

- Tracks assignment details and due dates
- Creates project directories for each assignment
- Provides deadline notifications and reminders
- Includes commands to list tasks due today or this week
- Supports markdown documentation for each assignment

**Usage**:
```
Select option 8 from the main menu
```

**Commands**:
- `task list` - List all tasks
- `task add` - Add a new task
- `task complete <id>` - Mark a task as complete
- `task view <id>` - View task details
- `task week` - See tasks due this week

### 9. Configure All Tools

Provides a way to set global configurations across all tools:

- Configures Git with user information
- Sets up backup paths
- Configures editor preferences
- Sets ZSH theme and plugins
- Configures VS Code settings

**Usage**:
```
Select option 9 from the main menu
```

## Customization

You can customize the script by editing the variables at the top:

```bash
# Edit these variables to customize your setup
DEFAULT_USERNAME="YourName"
DEFAULT_EMAIL="your.email@example.com"
DEFAULT_GITHUB_USERNAME="YourGitHubUsername"

# Project folders to create
PROJECTS=("project1" "project2" "web-projects" "experiments")

# Web browser settings
DEFAULT_BROWSER="brave"  # Options: brave, chrome, firefox
DEFAULT_SEARCH="google"  # Options: google, duckduckgo, brave

# Backup settings
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPT=true
```

## Troubleshooting

### Common Issues

**Issue**: Script fails with permission errors
**Solution**: Make sure you have sudo access and the script is executable (`chmod +x setup.sh`)

**Issue**: Package installation fails
**Solution**: Check your internet connection, try running the specific module again

**Issue**: WSL-specific features not working correctly
**Solution**: Ensure WSL is properly configured with Windows integration

**Issue**: Browser optimizer doesn't work on Linux
**Solution**: This feature is designed for Windows. For Linux, use the appropriate package manager to install browsers

### Logs

The script creates detailed logs in the `~/scripts/logs/` directory. Check these logs for detailed error information:

```bash
cat ~/scripts/logs/setup_YYYY-MM-DD_HH-MM-SS.log
```

## Frequently Asked Questions

**Q: Can I run only specific parts of the script?**
A: Yes, the script offers a menu where you can select specific modules to run.

**Q: Is it safe to run the script multiple times?**
A: Yes, the script is designed to be idempotent - running it multiple times won't cause issues.

**Q: Does this work on Windows directly (not WSL)?**
A: Some modules (like the Browser Optimizer and Clean Slate Configuration) work on Windows directly through PowerShell, but most features require WSL.

**Q: How do I update tools installed by this script?**
A: Most tools can be updated using their native update mechanisms. For a complete refresh, you can run the script again.

**Q: Can I contribute to this script?**
A: Yes! The script is open source - feel free to submit pull requests or create issues on the GitHub repository.
