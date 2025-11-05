<#
.SYNOPSIS
    "Super" Master Script to configure the entire Windows + WSL environment.
.DESCRIPTION
    1. Guarantees Administrator privileges.
    2. Installs WSL 2 (if not installed) and prompts for a required reboot.
    3. Installs Chocolatey (if not installed).
    4. Enables Chocolatey's auto-confirmation for scripts.
    5. Installs/Upgrades ALL Windows tools via Chocolatey (in batches for speed).
    6. Installs essential VS Code Extensions (in one batch).
    7. Automatically executes the 'wsl_ubuntu.sh' script.
    8. Installs all pending Windows Updates.
    9. Cleans up all temp files and optimizes the system.
.NOTES
    Version: 2.8 (Fixed burpsuite and nerd-font package IDs based on user feedback)
    Author: Kaua
    LOGIC: Uses 'choco upgrade' to install (if missing) or upgrade (if existing).
#>

# --- 0. Helper Functions & Global Variables ---
$Global:RebootIsNeeded = $false # We will track if a reboot is needed

# Robust function to check for any pending reboots (Registry or WU)
function Test-RebootRequired {
    # Check Windows Update Module first
    try {
        if (Test-PendingReboot -ErrorAction SilentlyContinue) { return $true }
    } catch {}
    
    # Check common registry keys
    $RegKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    )
    if (Get-ItemProperty -Path $RegKeys -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
        return $true
    }
    return $false
}

# --- 1. Administrator Check ---
Write-Host "Checking for Administrator privileges..." -ForegroundColor Yellow
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "Please right-click the script and 'Run as Administrator'." -ForegroundColor Red
    Read-Host "Press ENTER to exit..."
    exit
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green

# --- 2. WSL 2 Check & Installation ---
Write-Host ""
Write-Host "Checking WSL 2 installation..." -ForegroundColor Yellow
try {
    # Try to get WSL status. If it fails (ExitCode != 0), WSL is not installed.
    wsl --status | Out-Null
    Write-Host "WSL 2 is already installed." -ForegroundColor Green
} catch {
    Write-Host "WSL 2 not found. Starting installation..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes..."
    
    # Run the WSL installation command
    wsl --install
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  REBOOT REQUIRED" -ForegroundColor Red
    Write-Host "============================================================"
    Write-Host "WSL 2 has been installed."
    Write-Host "PLEASE RESTART YOUR COMPUTER NOW."
    Write-Host "After rebooting, run this 'setup.ps1' script again."
    Write-Host "The installation will continue from where it left off."
    Write-Host "============================================================"
    Read-Host "Press ENTER to close and restart your PC..."
    exit # Exit script to force reboot
}

# --- 3. Chocolatey Check & Installation ---
Write-Host ""
Write-Host "Checking if Chocolatey is installed..."
$chocoPath = Get-Command choco -ErrorAction SilentlyContinue
if ($null -eq $chocoPath) {
    Write-Host "Chocolatey not found. Installing now..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
        
        # Add choco to the current session's PATH
        $env:Path = "$($env:Path);$($env:ALLUSERSPROFILE)\chocolatey\bin"
    } catch {
        Write-Host "ERROR: Failed to install Chocolatey." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Read-Host "Press ENTER to exit..."
        exit
    }
} else {
    Write-Host "Chocolatey is already installed." -ForegroundColor Green
}

# --- 4. Enabling Chocolatey Auto-Confirmation ---
Write-Host ""
Write-Host "Enabling Chocolatey's automatic script confirmation (100% automated mode)..." -ForegroundColor Yellow
try {
    # This command prevents Choco from asking "[Y]es/[A]ll/[N]o" for every script
    choco feature enable -n=allowGlobalConfirmation
    Write-Host "Feature 'allowGlobalConfirmation' enabled." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to enable 'allowGlobalConfirmation'. Script may prompt for confirmation." -ForegroundColor Red
}

# --- 5. BEGINNING WINDOWS TOOL UPGRADES (Batch Optimized) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING INSTALLATION/UPGRADE OF WINDOWS TOOLS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
$env:ChocolateyInstallArguments = "--yes"

# 5.1: Editors, Terminals & Utilities
Write-Host "[+] Upgrading Editors, Terminals & Utilities..." -ForegroundColor Cyan
$batch1 = @("vscode", "microsoft-windows-terminal", "neovim", "7zip", "powershell-core")
choco upgrade $batch1 -y

# 5.2: Browsers (FIXED IDs)
Write-Host "[+] Upgrading Browsers..." -ForegroundColor Cyan
# REMOVED: 'firefox-dev' (pacote não encontrado no repositório Choco)
$batch2 = @("firefox", "googlechrome", "tor-browser")
choco upgrade $batch2 -y

