<#
.SYNOPSIS
    "Super" Master Script to configure the entire Windows + WSL environment.
.DESCRIPTION
    1. Guarantees Administrator privileges.
    2. Installs WSL 2 (if not installed) and prompts for a required reboot.
    3. Installs Chocolatey (if not installed).
    4. Enables Chocolatey's auto-confirmation for scripts.
    5. Installs/Upgrades ALL Windows tools via Chocolatey.
    6. Installs essential VS Code Extensions.
    7. Automatically executes the 'wsl_ubuntu.sh' script.
    8. Installs all pending Windows Updates.
    9. Cleans up all temp files and optimizes the system.
.NOTES
    Version: 1.9 (Final Robust Edition)
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

# --- 5. BEGINNING WINDOWS TOOL UPGRADES ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING INSTALLATION/UPGRADE OF WINDOWS TOOLS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
$env:ChocolateyInstallArguments = "--yes"

# 5.1: Editors, Terminals & Utilities
Write-Host "[+] Upgrading Editors, Terminals & Utilities..." -ForegroundColor Cyan
choco upgrade vscode; choco upgrade microsoft-windows-terminal; choco upgrade neovim; choco upgrade 7zip; choco upgrade powershell-core

# 5.2: Browsers
Write-Host "[+] Upgrading Browsers..." -ForegroundColor Cyan
choco upgrade firefox-developer-edition; choco upgrade googlechrome

# 5.3: Programming Languages & Runtimes
Write-Host "[+] Upgrading Languages & Runtimes..." -ForegroundColor Cyan
choco upgrade python3; choco upgrade nodejs-lts; choco upgrade openjdk17; choco upgrade dotnet-sdk

# 5.4: Build Tools & Version Control
Write-Host "[+] Upgrading Build Tools & Version Control..." -ForegroundColor Cyan
choco upgrade git.install; choco upgrade cmake.install --installargs 'ADD_CMAKE_TO_PATH_System'; choco upgrade msys2

# 5.5: Microsoft C++ Build Tools (MSVC)
Write-Host "[+] Upgrading Visual Studio 2022 Community IDE (for C++)..." -ForegroundColor Cyan
choco upgrade visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet"

# 5.6: Virtualization & Containers
Write-Host "[+] Upgrading Virtualization & Containers..." -ForegroundColor Cyan
choco upgrade docker-desktop; choco upgrade virtualbox

# 5.7: Databases & APIs
Write-Host "[+] Upgrading Database & API Clients..." -ForegroundColor Cyan
choco upgrade dbeaver; choco upgrade postman

# 5.8: Hardware Diagnostics, Benchmark & Monitoring
Write-Host "[+] Upgrading Hardware Diagnostics & Benchmark Kit..." -ForegroundColor Cyan
choco upgrade cpu-z; choco upgrade gpu-z; choco upgrade hwmonitor; choco upgrade crystaldiskinfo; choco upgrade crystaldiskmark; choco upgrade speccy; choco upgrade msi-afterburner; choco upgrade prime95

# 5.9: Productivity & Communication
Write-Host "[+] Upgrading Communication Tools..." -ForegroundColor Cyan
choco upgrade discord

# 5.10: DevOps & Cloud Tools
Write-Host "[+] Upgrading DevOps & Cloud Tools..." -ForegroundColor Cyan
choco upgrade aws-cli; choco upgrade azure-cli; choco upgrade terraform

# 5.11: Advanced Utilities & Personal Security
Write-Host "[+] Upgrading Advanced Utilities & Security..." -ForegroundColor Cyan
choco upgrade gsudo; choco upgrade keepassxc; choco upgrade windirstat; choco upgrade winscp

# 5.12: CYBERSECURITY & PENTESTING (Host)
Write-Host "[+] Upgrading Cybersecurity & Pentesting Arsenal..." -ForegroundColor Magenta
choco upgrade nmap; choco upgrade wireshark; choco upgrade zenmap; choco upgrade burpsuite; choco upgrade sqlmap; choco upgrade owasp-zap; choco upgrade ghidra; choco upgrade x64dbg; choco upgrade sysinternals; choco upgrade hashcat; choco upgrade autopsy; choco upgrade metasploit-framework; choco upgrade putty

