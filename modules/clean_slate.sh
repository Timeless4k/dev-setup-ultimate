#!/bin/bash
# Clean Slate Windows Configuration Module
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
LOG_FILE="$HOME/.dev-setup/logs/clean_slate_$(date +%Y-%m-%d_%H-%M-%S).log"
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

# Function to create the performance optimization script
create_performance_script() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m     🚀 WINDOWS PERFORMANCE OPTIMIZER   \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        warning "This module is designed for Windows with WSL. Your platform is $PLATFORM."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    info "Creating Windows Performance Optimization script..."
    
    # Create PowerShell script
    PS_SCRIPT="$HOME/.dev-setup/modules/performance_optimizer.ps1"
    
    cat > "$PS_SCRIPT" << 'EOL'
# Windows Performance Optimizer Script
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
    Write-Host "🚀 Starting Windows Performance Optimization..." -ForegroundColor Cyan

    # ======= Disable Unnecessary Services =======
    Write-Host "📋 Disabling unnecessary services..." -ForegroundColor Yellow
    $servicesToDisable = @(
        "DiagTrack",                  # Connected User Experiences and Telemetry
        "dmwappushservice",           # WAP Push Message Routing Service
        "SysMain",                    # Superfetch
        "WSearch",                    # Windows Search (disabling can improve performance)
        "lfsvc",                      # Geolocation Service
        "MapsBroker",                 # Downloaded Maps Manager
        "RetailDemo",                 # Retail Demo Service
        "XblAuthManager",             # Xbox Live Auth Manager
        "XblGameSave",                # Xbox Live Game Save
        "XboxNetApiSvc",              # Xbox Live Networking Service
        "WaaSMedicSvc",               # Windows Update Medic Service (can restart Windows Update)
        "PushToInstall",              # Windows PushToInstall Service
        "OneSyncSvc"                  # Sync Host Service
    )

    foreach ($service in $servicesToDisable) {
        $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($svc) {
            Write-Host "Disabling service: $service" -ForegroundColor Yellow
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

    # ======= Disable Visual Effects =======
    Write-Host "🎨 Optimizing visual effects for performance..." -ForegroundColor Yellow
    
    # Set visual effects to best performance
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    If (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "VisualFXSetting" -Value 2

    # Disable individual visual effects
    $regPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $regPath -Name "DragFullWindows" -Value 0
    Set-ItemProperty -Path $regPath -Name "MenuShowDelay" -Value 0
    Set-ItemProperty -Path $regPath -Name "UserPreferencesMask" -Value ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0x00, 0x00, 0x00))

    $regPath = "HKCU:\Control Panel\Desktop\WindowMetrics"
    Set-ItemProperty -Path $regPath -Name "MinAnimate" -Value 0

    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path $regPath -Name "ListviewAlphaSelect" -Value 0
    Set-ItemProperty -Path $regPath -Name "ListviewShadow" -Value 0
    Set-ItemProperty -Path $regPath -Name "TaskbarAnimations" -Value 0

    $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
    Set-ItemProperty -Path $regPath -Name "ShellState" -Value ([byte[]](0xB8, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0x00, 0x00, 0x00))

    # ======= Disable Hibernation =======
    Write-Host "💤 Disabling hibernation..." -ForegroundColor Yellow
    powercfg -h off

    # ======= Configure Power Settings =======
    Write-Host "⚡ Configuring power settings for performance..." -ForegroundColor Yellow
    
    # Balanced power scheme
    $powerScheme = "381b4222-f694-41f0-9685-ff5bb260df2e"
    powercfg /setactive $powerScheme
    
    # Never turn off display while plugged in
    powercfg /change monitor-timeout-ac 0
    
    # Never put computer to sleep while plugged in
    powercfg /change standby-timeout-ac 0
    
    # Set disk timeout to never while plugged in
    powercfg /change disk-timeout-ac 0
    
    # Set high performance for processors
    $processorGuid = "54533251-82be-4824-96c1-47b60b740d00"
    $perfPolicy = "0cc5b647-c1df-4637-891a-dec35c318583"
    powercfg /setacvalueindex $powerScheme $processorGuid $perfPolicy 0
    
    # ======= Configure Memory Management =======
    Write-Host "🧠 Optimizing memory management..." -ForegroundColor Yellow
    
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-ItemProperty -Path $regPath -Name "LargeSystemCache" -Value 0
    Set-ItemProperty -Path $regPath -Name "DisablePagingExecutive" -Value 1
    
    # ======= Optimize Network Settings =======
    Write-Host "🌐 Optimizing network settings..." -ForegroundColor Yellow
    
    # Enable NetDMA
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
    Set-ItemProperty -Path $regPath -Name "EnableTCPChimney" -Value 1
    Set-ItemProperty -Path $regPath -Name "EnableRSS" -Value 1
    
    # ======= Disable Windows Search Indexing =======
    Write-Host "🔍 Disabling Windows Search indexing..." -ForegroundColor Yellow
    
    $searchService = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
    if ($searchService) {
        Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    
        # Disable indexing on drives
        $drives = Get-PSDrive -PSProvider FileSystem
        foreach ($drive in $drives) {
            $indexingOptions = "$($drive.Root)"
            $indexing = New-Object -ComObject "CSearchManager"
            $catalog = $indexing.GetCatalog("SystemIndex")
            $manager = $catalog.GetCrawlScopeManager()
            $manager.RemoveRoot($indexingOptions)
            $manager.SaveAll()
        }
    }
    
    # ======= Optimize Drive Performance =======
    Write-Host "💿 Optimizing drive performance..." -ForegroundColor Yellow
    
    # Disable 8.3 filename creation for all drives
    fsutil behavior set disable8dot3 1
    
    # Disable last access timestamp for files
    fsutil behavior set disablelastaccess 1
    
    # ======= Disable Startup Programs =======
    Write-Host "🚀 Disabling unnecessary startup programs..." -ForegroundColor Yellow
    
    $startupItems = @(
        "OneDrive",
        "Spotify",
        "Microsoft Teams",
        "Skype",
        "Discord",
        "Slack"
    )
    
    foreach ($item in $startupItems) {
        $regPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
        $keys = Get-ItemProperty -Path $regPath | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match $item }
        
        foreach ($key in $keys) {
            if ($key) {
                Remove-ItemProperty -Path $regPath -Name $key.Name -ErrorAction SilentlyContinue
                Write-Host "Disabled startup item: $($key.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    # ======= Optimize Game Mode =======
    Write-Host "🎮 Optimizing Windows Game Mode..." -ForegroundColor Yellow
    
    $regPath = "HKCU:\Software\Microsoft\GameBar"
    If (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "AllowAutoGameMode" -Value 1
    Set-ItemProperty -Path $regPath -Name "AutoGameModeEnabled" -Value 1
    
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    If (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "AppCaptureEnabled" -Value 0
    
    # ======= Finalize =======
    Write-Host "🔄 Applying changes and cleaning up..." -ForegroundColor Yellow
    
    # Clean tmp files
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Run disk cleanup
    cleanmgr /sagerun:1

    Write-Host "✅ Windows Performance Optimization Complete!" -ForegroundColor Green
    Write-Host "🔍 Some changes may require a system restart to take full effect." -ForegroundColor Yellow
    
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL
    
    success "PowerShell script created at: $PS_SCRIPT"
    info "To run the performance optimizer, run this in Windows PowerShell as Administrator:"
    info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\performance_optimizer.ps1\""
    
    return 0
}

# Function to create the development environment setup script
create_dev_environment_script() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m     💻 WINDOWS DEV ENVIRONMENT SETUP   \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        warning "This module is designed for Windows with WSL. Your platform is $PLATFORM."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    info "Creating Windows Development Environment Setup script..."
    
    # Create PowerShell script
    PS_SCRIPT="$HOME/.dev-setup/modules/dev_environment_setup.ps1"
    
    cat > "$PS_SCRIPT" << 'EOL'
# Windows Development Environment Setup Script
# Run this with PowerShell as Administrator

$ErrorActionPreference = "Stop"
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())

# Check if running as Administrator
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script needs to be run as Administrator." -ForegroundColor Red
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

try {
    Write-Host "💻 Starting Windows Development Environment Setup..." -ForegroundColor Cyan

    # ======= Install Common Developer Tools =======
    Write-Host "🔧 Installing common developer tools..." -ForegroundColor Yellow
    
    $devTools = @(
        @{Name = "Git.Git"; Description = "Git version control system"},
        @{Name = "Microsoft.VisualStudioCode"; Description = "Visual Studio Code editor"},
        @{Name = "Microsoft.WindowsTerminal"; Description = "Windows Terminal"},
        @{Name = "Microsoft.PowerToys"; Description = "PowerToys for Windows"},
        @{Name = "7zip.7zip"; Description = "7-Zip file archiver"}
    )
    
    foreach ($tool in $devTools) {
        Write-Host "Installing $($tool.Description)..." -ForegroundColor Yellow
        winget install $tool.Name --accept-source-agreements --accept-package-agreements -s winget
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$($tool.Description) installed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Failed to install $($tool.Description)" -ForegroundColor Red
        }
    }
    
    # ======= Configure Windows Terminal =======
    Write-Host "⚙️ Configuring Windows Terminal..." -ForegroundColor Yellow
    
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if (Test-Path $terminalSettingsPath) {
        # Backup current settings
        Copy-Item -Path $terminalSettingsPath -Destination "$terminalSettingsPath.backup" -Force
        
        try {
            # Load current settings
            $terminalSettings = Get-Content -Path $terminalSettingsPath | ConvertFrom-Json
            
            # Set dark theme
            $terminalSettings.theme = "dark"
            
            # Set default profile to PowerShell
            $pwshProfile = $terminalSettings.profiles.list | Where-Object { $_.name -match "PowerShell" } | Select-Object -First 1
            if ($pwshProfile) {
                $terminalSettings.defaultProfile = $pwshProfile.guid
            }
            
            # Set appearance settings
            $terminalSettings | Add-Member -NotePropertyName "useAcrylicInTabRow" -NotePropertyValue $true -Force
            
            # Save changes
            $terminalSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $terminalSettingsPath
            
            Write-Host "Windows Terminal configured successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to configure Windows Terminal: $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Windows Terminal settings file not found. It will be created when you first run Windows Terminal." -ForegroundColor Yellow
    }
    
    # ======= Configure PowerToys =======
    Write-Host "⚙️ Configuring PowerToys..." -ForegroundColor Yellow
    
    $powerToysSettingsPath = "$env:LOCALAPPDATA\Microsoft\PowerToys\settings.json"
    $powerToysConfigured = $false
    
    # Wait a bit for PowerToys installation to complete
    Start-Sleep -Seconds 2
    
    if (Test-Path $powerToysSettingsPath) {
        # Backup current settings
        Copy-Item -Path $powerToysSettingsPath -Destination "$powerToysSettingsPath.backup" -Force
        
        try {
            # Load current settings
            $powerToysSettings = Get-Content -Path $powerToysSettingsPath | ConvertFrom-Json
            
            # FancyZones settings
            if ($powerToysSettings.fancyzones) {
                $powerToysSettings.fancyzones.properties.fancyzones_enable_editor_hotkey = true
                $powerToysSettings.fancyzones.properties.fancyzones_shiftDrag = true
                $powerToysSettings.fancyzones.properties.fancyzones_zoneSetChange_flashZones = true
            }
            
            # Save changes
            $powerToysSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $powerToysSettingsPath
            
            $powerToysConfigured = $true
            Write-Host "PowerToys configured successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to configure PowerToys: $_" -ForegroundColor Red
        }
    }
    
    if (-not $powerToysConfigured) {
        Write-Host "PowerToys settings file not found. It will be created when you first run PowerToys." -ForegroundColor Yellow
        Write-Host "Please run PowerToys and then run this script again to configure it." -ForegroundColor Yellow
    }
    
    # ======= Configure Git =======
    Write-Host "⚙️ Configuring Git..." -ForegroundColor Yellow
    
    $gitName = Read-Host "Enter your name for Git configuration"
    $gitEmail = Read-Host "Enter your email for Git configuration"
    
    if ($gitName -and $gitEmail) {
        git config --global user.name "$gitName"
        git config --global user.email "$gitEmail"
        git config --global core.autocrlf input
        git config --global init.defaultBranch main
        
        Write-Host "Git configured successfully" -ForegroundColor Green
    }
    else {
        Write-Host "Git configuration skipped (name or email not provided)" -ForegroundColor Yellow
    }
    
    # ======= Configure WSL =======
    Write-Host "⚙️ Configuring WSL..." -ForegroundColor Yellow
    
    # Check if WSL is installed
    $wslInstalled = $false
    try {
        $wslVersion = wsl --version
        $wslInstalled = $true
        Write-Host "WSL is already installed: $wslVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "WSL is not installed. Installing..." -ForegroundColor Yellow
        wsl --install
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WSL installed successfully. A system restart may be required." -ForegroundColor Green
            Write-Host "Please restart your computer to complete WSL installation." -ForegroundColor Yellow
            $wslInstalled = $true
        }
        else {
            Write-Host "Failed to install WSL" -ForegroundColor Red
        }
    }
    
    # Configure WSL if installed
    if ($wslInstalled) {
        # Set WSL 2 as default
        wsl --set-default-version 2
        
        # Create .wslconfig file with memory limit
        $wslConfigPath = "$env:USERPROFILE\.wslconfig"
        
        $wslConfig = @"
[wsl2]
memory=8GB
processors=4
localhostForwarding=true
"@
        
        $wslConfig | Set-Content -Path $wslConfigPath -Force
        
        Write-Host "WSL configured successfully" -ForegroundColor Green
    }
    
    # ======= VS Code Extensions =======
    Write-Host "⚙️ Installing VS Code extensions..." -ForegroundColor Yellow
    
    $vscodeExtensions = @(
        "ms-vscode-remote.vscode-remote-extensionpack",
        "ms-python.python",
        "ms-toolsai.jupyter",
        "ms-azuretools.vscode-docker",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "streetsidesoftware.code-spell-checker",
        "mhutchie.git-graph",
        "ritwickdey.liveserver",
        "ms-vscode.powershell",
        "visualstudioexptteam.vscodeintellicode"
    )
    
    foreach ($extension in $vscodeExtensions) {
        Write-Host "Installing VS Code extension: $extension" -ForegroundColor Yellow
        code --install-extension $extension
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Extension $extension installed successfully" -ForegroundColor Green
        }
        else {
            Write-Host "Failed to install extension $extension" -ForegroundColor Red
        }
    }
    
    # ======= Explorer Settings =======
    Write-Host "⚙️ Configuring File Explorer settings..." -ForegroundColor Yellow
    
    $explorerRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    
    # Show file extensions
    Set-ItemProperty -Path $explorerRegPath -Name "HideFileExt" -Value 0
    
    # Show hidden files
    Set-ItemProperty -Path $explorerRegPath -Name "Hidden" -Value 1
    
    # Show full path in title bar
    Set-ItemProperty -Path $explorerRegPath -Name "ShowFullPathInTitleBar" -Value 1
    
    # Launch Explorer to This PC instead of Quick Access
    Set-ItemProperty -Path $explorerRegPath -Name "LaunchTo" -Value 1
    
    Write-Host "File Explorer settings configured successfully" -ForegroundColor Green
    
    # ======= Restart Explorer =======
    Write-Host "🔄 Restarting Explorer to apply changes..." -ForegroundColor Yellow
    Stop-Process -Name explorer -Force
    Start-Process explorer
    
    # ======= Finalize =======
    Write-Host "✅ Windows Development Environment Setup Complete!" -ForegroundColor Green
    Write-Host "🔍 Some changes may require a system restart to take full effect." -ForegroundColor Yellow
    
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL
    
    success "PowerShell script created at: $PS_SCRIPT"
    info "To run the development environment setup, run this in Windows PowerShell as Administrator:"
    info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\dev_environment_setup.ps1\""
    
    return 0
}

# Function to create the WSL optimization script
create_wsl_optimization_script() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m         🐧 WSL OPTIMIZATION            \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        warning "This module is designed for Windows with WSL. Your platform is $PLATFORM."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    info "Creating WSL Optimization script..."
    
    # Create PowerShell script
    PS_SCRIPT="$HOME/.dev-setup/modules/wsl_optimizer.ps1"
    
    cat > "$PS_SCRIPT" << 'EOL'
# WSL Optimization Script
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
    Write-Host "🐧 Starting WSL Optimization..." -ForegroundColor Cyan

    # ======= Configure WSL Global Settings =======
    Write-Host "⚙️ Configuring WSL global settings..." -ForegroundColor Yellow
    
    # Create or update .wslconfig file
    $wslConfigPath = "$env:USERPROFILE\.wslconfig"
    
    $totalRam = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property capacity -Sum).Sum / 1GB
    $ramToAllocate = [Math]::Max(4, [Math]::Min(16, $totalRam / 2))
    $cpuCount = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
    $cpuToAllocate = [Math]::Max(2, [Math]::Min(8, $cpuCount - 2))
    
    $wslConfig = @"
