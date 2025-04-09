#!/bin/bash
# Downloads Organizer Module
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
LOG_FILE="$HOME/.dev-setup/logs/downloads_organizer_$(date +%Y-%m-%d_%H-%M-%S).log"
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
if [ "$PLATFORM" == "wsl" ]; then
    # Try to get Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
    if [ -n "$WIN_USER" ] && [[ ! "$WIN_USER" == *"%" ]]; then
        DEFAULT_DOWNLOADS_DIR="/mnt/c/Users/$WIN_USER/Downloads"
    else
        DEFAULT_DOWNLOADS_DIR="/mnt/c/Users/Public/Downloads"
    fi
else
    DEFAULT_DOWNLOADS_DIR="$HOME/Downloads"
fi

DOWNLOADS_DIR=${DOWNLOADS_DIR:-$DEFAULT_DOWNLOADS_DIR}
ORGANIZE_INSTALLERS=${ORGANIZE_INSTALLERS:-true}
ORGANIZE_IMAGES=${ORGANIZE_IMAGES:-true}
ORGANIZE_DOCUMENTS=${ORGANIZE_DOCUMENTS:-true}
ORGANIZE_ARCHIVES=${ORGANIZE_ARCHIVES:-true}
ORGANIZE_CODE=${ORGANIZE_CODE:-true}
DELETE_OLD=${DELETE_OLD:-true}
OLD_DAYS=${OLD_DAYS:-30}
TEMP_DIR=${TEMP_DIR:-"Temp"}

