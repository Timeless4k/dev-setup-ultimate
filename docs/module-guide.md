# Module-by-Module Guide

This guide provides detailed information about each module in the development environment setup script, with examples, screenshots, and expected outcomes.

## 1. Full Development Environment Setup

This is the most comprehensive module that installs and configures a complete development environment.

### What It Installs

- **Shell**: Zsh with Oh My Zsh, Powerlevel10k theme
- **Development Tools**: Build tools, Git, tmux, curl, wget
- **Node.js**: via NVM with latest LTS version
- **Python**: Core packages, data science libraries, ML frameworks
- **Databases**: PostgreSQL, MongoDB, Redis, SQLite
- **Containerization**: Docker, Docker Compose
- **Kubernetes**: kubectl, minikube
- **Cloud CLIs**: AWS, Azure, Google Cloud
- **IDE Extensions**: VS Code extensions for development

### Usage Example

From the main menu, select option 1:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
1. 💻 Full Development Environment Setup
...
Enter your choice [0-9]: 1
```

The script will:

1. Update system packages
2. Install essential tools
3. Configure Git
4. Install and configure Zsh with Oh My Zsh
5. Install Node.js, Python, and various development tools
6. Set up databases and cloud tools
7. Configure VS Code extensions

### Expected Output

```
ℹ️ Starting development environment setup...
ℹ️ Updating system packages...
✅ System update completed
ℹ️ Installing essential tools...
✅ Essential tools installation completed
ℹ️ Setting up Git global config...
✅ Git configuration completed
...
✅ Development environment setup complete!

Restart your terminal or run 'source ~/.zshrc' to activate all changes.
```

### After Installation

After installation, your terminal will have:
- Colorized prompt with Git integration
- Syntax highlighting and autosuggestions
- Development aliases like `gs` (git status), `dcu` (docker-compose up)
- Python virtual environment tools 
- Node.js with npm

## 2. Browser & Privacy Optimizer

This module sets up browsers with privacy enhancements and developer extensions.

### What It Does

- Installs Brave Browser and Google Chrome
- Disables Microsoft Edge bloat features
- Sets up privacy-focused browser extensions
- Configures Windows privacy settings
- Downloads and runs O&O ShutUp10++ for additional privacy

### Usage Example

From the main menu, select option 2:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
2. 🌐 Browser & Privacy Optimizer
...
Enter your choice [0-9]: 2
```

On WSL, you'll be provided with instructions to run a PowerShell script:

```
✅ Browser & Privacy Optimizer script created at /home/user/scripts/productivity/browser_privacy_setup.ps1

To run this script in Windows:
1. Open PowerShell as Administrator
2. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
3. Run: PowerShell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\user\scripts\productivity\browser_privacy_setup.ps1"
```

### Windows Execution

In Windows PowerShell (Administrator), after running the command:

```
🌐 Starting Browser & Privacy Optimization...
⬇️ Installing Brave Browser...
⬇️ Installing Google Chrome...
🔧 Disabling Microsoft Edge features...
🔍 Setting up Google as default search engine...
✨ Opening Brave to install extensions...
🔒 Configuring Windows privacy settings...
⬇️ Downloading O&O ShutUp10++...
🔧 Running O&O ShutUp10++ with recommended settings...
✅ Browser & Privacy Optimization Complete!
```

### After Installation

- Brave Browser and Chrome will be installed
- Browser extensions will be ready to install (links opened)
- Windows privacy settings will be optimized
- O&O ShutUp10++ will be available for additional privacy configurations

## 3. AI Modeling Workspace Generator

This module creates a structured project environment for AI/ML development.

### What It Creates

- Project directory structure (notebooks, scripts, models, data)
- Python virtual environment with data science packages
- Jupyter Lab kernel specific to the project
- Starter notebooks for data exploration and modeling
- Utility scripts for data processing and model training
- Optional starter datasets (MNIST, CIFAR-10, Iris, Boston)

### Usage Example

From the main menu, select option 3:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
3. 🧠 Create AI Modeling Workspace
...
Enter your choice [0-9]: 3
```

You'll be prompted for project details:

```
Enter project name (e.g., sentiment-analysis): image-classifier