[wsl2]
memory=${ramToAllocate}GB
processors=$cpuToAllocate
swap=4GB
localhostForwarding=true
kernelCommandLine=swapfile.size=4GB
"@
    
    $wslConfig | Set-Content -Path $wslConfigPath -Force
    
    Write-Host "WSL global settings configured:" -ForegroundColor Green
    Write-Host "- Memory allocation: ${ramToAllocate}GB" -ForegroundColor Green
    Write-Host "- CPU allocation: $cpuToAllocate processors" -ForegroundColor Green
    Write-Host "- Swap size: 4GB" -ForegroundColor Green
    
    # ======= Configure WSL Network Settings =======
    Write-Host "🌐 Optimizing WSL network settings..." -ForegroundColor Yellow
    
    $networkRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\hns\State"
    If (!(Test-Path $networkRegPath)) {
        New-Item -Path $networkRegPath -Force | Out-Null
    }
    
    # Set Fixed VirtualMachineMac to improve network stability
    Set-ItemProperty -Path $networkRegPath -Name "HostComputeNetwork" -Value ([byte[]](1, 0, 0, 0)) -Type Binary
    
    # ======= Configure Startup Performance =======
    Write-Host "🚀 Optimizing WSL startup performance..." -ForegroundColor Yellow
    
    $startupRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
    If (Test-Path $startupRegPath) {
        # Get all WSL distributions
        $distributions = Get-ChildItem -Path $startupRegPath
        
        foreach ($distro in $distributions) {
            # Set DefaultUid to 1000 (standard user) for better compatibility
            Set-ItemProperty -Path $distro.PSPath -Name "DefaultUid" -Value 1000 -Type DWord
            
            # Get distribution name for output
            $distroName = (Get-ItemProperty -Path $distro.PSPath).DistributionName
            Write-Host "Optimized startup for distribution: $distroName" -ForegroundColor Green
        }
    }
    
    # ======= Configure Hyper-V Memory Parameters =======
    Write-Host "🧠 Optimizing Hyper-V memory usage..." -ForegroundColor Yellow
    
    $hyperVRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization"
    If (!(Test-Path $hyperVRegPath)) {
        New-Item -Path $hyperVRegPath -Force | Out-Null
    }
    
    # Configure memory settings for better performance
    Set-ItemProperty -Path $hyperVRegPath -Name "MemoryReserve" -Value 1024 -Type DWord
    
    # ======= Configure Windows Terminal Integration =======
    Write-Host "🖥️ Configuring Windows Terminal integration..." -ForegroundColor Yellow
    
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    
    if (Test-Path $terminalSettingsPath) {
        # Backup current settings
        Copy-Item -Path $terminalSettingsPath -Destination "$terminalSettingsPath.backup" -Force
        
        try {
            # Load current settings
            $terminalSettings = Get-Content -Path $terminalSettingsPath | ConvertFrom-Json
            
            # Get WSL profiles
            $wslProfiles = $terminalSettings.profiles.list | Where-Object { $_.source -eq "Windows.Terminal.Wsl" }
            
            # Configure each WSL profile
            foreach ($profile in $wslProfiles) {
                $profile.colorScheme = "One Half Dark"
                $profile.startingDirectory = "~"
                $profile.fontFace = "Cascadia Code PL"
                $profile.fontSize = 11
                
                Write-Host "Optimized Windows Terminal profile for: $($profile.name)" -ForegroundColor Green
            }
            
            # Save changes
            $terminalSettings | ConvertTo-Json -Depth 100 | Set-Content -Path $terminalSettingsPath
        }
        catch {
            Write-Host "Failed to configure Windows Terminal: $_" -ForegroundColor Red
        }
    }
    
    # ======= Configure Security Settings =======
    Write-Host "🔒 Configuring security settings..." -ForegroundColor Yellow
    
    # Allow localhost connections
    $firewallRuleName = "WSL 2 Localhost Access"
    
    # Remove existing rule if it exists
    Remove-NetFirewallRule -DisplayName $firewallRuleName -ErrorAction SilentlyContinue
    
    # Create a new firewall rule
    New-NetFirewallRule -DisplayName $firewallRuleName -Direction Inbound -LocalPort 3000-3999,5000-5999,8000-8999 -Action Allow -Protocol TCP
    
    Write-Host "Firewall rules created to allow local development ports" -ForegroundColor Green
    
    # ======= Restart WSL =======
    Write-Host "🔄 Restarting WSL to apply changes..." -ForegroundColor Yellow
    wsl --shutdown
    
    # ======= Finalize =======
    Write-Host "✅ WSL Optimization Complete!" -ForegroundColor Green
    Write-Host "🔍 Restart your WSL sessions to apply all changes." -ForegroundColor Yellow
    
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL
    
    # Create a WSL optimization script for the Linux side
    WSL_SCRIPT="$HOME/.dev-setup/modules/wsl_optimize_linux.sh"
    
    cat > "$WSL_SCRIPT" << 'EOL'
