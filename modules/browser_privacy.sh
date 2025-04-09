#!/bin/bash
# Browser & Privacy Optimizer Module
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

# Default browser preferences
DEFAULT_BROWSER=${DEFAULT_BROWSER:-"brave"}
DEFAULT_SEARCH=${DEFAULT_SEARCH:-"google"}

# Setup logging
LOG_FILE="$HOME/.dev-setup/logs/browser_privacy_$(date +%Y-%m-%d_%H-%M-%S).log"
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

# Function to check for network availability
check_network() {
    if ping -c 1 google.com &> /dev/null; then
        return 0
    else
        error "Network connectivity issue. Please check your internet connection."
        return 1
    fi
}

# Function to retry a command
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

# Function to install browsers
install_browsers() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m          🌐 BROWSER SETUP             \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    # Ask which browsers to install
    echo "Select browsers to install:"
    echo "1. Brave Browser"
    echo "2. Firefox"
    echo "3. Google Chrome"
    echo "4. Microsoft Edge"
    echo "5. All of the above"
    echo "0. Skip browser installation"
    echo ""
    read -p "Enter your choices (comma-separated, e.g., 1,2,3): " browser_choices
    
    # If user selects all
    if [[ "$browser_choices" == "5" ]]; then
        browser_choices="1,2,3,4"
    fi
    
    # Skip if user selects 0
    if [[ "$browser_choices" == "0" ]]; then
        return 0
    fi
    
    # Make sure we have network
    if ! check_network; then
        error "Network connectivity is required for browser installation."
        return 1
    fi
    
    # Convert comma-separated string to array
    IFS=',' read -ra selected_browsers <<< "$browser_choices"
    
    # macOS-specific handling
    if [ "$PLATFORM" == "macos" ]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            info "Homebrew is required for browser installation on macOS."
            read -p "Do you want to install Homebrew? (y/n) [y]: " install_homebrew
            install_homebrew=${install_homebrew:-"y"}
            
            if [[ "$install_homebrew" =~ ^[Yy]$ ]]; then
                info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [ $? -ne 0 ]; then
                    error "Failed to install Homebrew. Please install it manually."
                    return 1
                fi
            else
                warning "Skipping browser installation as Homebrew is required."
                return 1
            fi
        fi
        
        # Install selected browsers with Homebrew
        for choice in "${selected_browsers[@]}"; do
            case $choice in
                1)
                    info "Installing Brave Browser..."
                    brew install --cask brave-browser
                    if [ $? -eq 0 ]; then success "Brave Browser installed"; else warning "Failed to install Brave Browser"; fi
                    ;;
                2)
                    info "Installing Firefox..."
                    brew install --cask firefox
                    if [ $? -eq 0 ]; then success "Firefox installed"; else warning "Failed to install Firefox"; fi
                    ;;
                3)
                    info "Installing Google Chrome..."
                    brew install --cask google-chrome
                    if [ $? -eq 0 ]; then success "Google Chrome installed"; else warning "Failed to install Google Chrome"; fi
                    ;;
                4)
                    info "Installing Microsoft Edge..."
                    brew install --cask microsoft-edge
                    if [ $? -eq 0 ]; then success "Microsoft Edge installed"; else warning "Failed to install Microsoft Edge"; fi
                    ;;
                *)
                    warning "Invalid browser option: $choice. Skipping."
                    ;;
            esac
        done
    # WSL-specific handling
    elif [ "$PLATFORM" == "wsl" ]; then
        info "For WSL, we'll create a PowerShell script to install browsers in Windows."
        
        # Create PowerShell script
        PS_SCRIPT="$HOME/.dev-setup/modules/install_browsers.ps1"
        
        # Start with a basic script header
        cat > "$PS_SCRIPT" << 'EOL'
# Browser Installation Script for Windows
# Run this with PowerShell as Administrator

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

# Check if winget is available
try {
    $wingetVersion = winget --version
    Write-Host "Winget is available: $wingetVersion" -ForegroundColor Green
}
catch {
    Write-Host "Winget is not available. Please install the App Installer from the Microsoft Store." -ForegroundColor Red
    exit 1
}

Write-Host "Starting browser installation..." -ForegroundColor Cyan