Select dataset type:
1. None (default)
2. MNIST (handwritten digits)
3. CIFAR-10 (images)
4. Iris (classification)
5. Boston Housing (regression)
Enter your choice [1-5]: 3
```

### Created Project Structure

```
image-classifier/
├── README.md
├── requirements.txt
├── venv/                  # Virtual environment
├── data/
│   ├── raw/               # Original data
│   ├── processed/         # Cleaned data
│   └── external/          # External data sources
├── notebooks/
│   ├── 01_data_exploration.ipynb
│   └── 02_model_development.ipynb
├── scripts/
│   ├── data_processing.py
│   ├── train_model.py
│   └── load_cifar10.py    # If CIFAR-10 was selected
├── models/                # For saved models
└── results/
    ├── figures/           # For visualizations
    └── tables/            # For result tables
```

### After Creation

```
✅ AI project 'image-classifier' created successfully!
📂 Project location: /home/user/Projects/image-classifier

To get started:
  cd /home/user/Projects/image-classifier
  source venv/bin/activate
  ./run_jupyter.sh
```

## 4. Clean Slate Windows Configuration

This module optimizes Windows settings for development work.

### What It Configures

- Disables hibernation and telemetry
- Enables dark mode
- Optimizes File Explorer settings for development
- Sets power settings for development work
- Installs PowerToys with FancyZones layout

### Usage Example

From the main menu, select option 4:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
4. 🪄 Clean Slate Windows Configuration
...
Enter your choice [0-9]: 4
```

For WSL users, instructions will be provided:

```
✅ Clean Slate Windows Configuration script created at /home/user/scripts/productivity/clean_slate_config.ps1

To run this script in Windows:
1. Open PowerShell as Administrator
2. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
3. Run: PowerShell.exe -ExecutionPolicy Bypass -File "\\wsl.localhost\Ubuntu\home\user\scripts\productivity\clean_slate_config.ps1"
```

### Windows Execution

In Windows PowerShell (Administrator), after running the command:

```
🪄 Starting Clean Slate Windows Configuration...
💤 Disabling hibernation...
🔒 Disabling telemetry...
🔕 Disabling non-critical notifications...
☁️ Disabling OneDrive auto-start...
🌙 Enabling dark mode...
⚡ Setting power configuration...
📂 Configuring File Explorer settings...
🔧 Installing PowerToys (if not already installed)...
📱 Setting up FancyZones layout...
🔄 Restarting Explorer to apply changes...
✅ Clean Slate Windows Configuration Complete!
```

### After Configuration

- Windows will be optimized for development
- Explorer will show file extensions and hidden files
- PowerToys will be installed with a productivity layout
- Dark mode will be enabled
- Power settings will be optimized for development

## 5. Downloads Organizer

This module creates an automated system to keep your Downloads folder organized.

### What It Does

- Organizes files by type (installers, images, documents, archives)
- Automatically sorts new downloads
- Optionally cleans up old files
- Can be scheduled to run daily

### Usage Example

From the main menu, select option 5:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
5. 🗂️ Setup Downloads Organizer
...
Enter your choice [0-9]: 5
```

You'll be prompted for configuration:

```
Enter the full path to your Downloads folder: /mnt/c/Users/YourUsername/Downloads

Do you want to customize which file types to organize? (y/n): y
Organize installer files (exe, msi, etc.)? (y/n) [y]: y
Organize image files (jpg, png, etc.)? (y/n) [y]: y
Organize document files (pdf, docx, etc.)? (y/n) [y]: y
Organize archive files (zip, rar, etc.)? (y/n) [y]: y

Do you want to configure cleanup of old files? (y/n): y
Enable automatic cleanup of old files? (y/n) [y]: y
How many days to keep files before cleanup? [30]: 14

Do you want to run the organizer now? (y/n): y
```

### Created Folder Structure

```
Downloads/
├── Installers/   # EXE, MSI, etc.
├── Images/       # JPG, PNG, etc.
├── Documents/    # PDF, DOCX, etc.
├── Archives/     # ZIP, RAR, etc.
└── Temp/         # Files to be cleaned up
```

### After Setup

```
✅ Downloads organization completed successfully

Do you want to schedule this to run daily? (y/n): y

PowerShell script for task scheduling created
To schedule the task, please run the PowerShell script as administrator:
PowerShell.exe -ExecutionPolicy Bypass -File "/home/user/scripts/productivity/setup_downloads_organizer_task.ps1"
```

## 6. Dotfiles Syncer

This module sets up a system to backup and synchronize your configuration files.

### What It Manages

- Shell configuration files (.zshrc, .bashrc)
- Git configuration
- Vim, tmux settings
- VS Code settings and snippets
- Other dotfiles

### Usage Example

From the main menu, select option 6:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
6. 🧱 Setup Dotfiles Syncer
...
Enter your choice [0-9]: 6
```

