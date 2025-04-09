#!/bin/bash
# Development Environment Setup Module
# Part of the DEV-SETUP framework
# License: MIT

# Get configuration file path from arguments
CONFIG_FILE="$1"

# Load configuration if provided
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found or not specified"
    exit 1
fi

# Setup logging
LOG_FILE="$HOME/.dev-setup/logs/dev_environment_$(date +%Y-%m-%d_%H-%M-%S).log"
touch "$LOG_FILE"

# Helper functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "\e[32m✅ $1\e[0m"
    log "[SUCCESS] $1"
}

info() {
    echo -e "\e[34mℹ️ $1\e[0m"
    log "[INFO] $1"
}

warning() {
    echo -e "\e[33m⚠️ $1\e[0m"
    log "[WARNING] $1"
}

error() {
    echo -e "\e[31m❌ $1\e[0m"
    log "[ERROR] $1"
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

# Function to install a package if it's missing
install_if_missing() {
    if ! command -v $1 &> /dev/null; then
        info "Installing $1..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install $1
        else
            sudo apt install -y $1
        fi
        
        if [ $? -ne 0 ]; then
            warning "Failed to install $1. You may need to install it manually."
            return 1
        fi
        return 0
    else
        info "$1 already installed"
        return 0
    fi
}

# Function to setup language environments
setup_languages() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m    🔧 PROGRAMMING LANGUAGES SETUP      \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""

    # Ask which languages to install
    echo "Select programming languages to install:"
    echo "1. Node.js (via NVM)"
    echo "2. Python and data science packages"
    echo "3. Go"
    echo "4. Rust"
    echo "5. Java"
    echo "6. All of the above"
    echo "0. Skip language installation"
    echo ""
    read -p "Enter your choices (comma-separated, e.g., 1,2,3): " language_choices
    
    # If user selects all
    if [[ "$language_choices" == "6" ]]; then
        language_choices="1,2,3,4,5"
    fi
    
    # Skip if user selects 0
    if [[ "$language_choices" == "0" ]]; then
        return 0
    fi
    
    # Convert comma-separated string to array
    IFS=',' read -ra selected_languages <<< "$language_choices"
    
    for lang in "${selected_languages[@]}"; do
        case $lang in
            1) install_nodejs ;;
            2) install_python ;;
            3) install_go ;;
            4) install_rust ;;
            5) install_java ;;
            *) warning "Invalid language option: $lang. Skipping." ;;
        esac
    done
    
    success "Language installation completed"
}

# Function to install Node.js via NVM
install_nodejs() {
    info "Installing Node.js LTS with NVM..."
    if [ ! -d "$HOME/.nvm" ]; then
        retry 3 curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        if [ $? -ne 0 ]; then
            error "Failed to install NVM"
            return 1
        else
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            
            # Check if nvm command is available
            if command -v nvm &> /dev/null; then
                retry 3 nvm install --lts
                if [ $? -ne 0 ]; then
                    warning "Failed to install Node.js LTS"
                    return 1
                else
                    nvm use --lts
                    success "NVM and Node.js LTS installed and configured"
                fi
            else
                warning "NVM installation succeeded but command not found. You may need to restart your terminal."
                return 1
            fi
        fi
    else
        info "NVM already installed, updating..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        if command -v nvm &> /dev/null; then
            retry 3 nvm install --lts
            if [ $? -ne 0 ]; then
                warning "Failed to update Node.js LTS"
                return 1
            else
                nvm use --lts
                success "Node.js updated to latest LTS version"
            fi
        else
            warning "NVM installation exists but command not found. Try restarting your terminal."
            return 1
        fi
    fi
    
    # Ask if user wants to install global NPM packages
    read -p "Do you want to install common global NPM packages? (y/n) [y]: " install_npm
    install_npm=${install_npm:-"y"}
    
    if [[ "$install_npm" =~ ^[Yy]$ ]]; then
        info "Installing global NPM packages..."
        
        NPM_PACKAGES=(
            "pnpm"
            "typescript"
            "ts-node"
            "eslint"
            "prettier"
        )
        
        for package in "${NPM_PACKAGES[@]}"; do
            info "Installing $package..."
            retry 3 npm install -g $package
            if [ $? -ne 0 ]; then
                warning "Failed to install $package"
            fi
        done
        
        # Ask if user wants to install framework CLIs
        read -p "Do you want to install framework CLIs (React, Next.js, etc.)? (y/n) [y]: " install_frameworks
        install_frameworks=${install_frameworks:-"y"}
        
        if [[ "$install_frameworks" =~ ^[Yy]$ ]]; then
            FRAMEWORK_PACKAGES=(
                "create-react-app"
                "next"
                "@nestjs/cli"
                "create-t3-app"
                "vite"
            )
            
            for package in "${FRAMEWORK_PACKAGES[@]}"; do
                info "Installing $package..."
                retry 3 npm install -g $package
                if [ $? -ne 0 ]; then
                    warning "Failed to install $package"
                fi
            done
        fi
        
        success "Global NPM packages installation completed"
    fi
    
    return 0
}

