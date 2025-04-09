    SYNC_FILES=(
        ".zshrc"
        ".bashrc"
        ".bash_aliases"
        ".gitconfig"
        ".vimrc"
        ".tmux.conf"
        ".p10k.zsh"
        ".aliases"
        ".profile"
        ".gitignore_global"
    )
fi

# VS Code settings
SYNC_VSCODE=${SYNC_VSCODE:-true}

# Check if VS Code settings directory exists
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
elif [ "$PLATFORM" == "macos" ]; then
    if [ -d "$HOME/Library/Application Support/Code/User" ]; then
        VSCODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    fi
fi

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        error "Git is not installed. Please install Git before using this module."
        return 1
    fi
    return 0
}

# Function to configure settings
configure_settings() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m       ⚙️ DOTFILES SYNCER SETTINGS      \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Current settings:"
    info "Dotfiles directory: $DOTFILES_DIR"
    info "Git repository: $DOTFILES_REPO"
    info "Git branch: $DOTFILES_BRANCH"
    info "Sync VS Code settings: $SYNC_VSCODE"
    echo ""
    info "Files to sync:"
    for file in "${SYNC_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    
    # Ask for repository URL if not set
    if [ -z "$DOTFILES_REPO" ]; then
        read -p "Enter Git repository URL for dotfiles: " new_repo
        
        if [ -n "$new_repo" ]; then
            DOTFILES_REPO="$new_repo"
            # Update config file
            if grep -q "DOTFILES_REPO=" "$CONFIG_FILE"; then
                sed -i "s|DOTFILES_REPO=.*|DOTFILES_REPO=\"$DOTFILES_REPO\"|" "$CONFIG_FILE"
            else
                echo "DOTFILES_REPO=\"$DOTFILES_REPO\"" >> "$CONFIG_FILE"
            fi
            success "Repository URL set to: $DOTFILES_REPO"
        else
            warning "Repository URL is required for syncing. Please try again."
            return 1
        fi
    else
        read -p "Update repository URL? Current: $DOTFILES_REPO (y/n) [n]: " update_repo
        update_repo=${update_repo:-"n"}
        
        if [[ "$update_repo" =~ ^[Yy]$ ]]; then
            read -p "Enter new repository URL: " new_repo
            
            if [ -n "$new_repo" ]; then
                DOTFILES_REPO="$new_repo"
                # Update config file
                if grep -q "DOTFILES_REPO=" "$CONFIG_FILE"; then
                    sed -i "s|DOTFILES_REPO=.*|DOTFILES_REPO=\"$DOTFILES_REPO\"|" "$CONFIG_FILE"
                else
                    echo "DOTFILES_REPO=\"$DOTFILES_REPO\"" >> "$CONFIG_FILE"
                fi
                success "Repository URL updated to: $DOTFILES_REPO"
            fi
        fi
    fi
    
    # Ask for dotfiles directory
    read -p "Enter dotfiles directory [$DOTFILES_DIR]: " new_dir
    new_dir=${new_dir:-$DOTFILES_DIR}
    
    if [ "$new_dir" != "$DOTFILES_DIR" ]; then
        DOTFILES_DIR="$new_dir"
        # Update config file
        if grep -q "DOTFILES_DIR=" "$CONFIG_FILE"; then
            sed -i "s|DOTFILES_DIR=.*|DOTFILES_DIR=\"$DOTFILES_DIR\"|" "$CONFIG_FILE"
        else
            echo "DOTFILES_DIR=\"$DOTFILES_DIR\"" >> "$CONFIG_FILE"
        fi
        success "Dotfiles directory updated to: $DOTFILES_DIR"
    fi
    
    # Ask for branch name
    read -p "Enter Git branch name [$DOTFILES_BRANCH]: " new_branch
    new_branch=${new_branch:-$DOTFILES_BRANCH}
    
    if [ "$new_branch" != "$DOTFILES_BRANCH" ]; then
        DOTFILES_BRANCH="$new_branch"
        # Update config file
        if grep -q "DOTFILES_BRANCH=" "$CONFIG_FILE"; then
            sed -i "s|DOTFILES_BRANCH=.*|DOTFILES_BRANCH=\"$DOTFILES_BRANCH\"|" "$CONFIG_FILE"
        else
            echo "DOTFILES_BRANCH=\"$DOTFILES_BRANCH\"" >> "$CONFIG_FILE"
        fi
        success "Git branch updated to: $DOTFILES_BRANCH"
    fi
    
    # Ask about VS Code settings sync
    read -p "Sync VS Code settings? (true/false) [$SYNC_VSCODE]: " new_vscode
    new_vscode=${new_vscode:-$SYNC_VSCODE}
    
    if [ "$new_vscode" != "$SYNC_VSCODE" ]; then
        SYNC_VSCODE="$new_vscode"
        # Update config file
        if grep -q "SYNC_VSCODE=" "$CONFIG_FILE"; then
            sed -i "s|SYNC_VSCODE=.*|SYNC_VSCODE=$SYNC_VSCODE|" "$CONFIG_FILE"
        else
            echo "SYNC_VSCODE=$SYNC_VSCODE" >> "$CONFIG_FILE"
        fi
        success "VS Code settings sync updated to: $SYNC_VSCODE"
    fi
    
    # Ask if user wants to update list of files to sync
    read -p "Update list of files to sync? (y/n) [n]: " update_files
    update_files=${update_files:-"n"}
    
    if [[ "$update_files" =~ ^[Yy]$ ]]; then
        echo "Enter files to sync (space-separated, include the dot prefix)."
        echo "Current files: ${SYNC_FILES[*]}"
        read -p "New file list: " new_files_input
        
        if [ -n "$new_files_input" ]; then
            # Convert space-separated string to array
            IFS=' ' read -ra new_files <<< "$new_files_input"
            
            # Update SYNC_FILES array
            SYNC_FILES=("${new_files[@]}")
            
            # Update config file
            if grep -q "SYNC_FILES=" "$CONFIG_FILE"; then
                # Find the opening bracket of the array
                line_num=$(grep -n "SYNC_FILES=" "$CONFIG_FILE" | cut -d: -f1)
                
                # Find the closing bracket of the array
                end_line_num=$(tail -n +$line_num "$CONFIG_FILE" | grep -n ")" | head -1 | cut -d: -f1)
                end_line_num=$((line_num + end_line_num - 1))
                
                # Remove the existing array
                sed -i "${line_num},${end_line_num}d" "$CONFIG_FILE"
                
                # Add the new array
                sed -i "${line_num}i\\SYNC_FILES=(" "$CONFIG_FILE"
                for file in "${SYNC_FILES[@]}"; do
                    sed -i "$((line_num+1))i\\    \"$file\"" "$CONFIG_FILE"
                done
                sed -i "$((line_num+${#SYNC_FILES[@]}+1))i\\)" "$CONFIG_FILE"
            else
                # Add the array to the config file
                echo "SYNC_FILES=(" >> "$CONFIG_FILE"
                for file in "${SYNC_FILES[@]}"; do
                    echo "    \"$file\"" >> "$CONFIG_FILE"
                done
                echo ")" >> "$CONFIG_FILE"
            fi
            
            success "Files to sync updated"
        fi
    fi
    
    success "Dotfiles syncer configuration updated"
    return 0
}