# 5.13: ESSENTIAL DEPENDENCIES (Runtimes)
Write-Host "[+] Upgrading Essential Runtimes..." -ForegroundColor Yellow
choco upgrade vcredist-all; choco upgrade dotnet3.5; choco upgrade dotnetfx; choco upgrade jre8; choco upgrade directx
Write-Host "Some runtimes may require a reboot. This will be checked at the end."

# 5.14: TERMINAL ENHANCEMENTS (Oh My Posh + Font)
Write-Host "[+] Upgrading Terminal Enhancements (Oh My Posh + Nerd Font)..." -ForegroundColor Cyan
choco upgrade oh-my-posh
choco upgrade caskaydiacove-nerdfont
Write-Host "Oh My Posh e CaskaydiaCove NF (Nerd Font) instalados/atualizados."

# 5.15: CONFIGURING POWERSHELL 7 PROFILE (Oh My Posh)
Write-Host "[+] Configuring PowerShell 7 Profile for Oh My Posh..." -ForegroundColor Yellow
try {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    $ProfilePath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"
    
    if (-not (Test-Path $ProfileDir)) {
        Write-Host "Creating PowerShell profile directory: $ProfileDir"
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
    }

    $OmpLine = "oh-my-posh init pwsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/jandedobbeleer.json' | Invoke-Expression"
    
    $FileContent = if (Test-Path $ProfilePath) { Get-Content $ProfilePath } else { $null }
    
    if ($FileContent -notcontains $OmpLine) {
        Write-Host "Adding Oh My Posh config to $ProfilePath..."
        Add-Content -Path $ProfilePath -Value $OmpLine
        Write-Host "Oh My Posh configurado." -ForegroundColor Green
    } else {
        Write-Host "Oh My Posh configuration already present in profile." -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to configure PowerShell profile." -ForegroundColor Red
    Write-Host "You may need to add the Oh My Posh init line manually."
}

Write-Host "=================================================" -ForegroundColor Green
Write-Host "  WINDOWS TOOLS UPGRADE COMPLETE!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""


# --- 6. INSTALLING VS CODE EXTENSIONS (Robust Check) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INSTALLING VS CODE EXTENSIONS..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "[+] Installing extensions for Git, Icons, and General Coding..." -ForegroundColor Cyan
    code --install-extension pkief.material-icon-theme --force
    code --install-extension eamodio.gitlens --force
    code --install-extension formulahendry.code-runner --force
    code --install-extension visualstudioexptteam.vscodeintellicode --force
    code --install-extension github.copilot --force

    Write-Host "[+] Installing extensions for Web Development (HTML/CSS/JS)..." -ForegroundColor Cyan
    code --install-extension esbenp.prettier-vscode --force
    code --install-extension dbaeumer.vscode-eslint --force
    code --install-extension ritwickdey.liveserver --force

    Write-Host "[+] Installing extensions for C/C++, Python, Java, and WSL..." -ForegroundColor Cyan
    code --install-extension ms-vscode.cpptools --force
    code --install-extension ms-vscode.cmake-tools --force
    code --install-extension ms-python.python --force
    code --install-extension ms-python.vscode-pylance --force
    code --install-extension vscjava.vscode-java-pack --force
    code --install-extension ms-vscode-remote.remote-wsl --force
    code --install-extension ms-azuretools.vscode-docker --force

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
    Write-Host "Executing 'wsl.exe' to run the script... (This will ask for your Ubuntu sudo password)" -ForegroundColor Yellow
    
    try {
        wsl.exe sudo bash "$fullLinuxPath"
        Write-Host "=================================================" -ForegroundColor Green
        Write-Host "  WSL (UBUNTU) SETUP COMPLETE!" -ForegroundColor Green
        Write-Host "================================================="
    } catch {
        Write-Host "ERROR: Failed to execute WSL script." -ForegroundColor Red
        Write-Host "You may need to run it manually: ./wsl_ubuntu.sh" -ForegroundColor Red
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
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    Install-Module -Name PSWindowsUpdate -Force -AcceptLicense -Confirm:$false
    Import-Module PSWindowsUpdate -Force
    
    Write-Host "[+] Searching, downloading, and installing all Windows Updates..." -ForegroundColor Yellow
    Write-Host "This may take a long time..."
    
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