# 5.3: Programming Languages & Runtimes
Write-Host "[+] Upgrading Languages & Runtimes..." -ForegroundColor Cyan
$batch3 = @("python3", "nodejs-lts", "openjdk17", "dotnet-sdk")
choco upgrade $batch3 -y

# 5.4: Build Tools & Version Control
Write-Host "[+] Upgrading Build Tools & Version Control..." -ForegroundColor Cyan
choco upgrade git.install -y
choco upgrade msys2 -y
choco upgrade cmake.install --install-arguments 'ADD_CMAKE_TO_PATH_System' -y

# 5.5: Microsoft C++ Build Tools (MSVC)
Write-Host ""
Write-Host "================== LONG TASK WARNING (VS 2022) ==================" -ForegroundColor Yellow
Write-Host "Starting 'Visual Studio 2022 Community' upgrade/install."
Write-Host "This is the largest download and can take 30-60 minutes."
Write-Host "The terminal MAY APPEAR FROZEN. This is normal. Please wait..."
Write-Host "================================================================="
Write-Host "[+] Upgrading Visual Studio 2022 Community IDE (for C++)..." -ForegroundColor Cyan
choco upgrade visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet" -y

# 5.6: Virtualization & Containers
Write-Host "[+] Upgrading Virtualization & Containers..." -ForegroundColor Cyan
$batch6 = @("docker-desktop", "virtualbox")
choco upgrade $batch6 -y

# 5.7: Databases & APIs
Write-Host "[+] Upgrading Database & API Clients..." -ForegroundColor Cyan
$batch7 = @("dbeaver", "postman")
choco upgrade $batch7 -y

# 5.8: Hardware Diagnostics, Benchmark & Monitoring (FIXED ID)
Write-Host "[+] Upgrading Hardware Diagnostics & Benchmark Kit..." -ForegroundColor Cyan
# REMOVED: 'msiafterburner' (pacote Choco quebrado, link de download negado)
$batch8 = @("cpu-z", "gpu-z", "hwmonitor", "crystaldiskinfo", "crystaldiskmark", "speccy", "prime95")
choco upgrade $batch8 -y
Write-Host "NOTE: 'msiafterburner' foi removido pois o pacote Choco está quebrado. Instale-o manualmente." -ForegroundColor Gray

# 5.9: Productivity & Communication
Write-Host "[+] Upgrading Communication Tools..." -ForegroundColor Cyan
choco upgrade discord -y

# 5.10: DevOps & Cloud Tools (FIXED ID)
Write-Host "[+] Upgrading DevOps & Cloud Tools..." -ForegroundColor Cyan
$batch10 = @("awscli", "azure-cli", "terraform")
choco upgrade $batch10 -y

# 5.11: Advanced Utilities & Personal Security
Write-Host "[+] Upgrading Advanced Utilities & Security..." -ForegroundColor Cyan
$batch11 = @("gsudo", "keepassxc", "windirstat", "winscp")
choco upgrade $batch11 -y

# 5.11-A: MODERN TERMINAL UTILITIES (QoL)
Write-Host "[+] Upgrading Modern Terminal Utilities (bat, eza, devtoys)..." -ForegroundColor Cyan
# ADDED: devtoys
$batch11a = @("bat", "eza", "devtoys")
choco upgrade $batch11a -y

# 5.12: CYBERSECURITY & PENTESTING (Host) (FIXED IDs)
Write-Host "[+] Upgrading Cybersecurity & Pentesting Arsenal..." -ForegroundColor Magenta
# REMOVED: 'zap' (instalador silencioso falha)
# FIXED: 'burpsuite-community' alterado para 'burp-suite-free-edition'. Não precisa mais do --pre.
$batch12 = @("nmap", "wireshark", "burp-suite-free-edition", "ghidra", "x64dbg.portable", "sysinternals", "hashcat", "autopsy", "putty")
choco upgrade $batch12 -y --ignore-http-cache
Write-Host "NOTE: 'zap' (OWASP ZAP) foi removido pois o instalador silencioso do Choco está falhando. Instale-o manualmente." -ForegroundColor Gray

# 5.13: ESSENTIAL DEPENDENCIES (Runtimes)
Write-Host "[+] Upgrading Essential Runtimes..." -ForegroundColor Yellow
$batch13 = @("vcredist-all", "dotnet3.5", "dotnetfx", "jre8", "directx")
choco upgrade $batch13 -y
Write-Host "Some runtimes may require a reboot. This will be checked at the end."

