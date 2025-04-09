# ========================================================================
#  MASTER SETUP SCRIPT - Complete Development Environment for CS/AI/Web
#  Author: Guru
#  Created: April 9, 2025
#  Updated: April 9, 2025 - Fixed various issues and improved error handling
# ========================================================================

# Set strict error handling
set -e

# ======= Configuration (Edit these variables) =======
DEFAULT_USERNAME="Timeless4k"
DEFAULT_EMAIL="guru12.it@gmail.com"
DEFAULT_GITHUB_USERNAME="Timeless4k"

# Paths
HOME_DIR="$HOME"
SCRIPTS_DIR="$HOME_DIR/scripts"
CONFIG_DIR="$SCRIPTS_DIR/config"
PROJECTS_DIR="$HOME_DIR/Projects"
DEFAULT_BACKUP_DIR="/mnt/g/My Drive/Backups"

# Project folders to create
PROJECTS=("vynlox-ai" "vynlox-marketing" "vynlox-docs" "web-projects" "experiments" "notebooks")

# Web browser settings
DEFAULT_BROWSER="brave"  # Options: brave, chrome, firefox
DEFAULT_SEARCH="google"  # Options: google, duckduckgo, brave

# Backup settings
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPT=true

# ======= Script Setup =======
SCRIPT_NAME=$(basename "$0")
LOG_FILE="$SCRIPTS_DIR/logs/setup_$(date +%Y-%m-%d_%H-%M-%S).log"

# Detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Create necessary directories
mkdir -p "$SCRIPTS_DIR/logs"
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE"

# ======= Helper Functions =======
log() {
    local message="$1"
    local level="${2:-INFO}"
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] [$level] $message" | tee -a "$LOG_FILE"
}

success() {
    log "$1" "SUCCESS"
    echo -e "\e[32m✅ $1\e[0m"
}

info() {
    log "$1" "INFO"
    echo -e "\e[34mℹ️ $1\e[0m"
}

warning() {
    log "$1" "WARNING"
    echo -e "\e[33m⚠️ $1\e[0m"
}

error() {
    log "$1" "ERROR"
    echo -e "\e[31m❌ $1\e[0m"
}

check_success() {
    if [ $? -eq 0 ]; then
        success "$1"
        return 0
    else
        error "$1 failed"
        return 1
    fi
}

install_if_missing() {
    if ! command -v $1 &> /dev/null; then
        info "Installing $1..."
        sudo apt install -y $1
        if ! check_success "$1 installation"; then
            warning "Failed to install $1. You may need to install it manually."
            return 1
        fi
        return 0
    else
        info "$1 already installed"
        return 0
    fi
}

# Retry a command up to a specific number of times until it succeeds
retry() {
    local retries=$1
    shift
    local count=0
    until "$@"; do
        exit=$?
        count=$((count + 1))
        if [ $count -lt $retries ]; then
            warning "Command failed. Attempt $count/$retries. Retrying in 5 seconds..."
            sleep 5
        else
            error "The command has failed after $retries attempts."
            return $exit
        fi
    done
    return 0
}

# Function to convert Windows path to WSL path
convert_windows_to_wsl_path() {
    local win_path="$1"
    
    # Replace backslashes with forward slashes
    win_path="${win_path//\\//}"
    
    # Extract drive letter and convert to lowercase
    local drive_letter="${win_path:0:1}"
    drive_letter=$(echo "$drive_letter" | tr '[:upper:]' '[:lower:]')
    
    # Remove the drive letter and colon
    local path_without_drive="${win_path:2}"
    
    # Construct WSL path
    echo "/mnt/$drive_letter$path_without_drive"
}

# Get Google Drive path in WSL format
get_google_drive_path() {
    local default_path="G:\\My Drive\\Backups"
    
    if [ "$PLATFORM" == "wsl" ]; then
        read -p "Enter your Google Drive path in Windows format (e.g., G:\\My Drive\\Backups): " win_path
        win_path=${win_path:-$default_path}
        
        # Convert Windows path to WSL path
        local wsl_path=$(convert_windows_to_wsl_path "$win_path")
        echo "$wsl_path"
    else
        # For Linux/macOS, ask for direct path
        read -p "Enter your backup path: " backup_path
        echo "${backup_path:-$HOME/Backups}"
    fi
}

# Function to check for network availability
check_network() {
    if ping -c 1 google.com &> /dev/null; then
        return 0
    else
        error "Network connectivity issue. Please check your internet connection."
        return 1
    fi
}

# ======= Main Menu Function =======
show_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m    🚀 DEVELOPMENT ENVIRONMENT SETUP    \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;33m1. 💻 Full Development Environment Setup\e[0m"
    echo -e "\e[1;33m2. 🌐 Browser & Privacy Optimizer\e[0m"
    echo -e "\e[1;33m3. 🧠 Create AI Modeling Workspace\e[0m"
    echo -e "\e[1;33m4. 🪄 Clean Slate Windows Configuration\e[0m"
    echo -e "\e[1;33m5. 🗂️ Setup Downloads Organizer\e[0m"
    echo -e "\e[1;33m6. 🧱 Setup Dotfiles Syncer\e[0m"
    echo -e "\e[1;33m7. 📦 Create System Backup\e[0m"
    echo -e "\e[1;33m8. 📋 Setup Academic Project Tracker\e[0m"
    echo -e "\e[1;33m9. ⚙️ Configure All Tools\e[0m"
    echo -e "\e[1;33m0. ❌ Exit\e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo -ne "\e[1;32mEnter your choice [0-9]: \e[0m"
    read choice

    case $choice in
        1) 
            if setup_dev_environment; then
                success "Development environment setup completed"
            else
                error "Development environment setup had errors"
            fi
            ;;
        2) setup_browser_privacy ;;
        3) create_ai_workspace ;;
        4) 
            if [ "$PLATFORM" != "wsl" ]; then
                warning "Clean Slate Configuration is designed for Windows with WSL. Your platform is $PLATFORM."
                read -p "Do you still want to continue? (y/n): " continue_anyway
                if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                    show_menu
                    return
                fi
            fi
            clean_slate_config 
            ;;
        5) setup_downloads_organizer ;;
        6) setup_dotfiles_syncer ;;
        7) create_system_backup ;;
        8) setup_academic_tracker ;;
        9) configure_all_tools ;;
        0) exit 0 ;;
        *) warning "Invalid option. Please try again."; show_menu ;;
    esac
}

# ======= 1. Development Environment Setup =======
setup_dev_environment() {
    info "Starting development environment setup..."
    
    # Create scripts directory structure
    mkdir -p "$SCRIPTS_DIR"/{backup,productivity,academic,utils,config,logs}
    
    # Check for network connectivity
    if ! check_network; then
        error "Network connectivity is required for development environment setup."
        return 1
    fi
    
    # Update and upgrade
    info "Updating system packages..."
    if ! sudo apt update; then
        error "Failed to update package lists. Check your network connection and try again."
        return 1
    fi
    
    # Only continue with upgrade if update succeeded
    if ! sudo apt upgrade -y; then
        warning "Package upgrade had issues. Continuing with installation but some packages might not be the latest version."
    else
        success "System update completed"
    fi
    
    # Install essential tools
    info "Installing essential tools..."
    ESSENTIALS="build-essential curl wget git zsh tmux unzip zip \
        software-properties-common gcc g++ make cmake libssl-dev libffi-dev \
        python3-dev python3-pip python3-venv fonts-powerline gnupg ca-certificates \
        lsb-release htop neofetch tree ripgrep fd-find jq fzf bat"
    
    if ! sudo apt install -y $ESSENTIALS; then
        error "Failed to install essential tools."
        warning "Continuing with setup, but you may need to install failed packages manually."
    else
        success "Essential tools installation completed"
    fi
    
    # Git configuration
    info "Setting up Git global config..."
    # Prompt for Git config if not already configured
    if ! git config --global user.name >/dev/null 2>&1; then
        read -p "Enter your name for Git configuration [$DEFAULT_USERNAME]: " git_username
        git_username=${git_username:-$DEFAULT_USERNAME}
        git config --global user.name "$git_username"
    fi
    
    if ! git config --global user.email >/dev/null 2>&1; then
        read -p "Enter your email for Git configuration [$DEFAULT_EMAIL]: " git_email
        git_email=${git_email:-$DEFAULT_EMAIL}
        git config --global user.email "$git_email"
    fi
    
    git config --global core.editor "code --wait"
    git config --global core.autocrlf input
    git config --global pull.rebase false
    git config --global init.defaultBranch main
    success "Git configuration completed"
    
    # Install Oh My Zsh
    if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
        info "Installing Oh My Zsh..."
        if ! retry 3 sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; then
            error "Failed to install Oh My Zsh"
            warning "Continuing setup, but shell customizations may be incomplete"
        else
            success "Oh My Zsh installation completed"
        fi
    else
        info "Oh My Zsh already installed"
    fi
    
    # Zsh plugins
    info "Installing Zsh plugins..."
    ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"
    
    # Create plugins directory if it doesn't exist
    mkdir -p "$ZSH_CUSTOM/plugins"
    
    # Function to clone or update a plugin
    install_zsh_plugin() {
        local repo="$1"
        local dest="$2"
        
        if [ ! -d "$dest" ]; then
            info "Installing plugin from $repo..."
            retry 3 git clone --depth=1 "https://github.com/$repo" "$dest"
            if [ $? -ne 0 ]; then
                warning "Failed to clone $repo. Skipping."
                return 1
            fi
        else
            info "Updating plugin at $dest..."
            (cd "$dest" && git pull)
        fi
        return 0
    }
    
    install_zsh_plugin "zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    install_zsh_plugin "zsh-users/zsh-syntax-highlighting" "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    install_zsh_plugin "zsh-users/zsh-completions" "${ZSH_CUSTOM}/plugins/zsh-completions"
    install_zsh_plugin "romkatv/powerlevel10k" "${ZSH_CUSTOM}/themes/powerlevel10k"
    
    # Update .zshrc with plugins and theme
    if [ -f "$HOME_DIR/.zshrc" ]; then
        # Backup existing .zshrc
        cp "$HOME_DIR/.zshrc" "$HOME_DIR/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        
        # Update theme if default is set
        if grep -q 'ZSH_THEME="robbyrussell"' "$HOME_DIR/.zshrc"; then
            sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME_DIR/.zshrc"
        fi
        
        # Update plugins if default is set
        if grep -q 'plugins=(git)' "$HOME_DIR/.zshrc"; then
            sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions docker docker-compose python pip npm node nvm)/' "$HOME_DIR/.zshrc"
        fi
        
        # Add source to bash_aliases if not already present
        if ! grep -q 'source ~/.bash_aliases' "$HOME_DIR/.zshrc"; then
            echo 'source ~/.bash_aliases' >> "$HOME_DIR/.zshrc"
        fi
        
        success "Zsh configuration updated"
    else
        warning ".zshrc not found, skipping Zsh configuration"
    fi
    
    # Change default shell to Zsh if it's available
    if command -v zsh &> /dev/null; then
        if [ "$SHELL" != "$(which zsh)" ]; then
            info "Changing default shell to Zsh..."
            chsh -s $(which zsh)
            if [ $? -ne 0 ]; then
                warning "Failed to change default shell. You can do this manually with: chsh -s $(which zsh)"
            else
                success "Default shell changed to Zsh"
            fi
        else
            info "Zsh is already the default shell"
        fi
    else
        warning "Zsh is not installed. Skipping shell change."
    fi
    
    # Node.js (via NVM)
    info "Installing Node.js LTS with NVM..."
    if [ ! -d "$HOME_DIR/.nvm" ]; then
        retry 3 curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        if [ $? -ne 0 ]; then
            error "Failed to install NVM"
            warning "Continuing setup, but Node.js functionality will be limited"
        else
            export NVM_DIR="$HOME_DIR/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            # Check if nvm command is available
            if command -v nvm &> /dev/null; then
                retry 3 nvm install --lts
                if [ $? -ne 0 ]; then
                    warning "Failed to install Node.js LTS"
                else
                    nvm use --lts
                    success "NVM and Node.js LTS installed and configured"
                fi
            else
                warning "NVM installation succeeded but command not found. You may need to restart your terminal."
            fi
        fi
    else
        info "NVM already installed, updating..."
        export NVM_DIR="$HOME_DIR/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command -v nvm &> /dev/null; then
            retry 3 nvm install --lts
            if [ $? -ne 0 ]; then
                warning "Failed to update Node.js LTS"
            else
                nvm use --lts
                success "Node.js updated to latest LTS version"
            fi
        else
            warning "NVM installation exists but command not found. Try restarting your terminal."
        fi
    fi
    
    # Global NPM packages - only if Node.js was successfully installed
    if command -v node &> /dev/null && command -v npm &> /dev/null; then
        info "Installing global NPM packages..."
        
        NPM_PACKAGES=(
            "pnpm"
            "vercel"
            "supabase"
            "create-t3-app"
            "eslint"
            "prettier"
            "typescript"
            "ts-node"
            "@nestjs/cli" 
            "next"
            "create-react-app"
            "netlify-cli"
            "npm-check-updates"
        )
        
        for package in "${NPM_PACKAGES[@]}"; do
            info "Installing $package..."
            retry 3 npm install -g $package
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        success "Global NPM packages installation completed"
    else
        warning "Node.js or npm not found, skipping global NPM packages installation"
    fi
    
    # Python setup
    info "Setting up Python environment..."
    if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
        # Determine which pip command to use
        PIP_CMD="pip"
        if ! command -v pip &> /dev/null && command -v pip3 &> /dev/null; then
            PIP_CMD="pip3"
        fi
        
        retry 3 $PIP_CMD install --user --upgrade pip
        if [ $? -ne 0 ]; then
            warning "Failed to upgrade pip"
        fi
        
        # Basic Python tools
        PYTHON_BASIC=(
            "virtualenv"
            "pipenv"
            "poetry"
        )
        
        for package in "${PYTHON_BASIC[@]}"; do
            info "Installing $package..."
            retry 3 $PIP_CMD install --user $package
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        # Python data science & ML packages
        info "Installing Python data science & ML packages..."
        
        # Core data science
        PYTHON_DATA=(
            "numpy"
            "pandas"
            "scikit-learn"
            "matplotlib"
            "seaborn"
            "plotly"
            "jupyterlab"
            "notebook"
            "ipywidgets"
        )
        
        for package in "${PYTHON_DATA[@]}"; do
            info "Installing $package..."
            retry 3 $PIP_CMD install --user $package
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        # ML frameworks - these can be large/complex so we'll handle errors more gracefully
        info "Installing machine learning frameworks..."
        retry 3 $PIP_CMD install --user tensorflow keras
        if [ $? -ne 0 ]; then
            warning "Failed to install TensorFlow. You may need to install it manually with specific options for your system."
        fi
        
        retry 3 $PIP_CMD install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
        if [ $? -ne 0 ]; then
            warning "Failed to install PyTorch. You may need to install it manually with specific options for your system."
            warning "Try: pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu"
        fi
        
        # ML tools
        PYTHON_ML_TOOLS=(
            "xgboost"
            "lightgbm"
            "catboost"
            "transformers"
            "datasets"
            "accelerate"
            "huggingface_hub"
            "fastapi"
            "uvicorn"
            "pydantic"
        )
        
        for package in "${PYTHON_ML_TOOLS[@]}"; do
            info "Installing $package..."
            retry 3 $PIP_CMD install --user $package
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        # IDE tools
        PYTHON_IDE=(
            "jupyterlab-vim"
            "jupyterlab-lsp"
            "python-lsp-server[all]"
            "black"
            "flake8"
            "mypy"
            "pytest"
        )
        
        for package in "${PYTHON_IDE[@]}"; do
            info "Installing $package..."
            retry 3 $PIP_CMD install --user "$package"
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        success "Python packages installation completed"
    else
        error "Python pip not found. Skipping Python packages installation."
    fi
    
    # Databases
    info "Installing database tools..."
    if command -v apt &> /dev/null; then
        DB_PACKAGES=(
            "postgresql"
            "postgresql-contrib"
            "sqlite3"
            "redis-server"
        )
        
        for package in "${DB_PACKAGES[@]}"; do
            info "Installing $package..."
            if ! sudo apt install -y $package; then
                warning "Failed to install $package"
            fi
        done
        
        # Start and enable PostgreSQL if installed
        if command -v pg_ctl &> /dev/null || command -v postgres &> /dev/null; then
            if command -v systemctl &> /dev/null; then
                sudo systemctl enable postgresql
                sudo systemctl start postgresql
                success "PostgreSQL enabled and started"
            else
                warning "systemctl not found. You may need to start PostgreSQL manually."
            fi
        fi
        
        # MongoDB - with careful error handling
        info "Installing MongoDB..."
        if ! command -v mongod &> /dev/null; then
            # Only attempt installation if not already installed
            if command -v wget &> /dev/null; then
                retry 3 wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
                
                if [ $? -eq 0 ]; then
                    # Get distribution codename
                    if command -v lsb_release &> /dev/null; then
                        DISTRO=$(lsb_release -cs)
                        echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $DISTRO/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
                        
                        sudo apt update
                        if ! sudo apt install -y mongodb-org; then
                            warning "Failed to install MongoDB"
                        else
                            if command -v systemctl &> /dev/null; then
                                sudo systemctl enable mongod
                                sudo systemctl start mongod
                                success "MongoDB installed, enabled, and started"
                            else
                                warning "systemctl not found. MongoDB installed but not started."
                            fi
                        fi
                    else
                        warning "lsb_release not found. Skipping MongoDB installation."
                    fi
                else
                    warning "Failed to add MongoDB repository key. Skipping MongoDB installation."
                fi
            else
                warning "wget not found. Skipping MongoDB installation."
            fi
        else
            info "MongoDB already installed"
            
            # Ensure MongoDB is running
            if command -v systemctl &> /dev/null; then
                if ! systemctl is-active --quiet mongod; then
                    sudo systemctl start mongod
                    success "MongoDB started"
                fi
                
                if ! systemctl is-enabled --quiet mongod; then
                    sudo systemctl enable mongod
                    success "MongoDB enabled to start on boot"
                fi
            fi
        fi
    else
        warning "apt not found. Skipping database installations."
    fi
    
    # Docker & Docker Compose
    info "Installing Docker & Docker Compose..."
    if ! command -v docker &> /dev/null; then
        if command -v curl &> /dev/null; then
            retry 3 curl -fsSL https://get.docker.com -o get-docker.sh
            
            if [ -f get-docker.sh ]; then
                if ! sudo sh get-docker.sh; then
                    error "Docker installation script failed"
                else
                    sudo usermod -aG docker $USER
                    if command -v systemctl &> /dev/null; then
                        sudo systemctl enable docker
                        sudo systemctl start docker
                        success "Docker installed, enabled, and started"
                    else
                        warning "systemctl not found. Docker installed but not started."
                    fi
                fi
                
                # Clean up
                rm -f get-docker.sh
            else
                error "Failed to download Docker installation script"
            fi
        else
            warning "curl not found. Skipping Docker installation."
        fi
    else
        info "Docker already installed"
    fi
    
    # Kubernetes tools
    info "Installing Kubernetes tools..."
    if ! command -v kubectl &> /dev/null; then
        if command -v curl &> /dev/null; then
            # Get latest stable kubectl version
            retry 3 curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            
            if [ -f kubectl ]; then
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm -f kubectl
                success "kubectl installed"
            else
                warning "Failed to download kubectl"
            fi
        else
            warning "curl not found. Skipping kubectl installation."
        fi
    else
        info "kubectl already installed"
    fi
    
    if ! command -v minikube &> /dev/null; then
        if command -v curl &> /dev/null; then
            # Install minikube
            retry 3 curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
            
            if [ -f minikube-linux-amd64 ]; then
                sudo install minikube-linux-amd64 /usr/local/bin/minikube
                rm -f minikube-linux-amd64
                success "minikube installed"
            else
                warning "Failed to download minikube"
            fi
        else
            warning "curl not found. Skipping minikube installation."
        fi
    else
        info "minikube already installed"
    fi
    
    # Cloud CLIs
    info "Installing Cloud CLI tools..."
    
    # AWS CLI
    if ! command -v aws &> /dev/null; then
        if command -v curl &> /dev/null && command -v unzip &> /dev/null; then
            info "Installing AWS CLI..."
            retry 3 curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
            
            if [ -f awscliv2.zip ]; then
                unzip -q awscliv2.zip
                if [ -d aws ]; then
                    sudo ./aws/install
                    rm -rf aws awscliv2.zip
                    success "AWS CLI installed"
                else
                    warning "AWS CLI extraction failed"
                    rm -f awscliv2.zip
                fi
            else
                warning "Failed to download AWS CLI"
            fi
        else
            warning "curl or unzip not found. Skipping AWS CLI installation."
        fi
    else
        info "AWS CLI already installed"
    fi
    
    # Azure CLI
    if ! command -v az &> /dev/null; then
        if command -v curl &> /dev/null; then
            info "Installing Azure CLI..."
            
            # This is a complex installation, so we'll capture the output and only show errors
            if ! curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash; then
                error "Azure CLI installation failed"
            else
                success "Azure CLI installed"
            fi
        else
            warning "curl not found. Skipping Azure CLI installation."
        fi
    else
        info "Azure CLI already installed"
    fi
    
    # Google Cloud SDK
    if ! command -v gcloud &> /dev/null; then
        if command -v apt-key &> /dev/null && command -v apt-get &> /dev/null; then
            info "Installing Google Cloud SDK..."
            
            echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
            curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
            
            if sudo apt-get update && sudo apt-get install -y google-cloud-sdk; then
                success "Google Cloud SDK installed"
            else
                error "Google Cloud SDK installation failed"
            fi
        else
            warning "apt-key or apt-get not found. Skipping Google Cloud SDK installation."
        fi
    else
        info "Google Cloud SDK already installed"
    fi
    
    # VS Code extensions - only if VS Code is installed
    if command -v code &> /dev/null; then
        info "Installing VS Code extensions..."
        EXTENSIONS=(
            "ms-python.python"
            "ms-toolsai.jupyter"
            "ms-toolsai.vscode-jupyter-slideshow"
            "esbenp.prettier-vscode"
            "dbaeumer.vscode-eslint"
            "bradlc.vscode-tailwindcss"
            "eamodio.gitlens"
            "visualstudioexptteam.vscodeintellicode"
            "ms-vsliveshare.vsliveshare"
            "ms-azuretools.vscode-docker"
            "ms-vscode-remote.remote-wsl"
            "github.vscode-pull-request-github"
            "ms-vscode-remote.remote-containers"
            "redhat.vscode-yaml"
            "yzhang.markdown-all-in-one"
            "streetsidesoftware.code-spell-checker"
            "davidanson.vscode-markdownlint"
            "mongodb.mongodb-vscode"
            "mtxr.sqltools"
                    return 1
    fi
    
    # Get task details
    local task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status <<< "$task_line"
    
    # Calculate days until due
    local days=$(days_until_due "$due_date")
    
    # Display task details
    echo -e "${COLOR_BLUE}=== Task Details ===${COLOR_RESET}"
    echo -e "${COLOR_CYAN}Name:${COLOR_RESET}        $name"
    echo -e "${COLOR_CYAN}Due Date:${COLOR_RESET}    $(format_date "$due_date")"
    echo -e "${COLOR_CYAN}Description:${COLOR_RESET} $description"
    echo -e "${COLOR_CYAN}Status:${COLOR_RESET}      $([ "$status" = "Completed" ] && echo -e "${COLOR_GREEN}Completed${COLOR_RESET}" || echo -e "${COLOR_YELLOW}Pending${COLOR_RESET}")"
    
    # Check if task folder exists
    task_dir="$UNI_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -d "$task_dir" ]; then
        echo -e "${COLOR_CYAN}Folder:${COLOR_RESET}      $task_dir"
        
        # Check for files in the task folder
        file_count=$(find "$task_dir" -type f | wc -l)
        if [ $file_count -gt 1 ]; then  # More than just README.md
            echo -e "${COLOR_CYAN}Files:${COLOR_RESET}       $(($file_count - 1)) files in folder (excluding README)"
            echo ""
            echo -e "${COLOR_BLUE}Files in task folder:${COLOR_RESET}"
            find "$task_dir" -type f -not -name "README.md" | while read -r file; do
                echo -e "- ${COLOR_CYAN}$(basename "$file")${COLOR_RESET} ($(du -h "$file" | cut -f1))"
            done
        else
            echo -e "${COLOR_CYAN}Files:${COLOR_RESET}       No additional files in folder"
        fi
    else
        echo -e "${COLOR_CYAN}Folder:${COLOR_RESET}      Not created yet"
    fi
}