# Function to setup dotfiles repository
setup_repo() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m       🔄 DOTFILES REPOSITORY SETUP     \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if Git is installed
    if ! check_git; then
        return 1
    fi
    
    # Make sure we have a repository URL
    if [ -z "$DOTFILES_REPO" ]; then
        error "Repository URL is not configured."
        read -p "Enter Git repository URL for dotfiles: " DOTFILES_REPO
        
        if [ -z "$DOTFILES_REPO" ]; then
            error "Repository URL is required for setup."
            return 1
        fi
        
        # Update config file
        if grep -q "DOTFILES_REPO=" "$CONFIG_FILE"; then
            sed -i "s|DOTFILES_REPO=.*|DOTFILES_REPO=\"$DOTFILES_REPO\"|" "$CONFIG_FILE"
        else
            echo "DOTFILES_REPO=\"$DOTFILES_REPO\"" >> "$CONFIG_FILE"
        fi
        success "Repository URL set to: $DOTFILES_REPO"
    fi
    
    # Check if repository directory already exists
    if [ -d "$DOTFILES_DIR" ]; then
        info "Repository directory already exists at $DOTFILES_DIR"
        read -p "Do you want to overwrite it? (y/n) [n]: " overwrite
        overwrite=${overwrite:-"n"}
        
        if [[ "$overwrite" =~ ^[Yy]$ ]]; then
            info "Backing up existing directory..."
            backup_dir="${DOTFILES_DIR}.backup.$(date +%Y%m%d%H%M%S)"
            mv "$DOTFILES_DIR" "$backup_dir"
            success "Existing directory backed up to $backup_dir"
        else
            info "Using existing repository directory"
            
            # Check if it's a Git repository
            if [ -d "$DOTFILES_DIR/.git" ]; then
                info "Directory is already a Git repository"
                
                # Change to the directory and check remote
                cd "$DOTFILES_DIR"
                
                # Check if the remote matches our configured repository
                current_repo=$(git config --get remote.origin.url)
                
                if [ "$current_repo" != "$DOTFILES_REPO" ]; then
                    info "Remote URL doesn't match configuration"
                    info "Current: $current_repo"
                    info "Configured: $DOTFILES_REPO"
                    
                    read -p "Update remote URL? (y/n) [y]: " update_remote
                    update_remote=${update_remote:-"y"}
                    
                    if [[ "$update_remote" =~ ^[Yy]$ ]]; then
                        git remote set-url origin "$DOTFILES_REPO"
                        success "Remote URL updated"
                    fi
                fi
                
                # Make sure we're on the right branch
                current_branch=$(git rev-parse --abbrev-ref HEAD)
                
                if [ "$current_branch" != "$DOTFILES_BRANCH" ]; then
                    info "Current branch ($current_branch) doesn't match configured branch ($DOTFILES_BRANCH)"
                    
                    # Check if the configured branch exists
                    if git show-ref --verify --quiet "refs/heads/$DOTFILES_BRANCH"; then
                        # Branch exists, switch to it
                        git checkout "$DOTFILES_BRANCH"
                        success "Switched to branch $DOTFILES_BRANCH"
                    else
                        # Branch doesn't exist, create it
                        read -p "Create branch '$DOTFILES_BRANCH'? (y/n) [y]: " create_branch
                        create_branch=${create_branch:-"y"}
                        
                        if [[ "$create_branch" =~ ^[Yy]$ ]]; then
                            git checkout -b "$DOTFILES_BRANCH"
                            success "Created and switched to branch $DOTFILES_BRANCH"
                        fi
                    fi
                fi
                
                # Pull latest changes
                git pull origin "$DOTFILES_BRANCH" || warning "Failed to pull from remote repository"
                
                return 0
            else
                error "Directory exists but is not a Git repository"
                read -p "Initialize as Git repository? (y/n) [y]: " init_git
                init_git=${init_git:-"y"}
                
                if [[ "$init_git" =~ ^[Yy]$ ]]; then
                    cd "$DOTFILES_DIR"
                    git init
                    git remote add origin "$DOTFILES_REPO"
                    git checkout -b "$DOTFILES_BRANCH"
                    success "Initialized Git repository"
                    return 0
                else
                    error "Cannot continue without a Git repository"
                    return 1
                fi
            fi
        fi
    fi
    
    # Create the repository directory
    mkdir -p "$DOTFILES_DIR"
    cd "$DOTFILES_DIR"
    
    # Initialize Git repository
    git init
    git remote add origin "$DOTFILES_REPO"
    git checkout -b "$DOTFILES_BRANCH"
    
    # Create a README file
    cat > "$DOTFILES_DIR/README.md" << EOF