You'll be prompted for repository information:

```
Enter your GitHub repository URL for dotfiles (e.g., git@github.com:username/dotfiles.git): git@github.com:yourusername/dotfiles.git

Do you want to customize which files to sync? (y/n): y
Enter the files you want to sync (separated by space):
> .zshrc .bashrc .gitconfig .vimrc .tmux.conf

Do you want to set up the dotfiles repository now? (y/n): y
```

### Repository Structure

```
.dotfiles/
├── README.md
├── .zshrc
├── .bashrc
├── .gitconfig
├── .vimrc
├── .tmux.conf
└── vscode/
    ├── settings.json
    ├── keybindings.json
    └── snippets/
        └── ...
```

### After Setup

```
Setting up dotfiles repository...
Repository set up successfully at /home/user/.dotfiles
Repository URL: git@github.com:yourusername/dotfiles.git

Do you want to push the initial commit to the remote repository? (y/n): y
Initial commit pushed to remote repository

Do you want to backup your dotfiles now? (y/n): y
Backing up dotfiles...
Backed up .zshrc
Backed up .bashrc
Backed up .gitconfig
Backed up .vimrc
Backed up .tmux.conf
Backed up VS Code settings.json
Changes committed
Changes pushed to remote repository
Backup completed successfully
```

## 7. System Backup

This module implements a comprehensive backup solution for your projects and configurations.

### What It Backs Up

- Projects directory
- University/academic files
- Configuration files
- Customizable backup targets
- Optional encryption

### Usage Example

From the main menu, select option 7:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
7. 📦 Create System Backup
...
Enter your choice [0-9]: 7
```

You'll be prompted for backup settings:

```
Enter your Google Drive path in Windows format (e.g., G:\My Drive\Backups): G:\My Drive\Backups

Do you want to enable backup encryption? (y/n): y
Enter encryption password: ********

How many days do you want to keep backups? (default: 30): 60

Do you want to run the backup now? (y/n): y
```

### Backup Process

```
==== Backup started at Wed Apr 9 14:30:22 EDT 2025 ====
Backup directory: /mnt/g/My Drive/Backups/2025-04-09_14-30-22

📦 Backing up Projects...
✅ Created backup: /mnt/g/My Drive/Backups/2025-04-09_14-30-22/Projects_2025-04-09_14-30-22.tar.gz (45M)
🔒 Encrypting backup for Projects...
✅ Encrypted backup: /mnt/g/My Drive/Backups/2025-04-09_14-30-22/Projects_2025-04-09_14-30-22.tar.gz.enc
🔍 Verifying encrypted backup for Projects...
✅ Verified backup: Projects

📦 Backing up University...
...

📝 Backing up configuration files...
✅ Backed up .zshrc
✅ Backed up .gitconfig
...
✅ Configuration files backed up and encrypted to /mnt/g/My Drive/Backups/2025-04-09_14-30-22/configs_2025-04-09_14-30-22.tar.gz.enc

📝 Created backup summary: /mnt/g/My Drive/Backups/2025-04-09_14-30-22/backup_summary.txt
🧹 Cleaning up old backups (older than 60 days)...
✅ Cleanup completed

==== Backup completed at Wed Apr 9 14:35:47 EDT 2025 ====
```

### After Backup

```
✅ Backup completed successfully

Do you want to schedule this to run weekly? (y/n): y

PowerShell script for task scheduling created
To schedule the task, please run the PowerShell script as administrator:
PowerShell.exe -ExecutionPolicy Bypass -File "/home/user/scripts/backup/setup_backup_task.ps1"
```

## 8. Academic Project Tracker

This module creates a system to manage academic assignments and deadlines.

### What It Offers

- Task tracking with due dates
- Project folder creation for assignments
- Deadline notifications and reminders
- Visual task status representation
- Markdown-based assignment documentation

### Usage Example

From the main menu, select option 8:

```
========================================
    🚀 DEVELOPMENT ENVIRONMENT SETUP    
========================================
...
8. 📋 Setup Academic Project Tracker
...
Enter your choice [0-9]: 8
```

The tracker will be set up with an example task:

```
===== Academic Project Tracker Demo =====
Academic Tasks:
ID  | Name                    | Due Date              | Status     
----------------------------------------------------------
1   | Example Assignment      | 2025-04-16 (Due in 7 days) | Pending  

Available commands:
  task list              - List all tasks
  task add               - Add a new task
  task complete <id>