# Function to configure settings
configure_settings() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m     ⚙️ DOWNLOADS ORGANIZER SETTINGS    \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Current settings:"
    info "Downloads directory: $DOWNLOADS_DIR"
    info "Organize installers: $ORGANIZE_INSTALLERS"
    info "Organize images: $ORGANIZE_IMAGES"
    info "Organize documents: $ORGANIZE_DOCUMENTS"
    info "Organize archives: $ORGANIZE_ARCHIVES"
    info "Organize code files: $ORGANIZE_CODE"
    info "Delete old files: $DELETE_OLD"
    info "Days to keep files before deletion: $OLD_DAYS"
    info "Temporary directory: $TEMP_DIR"
    echo ""
    
    # Ask for new downloads directory
    read -p "Enter downloads directory [$DOWNLOADS_DIR]: " new_downloads_dir
    new_downloads_dir=${new_downloads_dir:-$DOWNLOADS_DIR}
    
    # Update config with new settings
    if [ "$new_downloads_dir" != "$DOWNLOADS_DIR" ]; then
        if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
            sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$new_downloads_dir\"|" "$CONFIG_FILE"
        else
            echo "DOWNLOADS_DIR=\"$new_downloads_dir\"" >> "$CONFIG_FILE"
        fi
        DOWNLOADS_DIR="$new_downloads_dir"
        success "Downloads directory updated to: $DOWNLOADS_DIR"
    fi
    
    # Ask for organizing preferences
    read -p "Organize installer files (exe, msi, etc.)? (true/false) [$ORGANIZE_INSTALLERS]: " new_organize_installers
    new_organize_installers=${new_organize_installers:-$ORGANIZE_INSTALLERS}
    
    if [ "$new_organize_installers" != "$ORGANIZE_INSTALLERS" ]; then
        if grep -q "ORGANIZE_INSTALLERS=" "$CONFIG_FILE"; then
            sed -i "s/ORGANIZE_INSTALLERS=.*/ORGANIZE_INSTALLERS=$new_organize_installers/" "$CONFIG_FILE"
        else
            echo "ORGANIZE_INSTALLERS=$new_organize_installers" >> "$CONFIG_FILE"
        fi
        ORGANIZE_INSTALLERS="$new_organize_installers"
        success "Organize installers updated to: $ORGANIZE_INSTALLERS"
    fi
    
    read -p "Organize image files (jpg, png, etc.)? (true/false) [$ORGANIZE_IMAGES]: " new_organize_images
    new_organize_images=${new_organize_images:-$ORGANIZE_IMAGES}
    
    if [ "$new_organize_images" != "$ORGANIZE_IMAGES" ]; then
        if grep -q "ORGANIZE_IMAGES=" "$CONFIG_FILE"; then
            sed -i "s/ORGANIZE_IMAGES=.*/ORGANIZE_IMAGES=$new_organize_images/" "$CONFIG_FILE"
        else
            echo "ORGANIZE_IMAGES=$new_organize_images" >> "$CONFIG_FILE"
        fi
        ORGANIZE_IMAGES="$new_organize_images"
        success "Organize images updated to: $ORGANIZE_IMAGES"
    fi
    
    read -p "Organize document files (pdf, docx, etc.)? (true/false) [$ORGANIZE_DOCUMENTS]: " new_organize_documents
    new_organize_documents=${new_organize_documents:-$ORGANIZE_DOCUMENTS}
    
    if [ "$new_organize_documents" != "$ORGANIZE_DOCUMENTS" ]; then
        if grep -q "ORGANIZE_DOCUMENTS=" "$CONFIG_FILE"; then
            sed -i "s/ORGANIZE_DOCUMENTS=.*/ORGANIZE_DOCUMENTS=$new_organize_documents/" "$CONFIG_FILE"
        else
            echo "ORGANIZE_DOCUMENTS=$new_organize_documents" >> "$CONFIG_FILE"
        fi
        ORGANIZE_DOCUMENTS="$new_organize_documents"
        success "Organize documents updated to: $ORGANIZE_DOCUMENTS"
    fi
    
    read -p "Organize archive files (zip, rar, etc.)? (true/false) [$ORGANIZE_ARCHIVES]: " new_organize_archives
    new_organize_archives=${new_organize_archives:-$ORGANIZE_ARCHIVES}
    
    if [ "$new_organize_archives" != "$ORGANIZE_ARCHIVES" ]; then
        if grep -q "ORGANIZE_ARCHIVES=" "$CONFIG_FILE"; then
            sed -i "s/ORGANIZE_ARCHIVES=.*/ORGANIZE_ARCHIVES=$new_organize_archives/" "$CONFIG_FILE"
        else
            echo "ORGANIZE_ARCHIVES=$new_organize_archives" >> "$CONFIG_FILE"
        fi
        ORGANIZE_ARCHIVES="$new_organize_archives"
        success "Organize archives updated to: $ORGANIZE_ARCHIVES"
    fi
    
    read -p "Organize code files (js, py, etc.)? (true/false) [$ORGANIZE_CODE]: " new_organize_code
    new_organize_code=${new_organize_code:-$ORGANIZE_CODE}
    
    if [ "$new_organize_code" != "$ORGANIZE_CODE" ]; then
        if grep -q "ORGANIZE_CODE=" "$CONFIG_FILE"; then
            sed -i "s/ORGANIZE_CODE=.*/ORGANIZE_CODE=$new_organize_code/" "$CONFIG_FILE"
        else
            echo "ORGANIZE_CODE=$new_organize_code" >> "$CONFIG_FILE"
        fi
        ORGANIZE_CODE="$new_organize_code"
        success "Organize code files updated to: $ORGANIZE_CODE"
    fi
    
    # Ask about cleanup settings
    read -p "Enable automatic cleanup of old files? (true/false) [$DELETE_OLD]: " new_delete_old
    new_delete_old=${new_delete_old:-$DELETE_OLD}
    
    if [ "$new_delete_old" != "$DELETE_OLD" ]; then
        if grep -q "DELETE_OLD=" "$CONFIG_FILE"; then
            sed -i "s/DELETE_OLD=.*/DELETE_OLD=$new_delete_old/" "$CONFIG_FILE"
        else
            echo "DELETE_OLD=$new_delete_old" >> "$CONFIG_FILE"
        fi
        DELETE_OLD="$new_delete_old"
        success "Delete old files updated to: $DELETE_OLD"
    fi
    
    if [ "$DELETE_OLD" = true ]; then
        read -p "How many days to keep files before cleanup? [$OLD_DAYS]: " new_old_days
        new_old_days=${new_old_days:-$OLD_DAYS}
        
        if [ "$new_old_days" != "$OLD_DAYS" ]; then
            if grep -q "OLD_DAYS=" "$CONFIG_FILE"; then
                sed -i "s/OLD_DAYS=.*/OLD_DAYS=$new_old_days/" "$CONFIG_FILE"
            else
                echo "OLD_DAYS=$new_old_days" >> "$CONFIG_FILE"
            fi
            OLD_DAYS="$new_old_days"
            success "Days to keep files updated to: $OLD_DAYS"
        fi
        
        read -p "Enter temporary directory name [$TEMP_DIR]: " new_temp_dir
        new_temp_dir=${new_temp_dir:-$TEMP_DIR}
        
        if [ "$new_temp_dir" != "$TEMP_DIR" ]; then
            if grep -q "TEMP_DIR=" "$CONFIG_FILE"; then
                sed -i "s/TEMP_DIR=.*/TEMP_DIR=\"$new_temp_dir\"/" "$CONFIG_FILE"
            else
                echo "TEMP_DIR=\"$new_temp_dir\"" >> "$CONFIG_FILE"
            fi
            TEMP_DIR="$new_temp_dir"
            success "Temporary directory updated to: $TEMP_DIR"
        fi
    fi
    
    success "Downloads organizer configuration updated"
    return 0
}