# Function to install Python and data science packages
install_python() {
    info "Setting up Python environment..."
    
    # Ensure Python is installed
    install_if_missing python3
    install_if_missing pip3
    
    if command -v pip3 &> /dev/null; then
        retry 3 pip3 install --user --upgrade pip
        if [ $? -ne 0 ]; then
            warning "Failed to upgrade pip"
        fi
        
        # Ask which Python package types to install
        echo "Select Python package categories to install:"
        echo "1. Basic development tools (virtualenv, pipenv, etc.)"
        echo "2. Data science (numpy, pandas, jupyter, etc.)"
        echo "3. Machine learning (scikit-learn, tensorflow, pytorch, etc.)"
        echo "4. Web development (Django, Flask, FastAPI, etc.)"
        echo "5. All of the above"
        echo "0. Skip Python packages installation"
        echo ""
        read -p "Enter your choices (comma-separated, e.g., 1,2,3): " python_choices
        
        # If user selects all
        if [[ "$python_choices" == "5" ]]; then
            python_choices="1,2,3,4"
        fi
        
        # Skip if user selects 0
        if [[ "$python_choices" == "0" ]]; then
            return 0
        fi
        
        # Convert comma-separated string to array
        IFS=',' read -ra selected_python <<< "$python_choices"
        
        for choice in "${selected_python[@]}"; do
            case $choice in
                1)
                    # Basic Python tools
                    PYTHON_BASIC=(
                        "virtualenv"
                        "pipenv"
                        "poetry"
                        "black"
                        "flake8"
                        "mypy"
                        "pytest"
                    )
                    
                    for package in "${PYTHON_BASIC[@]}"; do
                        info "Installing $package..."
                        retry 3 pip3 install --user $package
                        if [ $? -ne 0 ]; then
                            warning "Failed to install $package"
                        fi
                    done
                    ;;
                2)
                    # Data science packages
                    PYTHON_DATA=(
                        "numpy"
                        "pandas"
                        "matplotlib"
                        "seaborn"
                        "plotly"
                        "jupyterlab"
                        "notebook"
                        "ipywidgets"
                    )
                    
                    for package in "${PYTHON_DATA[@]}"; do
                        info "Installing $package..."
                        retry 3 pip3 install --user $package
                        if [ $? -ne 0 ]; then
                            warning "Failed to install $package"
                        fi
                    done
                    ;;
                3)
                    # ML frameworks
                    info "Installing scikit-learn..."
                    retry 3 pip3 install --user scikit-learn
                    
                    read -p "Do you want to install TensorFlow? (y/n) [y]: " install_tf
                    install_tf=${install_tf:-"y"}
                    
                    if [[ "$install_tf" =~ ^[Yy]$ ]]; then
                        info "Installing TensorFlow..."
                        retry 3 pip3 install --user tensorflow
                        if [ $? -ne 0 ]; then
                            warning "Failed to install TensorFlow. You may need to install it manually with specific options for your system."
                        fi
                    fi
                    
                    read -p "Do you want to install PyTorch? (y/n) [y]: " install_pytorch
                    install_pytorch=${install_pytorch:-"y"}
                    
                    if [[ "$install_pytorch" =~ ^[Yy]$ ]]; then
                        info "Installing PyTorch..."
                        retry 3 pip3 install --user torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
                        if [ $? -ne 0 ]; then
                            warning "Failed to install PyTorch. You may need to install it manually with specific options for your system."
                        fi
                    fi
                    
                    # ML tools
                    PYTHON_ML_TOOLS=(
                        "xgboost"
                        "lightgbm"
                        "transformers"
                        "huggingface_hub"
                    )
                    
                    for package in "${PYTHON_ML_TOOLS[@]}"; do
                        info "Installing $package..."
                        retry 3 pip3 install --user $package
                        if [ $? -ne 0 ]; then
                            warning "Failed to install $package"
                        fi
                    done
                    ;;
                4)
                    # Web development
                    PYTHON_WEB=(
                        "django"
                        "flask"
                        "fastapi"
                        "uvicorn"
                        "requests"
                        "beautifulsoup4"
                    )
                    
                    for package in "${PYTHON_WEB[@]}"; do
                        info "Installing $package..."
                        retry 3 pip3 install --user $package
                        if [ $? -ne 0 ]; then
                            warning "Failed to install $package"
                        fi
                    done
                    ;;
                *)
                    warning "Invalid Python package category: $choice. Skipping."
                    ;;
            esac
        done
        
        success "Python packages installation completed"
    else
        error "Python pip not found. Skipping Python packages installation."
        return 1
    fi
    
    return 0
}