# Dotfiles

This repository contains my personal dotfiles, managed with the DEV-SETUP dotfiles syncer.

## Files

$(for file in "${SYNC_FILES[@]}"; do echo "- \`$file\`"; done)

## Installation

To use these dotfiles, clone this repository and run the restore script:

\`\`\`bash
git clone $DOTFILES_REPO ~/.dotfiles
cd ~/.dotfiles
./restore.sh
\`\`\`

## Requirements

- Git
- Bash

## License

MIT
EOF
    
    # Create a restore script
    cat > "$DOTFILES_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Dotfiles restore script

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_DIR"

echo "🔄 Restoring dotfiles..."

# Create backup directory
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy each file to home directory
for file in $(find . -maxdepth 1 -type f -name ".*" | grep -v ".git"); do
    filename=$(basename "$file")
    
    # Backup existing file if it exists
    if [ -f "$HOME/$filename" ]; then
        echo "📦 Backing up existing $filename"
        cp "$HOME/$filename" "$BACKUP_DIR/"
    fi
    
    # Copy file to home directory
    echo "✅ Restoring $filename"
    cp "$file" "$HOME/"
done

# Handle VS Code settings if they exist
if [ -d "./vscode" ]; then
    echo "🔍 Found VS Code settings"
    
    # Try to find VS Code settings directory
    VSCODE_DIR=""
    if [ -d "$HOME/.config/Code/User" ]; then
        VSCODE_DIR="$HOME/.config/Code/User"
    elif [ -d "$HOME/Library/Application Support/Code/User" ]; then
        VSCODE_DIR="$HOME/Library/Application Support/Code/User"
    elif [ -d "$HOME/AppData/Roaming/Code/User" ]; then
        VSCODE_DIR="$HOME/AppData/Roaming/Code/User"
    elif [ -n "$APPDATA" ] && [ -d "$APPDATA/Code/User" ]; then
        VSCODE_DIR="$APPDATA/Code/User"
    fi
    
    if [ -n "$VSCODE_DIR" ]; then
        echo "📂 VS Code directory found at: $VSCODE_DIR"
        
        # Backup existing settings
        if [ -f "$VSCODE_DIR/settings.json" ]; then
            mkdir -p "$BACKUP_DIR/vscode"
            cp "$VSCODE_DIR/settings.json" "$BACKUP_DIR/vscode/"
        fi
        
        if [ -f "$VSCODE_DIR/keybindings.json" ]; then
            mkdir -p "$BACKUP_DIR/vscode"
            cp "$VSCODE_DIR/keybindings.json" "$BACKUP_DIR/vscode/"
        fi
        
        # Restore VS Code settings
        if [ -f "./vscode/settings.json" ]; then
            echo "✅ Restoring VS Code settings"
            cp "./vscode/settings.json" "$VSCODE_DIR/"
        fi
        
        if [ -f "./vscode/keybindings.json" ]; then
            echo "✅ Restoring VS Code keybindings"
            cp "./vscode/keybindings.json" "$VSCODE_DIR/"
        fi
        
        # Restore snippets if they exist
        if [ -d "./vscode/snippets" ]; then
            echo "✅ Restoring VS Code snippets"
            mkdir -p "$VSCODE_DIR/snippets"
            cp -r ./vscode/snippets/* "$VSCODE_DIR/snippets/"
        fi
    else
        echo "⚠️ VS Code directory not found. Settings not restored."
    fi
fi

echo "✅ Dotfiles restoration completed!"
if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR")" ]; then
    echo "📂 Backup created at: $BACKUP_DIR"
else
    # Remove empty backup directory
    rmdir "$BACKUP_DIR" 2>/dev/null
fi

echo "🚀 You're good to go!"
EOF
    
    # Make the restore script executable
    chmod +x "$DOTFILES_DIR/restore.sh"
    
    # Create an empty .gitignore file
    cat > "$DOTFILES_DIR/.gitignore" << 'EOF'
# Ignore temporary files
*.swp
*.swo
*~
.DS_Store

# Ignore sensitive information
.env
.env.*
EOF
    
    # Commit the initial files
    git add README.md restore.sh .gitignore
    git commit -m "Initial dotfiles setup"
    
    success "Dotfiles repository initialized at $DOTFILES_DIR"
    info "Created README.md, restore.sh, and .gitignore"
    
    # Ask if user wants to push to remote repository
    read -p "Push to remote repository now? (y/n) [y]: " push_now
    push_now=${push_now:-"y"}
    
    if [[ "$push_now" =~ ^[Yy]$ ]]; then
        # Verify we can access the repository
        if git ls-remote --exit-code "$DOTFILES_REPO" &>/dev/null; then
            git push -u origin "$DOTFILES_BRANCH"
            success "Pushed to remote repository"
        else
            warning "Cannot access remote repository. You may need to set up SSH keys or authentication."
            
            # Offer to help set up SSH key
            read -p "Do you want to set up an SSH key for GitHub? (y/n) [y]: " setup_ssh
            setup_ssh=${setup_ssh:-"y"}
            
            if [[ "$setup_ssh" =~ ^[Yy]$ ]]; then
                # Check if SSH key already exists
                if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
                    read -p "Enter your email for the SSH key: " ssh_email
                    ssh-keygen -t ed25519 -C "$ssh_email"
                    
                    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
                        echo "📎 Here's your public key. Add it to GitHub:"
                        cat "$HOME/.ssh/id_ed25519.pub"
                        
                        # Start SSH agent
                        eval "$(ssh-agent -s)"
                        ssh-add "$HOME/.ssh/id_ed25519"
                        
                        info "After adding the key to GitHub, try pushing again with:"
                        info "cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
                    else
                        error "Failed to generate SSH key"
                    fi
                else
                    info "SSH key already exists at $HOME/.ssh/id_ed25519"
                    echo "📎 Here's your public key. Make sure it's added to GitHub:"
                    cat "$HOME/.ssh/id_ed25519.pub"
                    
                    # Start SSH agent
                    eval "$(ssh-agent -s)"
                    ssh-add "$HOME/.ssh/id_ed25519"
                    
                    read -p "Try pushing to repository again? (y/n) [y]: " retry_push
                    retry_push=${retry_push:-"y"}
                    
                    if [[ "$retry_push" =~ ^[Yy]$ ]]; then
                        git push -u origin "$DOTFILES_BRANCH"
                        if [ $? -eq 0 ]; then
                            success "Pushed to remote repository"
                        else
                            warning "Push failed. You can try again later with:"
                            info "cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
                        fi
                    fi
                fi
            fi
        fi
    else
        info "You can push to the remote repository later with:"
        info "cd $DOTFILES_DIR && git push -u origin $DOTFILES_BRANCH"
    fi
    
    return 0
}

# Function to backup dotfiles
backup_dotfiles() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          💾 BACKUP DOTFILES            \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if Git is installed
    if ! check_git; then
        return 1
    fi
    
    # Check if repository is set up
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        error "Dotfiles repository not set up. Please run setup first."
        read -p "Setup repository now? (y/n) [y]: " setup_now
        setup_now=${setup_now:-"y"}
        
        if [[ "$setup_now" =~ ^[Yy]$ ]]; then
            setup_repo
        else
            return 1
        fi
    fi
    
    info "Backing up dotfiles to repository at $DOTFILES_DIR"
    
    # Switch to repository directory
    cd "$DOTFILES_DIR"
    
    # Make sure we're on the right branch
    git checkout "$DOTFILES_BRANCH" || git checkout -b "$DOTFILES_BRANCH"
    
    # Copy each file to repository
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$HOME/$file" ]; then
            cp "$HOME/$file" "$DOTFILES_DIR/" && success "Backed up $file" || warning "Failed to backup $file"
        else
            warning "File not found: $HOME/$file"
        fi
    done
    
    # Handle VS Code settings if enabled
    if [ "$SYNC_VSCODE" = true ] && [ -n "$VSCODE_SETTINGS_DIR" ]; then
        mkdir -p "$DOTFILES_DIR/vscode"
        
        if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
            cp "$VSCODE_SETTINGS_DIR/settings.json" "$DOTFILES_DIR/vscode/" && success "Backed up VS Code settings" || warning "Failed to backup VS Code settings"
        fi
        
        if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]; then
            cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$DOTFILES_DIR/vscode/" && success "Backed up VS Code keybindings" || warning "Failed to backup VS Code keybindings"
        fi
        
        if [ -d "$VSCODE_SETTINGS_DIR/snippets" ]; then
            mkdir -p "$DOTFILES_DIR/vscode/snippets"
            cp -r "$VSCODE_SETTINGS_DIR/snippets"/* "$DOTFILES_DIR/vscode/snippets/" && success "Backed up VS Code snippets" || warning "Failed to backup VS Code snippets"
        fi
    fi
    
    # Check for changes
    if git diff --quiet && git diff --staged --quiet; then
        info "No changes to dotfiles detected"
    else
        # Commit changes
        git add -A
        git commit -m "Update dotfiles - $(date +'%Y-%m-%d %H:%M:%S')"
        success "Changes committed to local repository"
        
        # Ask if user wants to push changes
        read -p "Push changes to remote repository? (y/n) [y]: " push_changes
        push_changes=${push_changes:-"y"}
        
        if [[ "$push_changes" =~ ^[Yy]$ ]]; then
            git push origin "$DOTFILES_BRANCH"
            if [ $? -eq 0 ]; then
                success "Changes pushed to remote repository"
            else
                warning "Failed to push changes. You can try again later with:"
                info "cd $DOTFILES_DIR && git push origin $DOTFILES_BRANCH"
            fi
        else
            info "Changes committed to local repository only"
            info "You can push later with: cd $DOTFILES_DIR && git push origin $DOTFILES_BRANCH"
        fi
    fi
    
    return 0
}

# Function to restore dotfiles
restore_dotfiles() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          📥 RESTORE DOTFILES           \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if Git is installed
    if ! check_git; then
        return 1
    fi
    
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        info "Dotfiles repository not found locally. Cloning from remote..."
        
        if [ -z "$DOTFILES_REPO" ]; then
            error "Repository URL is not configured."
            read -p "Enter Git repository URL for dotfiles: " DOTFILES_REPO
            
            if [ -z "$DOTFILES_REPO" ]; then
                error "Repository URL is required for restoration."
                return 1
            fi
            
            # Update config file
            if grep -q "DOTFILES_REPO=" "$CONFIG_FILE"; then
                sed -i "s|DOTFILES_REPO=.*|DOTFILES_REPO=\"$DOTFILES_REPO\"|" "$CONFIG_FILE"
            else
                echo "DOTFILES_REPO=\"$DOTFILES_REPO\"" >> "$CONFIG_FILE"
            fi
        fi
        
        # Clone the repository
        git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$DOTFILES_DIR" || {
            error "Failed to clone repository from $DOTFILES_REPO"
            return 1
        }
    else
        info "Using existing repository at $DOTFILES_DIR"
        
        # Change to the directory and pull latest changes
        cd "$DOTFILES_DIR"
        git checkout "$DOTFILES_BRANCH" || {
            error "Failed to switch to branch $DOTFILES_BRANCH"
            return 1
        }
        
        git pull origin "$DOTFILES_BRANCH" || {
            warning "Failed to pull latest changes. Continuing with existing files."
        }
    fi
    
    # Verify if restore.sh exists
    if [ -f "$DOTFILES_DIR/restore.sh" ]; then
        info "Found restore script. Running it..."
        cd "$DOTFILES_DIR"
        ./restore.sh
        return $?
    fi
    
    # Manual restoration if no script exists
    info "No restore script found. Performing manual restoration..."
    
    # Create backup directory
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Copy each file to home directory
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$DOTFILES_DIR/$file" ]; then
            # Backup existing file if it exists
            if [ -f "$HOME/$file" ]; then
                cp "$HOME/$file" "$BACKUP_DIR/" && info "Backed up existing $file" || warning "Failed to backup existing $file"
            fi
            
            # Copy file to home directory
            cp "$DOTFILES_DIR/$file" "$HOME/" && success "Restored $file" || error "Failed to restore $file"
        else
            warning "File not found in repository: $file"
        fi
    done
    
    # Handle VS Code settings if enabled
    if [ "$SYNC_VSCODE" = true ] && [ -n "$VSCODE_SETTINGS_DIR" ] && [ -d "$DOTFILES_DIR/vscode" ]; then
        # Backup existing settings
        if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ]; then
            mkdir -p "$BACKUP_DIR/vscode"
            cp "$VSCODE_SETTINGS_DIR/settings.json" "$BACKUP_DIR/vscode/" && info "Backed up existing VS Code settings" || warning "Failed to backup VS Code settings"
        fi
        
        if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]; then
            mkdir -p "$BACKUP_DIR/vscode"
            cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$BACKUP_DIR/vscode/" && info "Backed up existing VS Code keybindings" || warning "Failed to backup VS Code keybindings"
        fi
        
        # Restore VS Code settings
        if [ -f "$DOTFILES_DIR/vscode/settings.json" ]; then
            mkdir -p "$VSCODE_SETTINGS_DIR"
            cp "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_SETTINGS_DIR/" && success "Restored VS Code settings" || error "Failed to restore VS Code settings"
        fi
        
        if [ -f "$DOTFILES_DIR/vscode/keybindings.json" ]; then
            mkdir -p "$VSCODE_SETTINGS_DIR"
            cp "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_SETTINGS_DIR/" && success "Restored VS Code keybindings" || error "Failed to restore VS Code keybindings"
        fi
        
        # Restore snippets if they exist
        if [ -d "$DOTFILES_DIR/vscode/snippets" ]; then
            mkdir -p "$VSCODE_SETTINGS_DIR/snippets"
            cp -r "$DOTFILES_DIR/vscode/snippets"/* "$VSCODE_SETTINGS_DIR/snippets/" && success "Restored VS Code snippets" || error "Failed to restore VS Code snippets"
        fi
    fi
    
    # Show summary
    success "Dotfiles restoration completed!"
    if [ -d "$BACKUP_DIR" ] && [ "$(ls -A "$BACKUP_DIR")" ]; then
        info "Backup created at: $BACKUP_DIR"
    else
        # Remove empty backup directory
        rmdir "$BACKUP_DIR" 2>/dev/null
    fi
    
    return 0
}

# Function to schedule automatic backups
schedule_backup() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      📅 SCHEDULE DOTFILES BACKUP       \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if command -v crontab &> /dev/null; then
        info "Setting up automatic backup using crontab..."
        
        # Create a script for cron to use
        BACKUP_SCRIPT="$HOME/.dev-setup/modules/run_dotfiles_backup.sh"
        
        cat > "$BACKUP_SCRIPT" << EOF
#!/bin/bash
# Automatic dotfiles backup script
$HOME/.dev-setup/modules/dotfiles_syncer.sh "$CONFIG_FILE" --backup > $HOME/.dev-setup/logs/dotfiles_backup_cron.log 2>&1
EOF
        
        chmod +x "$BACKUP_SCRIPT"
        
        # Ask about backup frequency
        echo "How often do you want to back up your dotfiles?"
        echo "1. Daily"
        echo "2. Weekly"
        echo "3. Monthly"
        echo "0. Cancel"
        read -p "Enter your choice [0-3]: " freq_choice
        
        case $freq_choice in
            1) # Daily at midnight
                cron_schedule="0 0 * * *"
                frequency="daily"
                ;;
            2) # Weekly on Sunday at midnight
                cron_schedule="0 0 * * 0"
                frequency="weekly"
                ;;
            3) # Monthly on the 1st at midnight
                cron_schedule="0 0 1 * *"
                frequency="monthly"
                ;;
            0|"") # Cancel or empty input
                info "Automatic backup cancelled"
                return 0
                ;;
            *)
                error "Invalid choice"
                return 1
                ;;
        esac
        
        # Add to crontab
        (crontab -l 2>/dev/null || echo "") | grep -v "run_dotfiles_backup.sh" | { cat; echo "$cron_schedule $BACKUP_SCRIPT"; } | crontab -
        
        if [ $? -eq 0 ]; then
            success "Automatic backup scheduled: $frequency"
            info "Schedule: $cron_schedule"
        else
            error "Failed to schedule backup via crontab"
            return 1
        fi
    else
        warning "crontab is not available on your system"
        
        if [ "$PLATFORM" == "wsl" ]; then
            info "For WSL, you can set up a scheduled task in Windows:"
            info "1. Create a batch file with this content:"
            echo 'wsl -d Ubuntu -e bash -c "~/.dev-setup/modules/run_dotfiles_backup.sh"'
            info "2. Open Task Scheduler in Windows"
            info "3. Create a basic task to run the batch file at your preferred frequency"
        elif [ "$PLATFORM" == "macos" ]; then
            info "For macOS, you can set up a LaunchAgent:"
            info "1. Create a plist file in ~/Library/LaunchAgents/"
            info "2. Use 'launchctl load' to load the agent"
        fi
    fi
    
    return 0
}

# Function to generate a diff report
generate_diff() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m           📊 DOTFILES DIFF             \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if repository is set up
    if [ ! -d "$DOTFILES_DIR/.git" ]; then
        error "Dotfiles repository not set up. Please run setup first."
        return 1
    fi
    
    info "Generating diff between repository and home directory..."
    
    # Create a temporary directory for diff
    TEMP_DIR=$(mktemp -d)
    
    # Function to clean up temporary directory
    cleanup() {
        rm -rf "$TEMP_DIR"
    }
    
    # Register cleanup function to run on exit
    trap cleanup EXIT
    
    # Track if any differences were found
    DIFF_FOUND=false
    
    # Compare each file
    for file in "${SYNC_FILES[@]}"; do
        if [ -f "$HOME/$file" ] && [ -f "$DOTFILES_DIR/$file" ]; then
            # Check if files are different
            if ! cmp -s "$HOME/$file" "$DOTFILES_DIR/$file"; then
                DIFF_FOUND=true
                echo -e "\e[1;33m=== Diff for $file ===\e[0m"
                diff -u "$DOTFILES_DIR/$file" "$HOME/$file" | grep -v "^---" | grep -v "^+++" | while read -r line; do
                    if [[ $line == -* ]]; then
                        echo -e "\e[31m$line\e[0m"  # Red for removed lines
                    elif [[ $line == +* ]]; then
                        echo -e "\e[32m$line\e[0m"  # Green for added lines
                    else
                        echo "$line"
                    fi
                done
                echo ""
            fi
        elif [ -f "$HOME/$file" ] && [ ! -f "$DOTFILES_DIR/$file" ]; then
            DIFF_FOUND=true
            echo -e "\e[33mFile '$file' exists in home directory but not in repository\e[0m"
            echo ""
        elif [ ! -f "$HOME/$file" ] && [ -f "$DOTFILES_DIR/$file" ]; then
            DIFF_FOUND=true
            echo -e "\e[33mFile '$file' exists in repository but not in home directory\e[0m"
            echo ""
        fi
    done
    
    # Handle VS Code settings if enabled
    if [ "$SYNC_VSCODE" = true ] && [ -n "$VSCODE_SETTINGS_DIR" ]; then
        # Check settings.json
        if [ -f "$VSCODE_SETTINGS_DIR/settings.json" ] && [ -f "$DOTFILES_DIR/vscode/settings.json" ]; then
            if ! cmp -s "$VSCODE_SETTINGS_DIR/settings.json" "$DOTFILES_DIR/vscode/settings.json"; then
                DIFF_FOUND=true
                echo -e "\e[1;33m=== Diff for VS Code settings.json ===\e[0m"
                diff -u "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_SETTINGS_DIR/settings.json" | grep -v "^---" | grep -v "^+++" | while read -r line; do
                    if [[ $line == -* ]]; then
                        echo -e "\e[31m$line\e[0m"
                    elif [[ $line == +* ]]; then
                        echo -e "\e[32m$line\e[0m"
                    else
                        echo "$line"
                    fi
                done
                echo ""
            fi
        elif [ -f "$VSCODE_SETTINGS_DIR/settings.json" ] && [ ! -f "$DOTFILES_DIR/vscode/settings.json" ]; then
            DIFF_FOUND=true
            echo -e "\e[33mVS Code settings.json exists in VS Code directory but not in repository\e[0m"
            echo ""
        elif [ ! -f "$VSCODE_SETTINGS_DIR/settings.json" ] && [ -f "$DOTFILES_DIR/vscode/settings.json" ]; then
            DIFF_FOUND=true
            echo -e "\e[33mVS Code settings.json exists in repository but not in VS Code directory\e[0m"
            echo ""
        fi
        
        # Check keybindings.json
        if [ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ] && [ -f "$DOTFILES_DIR/vscode/keybindings.json" ]; then
            if ! cmp -s "$VSCODE_SETTINGS_DIR/keybindings.json" "$DOTFILES_DIR/vscode/keybindings.json"; then
                DIFF_FOUND=true
                echo -e "\e[1;33m=== Diff for VS Code keybindings.json ===\e[0m"
                diff -u "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_SETTINGS_DIR/keybindings.json" | grep -v "^---" | grep -v "^+++" | while read -r line; do
                    if [[ $line == -* ]]; then
                        echo -e "\e[31m$line\e[0m"
                    elif [[ $line == +* ]]; then
                        echo -e "\e[32m$line\e[0m"
                    else
                        echo "$line"
                    fi
                done
                echo ""
            fi
        fi
    fi
    
    if [ "$DIFF_FOUND" = false ]; then
        info "No differences found. Home directory and repository are in sync."
    else
        warning "Differences found between home directory and repository."
        echo -e "\e[33mUse 'Backup' to update repository with home files or 'Restore' to update home with repository files.\e[0m"
    fi
    
    return 0
}

# Parse command-line arguments
parse_arguments() {
    if [ $# -gt 0 ]; then
        case "$1" in
            --backup)
                backup_dotfiles
                exit $?
                ;;
            --restore)
                restore_dotfiles
                exit $?
                ;;
            --setup)
                setup_repo
                exit $?
                ;;
            --diff)
                generate_diff
                exit $?
                ;;
            --schedule)
                schedule_backup
                exit $?
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    fi
}

# Show help function
show_help() {
    echo "Dotfiles Syncer"
    echo "Usage: $(basename $0) [options]"
    echo ""
    echo "Options:"
    echo "  --setup     Setup dotfiles repository"
    echo "  --backup    Backup dotfiles to repository"
    echo "  --restore   Restore dotfiles from repository"
    echo "  --diff      Show differences between home and repository"
    echo "  --schedule  Schedule automatic backups"
    echo "  --help      Show this help message"
    echo ""
    echo "If no options are provided, the interactive menu will be shown."
}

# Main menu function
show_syncer_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          🧱 DOTFILES SYNCER            \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    echo "Please select an option:"
    echo "1. Configure settings"
    echo "2. Setup repository"
    echo "3. Backup dotfiles"
    echo "4. Restore dotfiles"
    echo "5. Show diff"
    echo "6. Schedule automatic backup"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-6]: " menu_choice
    
    case $menu_choice in
        1) configure_settings ;;
        2) setup_repo ;;
        3) backup_dotfiles ;;
        4) restore_dotfiles ;;
        5) generate_diff ;;
        6) schedule_backup ;;
        0) exit 0 ;;
        *)
            warning "Invalid option. Please try again."
            show_syncer_menu
            ;;
    esac
    
    # Return to menu after function completes
    read -p "Press Enter to return to the main menu..."
    show_syncer_menu
}

# Main execution starts here
# Parse arguments if provided
parse_arguments "$@"

# Show the main menu
show_syncer_menu#!/bin/bash
# Dotfiles Syncer Module
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
LOG_FILE="$HOME/.dev-setup/logs/dotfiles_syncer_$(date +%Y-%m-%d_%H-%M-%S).log"
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

# Default settings
DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/.dotfiles"}
DOTFILES_REPO=${DOTFILES_REPO:-""}
DOTFILES_BRANCH=${DOTFILES_BRANCH:-"main"}

# Default list of files to sync
if [ -z "$SYNC_FILES" ]; then
    SYNC_FILES=(
        ".zsh