# Function to move files
move_files() {
    local pattern="$1"
    local destination="$2"
    local count=0
    
    # Check if destination exists, create if not
    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
        info "Created directory: $destination"
    fi
    
    # Find files matching pattern
    find "$DOWNLOADS_DIR" -maxdepth 1 -type f -name "$pattern" | while read file; do
        # Skip if file is in a subdirectory (this should never happen with -maxdepth 1)
        if [[ "$(dirname "$file")" != "$DOWNLOADS_DIR" ]]; then
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
        if [ $? -eq 0 ]; then
            count=$((count + 1))
            log "Moved: $filename to $(basename "$destination")"
        else
            warning "Failed to move: $filename"
        fi
    done
    
    if [ $count -gt 0 ]; then
        success "Moved $count files to $(basename "$destination")"
    fi
    
    return $count
}

# Function to clean old files
clean_old_files() {
    if [ "$DELETE_OLD" != "true" ]; then
        info "Automatic cleanup is disabled"
        return 0
    fi
    
    local temp_dir="$DOWNLOADS_DIR/$TEMP_DIR"
    
    # Check if temp directory exists, create if not
    if [ ! -d "$temp_dir" ]; then
        mkdir -p "$temp_dir"
        info "Created temporary directory: $temp_dir"
        return 0
    fi
    
    info "Checking for old files in $TEMP_DIR directory..."
    
    # Count old files
    local old_files_count=0
    if [ "$PLATFORM" == "macos" ]; then
        # macOS uses different find syntax
        old_files_count=$(find "$temp_dir" -type f -mtime +$OLD_DAYS | wc -l)
    else
        # Linux/WSL syntax
        old_files_count=$(find "$temp_dir" -type f -mtime +$OLD_DAYS | wc -l)
    fi
    
    if [ $old_files_count -eq 0 ]; then
        info "No old files to clean up"
        return 0
    fi
    
    info "Found $old_files_count old file(s) to clean up"
    
    # Delete old files
    if [ "$PLATFORM" == "macos" ]; then
        # macOS uses different find syntax
        find "$temp_dir" -type f -mtime +$OLD_DAYS -delete
    else
        # Linux/WSL syntax
        find "$temp_dir" -type f -mtime +$OLD_DAYS -delete
    fi
    
    success "Removed old files from $TEMP_DIR directory"
    return 0
}