# Function to install Go
install_go() {
    info "Installing Go..."
    
    if command -v go &> /dev/null; then
        current_version=$(go version | awk '{print $3}' | sed 's/go//')
        info "Go version $current_version is already installed"
        
        read -p "Do you want to update/reinstall Go? (y/n) [n]: " update_go
        update_go=${update_go:-"n"}
        
        if [[ ! "$update_go" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    if [ "$PLATFORM" == "macos" ]; then
        brew install go
    else
        # Get the latest Go version
        GO_VERSION=$(curl -s https://golang.org/VERSION?m=text | head -n 1)
        
        # Download and install Go
        wget -q https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz -O go.tar.gz
        if [ $? -ne 0 ]; then
            error "Failed to download Go"
            return 1
        fi
        
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf go.tar.gz
        rm go.tar.gz
        
        # Add Go to PATH if not already there
        if ! grep -q 'export PATH=$PATH:/usr/local/go/bin' ~/.profile; then
            echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
            echo 'export PATH=$PATH:$HOME/go/bin' >> ~/.profile
        fi
        
        # Set GOPATH
        if ! grep -q 'export GOPATH=$HOME/go' ~/.profile; then
            echo 'export GOPATH=$HOME/go' >> ~/.profile
        fi
        
        # Add to current session
        export PATH=$PATH:/usr/local/go/bin
        export PATH=$PATH:$HOME/go/bin
        export GOPATH=$HOME/go
    fi
    
    # Verify installation
    if command -v go &> /dev/null; then
        success "Go installed successfully: $(go version)"
    else
        warning "Go installation completed, but 'go' command not found. You may need to restart your terminal or source your profile."
    fi
    
    return 0
}

# Function to install Rust
install_rust() {
    info "Installing Rust..."
    
    if command -v rustc &> /dev/null; then
        current_version=$(rustc --version | awk '{print $2}')
        info "Rust version $current_version is already installed"
        
        read -p "Do you want to update Rust? (y/n) [y]: " update_rust
        update_rust=${update_rust:-"y"}
        
        if [[ "$update_rust" =~ ^[Yy]$ ]]; then
            info "Updating Rust..."
            rustup update
            success "Rust updated to: $(rustc --version)"
        fi
        
        return 0
    fi
    
    # Install Rust using rustup
    info "Installing Rust using rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    if [ $? -ne 0 ]; then
        error "Failed to install Rust"
        return 1
    fi
    
    # Add Rust to PATH for current session
    source "$HOME/.cargo/env"
    
    # Verify installation
    if command -v rustc &> /dev/null; then
        success "Rust installed successfully: $(rustc --version)"
    else
        warning "Rust installation completed, but 'rustc' command not found. You may need to restart your terminal."
    fi
    
    return 0
}

# Function to install Java
install_java() {
    info "Installing Java..."
    
    if command -v java &> /dev/null; then
        current_version=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        info "Java version $current_version is already installed"
        
        read -p "Do you want to reinstall Java? (y/n) [n]: " reinstall_java
        reinstall_java=${reinstall_java:-"n"}
        
        if [[ ! "$reinstall_java" =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    if [ "$PLATFORM" == "macos" ]; then
        brew install openjdk
    else
        sudo apt update
        sudo apt install -y default-jdk
    fi
    
    if [ $? -ne 0 ]; then
        error "Failed to install Java"
        return 1
    fi
    
    # Verify installation
    if command -v java &> /dev/null; then
        success "Java installed successfully: $(java -version 2>&1 | head -n 1)"
    else
        error "Java installation failed"
        return 1
    fi
    
    return 0
}

# Function to setup shell environment
setup_shell() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m       🐚 SHELL ENVIRONMENT SETUP       \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if zsh is installed
    if ! command -v zsh &> /dev/null; then
        info "Installing Zsh..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install zsh
        else
            sudo apt install -y zsh
        fi
        
        if [ $? -ne 0 ]; then
            error "Failed to install Zsh"
            return 1
        fi
    else
        info "Zsh is already installed"
    fi
    
    # Ask if user wants to set Zsh as default shell
    if [ "$SHELL" != "$(which zsh)" ]; then
        read -p "Do you want to set Zsh as your default shell? (y/n) [y]: " set_zsh_default
        set_zsh_default=${set_zsh_default:-"y"}
        
        if [[ "$set_zsh_default" =~ ^[Yy]$ ]]; then
            info "Changing default shell to Zsh..."
            chsh -s $(which zsh)
            if [ $? -ne 0 ]; then
                warning "Failed to change default shell. You can do this manually with: chsh -s $(which zsh)"
            else
                success "Default shell changed to Zsh"
            fi
        fi
    else
        info "Zsh is already the default shell"
    fi
    
    # Ask if user wants to install Oh My Zsh
    read -p "Do you want to install Oh My Zsh? (y/n) [y]: " install_omz
    install_omz=${install_omz:-"y"}
    
    if [[ "$install_omz" =~ ^[Yy]$ ]]; then
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            info "Installing Oh My Zsh..."
            retry 3 sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            
            if [ $? -ne 0 ]; then
                error "Failed to install Oh My Zsh"
            else
                success "Oh My Zsh installation completed"
                
                # Ask about installing Zsh plugins
                read -p "Do you want to install useful Zsh plugins? (y/n) [y]: " install_plugins
                install_plugins=${install_plugins:-"y"}
                
                if [[ "$install_plugins" =~ ^[Yy]$ ]]; then
                    install_zsh_plugins
                fi
            fi
        else
            info "Oh My Zsh already installed"
            
            # Ask about updating Zsh plugins
            read -p "Do you want to install/update Zsh plugins? (y/n) [y]: " update_plugins
            update_plugins=${update_plugins:-"y"}
            
            if [[ "$update_plugins" =~ ^[Yy]$ ]]; then
                install_zsh_plugins
            fi
        fi
    fi
    
    return 0
}

# Function to install Zsh plugins
install_zsh_plugins() {
    info "Installing Zsh plugins..."
    ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
    
    # Create plugins directory if it doesn't exist
    mkdir -p "$ZSH_CUSTOM/plugins"
    
    # Function to clone or update a plugin
    clone_or_update_plugin() {
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
    
    # Install popular plugins
    clone_or_update_plugin "zsh-users/zsh-autosuggestions" "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
    clone_or_update_plugin "zsh-users/zsh-syntax-highlighting" "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
    clone_or_update_plugin "zsh-users/zsh-completions" "${ZSH_CUSTOM}/plugins/zsh-completions"
    
    # Ask about theme
    read -p "Do you want to install the Powerlevel10k theme? (y/n) [y]: " install_p10k
    install_p10k=${install_p10k:-"y"}
    
    if [[ "$install_p10k" =~ ^[Yy]$ ]]; then
        clone_or_update_plugin "romkatv/powerlevel10k" "${ZSH_CUSTOM}/themes/powerlevel10k"
    fi
    
    # Update .zshrc with plugins and theme
    if [ -f "$HOME/.zshrc" ]; then
        # Backup existing .zshrc
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
        
        # Update theme if Powerlevel10k was installed
        if [[ "$install_p10k" =~ ^[Yy]$ ]]; then
            if grep -q 'ZSH_THEME="robbyrussell"' "$HOME/.zshrc"; then
                sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
            fi
        fi
        
        # Update plugins
        if grep -q 'plugins=(git)' "$HOME/.zshrc"; then
            sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$HOME/.zshrc"
        fi
        
        success "Zsh configuration updated"
    else
        warning ".zshrc not found, skipping Zsh configuration"
    fi
}

# Function to setup Git
setup_git() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          🔄 GIT CONFIGURATION          \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if Git is installed
    if ! command -v git &> /dev/null; then
        info "Installing Git..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install git
        else
            sudo apt install -y git
        fi
        
        if [ $? -ne 0 ]; then
            error "Failed to install Git"
            return 1
        fi
    else
        info "Git is already installed: $(git --version)"
    fi
    
    # Configure Git user
    if ! git config --global user.name &>/dev/null; then
        read -p "Enter your name for Git configuration: " git_username
        git config --global user.name "$git_username"
        success "Git username set to: $git_username"
    else
        current_name=$(git config --global user.name)
        read -p "Git username is currently '$current_name'. Change? (y/n) [n]: " change_name
        change_name=${change_name:-"n"}
        
        if [[ "$change_name" =~ ^[Yy]$ ]]; then
            read -p "Enter your name for Git configuration: " git_username
            git config --global user.name "$git_username"
            success "Git username set to: $git_username"
        fi
    fi
    
    if ! git config --global user.email &>/dev/null; then
        read -p "Enter your email for Git configuration: " git_email
        git config --global user.email "$git_email"
        success "Git email set to: $git_email"
    else
        current_email=$(git config --global user.email)
        read -p "Git email is currently '$current_email'. Change? (y/n) [n]: " change_email
        change_email=${change_email:-"n"}
        
        if [[ "$change_email" =~ ^[Yy]$ ]]; then
            read -p "Enter your email for Git configuration: " git_email
            git config --global user.email "$git_email"
            success "Git email set to: $git_email"
        fi
    fi
    
    # Configure Git preferences
    git config --global core.editor "vim"
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    
    # Platform-specific line ending configuration
    if [ "$PLATFORM" == "wsl" ] || [ "$PLATFORM" == "linux" ]; then
        git config --global core.autocrlf input
    elif [ "$PLATFORM" == "macos" ]; then
        git config --global core.autocrlf input
    fi
    
    success "Git configuration completed"
    
    # SSH key for GitHub
    read -p "Do you want to generate an SSH key for GitHub? (y/n) [y]: " gen_ssh
    gen_ssh=${gen_ssh:-"y"}
    
    if [[ "$gen_ssh" =~ ^[Yy]$ ]]; then
        if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
            info "Generating SSH key..."
            
            read -p "Enter your email for the SSH key: " ssh_email
            ssh-keygen -t ed25519 -C "$ssh_email" -f "$HOME/.ssh/id_ed25519"
            
            if [ $? -ne 0 ]; then
                error "Failed to generate SSH key"
                return 1
            fi
            
            # Start ssh-agent if it's not running
            eval "$(ssh-agent -s)"
            ssh-add "$HOME/.ssh/id_ed25519"
            
            echo "📎 Public key (copy this to GitHub SSH settings):"
            cat "$HOME/.ssh/id_ed25519.pub"
            success "SSH key generation completed"
        else
            info "SSH key already exists at $HOME/.ssh/id_ed25519"
            