# List pending tasks
list_pending() {
    if [ ! -s "$TASKS_FILE" ] || [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        echo -e "${COLOR_YELLOW}No tasks found.${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_BLUE}Pending Academic Tasks:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}ID  | Name                    | Due Date              ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}------------------------------------------------${COLOR_RESET}"
    
    # Skip header line and process each task
    tail -n +2 "$TASKS_FILE" | while IFS=, read -r name due_date description status || [ -n "$name" ]; do
        if [ "$status" != "Completed" ]; then
            # Find the line number using pattern matching
            line_pattern="$name,$due_date,$description,$status"
            line_number=$(grep -n "^$line_pattern$" "$TASKS_FILE" | cut -d: -f1)
            
            if [ -z "$line_number" ]; then
                continue
            fi
            
            # Adjust line number to be zero-based ID
            line_number=$((line_number - 1))
            
            # Format name (truncate if too long)
            if [ ${#name} -gt 20 ]; then
                name="${name:0:17}..."
            fi
            
            # Print task
            printf "${COLOR_CYAN}%-3s${COLOR_RESET} | %-23s | %-20s\n" "$line_number" "$name" "$(format_date "$due_date")"
        fi
    done
}

# List tasks due today
list_today() {
    if [ ! -s "$TASKS_FILE" ] || [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        echo -e "${COLOR_YELLOW}No tasks found.${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_BLUE}Tasks Due Today:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}ID  | Name                    | Status     ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}----------------------------------------${COLOR_RESET}"
    
    local today=$(date +%Y-%m-%d)
    local found=false
    
    # Skip header line and process each task
    tail -n +2 "$TASKS_FILE" | while IFS=, read -r name due_date description status || [ -n "$name" ]; do
        if [ "$due_date" = "$today" ]; then
            found=true
            
            # Find the line number using pattern matching
            line_pattern="$name,$due_date,$description,$status"
            line_number=$(grep -n "^$line_pattern$" "$TASKS_FILE" | cut -d: -f1)
            
            if [ -z "$line_number" ]; then
                continue
            fi
            
            # Adjust line number to be zero-based ID
            line_number=$((line_number - 1))
            
            # Format name (truncate if too long)
            if [ ${#name} -gt 20 ]; then
                name="${name:0:17}..."
            fi
            
            # Format status
            if [ "$status" = "Completed" ]; then
                status_text="${COLOR_GREEN}Completed${COLOR_RESET}"
            else
                status_text="${COLOR_YELLOW}Pending${COLOR_RESET}  "
            fi
            
            # Print task
            printf "${COLOR_CYAN}%-3s${COLOR_RESET} | %-23s | %s\n" "$line_number" "$name" "$status_text"
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "${COLOR_YELLOW}No tasks due today.${COLOR_RESET}"
    fi
}

# List tasks due this week
list_week() {
    if [ ! -s "$TASKS_FILE" ] || [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        echo -e "${COLOR_YELLOW}No tasks found.${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_BLUE}Tasks Due This Week:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}ID  | Name                    | Due Date              | Status     ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}----------------------------------------------------------${COLOR_RESET}"
    
    local found=false
    
    # Skip header line and process each task
    tail -n +2 "$TASKS_FILE" | while IFS=, read -r name due_date description status || [ -n "$name" ]; do
        local days=$(days_until_due "$due_date")
        
        if [ $days -ge 0 ] && [ $days -lt 7 ]; then
            found=true
            
            # Find the line number using pattern matching
            line_pattern="$name,$due_date,$description,$status"
            line_number=$(grep -n "^$line_pattern$" "$TASKS_FILE" | cut -d: -f1)
            
            if [ -z "$line_number" ]; then
                continue
            fi
            
            # Adjust line number to be zero-based ID
            line_number=$((line_number - 1))
            
            # Format name (truncate if too long)
            if [ ${#name} -gt 20 ]; then
                name="${name:0:17}..."
            fi
            
            # Format status
            if [ "$status" = "Completed" ]; then
                status_text="${COLOR_GREEN}Completed${COLOR_RESET}"
            else
                status_text="${COLOR_YELLOW}Pending${COLOR_RESET}  "
            fi
            
            # Print task
            printf "${COLOR_CYAN}%-3s${COLOR_RESET} | %-23s | %-20s | %s\n" "$line_number" "$name" "$(format_date "$due_date")" "$status_text"
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "${COLOR_YELLOW}No tasks due this week.${COLOR_RESET}"
    fi
}

# Main function to process commands
main() {
    if [ $# -eq 0 ]; then
        show_help
        return
    fi
    
    case "$1" in
        list)
            list_tasks
            ;;
        add)
            add_task
            ;;
        complete)
            complete_task "$2"
            ;;
        delete)
            delete_task "$2"
            ;;
        edit)
            edit_task "$2"
            ;;
        view)
            view_task "$2"
            ;;
        pending)
            list_pending
            ;;
        today)
            list_today
            ;;
        week)
            list_week
            ;;
        help)
            show_help
            ;;
        *)
            echo -e "${COLOR_RED}Unknown command: $1${COLOR_RESET}"
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
EOL

    chmod +x "$SCRIPTS_DIR/academic/task_manager.sh"
    
    # Create an alias for easy access
    if ! grep -q "alias task=" "$HOME/.bash_aliases" 2>/dev/null; then
        echo 'alias task="$HOME/scripts/academic/task_manager.sh"' >> "$HOME/.bash_aliases"
    fi
    
    return 0
}

setup_academic_tracker() {
    info "Setting up Academic Project Tracker..."
    
    # Create the script if it doesn't exist
    if [ ! -f "$SCRIPTS_DIR/academic/task_manager.sh" ]; then
        create_academic_tracker_script
    fi
    
    # Create an example task to show how it works
    if [ ! -s "$SCRIPTS_DIR/academic/tasks.csv" ] || [ $(wc -l < "$SCRIPTS_DIR/academic/tasks.csv") -le 1 ]; then
        echo "Name,Due Date,Description,Status" > "$SCRIPTS_DIR/academic/tasks.csv"
        
        # Calculate a due date one week from now using platform-specific date commands
        if [ "$PLATFORM" == "macos" ]; then
            # macOS date command
            due_date=$(date -v+7d +%Y-%m-%d)
        else
            # Linux date command
            due_date=$(date -d "+7 days" +%Y-%m-%d)
        fi
        
        echo "Example Assignment,$due_date,This is an example assignment to demonstrate the task tracker.,Pending" >> "$SCRIPTS_DIR/academic/tasks.csv"
        
        # Create example folder
        mkdir -p "$HOME/Uni/Example_Assignment"
        
        # Create README
        cat > "$HOME/Uni/Example_Assignment/README.md" << EOF
# Example Assignment

**Due Date:** $due_date
**Status:** Pending

## Description
This is an example assignment to demonstrate the task tracker.

## Notes
- This is just an example
- You can add your own notes here

## Resources
- Course website: https://example.edu/course
- Lecture notes: Week 3
EOF

        success "Example task created"
    fi
    
    # Demonstrate the tool
    echo ""
    echo "===== Academic Project Tracker Demo ====="
    bash "$SCRIPTS_DIR/academic/task_manager.sh" list
    echo ""
    echo "Available commands:"
    echo "  task list              - List all tasks"
    echo "  task add               - Add a new task"
    echo "  task complete <id>     - Mark a task as complete"
    echo "  task edit <id>         - Edit a task"
    echo "  task view <id>         - View task details"
    echo "  task week              - See tasks due this week"
    echo ""
    echo "Tasks are stored in: $SCRIPTS_DIR/academic/tasks.csv"
    echo "Project folders are created in: $HOME/Uni/"
    echo ""
    
    success "Academic Project Tracker setup complete"
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 9. Configure All Tools =======
configure_all_tools() {
    info "Configuring all tools..."
    
    # User information
    read -p "Enter your full name for configuration [$DEFAULT_USERNAME]: " full_name
    full_name=${full_name:-$DEFAULT_USERNAME}
    
    read -p "Enter your email for configuration [$DEFAULT_EMAIL]: " email
    email=${email:-$DEFAULT_EMAIL}
    
    read -p "Enter your GitHub username [$DEFAULT_GITHUB_USERNAME]: " github_username
    github_username=${github_username:-$DEFAULT_GITHUB_USERNAME}
    
    # Get Google Drive path for backups
    backup_path=$(get_google_drive_path)
    
    # Update config files
    if [ -f "$SCRIPTS_DIR/config/backup.conf" ]; then
        # Use different sed syntax based on platform
        if [ "$(uname)" == "Darwin" ]; then
            # macOS sed
            sed -i '' "s|BACKUP_BASE_DIR=.*|BACKUP_BASE_DIR=\"$backup_path\"|" "$SCRIPTS_DIR/config/backup.conf"
        else
            # Linux sed
            sed -i "s|BACKUP_BASE_DIR=.*|BACKUP_BASE_DIR=\"$backup_path\"|" "$SCRIPTS_DIR/config/backup.conf"
        fi
        
        success "Backup path set to $backup_path"
    fi
    
    # Set up Git config
    if [ -n "$full_name" ]; then
        git config --global user.name "$full_name"
        success "Git username set to: $full_name"
    fi
    
    if [ -n "$email" ]; then
        git config --global user.email "$email"
        success "Git email set to: $email"
    fi
    
    # Set up Zsh theme if zsh is installed
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "ZSH_THEME=\"robbyrussell\"" "$HOME/.zshrc"; then
            if [ "$(uname)" == "Darwin" ]; then
                # macOS sed
                sed -i '' 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
            else
                # Linux sed
                sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
            fi
            success "Zsh theme set to Powerlevel10k"
        fi
    fi
    
    # Configure VS Code settings if present
    vs_code_dir=""
    if [ -d "$HOME/.config/Code/User" ]; then
        vs_code_dir="$HOME/.config/Code/User"
    elif [ "$PLATFORM" == "wsl" ]; then
        # Try to detect VS Code settings in Windows
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        if [ -n "$WIN_USER" ] && [[ ! "$WIN_USER" == *"%" ]]; then
            POTENTIAL_VSCODE_DIR="/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User"
            if [ -d "$POTENTIAL_VSCODE_DIR" ]; then
                vs_code_dir="$POTENTIAL_VSCODE_DIR"
            fi
        fi
    fi
    
    if [ -n "$vs_code_dir" ]; then
        mkdir -p "$vs_code_dir"
        
        # Create settings.json
        cat > "$vs_code_dir/settings.json" << EOF
{
    "editor.fontFamily": "JetBrains Mono, Consolas, 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.lineHeight": 22,
    "editor.fontWeight": "400",
    "editor.tabSize": 2,
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.codeActionsOnSave": {
        "source.fixAll.eslint": true
    },
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.minimap.enabled": false,
    "editor.rulers": [80, 100],
    "editor.wordWrap": "on",
    "explorer.confirmDelete": false,
    "explorer.confirmDragAndDrop": false,
    "files.associations": {
        "*.css": "css"
    },
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/venv": true,
        ".pytest_cache": true,
        ".coverage": true
    },
    "terminal.integrated.fontFamily": "JetBrains Mono, Consolas, 'Courier New', monospace",
    "terminal.integrated.fontSize": 14,
    "workbench.colorTheme": "One Dark Pro",
    "workbench.iconTheme": "material-icon-theme",
    "workbench.editor.enablePreview": false,
    "workbench.startupEditor": "newUntitledFile",
    "javascript.updateImportsOnFileMove.enabled": "always",
    "javascript.format.enable": false,
    "python.formatting.provider": "black",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": true,
    "python.linting.flake8Enabled": true,
    "jupyter.themeMatplotlibPlots": true,
    "jupyter.askForKernelRestart": false,
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[python]": {
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "ms-python.python"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[html]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[css]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    }
}
EOF
        
        success "VS Code settings configured"
    else
        warning "VS Code settings directory not found. Skipping VS Code configuration."
    fi
    
    success "All tools configured"
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= Main Script Execution =======
# Display the main menu to start
show_menu
            # Use different sed syntax based on platform (macOS vs Linux)
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/ENCRYPTION_PASSWORD=\"\"/ENCRYPTION_PASSWORD=\"$encryption_password\"/" "$SCRIPTS_DIR/config/backup.conf"
            else
                sed -i "s/ENCRYPTION_PASSWORD=\"\"/ENCRYPTION_PASSWORD=\"$encryption_password\"/" "$SCRIPTS_DIR/config/backup.conf"
            fi
            
            success "Encryption enabled and password set"
            
            # Security warning
            warning "Note: Your encryption password is stored in plain text in $SCRIPTS_DIR/config/backup.conf"
            warning "Consider restricting access to this file: chmod 600 $SCRIPTS_DIR/config/backup.conf"
            
            # Set appropriate permissions on the config file
            chmod 600 "$SCRIPTS_DIR/config/backup.conf"
        else
            warning "No password provided, encryption may not work correctly"
        fi
    fi
    
    # Ask how many days to keep backups
    read -p "How many days do you want to keep backups? (default: 30): " retention_days
    
    if [ -n "$retention_days" ] && [[ "$retention_days" =~ ^[0-9]+$ ]]; then
        # Use different sed syntax based on platform (macOS vs Linux)
        if [ "$(uname)" == "Darwin" ]; then
            sed -i '' "s/RETENTION_DAYS=30/RETENTION_DAYS=$retention_days/" "$SCRIPTS_DIR/config/backup.conf"
        else
            sed -i "s/RETENTION_DAYS=30/RETENTION_DAYS=$retention_days/" "$SCRIPTS_DIR/config/backup.conf"
        fi
        
        success "Backup retention set to $retention_days days"
    fi
    
    # Ask if they want to run it now
    read -p "Do you want to run the backup now? (y/n): " run_now
    
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        # Source the updated config before running
        source "$SCRIPTS_DIR/config/backup.conf"
        
        # Check access to backup location before running
        if [ ! -d "$BACKUP_BASE_DIR" ]; then
            warning "Backup location $BACKUP_BASE_DIR doesn't exist or is not accessible"
            
            if [ "$PLATFORM" == "wsl" ]; then
                # For WSL, provide more specific guidance about Google Drive paths
                info "The Google Drive path is not accessible from WSL."
                info "Check that G: drive is properly mounted in Windows"
                info "Make sure 'G:\\My Drive\\Backups' exists in Windows Explorer"
                
                read -p "Try to create the backup directory manually? (y/n): " create_dir
                
                if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                    # Try a more robust directory creation approach
                    mkdir -p "$BACKUP_BASE_DIR" 2>/dev/null
                    
                    if [ ! -d "$BACKUP_BASE_DIR" ]; then
                        # If that fails, try using cmd.exe as fallback
                        win_path=$(echo "$BACKUP_BASE_DIR" | sed 's|/mnt/\([a-z]\)|\U\1:|' | sed 's|/|\\|g')
                        cmd.exe /C "mkdir \"$win_path\"" 2>/dev/null
                        
                        # Check again
                        if [ ! -d "$BACKUP_BASE_DIR" ]; then
                            error "Could not create backup directory."
                            info "Please create the following directory manually in Windows:"
                            info "G:\\My Drive\\Backups"
                            
                            read -p "Press Enter to continue..."
                            return 1
                        fi
                    fi
                else
                    warning "Backup cannot proceed without a valid backup location"
                    info "Please create the directory manually and try again"
                    read -p "Press Enter to continue..."
                    return 1
                fi
            else
                # For non-WSL platforms
                read -p "Do you want to create it? (y/n): " create_dir
                
                if [[ "$create_dir" =~ ^[Yy]$ ]]; then
                    mkdir -p "$BACKUP_BASE_DIR"
                    if [ $? -ne 0 ]; then
                        error "Failed to create backup directory. Please check your configuration."
                        info "You may need to create the directory manually or specify a different location."
                        return 1
                    fi
                else
                    warning "Backup cannot proceed without a valid backup location"
                    info "Please create the directory manually and try again"
                    read -p "Press Enter to continue..."
                    return 1
                fi
            fi
        fi
        
        # Run the backup with error handling
        if ! bash "$SCRIPTS_DIR/backup/backup_projects.sh"; then
            error "Backup failed. Check logs for details: $SCRIPTS_DIR/logs/"
        else
            success "Backup completed successfully"
        fi
    fi
    
    # Ask if they want to schedule it
    read -p "Do you want to schedule this to run weekly? (y/n): " schedule_it
    
    if [[ "$schedule_it" =~ ^[Yy]$ ]]; then
        # Create scheduled task script with improved robustness
        cat > "$SCRIPTS_DIR/backup/setup_backup_task.ps1" << 'EOL'