# Function to organize downloads
organize_downloads() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      🗂️ DOWNLOADS ORGANIZATION         \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Check if downloads directory exists
    if [ ! -d "$DOWNLOADS_DIR" ]; then
        error "Downloads directory not found: $DOWNLOADS_DIR"
        
        # Try to find the Downloads directory
        if [ "$PLATFORM" == "wsl" ]; then
            info "Trying to locate the Downloads directory in Windows..."
            
            # Try to get Windows username more robustly
            WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
            if [ -n "$WIN_USER" ] && [[ ! "$WIN_USER" == *"%" ]]; then
                POTENTIAL_PATH="/mnt/c/Users/$WIN_USER/Downloads"
                if [ -d "$POTENTIAL_PATH" ]; then
                    info "Found Downloads directory at $POTENTIAL_PATH"
                    read -p "Do you want to use this directory? (y/n) [y]: " use_potential
                    use_potential=${use_potential:-"y"}
                    
                    if [[ "$use_potential" =~ ^[Yy]$ ]]; then
                        DOWNLOADS_DIR="$POTENTIAL_PATH"
                        # Update config
                        if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
                            sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"|" "$CONFIG_FILE"
                        else
                            echo "DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"" >> "$CONFIG_FILE"
                        fi
                        success "Downloads directory updated to: $DOWNLOADS_DIR"
                    else
                        read -p "Enter the correct downloads directory path: " new_downloads_dir
                        if [ -d "$new_downloads_dir" ]; then
                            DOWNLOADS_DIR="$new_downloads_dir"
                            # Update config
                            if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
                                sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"|" "$CONFIG_FILE"
                            else
                                echo "DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"" >> "$CONFIG_FILE"
                            fi
                            success "Downloads directory updated to: $DOWNLOADS_DIR"
                        else
                            error "Directory not found: $new_downloads_dir"
                            return 1
                        fi
                    fi
                else
                    error "Could not find Windows Downloads directory"
                    read -p "Enter the correct downloads directory path: " new_downloads_dir
                    if [ -d "$new_downloads_dir" ]; then
                        DOWNLOADS_DIR="$new_downloads_dir"
                        # Update config
                        if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
                            sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"|" "$CONFIG_FILE"
                        else
                            echo "DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"" >> "$CONFIG_FILE"
                        fi
                        success "Downloads directory updated to: $DOWNLOADS_DIR"
                    else
                        error "Directory not found: $new_downloads_dir"
                        return 1
                    fi
                fi
            else
                error "Could not determine Windows username"
                read -p "Enter the correct downloads directory path: " new_downloads_dir
                if [ -d "$new_downloads_dir" ]; then
                    DOWNLOADS_DIR="$new_downloads_dir"
                    # Update config
                    if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
                        sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"|" "$CONFIG_FILE"
                    else
                        echo "DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"" >> "$CONFIG_FILE"
                    fi
                    success "Downloads directory updated to: $DOWNLOADS_DIR"
                else
                    error "Directory not found: $new_downloads_dir"
                    return 1
                fi
            fi
        else
            error "Please check your Downloads directory path"
            read -p "Enter the correct downloads directory path: " new_downloads_dir
            if [ -d "$new_downloads_dir" ]; then
                DOWNLOADS_DIR="$new_downloads_dir"
                # Update config
                if grep -q "DOWNLOADS_DIR=" "$CONFIG_FILE"; then
                    sed -i "s|DOWNLOADS_DIR=.*|DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"|" "$CONFIG_FILE"
                else
                    echo "DOWNLOADS_DIR=\"$DOWNLOADS_DIR\"" >> "$CONFIG_FILE"
                fi
                success "Downloads directory updated to: $DOWNLOADS_DIR"
            else
                error "Directory not found: $new_downloads_dir"
                return 1
            fi
        fi
    fi
    
    info "Starting Downloads organization for: $DOWNLOADS_DIR"
    
    # Organize installers
    if [ "$ORGANIZE_INSTALLERS" = true ]; then
        info "Organizing installers..."
        move_files "*.exe" "$DOWNLOADS_DIR/Installers"
        move_files "*.msi" "$DOWNLOADS_DIR/Installers"
        move_files "*.appx" "$DOWNLOADS_DIR/Installers"
        move_files "*.appxbundle" "$DOWNLOADS_DIR/Installers"
        move_files "*.msixbundle" "$DOWNLOADS_DIR/Installers"
        move_files "*.deb" "$DOWNLOADS_DIR/Installers"
        move_files "*.rpm" "$DOWNLOADS_DIR/Installers"
        move_files "*.pkg" "$DOWNLOADS_DIR/Installers"
        move_files "*.dmg" "$DOWNLOADS_DIR/Installers"
    fi
    
    # Organize images
    if [ "$ORGANIZE_IMAGES" = true ]; then
        info "Organizing images..."
        move_files "*.jpg" "$DOWNLOADS_DIR/Images"
        move_files "*.jpeg" "$DOWNLOADS_DIR/Images"
        move_files "*.png" "$DOWNLOADS_DIR/Images"
        move_files "*.gif" "$DOWNLOADS_DIR/Images"
        move_files "*.bmp" "$DOWNLOADS_DIR/Images"
        move_files "*.svg" "$DOWNLOADS_DIR/Images"
        move_files "*.webp" "$DOWNLOADS_DIR/Images"
        move_files "*.tiff" "$DOWNLOADS_DIR/Images"
        move_files "*.ico" "$DOWNLOADS_DIR/Images"
    fi
    
    # Organize documents
    if [ "$ORGANIZE_DOCUMENTS" = true ]; then
        info "Organizing documents..."
        move_files "*.pdf" "$DOWNLOADS_DIR/Documents"
        move_files "*.doc" "$DOWNLOADS_DIR/Documents"
        move_files "*.docx" "$DOWNLOADS_DIR/Documents"
        move_files "*.xls" "$DOWNLOADS_DIR/Documents"
        move_files "*.xlsx" "$DOWNLOADS_DIR/Documents"
        move_files "*.ppt" "$DOWNLOADS_DIR/Documents"
        move_files "*.pptx" "$DOWNLOADS_DIR/Documents"
        move_files "*.txt" "$DOWNLOADS_DIR/Documents"
        move_files "*.rtf" "$DOWNLOADS_DIR/Documents"
        move_files "*.odt" "$DOWNLOADS_DIR/Documents"
        move_files "*.ods" "$DOWNLOADS_DIR/Documents"
        move_files "*.odp" "$DOWNLOADS_DIR/Documents"
        move_files "*.md" "$DOWNLOADS_DIR/Documents"
        move_files "*.epub" "$DOWNLOADS_DIR/Documents"
    fi
    
    # Organize archives
    if [ "$ORGANIZE_ARCHIVES" = true ]; then
        info "Organizing archives..."
        move_files "*.zip" "$DOWNLOADS_DIR/Archives"
        move_files "*.rar" "$DOWNLOADS_DIR/Archives"
        move_files "*.7z" "$DOWNLOADS_DIR/Archives"
        move_files "*.tar" "$DOWNLOADS_DIR/Archives"
        move_files "*.tar.gz" "$DOWNLOADS_DIR/Archives"
        move_files "*.tgz" "$DOWNLOADS_DIR/Archives"
        move_files "*.gz" "$DOWNLOADS_DIR/Archives"
        move_files "*.bz2" "$DOWNLOADS_DIR/Archives"
        move_files "*.xz" "$DOWNLOADS_DIR/Archives"
    fi
    
    # Organize code files
    if [ "$ORGANIZE_CODE" = true ]; then
        info "Organizing code files..."
        move_files "*.py" "$DOWNLOADS_DIR/Code"
        move_files "*.js" "$DOWNLOADS_DIR/Code"
        move_files "*.html" "$DOWNLOADS_DIR/Code"
        move_files "*.css" "$DOWNLOADS_DIR/Code"
        move_files "*.java" "$DOWNLOADS_DIR/Code"
        move_files "*.c" "$DOWNLOADS_DIR/Code"
        move_files "*.cpp" "$DOWNLOADS_DIR/Code"
        move_files "*.h" "$DOWNLOADS_DIR/Code"
        move_files "*.sh" "$DOWNLOADS_DIR/Code"
        move_files "*.rb" "$DOWNLOADS_DIR/Code"
        move_files "*.php" "$DOWNLOADS_DIR/Code"
        move_files "*.go" "$DOWNLOADS_DIR/Code"
        move_files "*.rs" "$DOWNLOADS_DIR/Code"
        move_files "*.ts" "$DOWNLOADS_DIR/Code"
        move_files "*.json" "$DOWNLOADS_DIR/Code"
        move_files "*.xml" "$DOWNLOADS_DIR/Code"
        move_files "*.yml" "$DOWNLOADS_DIR/Code"
        move_files "*.yaml" "$DOWNLOADS_DIR/Code"
    fi
    
    # Clean old files
    if [ "$DELETE_OLD" = true ]; then
        clean_old_files
    fi
    
    success "Downloads organization completed"
    return 0
}