EOL
        
        # Add browser installation commands based on user selection
        for choice in "${selected_browsers[@]}"; do
            case $choice in
                1)
                    echo 'Write-Host "Installing Brave Browser..." -ForegroundColor Cyan' >> "$PS_SCRIPT"
                    echo 'winget install BraveSoftware.BraveBrowser --accept-source-agreements --accept-package-agreements -s winget' >> "$PS_SCRIPT"
                    echo 'if ($LASTEXITCODE -eq 0) { Write-Host "Brave Browser installed successfully" -ForegroundColor Green } else { Write-Host "Failed to install Brave Browser" -ForegroundColor Red }' >> "$PS_SCRIPT"
                    ;;
                2)
                    echo 'Write-Host "Installing Firefox..." -ForegroundColor Cyan' >> "$PS_SCRIPT"
                    echo 'winget install Mozilla.Firefox --accept-source-agreements --accept-package-agreements -s winget' >> "$PS_SCRIPT"
                    echo 'if ($LASTEXITCODE -eq 0) { Write-Host "Firefox installed successfully" -ForegroundColor Green } else { Write-Host "Failed to install Firefox" -ForegroundColor Red }' >> "$PS_SCRIPT"
                    ;;
                3)
                    echo 'Write-Host "Installing Google Chrome..." -ForegroundColor Cyan' >> "$PS_SCRIPT"
                    echo 'winget install Google.Chrome --accept-source-agreements --accept-package-agreements -s winget' >> "$PS_SCRIPT"
                    echo 'if ($LASTEXITCODE -eq 0) { Write-Host "Google Chrome installed successfully" -ForegroundColor Green } else { Write-Host "Failed to install Google Chrome" -ForegroundColor Red }' >> "$PS_SCRIPT"
                    ;;
                4)
                    echo 'Write-Host "Installing Microsoft Edge..." -ForegroundColor Cyan' >> "$PS_SCRIPT"
                    echo 'winget install Microsoft.Edge --accept-source-agreements --accept-package-agreements -s winget' >> "$PS_SCRIPT"
                    echo 'if ($LASTEXITCODE -eq 0) { Write-Host "Microsoft Edge installed successfully" -ForegroundColor Green } else { Write-Host "Failed to install Microsoft Edge" -ForegroundColor Red }' >> "$PS_SCRIPT"
                    ;;
                *)
                    warning "Invalid browser option: $choice. Skipping."
                    ;;
            esac
        done
        
        # Add script footer
        cat >> "$PS_SCRIPT" << 'EOL'
Write-Host "Browser installation completed!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
EOL
        
        success "PowerShell script created at: $PS_SCRIPT"
        info "To install browsers, run this in Windows PowerShell as Administrator:"
        info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\install_browsers.ps1\""
        
    # Linux-specific handling
    else
        for choice in "${selected_browsers[@]}"; do
            case $choice in
                1)
                    info "Installing Brave Browser..."
                    # Add Brave repository
                    sudo apt install -y apt-transport-https curl
                    curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
                    echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
                    sudo apt update
                    sudo apt install -y brave-browser
                    if [ $? -eq 0 ]; then success "Brave Browser installed"; else warning "Failed to install Brave Browser"; fi
                    ;;
                2)
                    info "Installing Firefox..."
                    sudo apt install -y firefox
                    if [ $? -eq 0 ]; then success "Firefox installed"; else warning "Failed to install Firefox"; fi
                    ;;
                3)
                    info "Installing Google Chrome..."
                    # Add Chrome repository
                    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
                    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
                    sudo apt update
                    sudo apt install -y google-chrome-stable
                    if [ $? -eq 0 ]; then success "Google Chrome installed"; else warning "Failed to install Google Chrome"; fi
                    ;;
                4)
                    info "Installing Microsoft Edge..."
                    # Add Edge repository
                    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
                    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
                    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
                    sudo rm microsoft.gpg
                    sudo apt update
                    sudo apt install -y microsoft-edge-stable
                    if [ $? -eq 0 ]; then success "Microsoft Edge installed"; else warning "Failed to install Microsoft Edge"; fi
                    ;;
                *)
                    warning "Invalid browser option: $choice. Skipping."
                    ;;
            esac
        done
    fi
    
    return 0
}