# 5.14: TERMINAL ENHANCEMENTS (Oh My Posh + Font) (FIXED ID)
Write-Host "[+] Upgrading Terminal Enhancements (Oh My Posh + Nerd Font)..." -ForegroundColor Cyan
# FIXED: 'caskaydiacove-nerd-font' alterado para 'nerd-fonts-cascadiacode'. Não precisa mais do --pre.
$batch14 = @("oh-my-posh", "nerd-fonts-cascadiacode")
choco upgrade $batch14 -y
Write-Host "Oh My Posh and CaskaydiaCove NF (Nerd Font) installed/updated."

# 5.15: CONFIGURING POWERSHELL 7 PROFILE (Productivity Pack)
Write-Host "[+] Configuring PowerShell 7 Profile (Oh My Posh, Terminal-Icons, PSReadLine)..." -ForegroundColor Yellow
try {
    Write-Host "[+] Installing 'Terminal-Icons' module..."
    # FIXED: Garante que o provedor NuGet está instalado
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    # FIXED: Define o PSGallery como confiável (removido -Scope)
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    # FIXED: Adicionado -ForceBootstrap para forçar a instalação do NuGet se ele falhar
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -Confirm:$false -ForceBootstrap -ErrorAction Stop

    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    $ProfilePath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"
    
    if (-not (Test-Path $ProfileDir)) {
        Write-Host "Creating PowerShell profile directory: $ProfileDir"
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
    }

    $ProfileContent = @"

# --- Productivity Pack Start ---
# Makes the terminal beautiful (themes)
oh-my-posh init pwsh | Invoke-Expression

# Enables icons in the terminal
Import-Module -Name Terminal-Icons

# Makes TAB completion use an interactive menu (like Linux)
Set-PSReadLineOption -EditMode Emacs

# Enables "ghost" auto-completion based on history
Set-PSReadLineOption -PredictionSource History

# Allow local scripts to run
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
# --- Productivity Pack End ---
"@
    
    $FileContent = if (Test-Path $ProfilePath) { Get-Content $Path $ProfilePath -Raw } else { "" }

    $Marker = "# --- Productivity Pack Start ---"
    
    if ($FileContent -notlike "*$Marker*") {
        Write-Host "Adding Productivity Pack to $ProfilePath..."
        # Add the entire block to the end of the file
        Add-Content -Path $ProfilePath -Value $ProfileContent
        Write-Host "PowerShell profile configured." -ForegroundColor Green
    } else {
        Write-Host "PowerShell profile already contains Productivity Pack. Skipping." -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to configure PowerShell profile." -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "=================================================" -ForegroundColor Green
Write-Host "  WINDOWS TOOLS UPGRADE COMPLETE!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""


# --- 6. INSTALLING VS CODE EXTENSIONS (Batch Optimized) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INSTALLING VS CODE EXTENSIONS..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "[+] Installing/Updating extensions in one batch..." -ForegroundColor Cyan
    
    # Define all extensions in an array
    $extensions = @(
        "pkief.material-icon-theme",
        "eamodio.gitlens",
        "formulahendry.code-runner",
        "visualstudioexptteam.vscodeintellicode",
        "github.copilot",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "ritwickdey.liveserver",
        "ms-vscode.cpptools",
        "ms-vscode.cmake-tools",
        "ms-python.python",
        "ms-python.vscode-pylance",
        "vscjava.vscode-java-pack",
        "ms-vscode-remote.remote-wsl",
        "ms-azuretools.vscode-docker",
        "firefox-devtools.vscode-firefox-debug"
    )

    # Loop and install (or use a single line, but loop gives better feedback)
    foreach ($ext in $extensions) {
        Write-Host "Installing $ext..."
        code --install-extension $ext --force
    }

    Write-Host "VS Code extensions installed/updated." -ForegroundColor Green
} else {
    Write-Host "ERROR: 'code.exe' not found in PATH. Skipping VS Code extension install." -ForegroundColor Red
    Write-Host "Please restart your terminal and run the script again if VS Code was just installed."
}


# --- 7. EXECUTING WSL SCRIPT (Automated Section) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING AUTOMATED WSL (UBUNTU) SETUP..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

# Find the path to the wsl_ubuntu.sh script in the same directory
$wslScriptPath = Join-Path $PSScriptRoot "wsl_ubuntu.sh"

if (-not (Test-Path $wslScriptPath)) {
    Write-Host "ERROR: 'wsl_ubuntu.sh' script not found in the same directory." -ForegroundColor Red
    Write-Host "WSL setup will have to be run manually." -ForegroundColor Red
} else {
    Write-Host "Found 'wsl_ubuntu.sh' script."
    Write-Host "Converting Windows path to WSL format..." -ForegroundColor Yellow
    
    $fullWinPath = (Resolve-Path $wslScriptPath).Path
    $driveLetter = $fullWinPath.Substring(0, 1).ToLower()
    $linuxPath = $fullWinPath.Substring(2) -replace '\\', '/'
    $fullLinuxPath = "/mnt/$driveLetter$linuxPath"
    
    Write-Host "WSL script path: $fullLinuxPath"
    
    Write-Host ""
    Write-Host "================== ATTENTION: SUDO PASSWORD ==================" -ForegroundColor Red
    Write-Host "The script will now run the Ubuntu (WSL) setup."
    Write-Host "The terminal WILL PAUSE and ask for your 'sudo' password (for Linux)."
    Write-Host "PLEASE TYPE YOUR UBUNTU PASSWORD AND PRESS ENTER."
    Write-Host "(You will not see characters as you type. This is normal.)"
    Write-Host "============================================================="
    Write-Host ""
    Write-Host "Starting 'wsl.exe'..." -ForegroundColor Yellow
    
    try {
        # FIXED: Garantir que o script seja executado com 'bash' para evitar problemas de shell
        wsl.exe sudo bash "$fullLinuxPath"
        Write-Host "=================================================" -ForegroundColor Green
        Write-Host "  WSL (UBUNTU) SETUP COMPLETE!" -ForegroundColor Green
        Write-Host "================================================="
    } catch {
        Write-Host "ERROR: Failed to execute WSL script." -ForegroundColor Red
        Write-Host "If this failed, check if 'wsl_ubuntu.sh' has the corrected package names." -ForegroundColor Red
    }
}

# --- 8. RUNNING WINDOWS UPDATE (SMART REBOOT) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  CHECKING FOR WINDOWS UPDATES..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

Write-Host "[+] Installing/Checking 'PSWindowsUpdate' module..." -ForegroundColor Cyan
try {
    # FIXED: Garante que o provedor NuGet está instalado
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    # FIXED: Define o PSGallery como confiável (removido -Scope)
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    # FIXED: Adicionado -ForceBootstrap para forçar a instalação do NuGet se ele falhar
    Install-Module -Name PSWindowsUpdate -Force -AcceptLicense -Confirm:$false -ForceBootstrap
    Import-Module PSWindowsUpdate -Force
    
    Write-Host "[+] Searching, downloading, and installing all Windows Updates..." -ForegroundColor Yellow
    Write-Host "This is the other step that MAY TAKE A VERY LONG TIME. Please wait..."
    
    # Install updates WITHOUT auto-rebooting
    Install-WindowsUpdate -AcceptAll -ErrorAction SilentlyContinue
    
    if (Test-RebootRequired) {
        $Global:RebootIsNeeded = $true
    }
    
    Write-Host "Windows Update check complete." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to run Windows Update." -ForegroundColor Red
    Write-Host "Please run Windows Update manually."
}

# --- 9. SYSTEM CLEANUP & OPTIMIZATION ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING SYSTEM CLEANUP & OPTIMIZATION..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

Write-Host "[+] Cleaning up Windows temporary files (User, System & Prefetch)..." -ForegroundColor Cyan
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[+] Cleaning up Chocolatey package cache..." -ForegroundColor Cyan
# FIXED: 'choco cache --remove --all' foi alterado para 'choco cache remove --all'
choco cache remove --all

Write-Host "[+] Optimizing main drive (C:)... (TRIM or Defrag)" -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -ErrorAction SilentlyContinue

Write-Host "System cleanup complete." -ForegroundColor Green


# --- 10. Finalization (SMART REBOOT) ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  ENTIRE SETUP COMPLETE (WINDOWS + WSL)!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""

# Final robust check for reboot
if (Test-RebootRequired) {
    $Global:RebootIsNeeded = $true
}

if ($Global:RebootIsNeeded) {
    Write-Host "****************** REBOOT REQUIRED ******************" -ForegroundColor Red
    Write-Host "A reboot is required to finalize Windows Updates"
    Write-Host "and register all system runtimes."
    Write-Host "Please restart your computer now."
    Write-Host "*****************************************************" -ForegroundColor Red
} else {
    Write-Host "All tasks complete." -ForegroundColor Green
    Write-Host "Please CLOSE AND RE-OPEN your terminal (Windows Terminal) for all"
    Write-Host "PATH changes and the new Zsh shell to take effect." -ForegroundColor Yellow
}

Read-Host "Press ENTER to close..."