# Setup Windows Task Scheduler for Weekly Backup
# Run this with PowerShell as Administrator

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

try {
    $taskName = "WeeklySystemBackup"
    $taskDescription = "Weekly backup of projects and configuration files"
    $scriptPath = "$env:USERPROFILE\scripts\backup\backup_projects.bat"

    # Check for WSL paths
    $wslPath = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages\*Ubuntu*\LocalState\rootfs\home\*\scripts\backup\backup_projects.bat" -ErrorAction SilentlyContinue
    
    if ($wslPath) {
        Write-Host "Found WSL script at: $($wslPath.FullName)" -ForegroundColor Cyan
        $scriptPath = $wslPath.FullName
    }
    
    # Verify script exists
    if (-not (Test-Path $scriptPath)) {
        Write-Host "❌ Script not found at: $scriptPath" -ForegroundColor Red
        $manualPath = Read-Host "Enter the full path to backup_projects.bat (or press Enter to cancel)"
        
        if ([string]::IsNullOrEmpty($manualPath)) {
            Write-Host "Task setup cancelled." -ForegroundColor Yellow
            exit 1
        }
        
        if (-not (Test-Path $manualPath)) {
            Write-Host "❌ Script still not found. Please verify the path and try again." -ForegroundColor Red
            exit 1
        }
        
        $scriptPath = $manualPath
    }

    # Create a new task action
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$scriptPath`""

    # Create a trigger to run weekly on Sunday at 2 AM
    $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

    # Register the task with higher privileges
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description $taskDescription -RunLevel Highest -Force

    Write-Host "✅ Weekly backup scheduled task created successfully!" -ForegroundColor Green
    Write-Host "⏰ The task will run every Sunday at 2:00 AM" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Error creating scheduled task: $_" -ForegroundColor Red
    exit 1
}
EOL

        success "PowerShell script for task scheduling created"
        info "To schedule the task, please run the PowerShell script as administrator:"
        info "PowerShell.exe -ExecutionPolicy Bypass -File \"$SCRIPTS_DIR/backup/setup_backup_task.ps1\""
    fi
    
    success "System Backup setup complete"
    
    # Add a reminder about backup in .zshrc if not already present
    if [ -f "$HOME/.zshrc" ] && ! grep -q "backup_projects.sh" "$HOME/.zshrc"; then
        cat >> "$HOME/.zshrc" << 'EOL'

# Backup reminder - check if it's been more than 7 days since last backup
if [ -f ~/last_backup.txt ]; then
    last_backup=$(cat ~/last_backup.txt)
    today=$(date +%Y-%m-%d)
    
    # Handle different date commands based on OS
    if [ "$(uname)" == "Darwin" ]; then
        # macOS
        last_backup_seconds=$(date -j -f "%Y-%m-%d" "$last_backup" +%s)
        today_seconds=$(date -j -f "%Y-%m-%d" "$today" +%s)
    else
        # Linux
        last_backup_seconds=$(date -d "$last_backup" +%s)
        today_seconds=$(date -d "$today" +%s)
    fi
    
    days_diff=$(( (today_seconds - last_backup_seconds) / 86400 ))
    
    if [ $days_diff -gt 7 ]; then
        echo "⚠️  It's been $days_diff days since your last backup. Consider running: backup"
    fi
fi
EOL

        success "Backup reminder added to .zshrc"
    fi
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 8. Academic Project Tracker =======
create_academic_tracker_script() {
    info "Creating Academic Project Tracker script..."
    
    mkdir -p "$SCRIPTS_DIR/academic"
    
    cat > "$SCRIPTS_DIR/academic/task_manager.sh" << 'EOL'
#!/bin/bash
# Academic Task Manager
# Helps track assignments, projects, and deadlines

set -e

# Configuration
SCRIPT_DIR="$HOME/scripts"
CONFIG_DIR="$SCRIPT_DIR/config"
TASKS_FILE="$SCRIPT_DIR/academic/tasks.csv"
UNI_DIR="$HOME/Uni"

# Function to detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Create directories if they don't exist
mkdir -p "$SCRIPT_DIR/academic"
mkdir -p "$UNI_DIR"

# Create tasks file if it doesn't exist
if [ ! -f "$TASKS_FILE" ]; then
    echo "Name,Due Date,Description,Status" > "$TASKS_FILE"
fi

# Colorized output
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_PURPLE='\033[0;35m'
COLOR_CYAN='\033[0;36m'
COLOR_RESET='\033[0m'

# Help function
show_help() {
    echo -e "${COLOR_BLUE}Academic Task Manager${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Usage:${COLOR_RESET} $(basename $0) [command] [options]"
    echo ""
    echo -e "${COLOR_YELLOW}Commands:${COLOR_RESET}"
    echo -e "  ${COLOR_CYAN}list${COLOR_RESET}                   List all tasks"
    echo -e "  ${COLOR_CYAN}add${COLOR_RESET}                    Add a new task"
    echo -e "  ${COLOR_CYAN}complete ${COLOR_RED}<id>${COLOR_RESET}           Mark a task as complete"
    echo -e "  ${COLOR_CYAN}delete ${COLOR_RED}<id>${COLOR_RESET}             Delete a task"
    echo -e "  ${COLOR_CYAN}edit ${COLOR_RED}<id>${COLOR_RESET}               Edit a task"
    echo -e "  ${COLOR_CYAN}view ${COLOR_RED}<id>${COLOR_RESET}               View task details"
    echo -e "  ${COLOR_CYAN}pending${COLOR_RESET}                List pending tasks"
    echo -e "  ${COLOR_CYAN}today${COLOR_RESET}                  List tasks due today"
    echo -e "  ${COLOR_CYAN}week${COLOR_RESET}                   List tasks due this week"
    echo -e "  ${COLOR_CYAN}help${COLOR_RESET}                   Show this help message"
    echo ""
    echo -e "${COLOR_YELLOW}Examples:${COLOR_RESET}"
    echo -e "  $(basename $0) add"
    echo -e "  $(basename $0) list"
    echo -e "  $(basename $0) complete 2"
    echo ""
}

# Function to validate date format
validate_date() {
    local date_str="$1"
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS date validation
        date -j -f "%Y-%m-%d" "$date_str" >/dev/null 2>&1
    else
        # Linux date validation
        date -d "$date_str" >/dev/null 2>&1
    fi
    
    return $?
}

# Function to calculate days until due
days_until_due() {
    local due_date="$1"
    local today=$(date +%s)
    local due
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS
        due=$(date -j -f "%Y-%m-%d" "$due_date" +%s)
    else
        # Linux
        due=$(date -d "$due_date" +%s)
    fi
    
    echo $(( (due - today) / 86400 ))
}

# Format date output
format_date() {
    local date_str="$1"
    local days=$(days_until_due "$date_str")
    local formatted_date
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS
        formatted_date=$(date -j -f "%Y-%m-%d" "$date_str" "+%Y-%m-%d")
    else
        # Linux
        formatted_date=$(date -d "$date_str" "+%Y-%m-%d")
    fi
    
    if [ $days -lt 0 ]; then
        echo -e "${COLOR_RED}$formatted_date (${days#-} days overdue)${COLOR_RESET}"
    elif [ $days -eq 0 ]; then
        echo -e "${COLOR_RED}$formatted_date (Due today)${COLOR_RESET}"
    elif [ $days -eq 1 ]; then
        echo -e "${COLOR_YELLOW}$formatted_date (Due tomorrow)${COLOR_RESET}"
    elif [ $days -le 7 ]; then
        echo -e "${COLOR_YELLOW}$formatted_date (Due in $days days)${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}$formatted_date (Due in $days days)${COLOR_RESET}"
    fi
}

# List tasks
list_tasks() {
    if [ ! -s "$TASKS_FILE" ] || [ $(wc -l < "$TASKS_FILE") -le 1 ]; then
        echo -e "${COLOR_YELLOW}No tasks found.${COLOR_RESET}"
        return
    fi
    
    echo -e "${COLOR_BLUE}Academic Tasks:${COLOR_RESET}"
    echo -e "${COLOR_CYAN}ID  | Name                    | Due Date              | Status     ${COLOR_RESET}"
    echo -e "${COLOR_CYAN}----------------------------------------------------------${COLOR_RESET}"
    
    # Skip header line and process each task
    tail -n +2 "$TASKS_FILE" | while IFS=, read -r name due_date description status || [ -n "$name" ]; do
        # Find the line number by pattern matching the entire line
        # We use pattern matching instead of line counter to handle potential issues with different IFS settings
        line_pattern="$name,$due_date,$description,$status"
        line_number=$(grep -n "^$line_pattern$" "$TASKS_FILE" | cut -d: -f1)
        
        if [ -z "$line_number" ]; then
            continue
        fi
        
        # Adjust line number to be zero-based ID
        line_number=$((line_number - 1))
        
        # Format name (truncate if too long)
        if [ ${#name} -gt 20 ]; then
            name="${name:0:17}..."
        fi
        
        # Format status
        if [ "$status" = "Completed" ]; then
            status_text="${COLOR_GREEN}Completed${COLOR_RESET}"
        else
            status_text="${COLOR_YELLOW}Pending${COLOR_RESET}  "
        fi
        
        # Print task
        printf "${COLOR_CYAN}%-3s${COLOR_RESET} | %-23s | %-20s | %s\n" "$line_number" "$name" "$(format_date "$due_date")" "$status_text"
    done
}

# Add a new task
add_task() {
    echo -e "${COLOR_BLUE}Add a new academic task:${COLOR_RESET}"
    
    # Get task details
    read -p "Task name: " name
    
    while true; do
        read -p "Due date (YYYY-MM-DD): " due_date
        if validate_date "$due_date"; then
            break
        else
            echo -e "${COLOR_RED}Invalid date format. Please use YYYY-MM-DD.${COLOR_RESET}"
        fi
    done
    
    read -p "Description: " description
    
    # Add task to CSV, escaping any commas in the name or description
    # Replace any existing commas with semicolons to avoid CSV field issues
    safe_name="${name//,/;}"
    safe_description="${description//,/;}"
    
    echo "$safe_name,$due_date,$safe_description,Pending" >> "$TASKS_FILE"
    
    # Create folder for the task
    task_dir="$UNI_DIR/$(echo "$safe_name" | tr ' ' '_')"
    mkdir -p "$task_dir"
    
    # Create README for the task
    cat > "$task_dir/README.md" << EOF
# $safe_name

**Due Date:** $due_date
**Status:** Pending

## Description
$safe_description

## Notes
- 

## Resources
- 
EOF
    
    echo -e "${COLOR_GREEN}Task added successfully!${COLOR_RESET}"
    echo -e "${COLOR_BLUE}Task folder created at: ${COLOR_CYAN}$task_dir${COLOR_RESET}"
}

# Mark a task as complete
complete_task() {
    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}Error: Task ID is required.${COLOR_RESET}"
        return 1
    fi
    
    local task_id="$1"
    local line_number=$((task_id + 1))
    
    if [ $line_number -le 1 ] || [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        echo -e "${COLOR_RED}Error: Invalid task ID.${COLOR_RESET}"
        return 1
    fi
    
    # Get task details
    local task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status <<< "$task_line"
    
    if [ "$status" = "Completed" ]; then
        echo -e "${COLOR_YELLOW}Task is already marked as completed.${COLOR_RESET}"
        return 0
    fi
    
    # Update task status using platform-specific sed commands
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}s/,Pending\$/,Completed/" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}s/,Pending\$/,Completed/" "$TASKS_FILE"
    fi
    
    # Update README in task folder
    task_dir="$UNI_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -f "$task_dir/README.md" ]; then
        if [ "$PLATFORM" == "macos" ]; then
            # macOS sed
            sed -i '' "s/\*\*Status:\*\* Pending/\*\*Status:\*\* Completed/" "$task_dir/README.md"
        else
            # Linux sed
            sed -i "s/\*\*Status:\*\* Pending/\*\*Status:\*\* Completed/" "$task_dir/README.md"
        fi
    fi
    
    echo -e "${COLOR_GREEN}Task marked as completed!${COLOR_RESET}"
}

# Delete a task
delete_task() {
    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}Error: Task ID is required.${COLOR_RESET}"
        return 1
    fi
    
    local task_id="$1"
    local line_number=$((task_id + 1))
    
    if [ $line_number -le 1 ] || [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        echo -e "${COLOR_RED}Error: Invalid task ID.${COLOR_RESET}"
        return 1
    fi
    
    # Get task details before deleting
    local task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status <<< "$task_line"
    
    # Confirm deletion
    read -p "Are you sure you want to delete task '$name'? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${COLOR_YELLOW}Task deletion cancelled.${COLOR_RESET}"
        return 0
    fi
    
    # Delete task from CSV using platform-specific sed commands
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}d" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}d" "$TASKS_FILE"
    fi
    
    # Ask about task folder
    task_dir="$UNI_DIR/$(echo "$name" | tr ' ' '_')"
    if [ -d "$task_dir" ]; then
        read -p "Do you want to delete the task folder as well? (y/n): " delete_folder
        if [[ "$delete_folder" =~ ^[Yy]$ ]]; then
            rm -rf "$task_dir"
            echo -e "${COLOR_GREEN}Task folder deleted.${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}Task folder kept at: ${COLOR_CYAN}$task_dir${COLOR_RESET}"
        fi
    fi
    
    echo -e "${COLOR_GREEN}Task deleted successfully!${COLOR_RESET}"
}

# Edit a task
edit_task() {
    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}Error: Task ID is required.${COLOR_RESET}"
        return 1
    fi
    
    local task_id="$1"
    local line_number=$((task_id + 1))
    
    if [ $line_number -le 1 ] || [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        echo -e "${COLOR_RED}Error: Invalid task ID.${COLOR_RESET}"
        return 1
    fi
    
    # Get task details
    local task_line=$(sed -n "${line_number}p" "$TASKS_FILE")
    IFS=, read -r name due_date description status <<< "$task_line"
    
    echo -e "${COLOR_BLUE}Editing task:${COLOR_RESET} ${COLOR_CYAN}$name${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}(Leave field empty to keep current value)${COLOR_RESET}"
    
    # Get new values
    read -p "Task name [$name]: " new_name
    new_name=${new_name:-$name}
    
    while true; do
        read -p "Due date [$due_date]: " new_due_date
        new_due_date=${new_due_date:-$due_date}
        
        if [ -z "$new_due_date" ] || validate_date "$new_due_date"; then
            break
        else
            echo -e "${COLOR_RED}Invalid date format. Please use YYYY-MM-DD.${COLOR_RESET}"
        fi
    done
    
    read -p "Description [$description]: " new_description
    new_description=${new_description:-$description}
    
    read -p "Status (Pending/Completed) [$status]: " new_status
    new_status=${new_status:-$status}
    
    # Validate status
    if [ "$new_status" != "Pending" ] && [ "$new_status" != "Completed" ]; then
        echo -e "${COLOR_RED}Invalid status. Using '$status'.${COLOR_RESET}"
        new_status=$status
    fi
    
    # Escape any commas to avoid CSV issues
    safe_new_name="${new_name//,/;}"
    safe_new_description="${new_description//,/;}"
    
    # Update task in CSV using platform-specific sed commands
    if [ "$PLATFORM" == "macos" ]; then
        # macOS sed
        sed -i '' "${line_number}s/.*/$safe_new_name,$new_due_date,$safe_new_description,$new_status/" "$TASKS_FILE"
    else
        # Linux sed
        sed -i "${line_number}s/.*/$safe_new_name,$new_due_date,$safe_new_description,$new_status/" "$TASKS_FILE"
    fi
    
    # Handle task folder if name changed
    if [ "$name" != "$new_name" ]; then
        old_task_dir="$UNI_DIR/$(echo "$name" | tr ' ' '_')"
        new_task_dir="$UNI_DIR/$(echo "$new_name" | tr ' ' '_')"
        
        if [ -d "$old_task_dir" ]; then
            # Move folder if it exists
            mv "$old_task_dir" "$new_task_dir"
            echo -e "${COLOR_BLUE}Task folder renamed to: ${COLOR_CYAN}$new_task_dir${COLOR_RESET}"
        else
            # Create new folder
            mkdir -p "$new_task_dir"
            echo -e "${COLOR_BLUE}New task folder created at: ${COLOR_CYAN}$new_task_dir${COLOR_RESET}"
        fi
        
        # Update README
        if [ -f "$new_task_dir/README.md" ]; then
            # Update README content with platform-specific sed commands
            if [ "$PLATFORM" == "macos" ]; then
                # macOS sed
                sed -i '' "s/^# .*$/# $new_name/" "$new_task_dir/README.md"
                sed -i '' "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$new_task_dir/README.md" 
                sed -i '' "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$new_task_dir/README.md"
            else
                # Linux sed
                sed -i "s/^# .*$/# $new_name/" "$new_task_dir/README.md"
                sed -i "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$new_task_dir/README.md"
                sed -i "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$new_task_dir/README.md"
            fi
            
            # Update description - this is trickier with sed, so we'll use a temp file
            awk -v desc="$new_description" '
            BEGIN{replaced=0}
            /^## Description/{print; print desc; getline; replaced=1; next}
            {print}
            ' "$new_task_dir/README.md" > "$new_task_dir/README.md.tmp" 
            
            mv "$new_task_dir/README.md.tmp" "$new_task_dir/README.md"
        else
            # Create new README
            cat > "$new_task_dir/README.md" << EOF
# $new_name

**Due Date:** $new_due_date
**Status:** $new_status

## Description
$new_description

## Notes
- 

## Resources
- 
EOF
        fi
    else
        # Just update README in existing folder
        task_dir="$UNI_DIR/$(echo "$name" | tr ' ' '_')"
        if [ -f "$task_dir/README.md" ]; then
            if [ "$PLATFORM" == "macos" ]; then
                # macOS sed
                sed -i '' "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$task_dir/README.md"
                sed -i '' "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$task_dir/README.md"
            else
                # Linux sed
                sed -i "s/\*\*Due Date:\*\* .*$/\*\*Due Date:\*\* $new_due_date/" "$task_dir/README.md"
                sed -i "s/\*\*Status:\*\* .*$/\*\*Status:\*\* $new_status/" "$task_dir/README.md"
            fi
            
            # Update description
            awk -v desc="$new_description" '
            BEGIN{replaced=0}
            /^## Description/{print; print desc; getline; replaced=1; next}
            {print}
            ' "$task_dir/README.md" > "$task_dir/README.md.tmp"
            
            mv "$task_dir/README.md.tmp" "$task_dir/README.md"
        fi
    fi
    
    echo -e "${COLOR_GREEN}Task updated successfully!${COLOR_RESET}"
}

# View task details
view_task() {
    if [ -z "$1" ]; then
        echo -e "${COLOR_RED}Error: Task ID is required.${COLOR_RESET}"
        return 1
    fi
    
    local task_id="$1"
    local line_number=$((task_id + 1))
    
    if [ $line_number -le 1 ] || [ $line_number -gt $(wc -l < "$TASKS_FILE") ]; then
        echo -e "${COLOR_RED}Error: Invalid task ID.${COLOR_RESET}"
        if [[ "\$PROJECTS_BACKUP" == *.enc ]]; then
        echo "🔑 Enter decryption password for Projects backup:"
        read -s password
        openssl enc -aes-256-cbc -d -in "\$PROJECTS_BACKUP" -out "Projects_${BACKUP_TIMESTAMP}.tar.gz" -k "\$password"
        PROJECTS_BACKUP="Projects_${BACKUP_TIMESTAMP}.tar.gz"
    fi
    
    echo "📂 Extracting Projects backup..."
    mkdir -p "$HOME/Projects"
    tar -xzf "\$PROJECTS_BACKUP" -C "$HOME"
    echo "✅ Projects restored to $HOME/Projects"
fi

# Extract university files
UNI_BACKUP="\$(ls University_${BACKUP_TIMESTAMP}.tar.gz 2>/dev/null || ls University_${BACKUP_TIMESTAMP}.tar.gz.enc 2>/dev/null)"
if [ -n "\$UNI_BACKUP" ]; then
    if [[ "\$UNI_BACKUP" == *.enc ]]; then
        echo "🔑 Enter decryption password for University backup:"
        read -s password
        openssl enc -aes-256-cbc -d -in "\$UNI_BACKUP" -out "University_${BACKUP_TIMESTAMP}.tar.gz" -k "\$password"
        UNI_BACKUP="University_${BACKUP_TIMESTAMP}.tar.gz"
    fi
    
    echo "📂 Extracting University backup..."
    mkdir -p "$HOME/Uni"
    tar -xzf "\$UNI_BACKUP" -C "$HOME"
    echo "✅ University files restored to $HOME/Uni"
fi

# Extract configuration files
CONFIG_BACKUP="\$(ls configs_${BACKUP_TIMESTAMP}.tar.gz 2>/dev/null || ls configs_${BACKUP_TIMESTAMP}.tar.gz.enc 2>/dev/null)"
if [ -n "\$CONFIG_BACKUP" ]; then
    if [[ "\$CONFIG_BACKUP" == *.enc ]]; then
        echo "🔑 Enter decryption password for configuration files backup:"
        read -s password
        openssl enc -aes-256-cbc -d -in "\$CONFIG_BACKUP" -out "configs_${BACKUP_TIMESTAMP}.tar.gz" -k "\$password"
        CONFIG_BACKUP="configs_${BACKUP_TIMESTAMP}.tar.gz"
    fi
    
    echo "📂 Extracting configuration files..."
    mkdir -p "configs_temp"
    tar -xzf "\$CONFIG_BACKUP" -C "configs_temp"
    
    # Backup existing configs before overwriting
    BACKUP_DIR="\$HOME/.config_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "\$BACKUP_DIR"
    
    # Copy each file back to its proper location
    find "configs_temp/configs" -type f | while read file; do
        relative_path="\${file#configs_temp/configs/}"
        target_path="\$HOME/\$relative_path"
        
        # Backup existing file if it exists
        if [ -f "\$target_path" ]; then
            mkdir -p "\$(dirname "\$BACKUP_DIR/\$relative_path")"
            cp "\$target_path" "\$BACKUP_DIR/\$relative_path"
        fi
        
        # Create the directory if it doesn't exist
        mkdir -p "\$(dirname "\$target_path")"
        
        # Copy the file
        cp "\$file" "\$target_path"
        echo "✅ Restored \$relative_path"
    done
    
    # Clean up
    rm -rf "configs_temp"
    echo "✅ Configuration files restored"
    echo "⚠️ Original configuration files have been backed up to \$BACKUP_DIR"
fi

echo "✅ Backup restoration completed!"
EOF

chmod +x "${BACKUP_DIR}/restore_backup.sh"
log "✅ Created restore script: ${BACKUP_DIR}/restore_backup.sh"

exit 0
EOL

    chmod +x "$SCRIPTS_DIR/backup/backup_projects.sh"
    
    # Create Windows batch file to trigger the script
    cat > "$SCRIPTS_DIR/backup/backup_projects.bat" << 'EOL'
@echo off
:: Run Projects Backup script via WSL
wsl bash -c "~/scripts/backup/backup_projects.sh"
EOL
    
    # Create configuration file
    mkdir -p "$SCRIPTS_DIR/config"
    
    cat > "$SCRIPTS_DIR/config/backup.conf" << 'EOL'
# Configuration for System Backup Script

# Backup locations
BACKUP_BASE_DIR="/mnt/g/My Drive/Backups"
PROJECTS_DIR="$HOME/Projects"
UNI_DIR="$HOME/Uni"

# Backup settings
BACKUP_CONFIG_FILES=true
BACKUP_ENCRYPTION=false
ENCRYPTION_PASSWORD=""
RETENTION_DAYS=30
EOL

    return 0
}

create_system_backup() {
    info "Setting up System Backup..."
    
    # Create the scripts if they don't exist
    if [ ! -f "$SCRIPTS_DIR/backup/backup_projects.sh" ]; then
        create_backup_scripts
    fi
    
    # Make sure config directory exists
    mkdir -p "$SCRIPTS_DIR/config"
    
    # Create default config if it doesn't exist
    if [ ! -f "$SCRIPTS_DIR/config/backup.conf" ]; then
        cat > "$SCRIPTS_DIR/config/backup.conf" << 'EOL'
# Configuration for System Backup Script

# Backup locations
BACKUP_BASE_DIR="/mnt/g/My Drive/Backups"
PROJECTS_DIR="$HOME/Projects"
UNI_DIR="$HOME/Uni"

# Backup settings
BACKUP_CONFIG_FILES=true
BACKUP_ENCRYPTION=false
ENCRYPTION_PASSWORD=""
RETENTION_DAYS=30
EOL
    fi
    
    # Get Google Drive path
    backup_path=$(get_google_drive_path)
    
    if [ -n "$backup_path" ]; then
        # Use different sed syntax based on platform (macOS vs Linux)
        if [ "$(uname)" == "Darwin" ]; then
            sed -i '' "s|BACKUP_BASE_DIR=.*|BACKUP_BASE_DIR=\"$backup_path\"|" "$SCRIPTS_DIR/config/backup.conf"
        else
            sed -i "s|BACKUP_BASE_DIR=.*|BACKUP_BASE_DIR=\"$backup_path\"|" "$SCRIPTS_DIR/config/backup.conf"
        fi
        
        success "Backup location set to $backup_path"
        
        # Create the backup directory structure if it doesn't exist
        if [ ! -d "$backup_path" ]; then
            info "Attempting to create backup directory: $backup_path"
            mkdir -p "$backup_path"
            
            if [ $? -ne 0 ]; then
                warning "Could not create backup directory automatically"
                warning "You may need to create it manually or check drive mapping"
                
                if [ "$PLATFORM" == "wsl" ]; then
                    info "For WSL, make sure your Google Drive is mounted correctly"
                    info "Try to create this path from Windows Explorer: G:\\My Drive\\Backups"
                fi
            else
                success "Created backup directory: $backup_path"
            fi
        fi
    else
        error "No backup path provided. Backup location may not work correctly."
    fi
    
    # Ask if they want to enable encryption
    read -p "Do you want to enable backup encryption? (y/n): " enable_encryption
    
    if [[ "$enable_encryption" =~ ^[Yy]$ ]]; then
        # Use different sed syntax based on platform (macOS vs Linux)
        if [ "$(uname)" == "Darwin" ]; then
            sed -i '' "s/BACKUP_ENCRYPTION=false/BACKUP_ENCRYPTION=true/" "$SCRIPTS_DIR/config/backup.conf"
        else
            sed -i "s/BACKUP_ENCRYPTION=false/BACKUP_ENCRYPTION=true/" "$SCRIPTS_DIR/config/backup.conf"
        fi
        
        # Ask for encryption password and store it securely
        read -s -p "Enter encryption password: " encryption_password
        echo ""
        
        if [ -n "$encryption_password" ]; then
            # Use different sed syntax based on platform (macOS vs Linux)
            if [ "$(u            if [ -d "$DOTFILES_DIR/vscode/snippets" ]; then
                # Backup existing snippets if they exist
                if [ -d "$VSCODE_DIR/snippets" ]; then
                    mkdir -p "$BACKUP_DIR/vscode"
                    cp -r "$VSCODE_DIR/snippets" "$BACKUP_DIR/vscode/"
                    log "Backed up existing VS Code snippets to $BACKUP_DIR/vscode/"
                fi
                
                mkdir -p "$VSCODE_DIR/snippets"
                cp -r "$DOTFILES_DIR/vscode/snippets/"* "$VSCODE_DIR/snippets/"
                log "Restored VS Code snippets"
            fi
        else
            log "Warning: VS Code settings directory not found, skipping VS Code settings restoration"
        fi
    fi
    
    log "Restore completed successfully"
    
    if [ "$(ls -A "$BACKUP_DIR")" ]; then
        log "Your original files have been backed up to $BACKUP_DIR"
    else
        # Remove empty backup directory
        rmdir "$BACKUP_DIR"
    fi
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    show_help
fi

case "$1" in
    --setup)
        check_git
        setup_repo
        ;;
    --backup)
        check_git
        backup_dotfiles
        ;;
    --restore)
        check_git
        restore_dotfiles
        ;;
    --help)
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        show_help
        ;;
esac

exit 0
EOL

    chmod +x "$SCRIPTS_DIR/backup/sync_dotfiles.sh"
    
    # Create configuration file
    mkdir -p "$SCRIPTS_DIR/config"
    
    cat > "$SCRIPTS_DIR/config/dotfiles_sync.conf" << 'EOL'
# Configuration for Dotfiles Sync Script

# Repository settings
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO=""  # Set this to your GitHub repository URL
DOTFILES_BRANCH="main"

# Files to sync
SYNC_FILES=(
    ".zshrc"
    ".bashrc"
    ".bash_aliases"
    ".gitconfig"
    ".vimrc"
    ".tmux.conf"
    ".prettierrc"
    ".editorconfig"
)

# VS Code settings
SYNC_VSCODE=true
VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
VSCODE_SETTINGS_WIN_DIR="/mnt/c/Users/$USER/AppData/Roaming/Code/User"
EOL

    return 0
}

setup_dotfiles_syncer() {
    info "Setting up Dotfiles Syncer..."
    
    # Create the script if it doesn't exist
    if [ ! -f "$SCRIPTS_DIR/backup/sync_dotfiles.sh" ]; then
        create_dotfiles_syncer_script
    fi
    
    # Ask for repository URL
    read -p "Enter your GitHub repository URL for dotfiles (e.g., git@github.com:username/dotfiles.git): " repo_url
    
    if [ -n "$repo_url" ]; then
        # Update the config file
        if [ "$(uname)" == "Darwin" ]; then
            sed -i '' "s|DOTFILES_REPO=\"\"|DOTFILES_REPO=\"$repo_url\"|" "$SCRIPTS_DIR/config/dotfiles_sync.conf"
        else
            sed -i "s|DOTFILES_REPO=\"\"|DOTFILES_REPO=\"$repo_url\"|" "$SCRIPTS_DIR/config/dotfiles_sync.conf"
        fi
        
        success "Repository URL set to $repo_url"
    else
        warning "No repository URL provided. You'll need to set it up later."
    fi
    
    # Ask which files to sync
    read -p "Do you want to customize which files to sync? (y/n): " customize_files
    
    if [[ "$customize_files" =~ ^[Yy]$ ]]; then
        echo "Enter the files you want to sync (separated by space):"
        echo "For example: .zshrc .bashrc .gitconfig"
        read -p "> " custom_files
        
        if [ -n "$custom_files" ]; then
            # Update the config file
            echo "SYNC_FILES=(" > "$SCRIPTS_DIR/config/dotfiles_sync.conf.new"
            for file in $custom_files; do
                echo "    \"$file\"" >> "$SCRIPTS_DIR/config/dotfiles_sync.conf.new"
            done
            echo ")" >> "$SCRIPTS_DIR/config/dotfiles_sync.conf.new"
            
            # Get the rest of the config file
            grep -v "^SYNC_FILES=" "$SCRIPTS_DIR/config/dotfiles_sync.conf" | grep -v "^)" >> "$SCRIPTS_DIR/config/dotfiles_sync.conf.new"
            
            # Replace the config file
            mv "$SCRIPTS_DIR/config/dotfiles_sync.conf.new" "$SCRIPTS_DIR/config/dotfiles_sync.conf"
            
            success "Custom files set for syncing"
        fi
    fi
    
    # Ask if they want to set up the repository now
    read -p "Do you want to set up the dotfiles repository now? (y/n): " setup_now
    
    if [[ "$setup_now" =~ ^[Yy]$ ]]; then
        # Check for SSH key
        if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ ! -f "$HOME/.ssh/id_rsa" ]; then
            warning "No SSH key found. You might need to create one for GitHub access."
            read -p "Do you want to create an SSH key now? (y/n): " create_key
            
            if [[ "$create_key" =~ ^[Yy]$ ]]; then
                read -p "Enter your email for the SSH key: " key_email
                ssh-keygen -t ed25519 -C "$key_email"
                
                if [ $? -eq 0 ]; then
                    success "SSH key created successfully"
                    echo "You'll need to add this key to your GitHub account:"
                    cat "$HOME/.ssh/id_ed25519.pub"
                    echo ""
                    read -p "Press Enter when you've added the key to GitHub..."
                else
                    error "Failed to create SSH key"
                    read -p "Press Enter to continue anyway..."
                fi
            fi
        fi
        
        bash "$SCRIPTS_DIR/backup/sync_dotfiles.sh" --setup
        if [ $? -ne 0 ]; then
            error "Repository setup failed"
        fi
    else
        info "You can set up the repository later with: $SCRIPTS_DIR/backup/sync_dotfiles.sh --setup"
    fi
    
    # Set up a periodic backup
    read -p "Do you want to set up a weekly dotfiles backup? (y/n): " setup_cron
    
    if [[ "$setup_cron" =~ ^[Yy]$ ]]; then
        # Check if crontab is installed
        if command -v crontab &> /dev/null; then
            # Add cron job for weekly backup
            (crontab -l 2>/dev/null || echo "") | grep -v "sync_dotfiles.sh" | { cat; echo "0 0 * * 0 $SCRIPTS_DIR/backup/sync_dotfiles.sh --backup > $SCRIPTS_DIR/logs/dotfiles_sync_cron.log 2>&1"; } | crontab -
            
            if [ $? -eq 0 ]; then
                success "Weekly backup scheduled via crontab"
            else
                error "Failed to schedule backup via crontab"
            fi
        else
            warning "crontab not found. You'll need to schedule backups manually."
        fi
    fi
    
    success "Dotfiles Syncer setup complete"
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 7. System Backup Script =======
create_backup_scripts() {
    info "Creating System Backup scripts..."
    
    mkdir -p "$SCRIPTS_DIR/backup"
    
    cat > "$SCRIPTS_DIR/backup/backup_projects.sh" << 'EOL'
#!/bin/bash
# System Backup Script - Comprehensive backup solution

set -e

# Configuration
CONFIG_FILE="$HOME/scripts/config/backup.conf"
LOG_FILE="$HOME/scripts/logs/backup_$(date +%Y-%m-%d_%H-%M-%S).log"
BACKUP_TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)

# Default settings
# Note: Google Drive path will be configured during setup
BACKUP_BASE_DIR="/mnt/g/My Drive/Backups"
PROJECTS_DIR="$HOME/Projects"
UNI_DIR="$HOME/Uni"
BACKUP_CONFIG_FILES=true
BACKUP_ENCRYPTION=false
# Note: Password should be set during setup, not hardcoded
ENCRYPTION_PASSWORD=""
RETENTION_DAYS=30

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Function to detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Logging function
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

error() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - ERROR: $1" | tee -a "$LOG_FILE"
    echo "❌ Error: $1"
}

# Check the backup directory exists
BACKUP_DIR="${BACKUP_BASE_DIR}/${BACKUP_TIMESTAMP}"
mkdir -p "$BACKUP_DIR"

# Verify directory creation worked
if [ ! -d "$BACKUP_DIR" ]; then
    error "Failed to create backup directory: $BACKUP_DIR"
    
    # Check if base directory is accessible
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        error "Backup base directory doesn't exist or is not accessible: $BACKUP_BASE_DIR"
        error "Check your Google Drive path configuration in $CONFIG_FILE"
        
        if [ "$PLATFORM" == "wsl" ]; then
            # Extract drive letter from path for better error messages
            if [[ "$BACKUP_BASE_DIR" =~ ^/mnt/([a-z]) ]]; then
                drive_letter="${BASH_REMATCH[1]^^}"  # Convert to uppercase
                error "Make sure drive $drive_letter: is mounted in WSL"
                error "Try accessing it through File Explorer: $drive_letter:\\"
            fi
            
            # Provide WSL-specific troubleshooting tips
            error "WSL path issues could be due to:"
            error "1. Google Drive not mounted in Windows"
            error "2. Drive letter mapping is different"
            error "3. WSL not having access to the Windows drive"
            error ""
            error "Try manually creating the directory from Windows: G:\\My Drive\\Backups"
        else
            error "Make sure the path exists and is accessible"
        fi
    fi
    
    exit 1
fi

log "==== Backup started at $(date) ===="
log "Backup directory: $BACKUP_DIR"

# Function to backup a single directory
backup_directory() {
    local source_dir="$1"
    local name="$2"
    local backup_file="${BACKUP_DIR}/${name}_${BACKUP_TIMESTAMP}.tar.gz"
    
    if [ ! -d "$source_dir" ]; then
        log "Directory not found: $source_dir, skipping..."
        return 1
    fi
    
    log "📦 Backing up $name..."
    
    # Create tar file with exclusions
    tar -czf "$backup_file" \
        --exclude="*/node_modules" \
        --exclude="*/.git" \
        --exclude="*/venv" \
        --exclude="*/__pycache__" \
        --exclude="*/.ipynb_checkpoints" \
        --exclude="*/dist" \
        --exclude="*/build" \
        -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
    
    if [ $? -ne 0 ]; then
        error "Failed to create backup for $name"
        return 1
    fi
    
    log "✅ Created backup: $backup_file ($(du -h "$backup_file" | cut -f1))"
    
    # Encrypt the backup if enabled
    if [ "$BACKUP_ENCRYPTION" = true ]; then
        if ! command -v openssl &> /dev/null; then
            log "Warning: openssl not found, skipping encryption"
        else
            # Check if encryption password is set
            if [ -z "$ENCRYPTION_PASSWORD" ]; then
                log "Warning: Encryption password not set, prompting..."
                read -s -p "Enter encryption password: " ENCRYPTION_PASSWORD
                echo ""
                
                if [ -z "$ENCRYPTION_PASSWORD" ]; then
                    log "Warning: No password provided, skipping encryption"
                else
                    # Save password to config
                    if [ -f "$CONFIG_FILE" ]; then
                        # Only update if file exists and doesn't already have a password
                        if grep -q 'ENCRYPTION_PASSWORD=""' "$CONFIG_FILE"; then
                            sed -i "s/ENCRYPTION_PASSWORD=\"\"/ENCRYPTION_PASSWORD=\"$ENCRYPTION_PASSWORD\"/" "$CONFIG_FILE"
                        fi
                    fi
                fi
            fi
            
            if [ -n "$ENCRYPTION_PASSWORD" ]; then
                log "🔒 Encrypting backup for $name..."
                openssl enc -aes-256-cbc -salt -in "$backup_file" -out "${backup_file}.enc" -k "$ENCRYPTION_PASSWORD"
                
                if [ $? -ne 0 ]; then
                    error "Failed to encrypt backup for $name"
                    return 1
                fi
                
                # Remove the unencrypted file
                rm "$backup_file"
                backup_file="${backup_file}.enc"
                log "✅ Encrypted backup: $backup_file"
            fi
        fi
    fi
    
    # Verify the backup
    if [ -f "$backup_file" ]; then
        if [ "$BACKUP_ENCRYPTION" = true ] && [[ "$backup_file" == *.enc ]]; then
            # Test decryption (without actually writing the decrypted file)
            log "🔍 Verifying encrypted backup for $name..."
            
            if [ -z "$ENCRYPTION_PASSWORD" ]; then
                error "Encryption password not available for verification"
                return 1
            fi
            
            # Create a temporary directory for verification
            local temp_verify_dir=$(mktemp -d)
            
            # Try to decrypt and extract a small portion to verify content
            openssl enc -aes-256-cbc -d -in "$backup_file" -k "$ENCRYPTION_PASSWORD" -out "$temp_verify_dir/test.tar.gz" 2>/dev/null
            
            if [ $? -ne 0 ]; then
                error "Verification failed: could not decrypt $name backup"
                rm -rf "$temp_verify_dir"
                return 1
            fi
            
            # Test if it's a valid tar file
            tar -tzf "$temp_verify_dir/test.tar.gz" > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
                error "Verification failed: decrypted file is not a valid archive for $name backup"
                rm -rf "$temp_verify_dir"
                return 1
            fi
            
            # Clean up
            rm -rf "$temp_verify_dir"
        else
            # For unencrypted backups, test the tar file
            log "🔍 Verifying backup for $name..."
            tar -tzf "$backup_file" > /dev/null 2>&1
            
            if [ $? -ne 0 ]; then
                error "Verification failed: not a valid archive for $name backup"
                return 1
            fi
        fi
        
        log "✅ Verified backup: $name"
        return 0
    else
        error "Backup file not found for $name"
        return 1
    fi
}

# Backup projects directory
backup_directory "$PROJECTS_DIR" "Projects"

# Backup university directory
backup_directory "$UNI_DIR" "University"

# Backup configuration files
if [ "$BACKUP_CONFIG_FILES" = true ]; then
    CONFIG_BACKUP_DIR="$BACKUP_DIR/configs"
    mkdir -p "$CONFIG_BACKUP_DIR"
    
    log "📝 Backing up configuration files..."
    
    # List of configuration files to backup
    CONFIG_FILES=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.bash_aliases"
        "$HOME/.gitconfig"
        "$HOME/.vimrc"
        "$HOME/.tmux.conf"
        "$HOME/.ssh/config"
    )
    
    # Copy each config file
    for file in "${CONFIG_FILES[@]}"; do
        if [ -f "$file" ]; then
            mkdir -p "$CONFIG_BACKUP_DIR/$(dirname "${file#$HOME/}")"
            cp "$file" "$CONFIG_BACKUP_DIR/${file#$HOME/}"
            log "✅ Backed up $(basename "$file")"
        fi
    done
    
    # VS Code settings
    VSCODE_SETTINGS_DIR=""
    if [ -d "$HOME/.config/Code/User" ]; then
        VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
    elif [ "$PLATFORM" == "wsl" ]; then
        # Try to get Windows username
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        if [ -n "$WIN_USER" ] && [[ ! "$WIN_USER" == *"%" ]]; then
            POTENTIAL_VSCODE_DIR="/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User"
            if [ -d "$POTENTIAL_VSCODE_DIR" ]; then
                VSCODE_SETTINGS_DIR="$POTENTIAL_VSCODE_DIR"
            fi
        fi
    fi
    
    if [ -n "$VSCODE_SETTINGS_DIR" ]; then
        mkdir -p "$CONFIG_BACKUP_DIR/vscode"
        
        if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
            cp "$VSCODE_SETTINGS_DIR/settings.json" "$CONFIG_BACKUP_DIR/vscode/"
            log "✅ Backed up VS Code settings.json"
        fi
        
        if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]; then
            cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$CONFIG_BACKUP_DIR/vscode/"
            log "✅ Backed up VS Code keybindings.json"
        fi
        
        if [ -d "$VSCODE_SETTINGS_DIR/snippets" ]; then
            mkdir -p "$CONFIG_BACKUP_DIR/vscode/snippets"
            cp -r "$VSCODE_SETTINGS_DIR/snippets/"* "$CONFIG_BACKUP_DIR/vscode/snippets/"
            log "✅ Backed up VS Code snippets"
        fi
    fi
    
    # Compress the config files
    CONFIG_ARCHIVE="${BACKUP_DIR}/configs_${BACKUP_TIMESTAMP}.tar.gz"
    tar -czf "$CONFIG_ARCHIVE" -C "$BACKUP_DIR" "configs"
    
    if [ $? -eq 0 ]; then
        # Remove the uncompressed directory
        rm -rf "$CONFIG_BACKUP_DIR"
        
        # Encrypt if needed
        if [ "$BACKUP_ENCRYPTION" = true ] && command -v openssl &> /dev/null && [ -n "$ENCRYPTION_PASSWORD" ]; then
            openssl enc -aes-256-cbc -salt -in "$CONFIG_ARCHIVE" -out "${CONFIG_ARCHIVE}.enc" -k "$ENCRYPTION_PASSWORD"
            
            if [ $? -eq 0 ]; then
                rm "$CONFIG_ARCHIVE"
                log "✅ Configuration files backed up and encrypted to ${CONFIG_ARCHIVE}.enc"
            else
                error "Failed to encrypt configuration files backup"
            fi
        else
            log "✅ Configuration files backed up to $CONFIG_ARCHIVE"
        fi
    else
        error "Failed to compress configuration files backup"
    fi
fi

# Create backup summary
SUMMARY_FILE="${BACKUP_DIR}/backup_summary.txt"
cat > "$SUMMARY_FILE" << EOF
========================================
BACKUP SUMMARY - ${BACKUP_TIMESTAMP}
========================================
Backup Location: $BACKUP_DIR
Encrypted: $([ "$BACKUP_ENCRYPTION" = true ] && echo "Yes" || echo "No")

Directories backed up:
- Projects: $PROJECTS_DIR
- University: $UNI_DIR
- Configuration Files: $([ "$BACKUP_CONFIG_FILES" = true ] && echo "Yes" || echo "No")

Date: $(date)
Username: $USER
Host: $(hostname)
========================================
EOF

log "📝 Created backup summary: $SUMMARY_FILE"

# Update last backup date
date +%Y-%m-%d > "$HOME/last_backup.txt"

# Clean up old backups
if [ $RETENTION_DAYS -gt 0 ]; then
    log "🧹 Cleaning up old backups (older than $RETENTION_DAYS days)..."
    
    if [ "$PLATFORM" == "macos" ]; then
        # macOS uses different find syntax
        find "$BACKUP_BASE_DIR" -type d -mtime +$RETENTION_DAYS -maxdepth 1 -mindepth 1 -exec rm -rf {} \; 2>/dev/null || true
    else
        # Linux/WSL syntax
        find "$BACKUP_BASE_DIR" -type d -mtime +$RETENTION_DAYS -maxdepth 1 -mindepth 1 -exec rm -rf {} \; 2>/dev/null || true
    fi
    
    log "✅ Cleanup completed"
fi

# Final status
log "==== Backup completed at $(date) ===="

# Create restore script in the backup directory
cat > "${BACKUP_DIR}/restore_backup.sh" << EOF
#!/bin/bash
# Auto-generated restore script for backup from ${BACKUP_TIMESTAMP}

set -e

echo "🔄 Starting backup restoration from ${BACKUP_TIMESTAMP}..."

# Extract projects
PROJECTS_BACKUP="\$(ls Projects_${BACKUP_TIMESTAMP}.tar.gz 2>/dev/null || ls Projects_${BACKUP_TIMESTAMP}.tar.gz.enc 2>/dev/null)"        if [[ "$(dirname "$file")" != "$DOWNLOADS_DIR" ]]; then
            continue
        fi
        
        # Get the filename
        filename=$(basename "$file")
        
        # Skip if destination is the same as source
        if [ "$(dirname "$file")" = "$destination" ]; then
            continue
        fi
        
        # Move the file
        mv "$file" "$destination/$filename"
        count=$((count + 1))
        log "Moved: $filename to $(basename "$destination")"
    done
    
    return $count
}

# Organize installers (exe, msi, appx, etc.)
if [ "$ORGANIZE_INSTALLERS" = true ]; then
    log "Organizing installers..."
    move_files "*.exe" "$DOWNLOADS_DIR/Installers"
    move_files "*.msi" "$DOWNLOADS_DIR/Installers"
    move_files "*.appx" "$DOWNLOADS_DIR/Installers"
    move_files "*.appxbundle" "$DOWNLOADS_DIR/Installers"
    move_files "*.msixbundle" "$DOWNLOADS_DIR/Installers"
    move_files "*.deb" "$DOWNLOADS_DIR/Installers"
    move_files "*.rpm" "$DOWNLOADS_DIR/Installers"
    log "Installers organized"
fi

# Organize images
if [ "$ORGANIZE_IMAGES" = true ]; then
    log "Organizing images..."
    move_files "*.jpg" "$DOWNLOADS_DIR/Images"
    move_files "*.jpeg" "$DOWNLOADS_DIR/Images"
    move_files "*.png" "$DOWNLOADS_DIR/Images"
    move_files "*.gif" "$DOWNLOADS_DIR/Images"
    move_files "*.bmp" "$DOWNLOADS_DIR/Images"
    move_files "*.svg" "$DOWNLOADS_DIR/Images"
    move_files "*.webp" "$DOWNLOADS_DIR/Images"
    log "Images organized"
fi

# Organize documents
if [ "$ORGANIZE_DOCUMENTS" = true ]; then
    log "Organizing documents..."
    move_files "*.pdf" "$DOWNLOADS_DIR/Documents"
    move_files "*.doc" "$DOWNLOADS_DIR/Documents"
    move_files "*.docx" "$DOWNLOADS_DIR/Documents"
    move_files "*.xls" "$DOWNLOADS_DIR/Documents"
    move_files "*.xlsx" "$DOWNLOADS_DIR/Documents"
    move_files "*.ppt" "$DOWNLOADS_DIR/Documents"
    move_files "*.pptx" "$DOWNLOADS_DIR/Documents"
    move_files "*.txt" "$DOWNLOADS_DIR/Documents"
    move_files "*.rtf" "$DOWNLOADS_DIR/Documents"
    log "Documents organized"
fi

# Organize archives
if [ "$ORGANIZE_ARCHIVES" = true ]; then
    log "Organizing archives..."
    move_files "*.zip" "$DOWNLOADS_DIR/Archives"
    move_files "*.rar" "$DOWNLOADS_DIR/Archives"
    move_files "*.7z" "$DOWNLOADS_DIR/Archives"
    move_files "*.tar" "$DOWNLOADS_DIR/Archives"
    move_files "*.tar.gz" "$DOWNLOADS_DIR/Archives"
    move_files "*.tgz" "$DOWNLOADS_DIR/Archives"
    move_files "*.gz" "$DOWNLOADS_DIR/Archives"
    log "Archives organized"
fi

# Clean old files from Temp directory
if [ "$DELETE_OLD" = true ]; then
    log "Checking for old files in $TEMP_DIR directory..."
    if [ "$PLATFORM" == "macos" ]; then
        # macOS uses different find syntax
        find "$DOWNLOADS_DIR/$TEMP_DIR" -type f -mtime +$OLD_DAYS -exec rm -f {} \;
    else
        # Linux/WSL syntax
        find "$DOWNLOADS_DIR/$TEMP_DIR" -type f -mtime +$OLD_DAYS -exec rm -f {} \;
    fi
    log "Removed old files from $TEMP_DIR directory"
fi

log "Downloads organization completed"
EOL

    chmod +x "$SCRIPTS_DIR/productivity/organize_downloads.sh"
    
    # Create Windows batch file to trigger the script
    cat > "$SCRIPTS_DIR/productivity/organize_downloads.bat" << 'EOL'
@echo off
:: Run Downloads Organizer script via WSL
wsl bash -c "~/scripts/productivity/organize_downloads.sh"
EOL
    
    # Create configuration file
    mkdir -p "$SCRIPTS_DIR/config"
    
    cat > "$SCRIPTS_DIR/config/downloads_organizer.conf" << 'EOL'
# Configuration for Downloads Organizer

# User settings - will be updated during setup
DOWNLOADS_DIR="/mnt/c/Users/$USER/Downloads"

# Organization settings
ORGANIZE_INSTALLERS=true
ORGANIZE_IMAGES=true
ORGANIZE_DOCUMENTS=true
ORGANIZE_ARCHIVES=true

# Cleanup settings
DELETE_OLD=true
OLD_DAYS=30
TEMP_DIR="Temp"
EOL

    # Create windows scheduled task
    cat > "$SCRIPTS_DIR/productivity/setup_downloads_organizer_task.ps1" << 'EOL'
# Setup Windows Task Scheduler for Downloads Organizer
# Run this with PowerShell as Administrator

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

try {
    $taskName = "DownloadsOrganizer"
    $taskDescription = "Automatically organize Downloads folder"
    $scriptPath = "$env:USERPROFILE\scripts\productivity\organize_downloads.bat"

    # Look for WSL script paths
    $wslPath = Get-ChildItem "$env:USERPROFILE\AppData\Local\Packages\*Ubuntu*\LocalState\rootfs\home\*\scripts\productivity\organize_downloads.bat" -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($wslPath) {
        Write-Host "Found WSL script at: $($wslPath.FullName)" -ForegroundColor Cyan
        $scriptPath = $wslPath.FullName
    }

    # Verify script exists
    if (-not (Test-Path $scriptPath)) {
        Write-Host "Script not found at: $scriptPath" -ForegroundColor Yellow
        
        # Try to locate the script in common locations
        $possiblePaths = @(
            "$env:USERPROFILE\AppData\Local\Packages\*Ubuntu*\LocalState\rootfs\home\*\scripts\productivity\organize_downloads.bat"
        )
        
        foreach ($pathPattern in $possiblePaths) {
            $foundPaths = Get-ChildItem $pathPattern -ErrorAction SilentlyContinue
            if ($foundPaths) {
                $scriptPath = $foundPaths[0].FullName
                Write-Host "Found script at: $scriptPath" -ForegroundColor Green
                break
            }
        }
        
        if (-not (Test-Path $scriptPath)) {
            $manualPath = Read-Host "Enter the full path to organize_downloads.bat (or press Enter to cancel)"
            
            if ([string]::IsNullOrEmpty($manualPath)) {
                Write-Host "Task setup cancelled." -ForegroundColor Yellow
                exit 1
            }
            
            if (-not (Test-Path $manualPath)) {
                Write-Host "Script still not found. Please verify the path and try again." -ForegroundColor Red
                exit 1
            }
            
            $scriptPath = $manualPath
        }
    }

    # Create a new task action
    $action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$scriptPath`""

    # Create a trigger to run daily at 3 AM
    $trigger = New-ScheduledTaskTrigger -Daily -At 3am

    # Register the task
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Description $taskDescription -RunLevel Highest -Force

    Write-Host "✅ Downloads Organizer scheduled task created successfully!" -ForegroundColor Green
    Write-Host "⏰ The task will run daily at 3:00 AM" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Error creating scheduled task: $_" -ForegroundColor Red
    exit 1
}
EOL

    return 0
}