# Function to create scheduling scripts
create_scheduling_scripts() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m       📅 SCHEDULE DOWNLOADS ORGANIZER  \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Setting up scripts for automated downloads organization..."
    
    # Create script directory if it doesn't exist
    mkdir -p "$HOME/.dev-setup/modules"
    
    # Create a standalone script that can be called directly
    ORGANIZER_SCRIPT="$HOME/.dev-setup/modules/run_downloads_organizer.sh"
    
    cat > "$ORGANIZER_SCRIPT" << EOF
#!/bin/bash
# Standalone Downloads Organizer
# This script is automatically generated and can be scheduled

# Load configuration
CONFIG_FILE="$CONFIG_FILE"
if [ -f "\$CONFIG_FILE" ]; then
    source "\$CONFIG_FILE"
fi

# Run the main organizer module with config
"$HOME/.dev-setup/modules/downloads_organizer.sh" "\$CONFIG_FILE"
EOF
    
    chmod +x "$ORGANIZER_SCRIPT"
    success "Standalone script created at: $ORGANIZER_SCRIPT"
    
    # Platform-specific scheduling
    if [ "$PLATFORM" == "wsl" ]; then
        # Create a batch file for Windows Task Scheduler
        BATCH_FILE="$HOME/.dev-setup/modules/run_downloads_organizer.bat"
        
        cat > "$BATCH_FILE" << EOF