#!/bin/bash
# WSL Linux-side optimization script

# Setup logging
LOG_FILE="$HOME/.dev-setup/logs/wsl_optimize_linux_$(date +%Y-%m-%d_%H-%M-%S).log"
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Helper functions
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

log "Starting WSL Linux-side optimization"

# Configure I/O scheduler for better performance
if [ -f /sys/block/sda/queue/scheduler ]; then
    echo 'mq-deadline' | sudo tee /sys/block/sda/queue/scheduler > /dev/null
    log "Set I/O scheduler to mq-deadline"
fi

# Set swappiness to reduce swap usage
if [ -f /proc/sys/vm/swappiness ]; then
    echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf > /dev/null
    log "Set vm.swappiness to 10"
fi

# Configure file system cache to favor application memory
if [ -f /proc/sys/vm/vfs_cache_pressure ]; then
    echo 50 | sudo tee /proc/sys/vm/vfs_cache_pressure > /dev/null
    echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf > /dev/null
    log "Set vm.vfs_cache_pressure to 50"
fi

# Add WSL-specific config to .bashrc or .zshrc
WSL_CONFIG="
# WSL-specific configurations
# Improve Windows/WSL integration
export BROWSER=wslview

# Preserve Windows PATH
if grep -q Microsoft /proc/version; then
    export PATH=\$PATH:/mnt/c/Windows/System32:/mnt/c/Windows:/mnt/c/Program Files/Microsoft VS Code/bin