# Function to install browser extensions (create guidance script)
install_extensions() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      🧩 BROWSER EXTENSIONS SETUP       \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Browser extensions must be installed manually, but we'll create a guide for you."
    
    # Ask which extension categories to include
    echo "Select extension categories to include in the guide:"
    echo "1. Privacy & Security"
    echo "2. Development Tools"
    echo "3. Productivity"
    echo "4. All of the above"
    echo "0. Skip extensions guide"
    echo ""
    read -p "Enter your choices (comma-separated, e.g., 1,2,3): " extension_choices
    
    # If user selects all
    if [[ "$extension_choices" == "4" ]]; then
        extension_choices="1,2,3"
    fi
    
    # Skip if user selects 0
    if [[ "$extension_choices" == "0" ]]; then
        return 0
    fi
    
    # Create a guide markdown file
    GUIDE_FILE="$HOME/.dev-setup/browser_extensions_guide.md"
    
    cat > "$GUIDE_FILE" << 'EOL'
# Recommended Browser Extensions Guide

This guide lists recommended browser extensions organized by category. Click the links to install them in your browser.

EOL
    
    # Convert comma-separated string to array
    IFS=',' read -ra selected_categories <<< "$extension_choices"
    
    for category in "${selected_categories[@]}"; do
        case $category in
            1)
                cat >> "$GUIDE_FILE" << 'EOL'
## Privacy & Security Extensions

### uBlock Origin
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/)
- **Description**: Efficient wide-spectrum content blocker with low memory usage.

### Privacy Badger
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/privacy-badger/pkehgijcmpdhfbdbbnkijodmdjhbjlgp)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/privacy-badger17/)
- **Description**: Automatically learns to block invisible trackers.

### HTTPS Everywhere
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/https-everywhere/gcbommkclmclpchllfjekcdonpmejbdp)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/https-everywhere/)
- **Description**: Encrypts your communications with many websites by forcing HTTPS.

### Bitwarden
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/bitwarden-password-manager/)
- **Description**: Free and open-source password manager.

EOL
                ;;
            2)
                cat >> "$GUIDE_FILE" << 'EOL'
## Development Tools Extensions

### JSON Formatter
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/json-formatter/bcjindcccaagfpapjjmafapmmgkkhgoa)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/json-formatter/)
- **Description**: Makes JSON easy to read by formatting and syntax highlighting.

### React Developer Tools
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/react-devtools/)
- **Description**: Inspect the React component hierarchy, props, state, and more.

### Redux DevTools
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/redux-devtools/lmhkpmbekcpmknklioeibfkpmmfibljd)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/reduxdevtools/)
- **Description**: Debug application's state changes for Redux.

### Wappalyzer
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/wappalyzer-technology-pro/gppongmhjkpfnbhagpmjfkannfbllamg)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/wappalyzer/)
- **Description**: Identifies web technologies used on websites.

### GitHub Repository Size
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/github-repository-size/apnjnioapinblneaedefcnopcjepgkci)
- **Description**: Displays the size of repositories on GitHub.

EOL
                ;;
            3)
                cat >> "$GUIDE_FILE" << 'EOL'
## Productivity Extensions

### Dark Reader
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/darkreader/)
- **Description**: Dark mode for every website that cares about your eyes.

### Grammarly
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/grammarly-grammar-checker/kbfnbcaeplbcioakkpcpgfkobkghlhen)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/grammarly/)
- **Description**: Checks grammar, spelling, and punctuation.

### OneTab
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/onetab/chphlpgkkbolifaimnlloiipkdnihall)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/onetab/)
- **Description**: Save up to 95% memory and reduce tab clutter.

### Notion Web Clipper
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/notion-web-clipper/knheggckgoiihginacbkhaalnibhilkk)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/notion-web-clipper/)
- **Description**: Save anything on the web to Notion.