setup_downloads_organizer() {
    info "Setting up Downloads Organizer..."
    
    # Create the script if it doesn't exist
    if [ ! -f "$SCRIPTS_DIR/productivity/organize_downloads.sh" ]; then
        create_downloads_organizer_script
    fi
    
    # Determine correct downloads path based on platform
    if [ "$PLATFORM" == "wsl" ]; then
        # Try to get Windows username
        win_username=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        
        if [ -z "$win_username" ] || [[ "$win_username" == *"%" ]]; then
            # Fallback to prompt
            read -p "Enter your Windows username: " win_username
        fi
        
        if [ -n "$win_username" ]; then
            downloads_path="/mnt/c/Users/$win_username/Downloads"
            
            # Check if path exists
            if [ ! -d "$downloads_path" ]; then
                warning "Downloads directory not found at $downloads_path"
                read -p "Enter the full path to your Downloads folder: " downloads_path
            fi
        else
            read -p "Enter the full path to your Downloads folder: " downloads_path
        fi
    else
        # For Linux/macOS
        if [ -d "$HOME/Downloads" ]; then
            downloads_path="$HOME/Downloads"
        else
            read -p "Enter the full path to your Downloads folder: " downloads_path
        fi
    fi
    
    # Update the config file
    if [ -n "$downloads_path" ]; then
        # Use different sed syntax based on platform (macOS vs Linux)
        if [ "$(uname)" == "Darwin" ]; then
            sed -i '' "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$downloads_path\"|" "$SCRIPTS_DIR/config/downloads_organizer.conf"
        else
            sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$downloads_path\"|" "$SCRIPTS_DIR/config/downloads_organizer.conf"
        fi
        
        success "Downloads path set to $downloads_path"
    else
        error "No downloads path provided. Organization may not work correctly."
    fi
    
    # Ask if they want to customize organization settings
    read -p "Do you want to customize which file types to organize? (y/n): " customize
    
    if [[ "$customize" =~ ^[Yy]$ ]]; then
        read -p "Organize installer files (exe, msi, etc.)? (y/n) [y]: " organize_installers
        if [[ "$organize_installers" =~ ^[Nn]$ ]]; then
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/ORGANIZE_INSTALLERS=true/ORGANIZE_INSTALLERS=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            else
                sed -i "s/ORGANIZE_INSTALLERS=true/ORGANIZE_INSTALLERS=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            fi
        fi
        
        read -p "Organize image files (jpg, png, etc.)? (y/n) [y]: " organize_images
        if [[ "$organize_images" =~ ^[Nn]$ ]]; then
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/ORGANIZE_IMAGES=true/ORGANIZE_IMAGES=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            else
                sed -i "s/ORGANIZE_IMAGES=true/ORGANIZE_IMAGES=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            fi
        fi
        
        read -p "Organize document files (pdf, docx, etc.)? (y/n) [y]: " organize_documents
        if [[ "$organize_documents" =~ ^[Nn]$ ]]; then
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/ORGANIZE_DOCUMENTS=true/ORGANIZE_DOCUMENTS=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            else
                sed -i "s/ORGANIZE_DOCUMENTS=true/ORGANIZE_DOCUMENTS=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            fi
        fi
        
        read -p "Organize archive files (zip, rar, etc.)? (y/n) [y]: " organize_archives
        if [[ "$organize_archives" =~ ^[Nn]$ ]]; then
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/ORGANIZE_ARCHIVES=true/ORGANIZE_ARCHIVES=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            else
                sed -i "s/ORGANIZE_ARCHIVES=true/ORGANIZE_ARCHIVES=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            fi
        fi
    fi
    
    # Ask about cleanup settings
    read -p "Do you want to configure cleanup of old files? (y/n): " configure_cleanup
    
    if [[ "$configure_cleanup" =~ ^[Yy]$ ]]; then
        read -p "Enable automatic cleanup of old files? (y/n) [y]: " enable_cleanup
        if [[ "$enable_cleanup" =~ ^[Nn]$ ]]; then
            if [ "$(uname)" == "Darwin" ]; then
                sed -i '' "s/DELETE_OLD=true/DELETE_OLD=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            else
                sed -i "s/DELETE_OLD=true/DELETE_OLD=false/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
            fi
        else
            read -p "How many days to keep files before cleanup? [30]: " cleanup_days
            if [ -n "$cleanup_days" ] && [[ "$cleanup_days" =~ ^[0-9]+$ ]]; then
                if [ "$(uname)" == "Darwin" ]; then
                    sed -i '' "s/OLD_DAYS=30/OLD_DAYS=$cleanup_days/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
                else
                    sed -i "s/OLD_DAYS=30/OLD_DAYS=$cleanup_days/" "$SCRIPTS_DIR/config/downloads_organizer.conf"
                fi
            fi
        fi
    fi
    
    # Ask if they want to run it now
    read -p "Do you want to run the organizer now? (y/n): " run_now
    
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        # Source the updated config before running
        source "$SCRIPTS_DIR/config/downloads_organizer.conf"
        
        # Check access to downloads location before running
        if [ ! -d "$DOWNLOADS_DIR" ]; then
            error "Downloads location $DOWNLOADS_DIR doesn't exist or is not accessible"
            info "Please check your configuration and try again"
            read -p "Press Enter to continue..."
            return 1
        fi
        
        # Run the script
        bash "$SCRIPTS_DIR/productivity/organize_downloads.sh"
        if [ $? -ne 0 ]; then
            error "Downloads organization failed. Check logs for details."
        else
            success "Downloads organization completed successfully"
        fi
    fi
    
    # Ask if they want to schedule it (Windows only)
    if [ "$PLATFORM" == "wsl" ]; then
        read -p "Do you want to schedule this to run daily? (y/n): " schedule_it
        
        if [[ "$schedule_it" =~ ^[Yy]$ ]]; then
            success "PowerShell script for task scheduling created"
            info "To schedule the task, please run the PowerShell script as administrator:"
            info "PowerShell.exe -ExecutionPolicy Bypass -File \"$SCRIPTS_DIR/productivity/setup_downloads_organizer_task.ps1\""
        fi
    fi
    
    success "Downloads Organizer setup complete"
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 6. Dotfiles Syncer Script =======
create_dotfiles_syncer_script() {
    info "Creating Dotfiles Syncer script..."
    
    mkdir -p "$SCRIPTS_DIR/backup"
    
    cat > "$SCRIPTS_DIR/backup/sync_dotfiles.sh" << 'EOL'
#!/bin/bash
# Dotfiles Sync Script
# Syncs your configuration files to a Git repository

set -e

# Configuration
CONFIG_FILE="$HOME/scripts/config/dotfiles_sync.conf"
LOG_FILE="$HOME/scripts/logs/dotfiles_sync.log"
DOTFILES_DIR="$HOME/.dotfiles"
DOTFILES_REPO=""
DOTFILES_BRANCH="main"

# Files to sync (default)
SYNC_FILES=(
    ".zshrc"
    ".bashrc"
    ".bash_aliases"
    ".gitconfig"
    ".vimrc"
    ".tmux.conf"
)

# VS Code settings
SYNC_VSCODE=true
VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"
VSCODE_SETTINGS_WIN_DIR="/mnt/c/Users/$USER/AppData/Roaming/Code/User"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Function to detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

show_help() {
    echo "Dotfiles Sync Script"
    echo "Usage: $(basename $0) [options]"
    echo ""
    echo "Options:"
    echo "  --backup    Backup dotfiles to repository"
    echo "  --restore   Restore dotfiles from repository"
    echo "  --setup     Initial setup of dotfiles repository"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $(basename $0) --setup"
    echo "  $(basename $0) --backup"
    echo "  $(basename $0) --restore"
    exit 0
}

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        log "Error: Git is not installed"
        log "Please install Git before continuing"
        exit 1
    fi
}

# Function to check if git repository is configured
check_repo_config() {
    if [ -z "$DOTFILES_REPO" ]; then
        log "Error: Dotfiles repository not configured. Please set DOTFILES_REPO in $CONFIG_FILE"
        log "You can use --setup option to configure it"
        exit 1
    fi
}

# Function to set up dotfiles repository
setup_repo() {
    log "Setting up dotfiles repository..."
    
    # Check if repo already exists
    if [ -d "$DOTFILES_DIR" ]; then
        log "Repository directory already exists at $DOTFILES_DIR"
        read -p "Do you want to overwrite it? (y/n): " overwrite
        
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            log "Setup aborted by user"
            exit 0
        fi
        
        rm -rf "$DOTFILES_DIR"
    fi
    
    # Create repo directory
    mkdir -p "$DOTFILES_DIR"
    
    # Ask for repository URL if not configured
    if [ -z "$DOTFILES_REPO" ]; then
        read -p "Enter your dotfiles repository URL (e.g., git@github.com:username/dotfiles.git): " DOTFILES_REPO
        
        if [ -z "$DOTFILES_REPO" ]; then
            log "Error: No repository URL provided"
            exit 1
        fi
        
        # Save to config
        mkdir -p "$(dirname "$CONFIG_FILE")"
        echo "DOTFILES_REPO=\"$DOTFILES_REPO\"" > "$CONFIG_FILE"
        echo "DOTFILES_DIR=\"$DOTFILES_DIR\"" >> "$CONFIG_FILE"
        echo "DOTFILES_BRANCH=\"$DOTFILES_BRANCH\"" >> "$CONFIG_FILE"
        echo "SYNC_FILES=(" >> "$CONFIG_FILE"
        for file in "${SYNC_FILES[@]}"; do
            echo "    \"$file\"" >> "$CONFIG_FILE"
        done
        echo ")" >> "$CONFIG_FILE"
        echo "SYNC_VSCODE=$SYNC_VSCODE" >> "$CONFIG_FILE"
        
        # Set appropriate permissions on config file
        chmod 600 "$CONFIG_FILE"
    fi
    
    # Initialize git repository
    cd "$DOTFILES_DIR"
    git init
    
    # Add remote
    git remote add origin "$DOTFILES_REPO"
    
    # Create README
    cat > "$DOTFILES_DIR/README.md" << EOF
# Dotfiles

My personal dotfiles, managed with a custom syncing script.

## Files Included

$(for file in "${SYNC_FILES[@]}"; do echo "- \`$file\`"; done)

## Setup

To restore these dotfiles, run:

\`\`\`bash
./sync_dotfiles.sh --restore
\`\`\`

## Automatic Backup

These dotfiles are automatically backed up using a custom script.
EOF

    # Create initial commit
    git add README.md
    git commit -m "Initial dotfiles setup"
    
    log "Repository set up successfully at $DOTFILES_DIR"
    log "Repository URL: $DOTFILES_REPO"
    
    # Ask if user wants to push
    read -p "Do you want to push the initial commit to the remote repository? (y/n): " push_now
    
    if [[ "$push_now" =~ ^[Yy]$ ]]; then
        # Test repository access before pushing
        if ! git ls-remote --exit-code "$DOTFILES_REPO" &>/dev/null; then
            log "Warning: Cannot access the remote repository"
            log "This may be due to SSH key configuration or repository permissions"
            read -p "Try pushing anyway? (y/n): " force_push
            
            if [[ ! "$force_push" =~ ^[Yy]$ ]]; then
                log "Push aborted. You can push manually later with: cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
                return
            fi
        fi
        
        git push -u origin "$DOTFILES_BRANCH"
        if [ $? -ne 0 ]; then
            log "Warning: Failed to push to remote repository"
            log "You can try again later with: cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
        else
            log "Initial commit pushed to remote repository"
        fi
    else
        log "You can push the initial commit later with: cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
    fi
    
    # Ask if user wants to backup now
    read -p "Do you want to backup your dotfiles now? (y/n): " backup_now
    
    if [[ "$backup_now" =~ ^[Yy]$ ]]; then
        backup_dotfiles
    fi
}

# Function to backup dotfiles
backup_dotfiles() {
    log "Backing up dotfiles..."
    
    check_repo_config
    
    # Check if repo directory exists
    if [ ! -d "$DOTFILES_DIR" ]; then
        log "Repository directory not found at $DOTFILES_DIR"
        read -p "Do you want to set up the repository now? (y/n): " setup_now
        
        if [[ "$setup_now" =~ ^[Yy]$ ]]; then
            setup_repo
            return
        else
            log "Backup aborted"
            exit 1
        fi
    fi
    
    # Ensure we're on the right branch
    cd "$DOTFILES_DIR"
    git fetch origin "$DOTFILES_BRANCH" || true
    git checkout "$DOTFILES_BRANCH" || git checkout -b "$DOTFILES_BRANCH"
    
    # Copy dotfiles
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$DOTFILES_DIR/"
            log "Backed up $file"
        else
            log "Warning: $HOME/$file not found, skipping"
        fi
    done
    
    # Copy VS Code settings if enabled
    if [ "$SYNC_VSCODE" = true ]; then
        # Determine which VS Code settings directory to use
        VSCODE_DIR=""
        if [ -d "$VSCODE_SETTINGS_DIR" ]; then
            VSCODE_DIR="$VSCODE_SETTINGS_DIR"
        elif [ -d "$VSCODE_SETTINGS_WIN_DIR" ]; then
            VSCODE_DIR="$VSCODE_SETTINGS_WIN_DIR"
        fi
        
        if [ -n "$VSCODE_DIR" ]; then
            mkdir -p "$DOTFILES_DIR/vscode"
            
            if [ -f "$VSCODE_DIR/settings.json" ]; then
                cp "$VSCODE_DIR/settings.json" "$DOTFILES_DIR/vscode/"
                log "Backed up VS Code settings.json"
            fi
            
            if [ -f "$VSCODE_DIR/keybindings.json" ]; then
                cp "$VSCODE_DIR/keybindings.json" "$DOTFILES_DIR/vscode/"
                log "Backed up VS Code keybindings.json"
            fi
            
            if [ -d "$VSCODE_DIR/snippets" ]; then
                mkdir -p "$DOTFILES_DIR/vscode/snippets"
                cp -r "$VSCODE_DIR/snippets/"* "$DOTFILES_DIR/vscode/snippets/"
                log "Backed up VS Code snippets"
            fi
        else
            log "Warning: VS Code settings directory not found, skipping"
        fi
    fi
    
    # Commit changes
    cd "$DOTFILES_DIR"
    git add .
    
    if git diff --staged --quiet; then
        log "No changes to commit"
    else
        git commit -m "Update dotfiles: $(date '+%Y-%m-%d %H:%M:%S')"
        log "Changes committed"
        
        # Push to remote
        git push origin "$DOTFILES_BRANCH"
        if [ $? -ne 0 ]; then
            log "Warning: Failed to push to remote repository"
            log "You can try again later with: cd $DOTFILES_DIR && git push origin $DOTFILES_BRANCH"
        else
            log "Changes pushed to remote repository"
        fi
    fi
    
    log "Backup completed successfully"
}

# Function to restore dotfiles
restore_dotfiles() {
    log "Restoring dotfiles..."
    
    check_repo_config
    
    # Clone repository if it doesn't exist
    if [ ! -d "$DOTFILES_DIR" ]; then
        log "Cloning repository..."
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR" || {
            log "Error: Failed to clone repository"
            exit 1
        }
    else
        # Pull latest changes
        cd "$DOTFILES_DIR"
        git fetch origin "$DOTFILES_BRANCH" || {
            log "Warning: Failed to fetch from remote repository"
        }
        git checkout "$DOTFILES_BRANCH" || {
            log "Error: Failed to checkout branch $DOTFILES_BRANCH"
            exit 1
        }
        git pull origin "$DOTFILES_BRANCH" || {
            log "Warning: Failed to pull from remote repository"
        }
    fi
    
    # Create backups of existing files
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date '+%Y%m%d%H%M%S')"
    mkdir -p "$BACKUP_DIR"
    
    # Restore dotfiles
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            # Backup existing file if it exists
            if [ -f "$HOME/$file" ]; then
                cp "$HOME/$file" "$BACKUP_DIR/"
                log "Backed up existing $file to $BACKUP_DIR/"
            fi
            
            # Copy from repository
            cp "$DOTFILES_DIR/$file" "$HOME/"
            log "Restored $file"
        else
            log "Warning: $file not found in repository, skipping"
        fi
    done
    
    # Restore VS Code settings if enabled
    if [ "$SYNC_VSCODE" = true ] && [ -d "$DOTFILES_DIR/vscode" ]; then
        # Determine which VS Code settings directory to use
        VSCODE_DIR=""
        if [ -d "$VSCODE_SETTINGS_DIR" ]; then
            VSCODE_DIR="$VSCODE_SETTINGS_DIR"
        elif [ -d "$VSCODE_SETTINGS_WIN_DIR" ]; then
            VSCODE_DIR="$VSCODE_SETTINGS_WIN_DIR"
        fi
        
        if [ -n "$VSCODE_DIR" ]; then
            mkdir -p "$VSCODE_DIR"
            
            if [ -f "$DOTFILES_DIR/vscode/settings.json" ]; then
                # Backup existing file if it exists
                if [ -f "$VSCODE_DIR/settings.json" ]; then
                    mkdir -p "$BACKUP_DIR/vscode"
                    cp "$VSCODE_DIR/settings.json" "$BACKUP_DIR/vscode/"
                    log "Backed up existing VS Code settings.json to $BACKUP_DIR/vscode/"
                fi
                
                cp "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_DIR/"
                log "Restored VS Code settings.json"
            fi
            
            if [ -f "$DOTFILES_DIR/vscode/keybindings.json" ]; then
                # Backup existing file if it exists
                if [ -f "$VSCODE_DIR/keybindings.json" ]; then
                    mkdir -p "$BACKUP_DIR/vscode"
                    cp "$VSCODE_DIR/keybindings.json" "$BACKUP_DIR/vscode/"
                    log "Backed up existing VS Code keybindings.json to $BACKUP_DIR/vscode/"
                fi
                
                cp "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_DIR/"
                log "Restored VS Code keybindings.json"
            fi
            
            if [ -d "$DOTFILES_DIR/vscode/snippets" ];    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "from sklearn.model_selection import train_test_split\n",
    "from sklearn.metrics import accuracy_score, classification_report, confusion_matrix\n",
    "\n",
    "# Set visualization style\n",
    "sns.set_style('whitegrid')\n",
    "plt.rcParams['figure.figsize'] = (12, 8)\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2.1 Load and Prepare Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Load processed data\n",
    "# Replace with your actual data loading code\n",
    "# df = pd.read_csv('../data/processed/processed_data.csv')\n",
    "\n",
    "# Define features and target\n",
    "# X = df.drop('target', axis=1)\n",
    "# y = df['target']\n",
    "\n",
    "# Split the data\n",
    "# X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2.2 Model Training"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Example model training code\n",
    "# from sklearn.ensemble import RandomForestClassifier\n",
    "# \n",
    "# model = RandomForestClassifier(n_estimators=100, random_state=42)\n",
    "# model.fit(X_train, y_train)\n",
    "# \n",
    "# y_pred = model.predict(X_test)"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 2.3 Model Evaluation"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Evaluate the model\n",
    "# print(f\"Accuracy: {accuracy_score(y_test, y_pred):.4f}\")\n",
    "# print(\"\\nClassification Report:\")\n",
    "# print(classification_report(y_test, y_pred))\n",
    "# \n",
    "# # Confusion Matrix\n",
    "# plt.figure(figsize=(8, 6))\n",
    "# sns.heatmap(confusion_matrix(y_test, y_pred), annot=True, fmt='d', cmap='Blues')\n",
    "# plt.xlabel('Predicted')\n",
    "# plt.ylabel('Actual')\n",
    "# plt.title('Confusion Matrix')\n",
    "# plt.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python ($PROJECT_NAME)",
   "language": "python",
   "name": "$PROJECT_NAME"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Create utility scripts
echo "🔧 Creating utility scripts..."

# Create data processing script
cat > "$PROJECT_DIR/scripts/data_processing.py" << EOF
#!/usr/bin/env python3
"""
Data processing script for $PROJECT_NAME.
This script handles data cleaning, preprocessing, and feature engineering.
"""

import numpy as np
import pandas as pd
import os
import argparse
from sklearn.preprocessing import StandardScaler
import logging

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_data(filepath):
    """Load data from a file."""
    logger.info(f"Loading data from {filepath}")
    # Add your data loading code here
    # Example: return pd.read_csv(filepath)
    return None

def preprocess_data(df):
    """Preprocess the data."""
    logger.info("Preprocessing data")
    # Add your preprocessing code here
    # Example: handling missing values, data type conversions, etc.
    return df

def extract_features(df):
    """Extract features from the data."""
    logger.info("Extracting features")
    # Add your feature extraction code here
    return df

def save_processed_data(df, output_path):
    """Save the processed data."""
    logger.info(f"Saving processed data to {output_path}")
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    # Save the data
    # Example: df.to_csv(output_path, index=False)

def main():
    parser = argparse.ArgumentParser(description='Process data for $PROJECT_NAME')
    parser.add_argument('--input', required=True, help='Path to input data file')
    parser.add_argument('--output', required=True, help='Path to save processed data')
    args = parser.parse_args()

    # Process the data
    df = load_data(args.input)
    if df is not None:
        df = preprocess_data(df)
        df = extract_features(df)
        save_processed_data(df, args.output)
        logger.info("Data processing completed")
    else:
        logger.error("Failed to load data")

if __name__ == "__main__":
    main()
EOF

# Create model training script
cat > "$PROJECT_DIR/scripts/train_model.py" << EOF
#!/usr/bin/env python3
"""
Model training script for $PROJECT_NAME.
This script handles model training, evaluation, and saving.
"""

import numpy as np
import pandas as pd
import os
import argparse
import pickle
import logging
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def load_data(filepath):
    """Load processed data."""
    logger.info(f"Loading data from {filepath}")
    # Add your data loading code here
    # Example: return pd.read_csv(filepath)
    return None

def train_model(X_train, y_train, model_type='rf'):
    """Train a model."""
    logger.info(f"Training {model_type} model")
    
    if model_type == 'rf':
        from sklearn.ensemble import RandomForestClassifier
        model = RandomForestClassifier(n_estimators=100, random_state=42)
    elif model_type == 'xgb':
        import xgboost as xgb
        model = xgb.XGBClassifier(n_estimators=100, random_state=42)
    else:
        logger.error(f"Unknown model type: {model_type}")
        return None
    
    model.fit(X_train, y_train)
    return model

def evaluate_model(model, X_test, y_test, output_dir):
    """Evaluate the model and save results."""
    logger.info("Evaluating model")
    
    # Make predictions
    y_pred = model.predict(X_test)
    
    # Calculate metrics
    accuracy = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred)
    
    # Log results
    logger.info(f"Accuracy: {accuracy:.4f}")
    logger.info(f"Classification Report:\n{report}")
    
    # Create output directory if it doesn't exist
    os.makedirs(output_dir, exist_ok=True)
    
    # Save metrics
    with open(os.path.join(output_dir, 'metrics.txt'), 'w') as f:
        f.write(f"Accuracy: {accuracy:.4f}\n\n")
        f.write(f"Classification Report:\n{report}\n")
    
    # Plot and save confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.xlabel('Predicted')
    plt.ylabel('Actual')
    plt.title('Confusion Matrix')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'confusion_matrix.png'))
    
    return accuracy

def save_model(model, filepath):
    """Save the trained model."""
    logger.info(f"Saving model to {filepath}")
    # Create the directory if it doesn't exist
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    # Save the model
    with open(filepath, 'wb') as f:
        pickle.dump(model, f)

def main():
    parser = argparse.ArgumentParser(description='Train model for $PROJECT_NAME')
    parser.add_argument('--data', required=True, help='Path to processed data')
    parser.add_argument('--model-dir', required=True, help='Directory to save model')
    parser.add_argument('--results-dir', required=True, help='Directory to save results')
    parser.add_argument('--model-type', default='rf', choices=['rf', 'xgb'], help='Type of model to train')
    args = parser.parse_args()

    # Load data
    df = load_data(args.data)
    
    if df is not None:
        # Assume the last column is the target
        X = df.iloc[:, :-1]
        y = df.iloc[:, -1]
        
        # Split the data
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
        
        # Train model
        model = train_model(X_train, y_train, args.model_type)
        
        if model is not None:
            # Evaluate model
            evaluate_model(model, X_test, y_test, args.results_dir)
            
            # Save model
            save_model(model, os.path.join(args.model_dir, f"{args.model_type}_model.pkl"))
            
            logger.info("Model training completed")
    else:
        logger.error("Failed to load data")

if __name__ == "__main__":
    main()
EOF

# Make scripts executable
chmod +x "$PROJECT_DIR/scripts/data_processing.py"
chmod +x "$PROJECT_DIR/scripts/train_model.py"

# Initialize git repository
echo "🔄 Initializing Git repository..."
git init
echo "venv/" > .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore
echo ".ipynb_checkpoints/" >> .gitignore
git add .
git commit -m "Initial project setup"

# Download starter dataset if requested
if [ "$DATASET_TYPE" != "none" ]; then
    echo "📥 Downloading $DATASET_TYPE dataset..."
    
    case "$DATASET_TYPE" in
        mnist)
            python -c "from tensorflow.keras.datasets import mnist; mnist.load_data()" || echo "⚠️ Warning: Failed to download MNIST dataset"
            echo "from tensorflow.keras.datasets import mnist" > "$PROJECT_DIR/scripts/load_mnist.py"
            echo "(X_train, y_train), (X_test, y_test) = mnist.load_data()" >> "$PROJECT_DIR/scripts/load_mnist.py"
            echo "print('MNIST dataset loaded successfully')" >> "$PROJECT_DIR/scripts/load_mnist.py"
            echo "print(f'Training data shape: {X_train.shape}')" >> "$PROJECT_DIR/scripts/load_mnist.py"
            echo "print(f'Test data shape: {X_test.shape}')" >> "$PROJECT_DIR/scripts/load_mnist.py"
            ;;
        cifar10)
            python -c "from tensorflow.keras.datasets import cifar10; cifar10.load_data()" || echo "⚠️ Warning: Failed to download CIFAR-10 dataset"
            echo "from tensorflow.keras.datasets import cifar10" > "$PROJECT_DIR/scripts/load_cifar10.py"
            echo "(X_train, y_train), (X_test, y_test) = cifar10.load_data()" >> "$PROJECT_DIR/scripts/load_cifar10.py"
            echo "print('CIFAR-10 dataset loaded successfully')" >> "$PROJECT_DIR/scripts/load_cifar10.py"
            echo "print(f'Training data shape: {X_train.shape}')" >> "$PROJECT_DIR/scripts/load_cifar10.py"
            echo "print(f'Test data shape: {X_test.shape}')" >> "$PROJECT_DIR/scripts/load_cifar10.py"
            ;;
        iris)
            echo "from sklearn.datasets import load_iris" > "$PROJECT_DIR/scripts/load_iris.py"
            echo "import pandas as pd" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "import os" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "iris = load_iris()" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "df = pd.DataFrame(data=iris.data, columns=iris.feature_names)" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "df['target'] = iris.target" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "os.makedirs('../data/raw', exist_ok=True)" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "df.to_csv('../data/raw/iris.csv', index=False)" >> "$PROJECT_DIR/scripts/load_iris.py"
            echo "print('Iris dataset saved to ../data/raw/iris.csv')" >> "$PROJECT_DIR/scripts/load_iris.py"
            python "$PROJECT_DIR/scripts/load_iris.py" || echo "⚠️ Warning: Failed to load Iris dataset"
            ;;
        boston)
            echo "from sklearn.datasets import load_boston" > "$PROJECT_DIR/scripts/load_boston.py"
            echo "import pandas as pd" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "import os" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "boston = load_boston()" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "df = pd.DataFrame(data=boston.data, columns=boston.feature_names)" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "df['target'] = boston.target" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "os.makedirs('../data/raw', exist_ok=True)" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "df.to_csv('../data/raw/boston.csv', index=False)" >> "$PROJECT_DIR/scripts/load_boston.py"
            echo "print('Boston dataset saved to ../data/raw/boston.csv')" >> "$PROJECT_DIR/scripts/load_boston.py"
            python "$PROJECT_DIR/scripts/load_boston.py" || echo "⚠️ Warning: Failed to load Boston dataset"
            ;;
        *)
            echo "Unknown dataset type: $DATASET_TYPE"
            ;;
    esac
fi

# Create a script to run Jupyter Lab
cat > "$PROJECT_DIR/run_jupyter.sh" << EOF
#!/bin/bash
# Activate virtual environment and start Jupyter Lab
source venv/bin/activate
jupyter lab
EOF
chmod +x "$PROJECT_DIR/run_jupyter.sh"

echo "✅ AI project '$PROJECT_NAME' created successfully!"
echo "📂 Project location: $PROJECT_DIR"
echo ""
echo "To get started:"
echo "  cd $PROJECT_DIR"
echo "  source venv/bin/activate"
echo "  ./run_jupyter.sh"

# Deactivate virtual environment
deactivate
EOL

    chmod +x "$SCRIPTS_DIR/productivity/create_ai_project.sh"
    
    return 0
}

create_ai_workspace() {
    info "Setting up AI Modeling Workspace Generator..."
    
    # Create the script if it doesn't exist
    if [ ! -f "$SCRIPTS_DIR/productivity/create_ai_project.sh" ]; then
        create_ai_workspace_script
    fi
    
    # Ask for project name
    read -p "Enter project name (e.g., sentiment-analysis): " project_name
    
    if [ -z "$project_name" ]; then
        error "Project name cannot be empty"
        read -p "Press Enter to return to the main menu..."
        show_menu
        return 1
    fi
    
    # Ask for dataset type
    echo "Select dataset type:"
    echo "1. None (default)"
    echo "2. MNIST (handwritten digits)"
    echo "3. CIFAR-10 (images)"
    echo "4. Iris (classification)"
    echo "5. Boston Housing (regression)"
    read -p "Enter your choice [1-5]: " dataset_choice
    
    case $dataset_choice in
        1) dataset_type="none" ;;
        2) dataset_type="mnist" ;;
        3) dataset_type="cifar10" ;;
        4) dataset_type="iris" ;;
        5) dataset_type="boston" ;;
        *) dataset_type="none" ;;
    esac
    
    # Run the script
    bash "$SCRIPTS_DIR/productivity/create_ai_project.sh" "$project_name" "$dataset_type"
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 4. Clean Slate Windows Configuration =======
clean_slate_config() {
    info "Creating Clean Slate Windows Configuration script..."
    
    mkdir -p "$SCRIPTS_DIR/productivity"
    
    cat > "$SCRIPTS_DIR/productivity/clean_slate_config.ps1" << 'EOL'
# Clean Slate Windows Configuration
# Run this with PowerShell as Administrator
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "🪄 Starting Clean Slate Windows Configuration..." -ForegroundColor Cyan

    # ======= Disable Hibernation =======
    Write-Host "💤 Disabling hibernation..." -ForegroundColor Yellow
    powercfg -h off

    # ======= Disable Telemetry =======
    Write-Host "🔒 Disabling telemetry..." -ForegroundColor Yellow
    $telemetryRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    If (!(Test-Path $telemetryRegPath)) {
        New-Item -Path $telemetryRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $telemetryRegPath -Name "AllowTelemetry" -Type DWord -Value 0

    # ======= Disable Notifications =======
    Write-Host "🔕 Disabling non-critical notifications..." -ForegroundColor Yellow
    $notificationsRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Notifications\Settings"
    If (!(Test-Path $notificationsRegPath)) {
        New-Item -Path $notificationsRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $notificationsRegPath -Name "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" -Type DWord -Value 0

    # ======= Disable OneDrive Auto-Start =======
    Write-Host "☁️ Disabling OneDrive auto-start..." -ForegroundColor Yellow
    $oneDriveRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Get-ItemProperty -Path $oneDriveRegPath -Name "OneDrive" -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $oneDriveRegPath -Name "OneDrive"
    }

    # ======= Enable Dark Mode =======
    Write-Host "🌙 Enabling dark mode..." -ForegroundColor Yellow
    $darkModeRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    If (!(Test-Path $darkModeRegPath)) {
        New-Item -Path $darkModeRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $darkModeRegPath -Name "AppsUseLightTheme" -Type DWord -Value 0
    Set-ItemProperty -Path $darkModeRegPath -Name "SystemUsesLightTheme" -Type DWord -Value 0

    # ======= Set Power Settings =======
    Write-Host "⚡ Setting power configuration..." -ForegroundColor Yellow
    # Balanced power scheme
    $powerScheme = "381b4222-f694-41f0-9685-ff5bb260df2e"
    powercfg /setactive $powerScheme
    # Never turn off display while plugged in
    powercfg /change monitor-timeout-ac 0
    # Never put computer to sleep while plugged in
    powercfg /change standby-timeout-ac 0

    # ======= Explorer Settings =======
    Write-Host "📂 Configuring File Explorer settings..." -ForegroundColor Yellow
    $explorerRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    If (!(Test-Path $explorerRegPath)) {
        New-Item -Path $explorerRegPath -Force | Out-Null
    }
    # Show file extensions
    Set-ItemProperty -Path $explorerRegPath -Name "HideFileExt" -Type DWord -Value 0
    # Show hidden files
    Set-ItemProperty -Path $explorerRegPath -Name "Hidden" -Type DWord -Value 1
    # Show full path in title bar
    Set-ItemProperty -Path $explorerRegPath -Name "ShowFullPathInTitleBar" -Type DWord -Value 1
    # Launch Explorer to This PC instead of Quick Access
    Set-ItemProperty -Path $explorerRegPath -Name "LaunchTo" -Type DWord -Value 1

    # ======= Install PowerToys =======
    Write-Host "🔧 Installing PowerToys (if not already installed)..." -ForegroundColor Yellow
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget not found. Please install PowerToys manually." -ForegroundColor Red
    }
    else {
        # Install PowerToys if not already installed
        $powerToysInstalled = winget list Microsoft.PowerToys
        if ($LASTEXITCODE -ne 0) {
            winget install Microsoft.PowerToys --accept-source-agreements --accept-package-agreements -s winget
        } else {
            Write-Host "PowerToys already installed." -ForegroundColor Green
        }
    }

    # ======= Create FancyZones Layout =======
    Write-Host "📱 Setting up FancyZones layout..." -ForegroundColor Yellow
    $fancyZonesConfigPath = "$env:LOCALAPPDATA\Microsoft\PowerToys\FancyZones"
    $fancyZonesSettingsPath = "$fancyZonesConfigPath\settings.json"

    # Check if PowerToys is installed and settings directory exists
    if (Test-Path "$fancyZonesConfigPath") {
        # Create a simple layout - you can customize this
        If (!(Test-Path "$fancyZonesConfigPath\layouts")) {
            New-Item -Path "$fancyZonesConfigPath\layouts" -ItemType Directory -Force | Out-Null
        }
        
        # Create a productivity layout JSON
        $layoutGuid = [guid]::NewGuid().ToString()
        $layoutPath = "$fancyZonesConfigPath\layouts\$layoutGuid-productivity.json"
        
        $productivityLayout = @{
            "type" = "grid"
            "showSpacing" = $true
            "spacing" = 5
            "zoneCount" = 3
            "sensitivityRadius" = 20
        } | ConvertTo-Json
        
        Set-Content -Path $layoutPath -Value $productivityLayout
        
        Write-Host "✅ FancyZones layout created! You can activate it in PowerToys." -ForegroundColor Green
    } else {
        Write-Host "PowerToys not found or not configured. Please run PowerToys first." -ForegroundColor Yellow
    }

    # ======= Restart Explorer =======
    Write-Host "🔄 Restarting Explorer to apply changes..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Process explorer

    Write-Host "✅ Clean Slate Windows Configuration Complete!" -ForegroundColor Green
    Write-Host "🚀 Your system has been optimized for development work!" -ForegroundColor Green
    Write-Host "🔍 Note: Some changes may require a system restart to take full effect." -ForegroundColor Yellow
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL

    success "Clean Slate Windows Configuration script created at $SCRIPTS_DIR/productivity/clean_slate_config.ps1"
    
    if [ "$PLATFORM" == "wsl" ]; then
        info "To run this script in Windows:"
        info "1. Open PowerShell as Administrator"
        info "2. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        info "3. Run: PowerShell.exe -ExecutionPolicy Bypass -File \"\\wsl.localhost\\Ubuntu\\home\\$USER\\scripts\\productivity\\clean_slate_config.ps1\""
    else
        info "You can transfer this script to a Windows machine and run it in PowerShell as administrator"
    fi
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 5. Downloads Organizer Script =======
create_downloads_organizer_script() {
    info "Creating Downloads Organizer script..."
    
    mkdir -p "$SCRIPTS_DIR/productivity"
    
    cat > "$SCRIPTS_DIR/productivity/organize_downloads.sh" << 'EOL'
#!/bin/bash
# Downloads Organizer Script
# Automatically organizes files in Downloads folder

set -e

# Configuration
CONFIG_FILE="$HOME/scripts/config/downloads_organizer.conf"
LOG_FILE="$HOME/scripts/logs/downloads_organizer.log"

# Default settings
if [ "$PLATFORM" == "wsl" ]; then
    DOWNLOADS_DIR="/mnt/c/Users/$USER/Downloads"
else
    DOWNLOADS_DIR="$HOME/Downloads"
fi
ORGANIZE_INSTALLERS=true
ORGANIZE_IMAGES=true
ORGANIZE_DOCUMENTS=true
ORGANIZE_ARCHIVES=true
DELETE_OLD=true
OLD_DAYS=30
TEMP_DIR="Temp"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

# Function to detect platform - WSL, Linux, or macOS
detect_platform() {
    if grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "linux"
    fi
}

PLATFORM=$(detect_platform)

# Check if Downloads directory exists and is accessible
if [ ! -d "$DOWNLOADS_DIR" ]; then
    log "Error: Downloads directory not found at $DOWNLOADS_DIR"
    
    if [ "$PLATFORM" == "wsl" ]; then
        # Try to get Windows username
        WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
        if [ -n "$WIN_USER" ] && [[ ! "$WIN_USER" == *"%" ]]; then
            POTENTIAL_PATH="/mnt/c/Users/$WIN_USER/Downloads"
            if [ -d "$POTENTIAL_PATH" ]; then
                log "Found Downloads directory at $POTENTIAL_PATH"
                log "Update your config file to use this path"
                DOWNLOADS_DIR="$POTENTIAL_PATH"
            else
                log "Error: Could not find Windows Downloads directory"
                exit 1
            fi
        else
            log "Error: Could not determine Windows username"
            exit 1
        fi
    else
        log "Error: Please check your Downloads directory path"
        exit 1
    fi
fi

log "Starting Downloads Organizer"
log "Downloads directory: $DOWNLOADS_DIR"

# Create organization folders if they don't exist
if [ "$ORGANIZE_INSTALLERS" = true ]; then
    mkdir -p "$DOWNLOADS_DIR/Installers"
    log "Created Installers directory"
fi

if [ "$ORGANIZE_IMAGES" = true ]; then
    mkdir -p "$DOWNLOADS_DIR/Images"
    log "Created Images directory"
fi

if [ "$ORGANIZE_DOCUMENTS" = true ]; then
    mkdir -p "$DOWNLOADS_DIR/Documents"
    log "Created Documents directory"
fi

if [ "$ORGANIZE_ARCHIVES" = true ]; then
    mkdir -p "$DOWNLOADS_DIR/Archives"
    log "Created Archives directory"
fi

if [ "$DELETE_OLD" = true ]; then
    mkdir -p "$DOWNLOADS_DIR/$TEMP_DIR"
    log "Created $TEMP_DIR directory"
fi

# Function to move files
move_files() {
    local pattern="$1"
    local destination="$2"
    local count=0
    
    find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name "$pattern" | while read file; do
        # Skip if file is in a subdirectory (this should never happen with -maxdepth 1)
        if [[ "$(dirname "$file")" != "$DOWNLOADS_DIR" ]            "mtxr.sqltools"
            "mtxr.sqltools-driver-pg"
            "bierner.markdown-preview-github-styles"
            "ritwickdey.liveserver"
        )
        
        for ext in "${EXTENSIONS[@]}"; do
            info "Installing extension: $ext"
            code --install-extension "$ext" || warning "Failed to install $ext"
        done
        
        success "VS Code extensions installation completed"
    else
        warning "VS Code not found. Skipping extensions installation."
    fi
    
    # Generate SSH key for GitHub if it doesn't exist
    info "Checking SSH key for GitHub..."
    if [ ! -f "$HOME_DIR/.ssh/id_ed25519" ]; then
        info "Generating SSH key for GitHub..."
        # Check if ssh-keygen exists
        if command -v ssh-keygen &> /dev/null; then
            # Prompt for email if not set
            read -p "Enter email for SSH key [$DEFAULT_EMAIL]: " ssh_email
            ssh_email=${ssh_email:-$DEFAULT_EMAIL}
            
            # Create .ssh directory if it doesn't exist
            mkdir -p "$HOME_DIR/.ssh"
            chmod 700 "$HOME_DIR/.ssh"
            
            # Generate key with no passphrase
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME_DIR/.ssh/id_ed25519" -N ""
            if [ $? -ne 0 ]; then
                error "Failed to generate SSH key"
            else
                # Start ssh-agent if it's not running
                eval "$(ssh-agent -s)"
                ssh-add "$HOME_DIR/.ssh/id_ed25519"
                
                echo "📎 Public key (copy this to GitHub SSH settings):"
                cat "$HOME_DIR/.ssh/id_ed25519.pub"
                success "SSH key generation completed"
            fi
        else
            warning "ssh-keygen not found. Skipping SSH key generation."
        fi
    else
        info "SSH key already exists at $HOME_DIR/.ssh/id_ed25519"
    fi
    
    # Create project directories
    info "Creating project directories..."
    mkdir -p "$PROJECTS_DIR"
    for project in "${PROJECTS[@]}"; do
        mkdir -p "$PROJECTS_DIR/$project"
    done
    
    mkdir -p "$HOME_DIR/Datasets" "$HOME_DIR/Resources/PDFs" "$HOME_DIR/Resources/Templates" 
    mkdir -p "$HOME_DIR/AI_Models/Checkpoints" "$HOME_DIR/AI_Models/FineTuned" 
    mkdir -p "$HOME_DIR/Uni/2025_T1" "$HOME_DIR/Uni/Assignments"
    success "Project directories creation completed"
    
    # Install LaTeX for academic papers
    info "Installing LaTeX for academic papers..."
    if command -v apt &> /dev/null; then
        sudo apt install -y texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra
        if [ $? -ne 0 ]; then
            warning "LaTeX installation had issues. You may need to install it manually."
        else
            success "LaTeX installation completed"
        fi
    else
        warning "apt not found. Skipping LaTeX installation."
    fi
    
    # R and RStudio for Statistics
    info "Installing R and RStudio for statistics..."
    
    # Check if R is already installed
    if ! command -v R &> /dev/null; then
        if command -v apt-key &> /dev/null && command -v add-apt-repository &> /dev/null; then
            # Add R repository
            sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 || warning "Failed to add R repository key"
            
            # Get distribution codename
            if command -v lsb_release &> /dev/null; then
                DISTRO=$(lsb_release -cs)
                sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu ${DISTRO}-cran40/" || warning "Failed to add R repository"
                
                # Install R
                sudo apt update
                if ! sudo apt install -y r-base r-base-dev; then
                    warning "R installation failed"
                else
                    success "R installed successfully"
                fi
            else
                warning "lsb_release not found. Skipping R installation."
            fi
        else
            warning "apt-key or add-apt-repository not found. Skipping R installation."
        fi
    else
        info "R is already installed"
    fi
    
    # Install RStudio
    if [ "$PLATFORM" == "wsl" ] || [ "$PLATFORM" == "linux" ]; then
        if ! command -v rstudio &> /dev/null; then
            info "Installing RStudio..."
            RSTUDIO_DEB="rstudio-2023.06.0-421-amd64.deb"
            
            if retry 3 wget https://download1.rstudio.org/electron/focal/amd64/${RSTUDIO_DEB}; then
                if sudo dpkg -i ${RSTUDIO_DEB}; then
                    success "RStudio installed successfully"
                else
                    # Try to fix dependencies
                    sudo apt install -f -y
                    if sudo dpkg -i ${RSTUDIO_DEB}; then
                        success "RStudio installed successfully after fixing dependencies"
                    else
                        warning "RStudio installation failed"
                    fi
                fi
                # Clean up
                rm -f ${RSTUDIO_DEB}
            else
                warning "Failed to download RStudio"
            fi
        else
            info "RStudio is already installed"
        fi
    else
        warning "Skipping RStudio installation on macOS. Please install it manually."
    fi
    
    # API development tools
    info "Installing API development tools..."
    # Install Postman if on Linux and snap is available
    if [ "$PLATFORM" == "linux" ] && command -v snap &> /dev/null; then
        if ! command -v postman &> /dev/null; then
            info "Installing Postman via snap..."
            sudo snap install postman
            if [ $? -ne 0 ]; then
                warning "Postman installation failed"
            else
                success "Postman installed successfully"
            fi
        else
            info "Postman is already installed"
        fi
    elif [ "$PLATFORM" == "wsl" ]; then
        info "Skipping Postman installation on WSL. Please install it directly in Windows."
    else
        warning "Snap not found or not on Linux. Skipping Postman installation."
    fi
    
    # Setup aliases
    info "Setting up useful aliases..."
    # Backup existing .bash_aliases if it exists
    if [ -f "$HOME_DIR/.bash_aliases" ]; then
        cp "$HOME_DIR/.bash_aliases" "$HOME_DIR/.bash_aliases.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    cat > "$HOME_DIR/.bash_aliases" << 'EOL'
# Development shortcuts
alias vyn="cd ~/Projects/vynlox-ai"
alias market="cd ~/Projects/vynlox-marketing"
alias docs="cd ~/Projects/vynlox-docs"
alias exp="cd ~/Projects/experiments"
alias web="cd ~/Projects/web-projects"
alias uni="cd ~/Uni"

# Utility shortcuts
alias ll="ls -la"
alias la="ls -A"
alias l="ls -CF"
alias cl="clear"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Docker shortcuts
alias dps="docker ps"
alias dcu="docker-compose up -d"
alias dcd="docker-compose down"
alias dclogs="docker-compose logs -f"

# Python shortcuts
alias py="python3"
alias pyvenv="python3 -m venv venv"
alias activate="source venv/bin/activate"
alias jlab="jupyter lab"

# Git shortcuts
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"
alias gl="git pull"
alias glog="git log --oneline --graph --decorate"

# Server shortcuts
alias serve="python3 -m http.server"
alias servephp="php -S localhost:8000"

# Custom scripts
alias backup="bash ~/scripts/backup/backup_projects.sh"
alias aiproj="bash ~/scripts/productivity/create_ai_project.sh"
alias organize="bash ~/scripts/productivity/organize_downloads.sh"
alias task="bash ~/scripts/academic/task_manager.sh"
EOL
    success "Aliases setup completed"
    
    # Create a welcome message
    info "Creating welcome message..."
    cat > "$HOME_DIR/.welcome_message.sh" << 'EOL'
#!/bin/bash
echo -e "\n\033[1;34m====================================\033[0m"
echo -e "\033[1;32m👋 Welcome back, ${USER}!\033[0m"
echo -e "\033[1;34m====================================\033[0m"
echo -e "\033[1;36m$(date '+%A, %B %d %Y, %I:%M %p')\033[0m"

# Show system info if neofetch is available
if command -v neofetch &> /dev/null; then
    echo -e "\033[1;33m$(neofetch --off)\033[0m"
fi

# Check for pending updates if apt is available
if command -v apt &> /dev/null; then
    echo -e "\033[1;34m====================================\033[0m"
    echo -e "\033[1;33m📦 System Updates:\033[0m"
    if sudo apt update -qq &> /dev/null; then
        updates=$(apt list --upgradable 2>/dev/null | wc -l)
        security_updates=$(apt list --upgradable 2>/dev/null | grep -i security | wc -l)
        ((updates--)) # Adjust for header line
        
        if [ $updates -gt 0 ]; then
            echo -e "\033[1;31m$updates updates available ($security_updates security updates)\033[0m"
            echo -e "\033[0;33mRun 'sudo apt upgrade' to install them\033[0m"
        else
            echo -e "\033[1;32mSystem is up to date!\033[0m"
        fi
    else
        echo -e "\033[1;31mCouldn't check for updates. Network issue?\033[0m"
    fi
fi

# Show last backup date
if [ -f ~/last_backup.txt ]; then
    last_backup=$(cat ~/last_backup.txt)
    echo -e "\033[1;34m====================================\033[0m"
    echo -e "\033[1;33m💾 Last backup:\033[0m \033[1;36m$last_backup\033[0m"
fi

# Show pending academic tasks
if [ -f ~/scripts/academic/tasks.csv ]; then
    echo -e "\033[1;34m====================================\033[0m"
    echo -e "\033[1;33m📚 Academic Tasks:\033[0m"
    
    # Display tasks with due dates in the next 7 days
    today=$(date +%s)
    while IFS=, read -r name due_date description status || [ -n "$name" ]; do
        # Skip header and completed tasks
        if [ "$name" = "Name" ] || [ "$status" = "Completed" ]; then
            continue
        fi
        
        # Convert due_date to seconds since epoch
        due_date_s=$(date -d "$due_date" +%s 2>/dev/null || date -j -f "%Y-%m-%d" "$due_date" +%s 2>/dev/null)
        if [ $? -ne 0 ]; then
            continue
        fi
        
        # Calculate days until due
        days_until=$(( (due_date_s - today) / 86400 ))
        
        if [ $days_until -le 7 ] && [ $days_until -ge 0 ]; then
            if [ $days_until -eq 0 ]; then
                echo -e "\033[1;31m⚠️  DUE TODAY: $name\033[0m"
            elif [ $days_until -eq 1 ]; then
                echo -e "\033[1;31m⚠️  DUE TOMORROW: $name\033[0m"
            else
                echo -e "\033[1;33m⏰ Due in $days_until days: $name\033[0m"
            fi
        fi
    done < ~/scripts/academic/tasks.csv 2>/dev/null
fi

# Show disk usage
echo -e "\033[1;34m====================================\033[0m"
echo -e "\033[1;33m💽 Disk Usage:\033[0m"
if command -v df &> /dev/null; then
    df -h | grep -E 'Filesystem|/dev/sd|/dev/nvme' 2>/dev/null || df -h | head -2
fi

echo -e "\033[1;34m====================================\033[0m"
echo -e "\033[1;35m🚀 Have a productive day!\033[0m"
echo -e "\033[1;34m====================================\033[0m\n"
EOL

    chmod +x "$HOME_DIR/.welcome_message.sh"
    
    # Add to .zshrc to show welcome message at startup if not already present
    if [ -f "$HOME_DIR/.zshrc" ]; then
        if ! grep -q "$HOME_DIR/.welcome_message.sh" "$HOME_DIR/.zshrc"; then
            echo "# Show welcome message" >> "$HOME_DIR/.zshrc"
            echo "$HOME_DIR/.welcome_message.sh" >> "$HOME_DIR/.zshrc"
        fi
    fi
    
    # Copy all utility scripts
    info "Creating utility scripts..."
    
    # Create backup script
    create_backup_scripts
    
    # Create AI workspace script
    create_ai_workspace_script
    
    # Create downloads organizer script
    create_downloads_organizer_script
    
    # Create academic tracker script
    create_academic_tracker_script
    
    # Create dotfiles syncer script
    create_dotfiles_syncer_script
    
    success "Dev environment setup complete!"
    echo ""
    info "Restart your terminal or run 'source ~/.zshrc' to activate all changes."
    
    return 0
}

# ======= 2. Browser & Privacy Optimizer =======
setup_browser_privacy() {
    info "Setting up Browser & Privacy Optimizer..."
    
    # Create the script
    mkdir -p "$SCRIPTS_DIR/productivity"
    
    cat > "$SCRIPTS_DIR/productivity/browser_privacy_setup.ps1" << 'EOL'
# Browser & Privacy Optimizer for Windows
# Run this with PowerShell as Administrator
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

try {
    Write-Host "🌐 Starting Browser & Privacy Optimization..." -ForegroundColor Cyan

    # ======= Install Browsers =======
    Write-Host "⬇️ Installing Brave Browser..." -ForegroundColor Yellow
    winget install BraveSoftware.BraveBrowser --accept-source-agreements --accept-package-agreements -s winget

    Write-Host "⬇️ Installing Google Chrome..." -ForegroundColor Yellow
    winget install Google.Chrome --accept-source-agreements --accept-package-agreements -s winget

    # ======= Disable Microsoft Edge Bloat =======
    Write-Host "🔧 Disabling Microsoft Edge features..." -ForegroundColor Yellow

    # Disable Edge startup boost
    $edgeRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    If (!(Test-Path $edgeRegPath)) {
        New-Item -Path $edgeRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $edgeRegPath -Name "StartupBoostEnabled" -Type DWord -Value 0

    # Disable Edge preloading
    $edgeRegPath2 = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"
    If (!(Test-Path $edgeRegPath2)) {
        New-Item -Path $edgeRegPath2 -Force | Out-Null
    }
    Set-ItemProperty -Path $edgeRegPath2 -Name "AllowPrelaunch" -Type DWord -Value 0

    # ======= Set Default Browser =======
    Write-Host "🔄 Setting Brave as default browser..." -ForegroundColor Yellow
    # This requires user action, but we can open the settings page
    Start-Process "ms-settings:defaultapps"

    # ======= Set Default Search Engine =======
    Write-Host "🔍 Setting up Google as default search engine..." -ForegroundColor Yellow
    Write-Host "Please manually set Google as your default search engine in Brave after installation." -ForegroundColor Yellow

    # ======= Install Browser Extensions =======
    Write-Host "✨ Opening Brave to install extensions..." -ForegroundColor Yellow
    # We'll provide links to the extensions since we can't automate installation
    $extensionUrls = @(
        "https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm",
        "https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh",
        "https://chrome.google.com/webstore/detail/json-formatter/bcjindcccaagfpapjjmafapmmgkkhgoa",
        "https://chrome.google.com/webstore/detail/wappalyzer-technology-pro/gppongmhjkpfnbhagpmjfkannfbllamg",
        "https://chrome.google.com/webstore/detail/grammarly-grammar-checker/kbfnbcaeplbcioakkpcpgfkobkghlhen"
    )

    # Wait for Brave to be installed before opening extension pages
    Start-Sleep -Seconds 5

    foreach ($url in $extensionUrls) {
        if (Test-Path "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe") {
            Start-Process "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" $url
        } else {
            Start-Process "brave.exe" $url
        }
        Start-Sleep -Seconds 1
    }

    # ======= Privacy Settings =======
    Write-Host "🔒 Configuring Windows privacy settings..." -ForegroundColor Yellow

    # Disable telemetry
    $telemetryRegPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    If (!(Test-Path $telemetryRegPath)) {
        New-Item -Path $telemetryRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $telemetryRegPath -Name "AllowTelemetry" -Type DWord -Value 0

    # Disable advertising ID
    $advertisingRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
    If (!(Test-Path $advertisingRegPath)) {
        New-Item -Path $advertisingRegPath -Force | Out-Null
    }
    Set-ItemProperty -Path $advertisingRegPath -Name "Enabled" -Type DWord -Value 0

    # Disable app launch tracking
    $appLaunchRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $appLaunchRegPath -Name "Start_TrackProgs" -Type DWord -Value 0

    # Disable suggestions
    $suggestionsRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $suggestionsRegPath -Name "SubscribedContent-338388Enabled" -Type DWord -Value 0

    # ======= Download O&O ShutUp10 =======
    Write-Host "⬇️ Downloading O&O ShutUp10++..." -ForegroundColor Yellow
    $shutupUrl = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
    $shutupPath = "$env:TEMP\OOSU10.exe"
    
    try {
        Invoke-WebRequest -Uri $shutupUrl -OutFile $shutupPath
        
        # Run O&O ShutUp10 with recommended settings
        Write-Host "🔧 Running O&O ShutUp10++ with recommended settings..." -ForegroundColor Yellow
        Start-Process -FilePath $shutupPath
    }
    catch {
        Write-Host "❌ Failed to download O&O ShutUp10++: $_" -ForegroundColor Red
        Write-Host "You can download it manually from: https://www.oo-software.com/en/shutup10" -ForegroundColor Yellow
    }

    Write-Host "✅ Browser & Privacy Optimization Complete!" -ForegroundColor Green
    Write-Host "NOTE: Some settings require manual confirmation. Please follow any prompts." -ForegroundColor Yellow
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL

    success "Browser & Privacy Optimizer script created at $SCRIPTS_DIR/productivity/browser_privacy_setup.ps1"
    
    if [ "$PLATFORM" == "wsl" ]; then
        info "To run this script in Windows:"
        info "1. Open PowerShell as Administrator"
        info "2. Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        info "3. Run: PowerShell.exe -ExecutionPolicy Bypass -File \"\\wsl.localhost\\Ubuntu\\home\\$USER\\scripts\\productivity\\browser_privacy_setup.ps1\""
    else
        info "You can transfer this script to a Windows machine and run it in PowerShell as administrator"
    fi
    
    read -p "Press Enter to return to the main menu..."
    show_menu
}

# ======= 3. AI Modeling Workspace Generator =======
create_ai_workspace_script() {
    info "Creating AI Modeling Workspace Generator script..."
    
    mkdir -p "$SCRIPTS_DIR/productivity"
    
    cat > "$SCRIPTS_DIR/productivity/create_ai_project.sh" << 'EOL'
#!/bin/bash
# AI Modeling Workspace Generator
# Usage: ./create_ai_project.sh <project_name> [dataset_type]

set -e

# Configuration
SCRIPTS_DIR="$HOME/scripts"
CONFIG_FILE="$SCRIPTS_DIR/config/ai_projects.conf"
PROJECTS_DIR="$HOME/Projects"
DEFAULT_PACKAGES="numpy pandas matplotlib seaborn scikit-learn tensorflow torch"

# Load configuration if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Display help
show_help() {
    echo "AI Modeling Workspace Generator"
    echo "Usage: $(basename $0) <project_name> [dataset_type]"
    echo ""
    echo "Options:"
    echo "  <project_name>   Name of the project (required)"
    echo "  [dataset_type]   Type of starter dataset to download (optional)"
    echo "                   Options: mnist, cifar10, iris, boston, none (default)"
    echo ""
    echo "Examples:"
    echo "  $(basename $0) sentiment-analysis"
    echo "  $(basename $0) image-classifier cifar10"
    exit 0
}

# Validate arguments
if [ $# -lt 1 ]; then
    echo "Error: Project name is required"
    show_help
fi

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
fi

PROJECT_NAME="$1"
DATASET_TYPE="${2:-none}"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

# Check if project already exists
if [ -d "$PROJECT_DIR" ]; then
    echo "Error: Project '$PROJECT_NAME' already exists"
    exit 1
fi

echo "🧠 Creating new AI project: $PROJECT_NAME"

# Create project directory structure
mkdir -p "$PROJECT_DIR"/{notebooks,scripts,models,data/{raw,processed,external},results/{figures,tables},docs}

# Create README file
cat > "$PROJECT_DIR/README.md" << EOF
# $PROJECT_NAME

## Project Overview
[Brief description of the project]

## Directory Structure
- \`notebooks/\`: Jupyter notebooks for exploration and analysis
- \`scripts/\`: Python scripts for data processing and modeling
- \`models/\`: Saved model files
- \`data/\`: Data files
  - \`raw/\`: Original, immutable data
  - \`processed/\`: Cleaned and processed data
  - \`external/\`: Data from external sources
- \`results/\`: Output from models
  - \`figures/\`: Generated figures and visualizations
  - \`tables/\`: Generated tables
- \`docs/\`: Documentation

## Setup
\`\`\`bash
# Activate the environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
\`\`\`

## Dataset
[Description of the dataset]

## Models
[Description of models used]

## Results
[Summary of results]
EOF

# Verify Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed or not in PATH"
    echo "Please install Python 3 before continuing"
    exit 1
fi

# Create virtual environment
echo "🔧 Setting up Python virtual environment..."
cd "$PROJECT_DIR"
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to create virtual environment"
    echo "Please install python3-venv package and try again"
    exit 1
fi

# Activate virtual environment
source venv/bin/activate
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to activate virtual environment"
    exit 1
fi

# Create requirements.txt
echo "📦 Creating requirements file..."
cat > "$PROJECT_DIR/requirements.txt" << EOF
# Data processing
numpy
pandas
scikit-learn

# Visualization
matplotlib
seaborn
plotly

# Deep learning
tensorflow
torch
torchvision

# Jupyter
jupyterlab
notebook
ipywidgets

# ML libraries
xgboost
lightgbm

# Utilities
tqdm
pyyaml
EOF

# Install basic requirements
echo "⬇️ Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt || echo "⚠️ Warning: Some packages failed to install. You might need to install them manually."

# Set up Jupyter kernel
echo "🔮 Setting up Jupyter kernel..."
python -m ipykernel install --user --name="$PROJECT_NAME" --display-name="Python ($PROJECT_NAME)" || echo "⚠️ Warning: Failed to install Jupyter kernel"

# Create starter notebooks
echo "📓 Creating starter notebooks..."

# Data exploration notebook
cat > "$PROJECT_DIR/notebooks/01_data_exploration.ipynb" << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 1. Data Exploration\n",
    "\n",
    "This notebook explores the dataset and provides initial insights."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import libraries\n",
    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "# Set visualization style\n",
    "sns.set_style('whitegrid')\n",
    "plt.rcParams['figure.figsize'] = (12, 8)\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 1.1 Load the Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Load data\n",
    "# Replace with your actual data loading code\n",
    "# df = pd.read_csv('../data/raw/your_dataset.csv')\n",
    "\n",
    "# Display the first few rows\n",
    "# df.head()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 1.2 Data Overview"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Basic info\n",
    "# df.info()\n",
    "\n",
    "# Summary statistics\n",
    "# df.describe()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## 1.3 Check for Missing Values"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Check for missing values\n",
    "# df.isnull().sum()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python ($PROJECT_NAME)",
   "language": "python",
   "name": "$PROJECT_NAME"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.10"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

# Model development notebook
cat > "$PROJECT_DIR/notebooks/02_model_development.ipynb" << EOF
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# 2. Model Development\n",
    "\n",
    "This notebook builds and evaluates different models."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Import libraries\n",
    "import numpy as np\n",
    "import pandas as pd\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n#!/bin/bash