@echo off
:: Run Downloads Organizer script via WSL
wsl bash -c "$ORGANIZER_SCRIPT"
EOF
        
        success "Windows batch file created at: $BATCH_FILE"
        
        # Create PowerShell script for Task Scheduler
        PS_SCRIPT="$HOME/.dev-setup/modules/schedule_downloads_organizer.ps1"
        
        cat > "$PS_SCRIPT" << 'EOL'
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
    
    # Find WSL distribution name
    $wslCommand = "wsl.exe"
    $wslDistro = wsl.exe -l | Select-String -Pattern "Ubuntu" | ForEach-Object { $_.ToString().Trim() }
    
    if (-not $wslDistro) {
        $wslDistro = Read-Host "Enter your WSL distribution name (e.g., Ubuntu-20.04)"
    }
    
    # Get script path in WSL
    $scriptPath = "\\wsl$\$wslDistro\home\$env:USERNAME\.dev-setup\modules\run_downloads_organizer.bat"
    
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
        
        success "PowerShell script created at: $PS_SCRIPT"
        info "To schedule the task, run this in Windows PowerShell as Administrator:"
        info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\schedule_downloads_organizer.ps1\""
        
    elif command -v crontab &> /dev/null; then
        # Use crontab for Linux/macOS
        info "Setting up cron job for automatic downloads organization"
        
        read -p "How often do you want to run the organizer? (daily/weekly) [daily]: " organizer_frequency
        organizer_frequency=${organizer_frequency:-"daily"}
        
        case $organizer_frequency in
            daily)
                # Daily at 3 AM
                cron_schedule="0 3 * * *"
                ;;
            weekly)
                # Weekly on Sunday at 3 AM
                cron_schedule="0 3 * * 0"
                ;;
            *)
                warning "Invalid frequency, defaulting to daily"
                cron_schedule="0 3 * * *"
                ;;
        esac
        
        # Add to crontab
        (crontab -l 2>/dev/null || echo "") | grep -v "run_downloads_organizer.sh" | { cat; echo "$cron_schedule $ORGANIZER_SCRIPT > $HOME/.dev-setup/logs/downloads_organizer_cron.log 2>&1"; } | crontab -
        
        if [ $? -eq 0 ]; then
            success "Downloads organizer scheduled via crontab: $organizer_frequency"
            info "Schedule: $cron_schedule"
        else
            error "Failed to schedule downloads organizer via crontab"
            return 1
        fi
    else
        warning "Could not find a suitable scheduling method for your platform"
        info "You'll need to schedule the organizer manually"
        return 1
    fi
    
    return 0
}

# Main menu function
show_organizer_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      🗂️ DOWNLOADS ORGANIZER            \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    echo "Please select an option:"
    echo "1. Configure organizer settings"
    echo "2. Organize downloads now"
    echo "3. Schedule automatic organization"
    echo "4. Complete setup (all of the above)"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-4]: " menu_choice
    
    case $menu_choice in
        1) configure_settings ;;
        2) organize_downloads ;;
        3) create_scheduling_scripts ;;
        4)
            configure_settings
            organize_downloads
            create_scheduling_scripts
            ;;
        0) exit 0 ;;
        *)
            warning "Invalid option. Please try again."
            show_organizer_menu
            ;;
    esac
    
    # Return to menu after function completes
    read -p "Press Enter to return to the main menu..."
    show_organizer_menu
}

# Main execution starts here
show_organizer_menu