### Pocket
- **Chrome/Brave/Edge**: [Chrome Web Store](https://chrome.google.com/webstore/detail/save-to-pocket/niloccemoadcdkdjlinkgdfekeahmflj)
- **Firefox**: [Firefox Add-ons](https://addons.mozilla.org/en-US/firefox/addon/pocket/)
- **Description**: Save articles, videos, and stories from any publication, page, or app.

EOL
                ;;
            *)
                warning "Invalid category option: $category. Skipping."
                ;;
        esac
    done
    
    cat >> "$GUIDE_FILE" << 'EOL'

## Installation Instructions

1. Click on the link for your browser
2. Click "Add to [Browser]" button
3. Follow any additional prompts to complete installation

Some browsers may require additional permissions for certain extensions. You can always adjust extension permissions in your browser's extension settings.
EOL
    
    success "Browser extensions guide created at: $GUIDE_FILE"
    
    # Ask if user wants to open the guide now
    read -p "Do you want to open the guide now? (y/n) [y]: " open_guide
    open_guide=${open_guide:-"y"}
    
    if [[ "$open_guide" =~ ^[Yy]$ ]]; then
        # Try different methods to open the file
        if command -v xdg-open &> /dev/null; then
            xdg-open "$GUIDE_FILE"
        elif command -v open &> /dev/null; then
            open "$GUIDE_FILE"
        else
            info "Please open the guide manually at: $GUIDE_FILE"
        fi
    fi
    
    return 0
}

# Function to create privacy script for Windows
create_privacy_script() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      🔒 WINDOWS PRIVACY SETUP          \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        info "Windows privacy settings are only applicable to Windows/WSL platform."
        return 0
    fi
    
    info "Creating Windows privacy configuration script..."
    
    # Create PowerShell script
    PS_SCRIPT="$HOME/.dev-setup/modules/privacy_settings.ps1"
    
    cat > "$PS_SCRIPT" << 'EOL'
# Windows Privacy Configuration Script
# Run this with PowerShell as Administrator

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script needs to be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the PowerShell icon and select 'Run as administrator', then try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting Windows Privacy Configuration..." -ForegroundColor Cyan

# Function to set registry value
function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWORD"
    )
    
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    Write-Host "Set registry value: $Path\$Name = $Value" -ForegroundColor Green
}

# ======= Disable Telemetry =======
Write-Host "Disabling telemetry..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0

# ======= Disable Advertising ID =======
Write-Host "Disabling advertising ID..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0

# ======= Disable App Launch Tracking =======
Write-Host "Disabling app launch tracking..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0

# ======= Disable Suggestions =======
Write-Host "Disabling suggestions..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0

# ======= Disable Location Tracking =======
Write-Host "Disabling location tracking..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type "String"

# ======= Disable Feedback =======
Write-Host "Disabling feedback..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0

# ======= Disable Background Apps =======
Write-Host "Disabling background apps..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1

# ======= Disable Timeline =======
Write-Host "Disabling timeline..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0

# ======= Disable Diagnostics =======
Write-Host "Disabling diagnostics..." -ForegroundColor Yellow
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1

# ======= Download O&O ShutUp10 =======
Write-Host "Downloading O&O ShutUp10++..." -ForegroundColor Yellow
$shutupUrl = "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe"
$shutupPath = "$env:TEMP\OOSU10.exe"

try {
    Invoke-WebRequest -Uri $shutupUrl -OutFile $shutupPath -ErrorAction Stop
    Write-Host "O&O ShutUp10++ downloaded. You can run it manually to apply additional privacy settings." -ForegroundColor Green
    Write-Host "Path: $shutupPath" -ForegroundColor Cyan
}
catch {
    Write-Host "Failed to download O&O ShutUp10++: $_" -ForegroundColor Red
    Write-Host "You can download it manually from: https://www.oo-software.com/en/shutup10" -ForegroundColor Yellow
}

Write-Host "Windows Privacy Configuration Completed!" -ForegroundColor Green
Write-Host "Some settings may require a system restart to take effect." -ForegroundColor Yellow

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
EOL
    
    success "PowerShell script created at: $PS_SCRIPT"
    info "To apply privacy settings, run this in Windows PowerShell as Administrator:"
    info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\privacy_settings.ps1\""
    
    return 0
}