fi

# Use Windows home for certain apps to improve performance
if grep -q Microsoft /proc/version; then
    # No need to keep these inside the Linux filesystem
    export NPM_CONFIG_CACHE=/mnt/c/temp/npm-cache
    export YARN_CACHE_FOLDER=/mnt/c/temp/yarn-cache
    
    # Create cache directories if they don't exist
    mkdir -p /mnt/c/temp/npm-cache
    mkdir -p /mnt/c/temp/yarn-cache
fi
"

# Add to shell config files if not already present
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "WSL-specific configurations" "$HOME/.bashrc"; then
        echo "$WSL_CONFIG" >> "$HOME/.bashrc"
        log "Added WSL configurations to .bashrc"
    fi
fi

if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "WSL-specific configurations" "$HOME/.zshrc"; then
        echo "$WSL_CONFIG" >> "$HOME/.zshrc"
        log "Added WSL configurations to .zshrc"
    fi
fi

# Create WSL configuration
WSL_CONF="
# Enable case sensitivity
[automount]
options = \"case=dir\"
mountFsTab = false

# Set unmask for better permission handling
[interop]
appendWindowsPath = true
enabled = true

# Configure network
[network]
generateHosts = true
generateResolvConf = true
"

if [ -f /etc/wsl.conf ]; then
    sudo cp /etc/wsl.conf /etc/wsl.conf.backup
    log "Backed up existing /etc/wsl.conf"