# Function to configure browser settings
configure_default_browser() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m     🔄 DEFAULT BROWSER SETUP           \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" == "wsl" ]; then
        info "For WSL, you need to set the default browser in Windows settings."
        info "Opening Windows Settings > Default Apps..."
        cmd.exe /c start "" ms-settings:defaultapps
        return 0
    fi
    
    info "Configuring default browser settings..."
    
    # Show current default browser preference
    info "Current default browser preference: $DEFAULT_BROWSER"
    
    # Ask for new default browser preference
    echo "Select default browser:"
    echo "1. Brave Browser"
    echo "2. Firefox"
    echo "3. Google Chrome"
    echo "4. Microsoft Edge"
    echo "0. Skip default browser configuration"
    echo ""
    read -p "Enter your choice [0-4]: " browser_choice
    
    case $browser_choice in
        1) new_browser="brave" ;;
        2) new_browser="firefox" ;;
        3) new_browser="chrome" ;;
        4) new_browser="edge" ;;
        0) return 0 ;;
        *) 
            warning "Invalid choice. Skipping."
            return 1
            ;;
    esac
    
    # Update the config file
    if grep -q "DEFAULT_BROWSER=" "$CONFIG_FILE"; then
        sed -i "s/DEFAULT_BROWSER=.*/DEFAULT_BROWSER=\"$new_browser\"/" "$CONFIG_FILE"
    else
        echo "DEFAULT_BROWSER=\"$new_browser\"" >> "$CONFIG_FILE"
    fi
    
    success "Default browser preference updated to: $new_browser"
    
    if [ "$PLATFORM" == "macos" ]; then
        info "For macOS, you need to set the default browser in System Preferences."
        info "Opening System Preferences > General..."
        open "/System/Library/PreferencePanes/General.prefPane"
    elif [ "$PLATFORM" == "linux" ]; then
        # Check for xdg-settings
        if command -v xdg-settings &> /dev/null; then
            info "Setting default browser using xdg-settings..."
            case $new_browser in
                brave) xdg-settings set default-web-browser brave-browser.desktop ;;
                firefox) xdg-settings set default-web-browser firefox.desktop ;;
                chrome) xdg-settings set default-web-browser google-chrome.desktop ;;
                edge) xdg-settings set default-web-browser microsoft-edge.desktop ;;
            esac
            
            if [ $? -eq 0 ]; then
                success "Default browser set to $new_browser"
            else
                warning "Failed to set default browser. Please set it manually in your desktop environment settings."
            fi
        else
            info "xdg-settings not found. Please set the default browser manually in your desktop environment settings."
        fi
    fi
    
    return 0
}

# Function to configure default search engine
configure_search_engine() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m    🔍 SEARCH ENGINE CONFIGURATION      \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    info "Search engines must be configured manually in your browser."
    info "Here's a guide for setting up your preferred search engine:"
    
    # Show current default search engine preference
    info "Current default search engine preference: $DEFAULT_SEARCH"
    
    # Ask for new default search engine preference
    echo "Select default search engine:"
    echo "1. Google"
    echo "2. DuckDuckGo"
    echo "3. Bing"
    echo "4. Brave Search"
    echo "0. Skip search engine configuration"
    echo ""
    read -p "Enter your choice [0-4]: " search_choice
    
    case $search_choice in
        1) new_search="google" ;;
        2) new_search="duckduckgo" ;;
        3) new_search="bing" ;;
        4) new_search="brave" ;;
        0) return 0 ;;
        *) 
            warning "Invalid choice. Skipping."
            return 1
            ;;
    esac
    
    # Update the config file
    if grep -q "DEFAULT_SEARCH=" "$CONFIG_FILE"; then
        sed -i "s/DEFAULT_SEARCH=.*/DEFAULT_SEARCH=\"$new_search\"/" "$CONFIG_FILE"
    else
        echo "DEFAULT_SEARCH=\"$new_search\"" >> "$CONFIG_FILE"
    fi
    
    success "Default search engine preference updated to: $new_search"
    
    # Create a guide for setting up the search engine
    GUIDE_FILE="$HOME/.dev-setup/search_engine_guide.md"
    
    cat > "$GUIDE_FILE" << EOL
# Setting Up ${new_search^} as Your Default Search Engine

This guide will help you set up ${new_search^} as your default search engine in different browsers.

## Brave Browser

1. Open Brave Browser
2. Click the menu button (three lines in the top-right corner)
3. Select "Settings"
4. In the left sidebar, click "Search engine"
5. Under "Search engine used in the address bar", select "${new_search^}"
6. If ${new_search^} is not in the list, you'll need to add it:
   - Scroll down to "Manage search engines"
   - Click "Add" and enter the following details:

EOL

    case $new_search in
        google)
            cat >> "$GUIDE_FILE" << 'EOL'
   - Search engine: Google
   - Keyword: google.com
   - URL with %s in place of query: https://www.google.com/search?q=%s
EOL
            ;;
        duckduckgo)
            cat >> "$GUIDE_FILE" << 'EOL'
   - Search engine: DuckDuckGo
   - Keyword: duckduckgo.com
   - URL with %s in place of query: https://duckduckgo.com/?q=%s
EOL
            ;;
        bing)
            cat >> "$GUIDE_FILE" << 'EOL'
   - Search engine: Bing
   - Keyword: bing.com
   - URL with %s in place of query: https://www.bing.com/search?q=%s
EOL
            ;;
        brave)
            cat >> "$GUIDE_FILE" << 'EOL'
   - Search engine: Brave Search
   - Keyword: search.brave.com
   - URL with %s in place of query: https://search.brave.com/search?q=%s
EOL
            ;;
    esac

    cat >> "$GUIDE_FILE" << 'EOL'

## Firefox

1. Open Firefox
2. Click the menu button (three lines in the top-right corner)
3. Select "Settings"
4. Scroll down to "Search" in the left sidebar
5. Under "Default Search Engine", select your preferred search engine
6. If your search engine is not in the list, you'll need to add it:
   - Scroll down to "One-Click Search Engines"
   - Click "Find more search engines" link
   - Search for your preferred engine and click "Add to Firefox"

## Google Chrome

1. Open Google Chrome
2. Click the menu button (three dots in the top-right corner)
3. Select "Settings"
4. In the left sidebar, click "Search engine"
5. Under "Search engine used in the address bar", select your preferred search engine
6. If your search engine is not in the list, you'll need to add it:
   - Click "Manage search engines and site search"
   - Click "Add" and enter the details as shown in the Brave Browser section

## Microsoft Edge

1. Open Microsoft Edge
2. Click the menu button (three dots in the top-right corner)
3. Select "Settings"
4. Click "Privacy, search, and services" in the left sidebar
5. Scroll down to "Services" and click "Address bar and search"
6. Under "Search engine used in the address bar", select your preferred search engine
7. If your search engine is not in the list, you'll need to add it:
   - Click "Manage search engines"
   - Click "Add" and enter the details as shown in the Brave Browser section

## Testing Your Configuration

After setting your default search engine, try these steps to verify it's working:
1. Open a new tab
2. Type a search term in the address bar and press Enter
3. Confirm that the search results come from your selected search engine
EOL

    success "Search engine guide created at: $GUIDE_FILE"
    
    # Ask if user wants to open the guide now
    read -p "Do you want to open the guide now? (y/n) [y]: " open_guide
    open_guide=${open_guide:-"y"}
    
    if [[ "$open_guide" =~ ^[Yy]$ ]]; then
        # Try different methods to open the file
        if command -v xdg-open &> /dev/null; then
            xdg-open "$GUIDE_FILE"
        elif command -v open &> /dev/null; then
            open "$GUIDE_FILE"
        else
            info "Please open the guide manually at: $GUIDE_FILE"
        fi
    fi
    
    return 0
}

# Main menu function
show_browser_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m      🌐 BROWSER & PRIVACY SETUP        \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    echo "Please select an option:"
    echo "1. Install browsers"
    echo "2. Setup browser extensions"
    echo "3. Configure Windows privacy settings"
    echo "4. Configure default browser"
    echo "5. Configure default search engine"
    echo "6. Complete setup (all of the above)"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-6]: " menu_choice
    
    case $menu_choice in
        1) install_browsers ;;
        2) install_extensions ;;
        3) create_privacy_script ;;
        4) configure_default_browser ;;
        5) configure_search_engine ;;
        6)
            install_browsers
            install_extensions
            create_privacy_script
            configure_default_browser
            configure_search_engine
            ;;
        0) exit 0 ;;
        *)
            warning "Invalid option. Please try again."
            show_browser_menu
            ;;
    esac
    
    # Return to menu after function completes
    read -p "Press Enter to return to the main menu..."
    show_browser_menu
}

# Main execution starts here
show_browser_menu