fi

echo "$WSL_CONF" | sudo tee /etc/wsl.conf > /dev/null
log "Created optimized /etc/wsl.conf"

# Install WSL utilities if not already present
if ! command -v wslu > /dev/null; then
    if command -v apt > /dev/null; then
        sudo apt update
        sudo apt install -y wslu
        log "Installed wslu (WSL utilities)"
    elif command -v dnf > /dev/null; then
        sudo dnf install -y wslu
        log "Installed wslu (WSL utilities)"
    fi
fi

log "WSL Linux-side optimization completed"
log "Please restart your WSL session for all changes to take effect"
echo "✅ WSL Linux-side optimization completed!"
echo "Please restart your WSL session for all changes to take effect"
EOL
    
    chmod +x "$WSL_SCRIPT"
    
    success "PowerShell script created at: $PS_SCRIPT"
    success "Linux optimization script created at: $WSL_SCRIPT"
    info "To run the WSL optimizer (Windows side), run this in Windows PowerShell as Administrator:"
    info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\wsl_optimizer.ps1\""
    info "To run the Linux-side optimization, run:"
    info "bash ~/.dev-setup/modules/wsl_optimize_linux.sh"
    
    # Ask if the user wants to run the Linux-side script now
    read -p "Do you want to run the Linux-side optimization script now? (y/n) [y]: " run_now
    run_now=${run_now:-"y"}
    
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        bash "$WSL_SCRIPT"
    fi
    
    return 0
}

# Function to create the startup apps manager script
create_startup_manager_script() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m       🚀 STARTUP APPS MANAGER          \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        warning "This module is designed for Windows with WSL. Your platform is $PLATFORM."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    info "Creating Startup Apps Manager script..."
    
    # Create PowerShell script
    PS_SCRIPT="$HOME/.dev-setup/modules/startup_manager.ps1"
    
    cat > "$PS_SCRIPT" << 'EOL'
# Startup Apps Manager Script
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
    Write-Host "🚀 Starting Startup Apps Manager..." -ForegroundColor Cyan

    # Get current startup apps
    Write-Host "📋 Listing current startup apps..." -ForegroundColor Yellow
    
    # Get apps from Run registry key
    $runApps = @()
    $runRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $runItems = Get-ItemProperty -Path $runRegPath
    $runProps = $runItems.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
    
    foreach ($prop in $runProps) {
        $runApps += [PSCustomObject]@{
            Name = $prop.Name
            Command = $prop.Value
            Type = "Registry Key (Current User)"
            Status = "Enabled"
            KeyPath = $runRegPath
        }
    }
    
    # Get apps from RunOnce registry key
    $runOnceRegPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    if (Test-Path $runOnceRegPath) {
        $runOnceItems = Get-ItemProperty -Path $runOnceRegPath
        $runOnceProps = $runOnceItems.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
        
        foreach ($prop in $runOnceProps) {
            $runApps += [PSCustomObject]@{
                Name = $prop.Name
                Command = $prop.Value
                Type = "Registry Key (RunOnce)"
                Status = "Enabled (Once)"
                KeyPath = $runOnceRegPath
            }
        }
    }
    
    # Get system-wide startup apps
    $systemRunRegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $systemRunItems = Get-ItemProperty -Path $systemRunRegPath
    $systemRunProps = $systemRunItems.PSObject.Properties | Where-Object { $_.Name -notlike "PS*" }
    
    foreach ($prop in $systemRunProps) {
        $runApps += [PSCustomObject]@{
            Name = $prop.Name
            Command = $prop.Value
            Type = "Registry Key (System-wide)"
            Status = "Enabled"
            KeyPath = $systemRunRegPath
        }
    }
    
    # Get startup folder items
    $startupFolderPath = [Environment]::GetFolderPath("Startup")
    $startupItems = Get-ChildItem -Path $startupFolderPath -File

    foreach ($item in $startupItems) {
        $runApps += [PSCustomObject]@{
            Name = $item.BaseName
            Command = $item.FullName
            Type = "Startup Folder"
            Status = "Enabled"
            KeyPath = $startupFolderPath
        }
    }
    
    # Get all users startup folder items
    $allUsersStartupFolderPath = [Environment]::GetFolderPath("CommonStartup")
    $allUsersStartupItems = Get-ChildItem -Path $allUsersStartupFolderPath -File

    foreach ($item in $allUsersStartupItems) {
        $runApps += [PSCustomObject]@{
            Name = $item.BaseName
            Command = $item.FullName
            Type = "All Users Startup Folder"
            Status = "Enabled"
            KeyPath = $allUsersStartupFolderPath
        }
    }
    
    # Get Task Scheduler items that run at startup
    $tasks = Get-ScheduledTask | Where-Object { $_.Settings.DisallowStartIfOnBatteries -eq $false -and $_.Triggers.Count -gt 0 }
    
    foreach ($task in $tasks) {
        $trigger = $task.Triggers[0]
        
        # Check if the task runs at startup or logon
        if ($trigger.CimClass.CimClassName -like "*BootTrigger" -or $trigger.CimClass.CimClassName -like "*LogonTrigger") {
            # Get the status
            $status = "Disabled"
            if ($task.State -eq "Ready") {
                $status = "Enabled"
            }
            
            $runApps += [PSCustomObject]@{
                Name = $task.TaskName
                Command = "Task Scheduler"
                Type = "Scheduled Task"
                Status = $status
                KeyPath = $task.TaskPath
            }
        }
    }
    
    # Display all startup apps
    if ($runApps.Count -eq 0) {
        Write-Host "No startup apps found." -ForegroundColor Yellow
    }
    else {
        Write-Host "Found $($runApps.Count) startup apps:" -ForegroundColor Cyan
        $index = 0
        foreach ($app in $runApps) {
            $index++
            $statusColor = "Green"
            if ($app.Status -like "*Disabled*") {
                $statusColor = "Red"
            }
            
            Write-Host "[$index] $($app.Name)" -ForegroundColor Yellow
            Write-Host "    Type: $($app.Type)" -ForegroundColor Gray
            Write-Host "    Status: " -ForegroundColor Gray -NoNewline
            Write-Host "$($app.Status)" -ForegroundColor $statusColor
            Write-Host "    Command: $($app.Command)" -ForegroundColor Gray
            Write-Host ""
        }
        
        # Menu for managing startup apps
        Write-Host "Startup Apps Management Options:" -ForegroundColor Cyan
        Write-Host "1. Disable a startup app" -ForegroundColor Yellow
        Write-Host "2. Enable a startup app" -ForegroundColor Yellow
        Write-Host "3. Remove a startup app" -ForegroundColor Yellow
        Write-Host "4. Add a new startup app" -ForegroundColor Yellow
        Write-Host "0. Exit" -ForegroundColor Yellow
        
        $choice = Read-Host "Enter your choice (0-4)"
        
        switch ($choice) {
            "1" {
                # Disable a startup app
                $appIndex = Read-Host "Enter the number of the app to disable"
                
                if ($appIndex -gt 0 -and $appIndex -le $runApps.Count) {
                    $appToDisable = $runApps[$appIndex - 1]
                    
                    if ($appToDisable.Type -like "*Registry Key*") {
                        # For registry keys, move to the Disabled key
                        $disabledKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                        
                        if (!(Test-Path $disabledKeyPath)) {
                            New-Item -Path $disabledKeyPath -Force | Out-Null
                        }
                        
                        # Create a registry value for this app
                        $disabledValue = [byte[]]@(3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                        Set-ItemProperty -Path $disabledKeyPath -Name $appToDisable.Name -Value $disabledValue -Type Binary
                        
                        Write-Host "✅ Disabled startup app: $($appToDisable.Name)" -ForegroundColor Green
                    }
                    elseif ($appToDisable.Type -like "*Scheduled Task*") {
                        # For scheduled tasks, disable the task
                        Disable-ScheduledTask -TaskName $appToDisable.Name -TaskPath $appToDisable.KeyPath
                        Write-Host "✅ Disabled scheduled task: $($appToDisable.Name)" -ForegroundColor Green
                    }
                    elseif ($appToDisable.Type -like "*Startup Folder*") {
                        # For startup folder items, move to a backup folder
                        $backupPath = "$env:USERPROFILE\StartupBackup"
                        
                        if (!(Test-Path $backupPath)) {
                            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
                        }
                        
                        Move-Item -Path $appToDisable.Command -Destination $backupPath
                        Write-Host "✅ Moved startup item to backup folder: $($appToDisable.Name)" -ForegroundColor Green
                    }
                    else {
                        Write-Host "❌ Unable to disable this type of startup app: $($appToDisable.Type)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "❌ Invalid app number" -ForegroundColor Red
                }
            }
            "2" {
                # Enable a startup app
                $appIndex = Read-Host "Enter the number of the app to enable"
                
                if ($appIndex -gt 0 -and $appIndex -le $runApps.Count) {
                    $appToEnable = $runApps[$appIndex - 1]
                    
                    if ($appToEnable.Type -like "*Registry Key*") {
                        # For registry keys, remove from the Disabled key
                        $disabledKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
                        
                        if (Test-Path $disabledKeyPath) {
                            Remove-ItemProperty -Path $disabledKeyPath -Name $appToEnable.Name -ErrorAction SilentlyContinue
                        }
                        
                        Write-Host "✅ Enabled startup app: $($appToEnable.Name)" -ForegroundColor Green
                    }
                    elseif ($appToEnable.Type -like "*Scheduled Task*") {
                        # For scheduled tasks, enable the task
                        Enable-ScheduledTask -TaskName $appToEnable.Name -TaskPath $appToEnable.KeyPath
                        Write-Host "✅ Enabled scheduled task: $($appToEnable.Name)" -ForegroundColor Green
                    }
                    elseif ($appToEnable.Type -like "*Startup Folder*") {
                        # For startup folder items, move back from backup folder
                        $backupPath = "$env:USERPROFILE\StartupBackup\$($appToEnable.Name)"
                        
                        if (Test-Path $backupPath) {
                            Move-Item -Path $backupPath -Destination $appToEnable.KeyPath
                            Write-Host "✅ Restored startup item from backup folder: $($appToEnable.Name)" -ForegroundColor Green
                        }
                        else {
                            Write-Host "❌ Backup file not found for: $($appToEnable.Name)" -ForegroundColor Red
                        }
                    }
                    else {
                        Write-Host "❌ Unable to enable this type of startup app: $($appToEnable.Type)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "❌ Invalid app number" -ForegroundColor Red
                }
            }
            "3" {
                # Remove a startup app
                $appIndex = Read-Host "Enter the number of the app to remove"
                
                if ($appIndex -gt 0 -and $appIndex -le $runApps.Count) {
                    $appToRemove = $runApps[$appIndex - 1]
                    
                    # Confirm removal
                    $confirm = Read-Host "Are you sure you want to remove '$($appToRemove.Name)'? (y/n)"
                    
                    if ($confirm -eq "y") {
                        if ($appToRemove.Type -like "*Registry Key*") {
                            # For registry keys, remove the key
                            Remove-ItemProperty -Path $appToRemove.KeyPath -Name $appToRemove.Name
                            Write-Host "✅ Removed startup app: $($appToRemove.Name)" -ForegroundColor Green
                        }
                        elseif ($appToRemove.Type -like "*Scheduled Task*") {
                            # For scheduled tasks, delete the task
                            Unregister-ScheduledTask -TaskName $appToRemove.Name -TaskPath $appToRemove.KeyPath -Confirm:$false
                            Write-Host "✅ Removed scheduled task: $($appToRemove.Name)" -ForegroundColor Green
                        }
                        elseif ($appToRemove.Type -like "*Startup Folder*") {
                            # For startup folder items, delete the file
                            Remove-Item -Path $appToRemove.Command -Force
                            Write-Host "✅ Removed startup item: $($appToRemove.Name)" -ForegroundColor Green
                        }
                        else {
                            Write-Host "❌ Unable to remove this type of startup app: $($appToRemove.Type)" -ForegroundColor Red
                        }
                    }
                    else {
                        Write-Host "Removal cancelled" -ForegroundColor Yellow
                    }
                }
                else {
                    Write-Host "❌ Invalid app number" -ForegroundColor Red
                }
            }
            "4" {
                # Add a new startup app
                $appName = Read-Host "Enter the name for the new startup app"
                $appPath = Read-Host "Enter the full path to the executable or script"
                
                if ($appName -and $appPath) {
                    # Choose where to add it
                    Write-Host "Where would you like to add this startup app?" -ForegroundColor Yellow
                    Write-Host "1. Current User Registry (recommended)" -ForegroundColor Yellow
                    Write-Host "2. Startup Folder" -ForegroundColor Yellow
                    Write-Host "3. All Users Registry (system-wide)" -ForegroundColor Yellow
                    
                    $addChoice = Read-Host "Enter your choice (1-3)"
                    
                    switch ($addChoice) {
                        "1" {
                            # Add to current user registry
                            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name $appName -Value "`"$appPath`""
                            Write-Host "✅ Added startup app to Current User Registry: $appName" -ForegroundColor Green
                        }
                        "2" {
                            # Add to Startup folder
                            $startupFolderPath = [Environment]::GetFolderPath("Startup")
                            
                            # Create a shortcut
                            $WshShell = New-Object -ComObject WScript.Shell
                            $Shortcut = $WshShell.CreateShortcut("$startupFolderPath\$appName.lnk")
                            $Shortcut.TargetPath = $appPath
                            $Shortcut.Save()
                            
                            Write-Host "✅ Added startup app to Startup Folder: $appName" -ForegroundColor Green
                        }
                        "3" {
                            # Add to system-wide registry
                            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name $appName -Value "`"$appPath`""
                            Write-Host "✅ Added startup app to System Registry: $appName" -ForegroundColor Green
                        }
                        default {
                            Write-Host "❌ Invalid choice" -ForegroundColor Red
                        }
                    }
                }
                else {
                    Write-Host "❌ App name and path are required" -ForegroundColor Red
                }
            }
            default {
                # Exit
                Write-Host "Exiting Startup Apps Manager" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "✅ Startup Apps Manager Complete!" -ForegroundColor Green
    
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
EOL
    
    success "PowerShell script created at: $PS_SCRIPT"
    info "To run the Startup Apps Manager, run this in Windows PowerShell as Administrator:"
    info "PowerShell.exe -ExecutionPolicy Bypass -File \"\\\\wsl\$\\$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '\"')\\home\\$USER\\.dev-setup\\modules\\startup_manager.ps1\""
    
    return 0
}

# Main menu function
show_clean_slate_menu() {
    clear
    echo -e "\e[1;36m========================================\e[0m"
    echo -e "\e[1;36m    🪄 CLEAN SLATE WINDOWS CONFIG       \e[0m"
    echo -e "\e[1;36m========================================\e[0m"
    echo ""
    
    if [ "$PLATFORM" != "wsl" ]; then
        warning "This module is designed for Windows with WSL. Your platform is $PLATFORM."
        read -p "Do you want to continue anyway? (y/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    echo "Please select an option:"
    echo "1. Create Performance Optimization script"
    echo "2. Create Development Environment Setup script"
    echo "3. Create WSL Optimization script"
    echo "4. Create Startup Apps Manager script"
    echo "5. Generate all scripts"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-5]: " menu_choice
    
    case $menu_choice in
        1) create_performance_script ;;
        2) create_dev_environment_script ;;
        3) create_wsl_optimization_script ;;
        4) create_startup_manager_script ;;
        5)
            create_performance_script
            create_dev_environment_script
            create_wsl_optimization_script
            create_startup_manager_script
            ;;
        0) exit 0 ;;
        *)
            warning "Invalid option. Please try again."
            show_clean_slate_menu
            ;;
    esac
    
    # Return to menu after function completes
    read -p "Press Enter to return to the main menu..."
    show_clean_slate_menu
}

# Main execution starts here
show_clean_slate_menu#!/bin/bash
# Clean Slate Windows Configuration Module
# Part of the