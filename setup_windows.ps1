<#
.SYNOPSIS
    "Super" Master Script to configure the entire Windows + WSL environment.
.DESCRIPTION
    1. Guarantees Administrator privileges (using gsudo if available, or manual check).
    2. Installs WSL 2 (if not installed) and prompts for a required reboot.
    3. Installs Chocolatey (if not installed).
    4. Enables Chocolatey's auto-confirmation for scripts.
    5. Installs/Upgrades ALL Windows tools via Chocolatey (centralized batches).
    6. Installs essential VS Code Extensions.
    7. Automatically executes the 'wsl_ubuntu.sh' script.
    8. Installs all pending Windows Updates.
    9. Cleans up all temp files and optimizes the system.
.NOTES
    Version: 3.6 (Adicionado StrictMode, Checagem Inicial de Reboot, Novas Ferramentas, gsudo fallback)
    Author: Kaua
    LOGIC: Uses 'choco upgrade' to install (if missing) or upgrade (if existing).
#>

Set-StrictMode -Version Latest # MELHORIA: Força verificação rigorosa de erros

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

# Função para instalar módulo PS com checagem
function Install-PSModuleSafely {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Host "Instalando módulo PowerShell: $Name..." -ForegroundColor Yellow
        Install-Module -Name $Name -Force -Scope CurrentUser -Confirm:$false -ForceBootstrap -ErrorAction Stop
    } else {
        Write-Host "Módulo PowerShell '$Name' já instalado." -ForegroundColor Green
    }
}

# --- DEFINIÇÃO CENTRALIZADA DE PACOTES ---
# Tipos: 'choco' (Chocolatey), 'winget' (Winget)
$PackageDefinitions = @{
    "winget" = @{
        "Editors & Terminals" = @(
            @{ID="Microsoft.VisualStudioCode"; Name="VS Code"}
            @{ID="Microsoft.WindowsTerminal"; Name="Windows Terminal"}
        )
        "Browsers" = @(
            @{ID="Google.Chrome"; Name="Google Chrome"}
            @{ID="Mozilla.Firefox"; Name="Mozilla Firefox"}
        )
        "Advanced Utilities & Security" = @(
            @{ID="Insomnia.Insomnia"; Name="Insomnia API Client"}
            @{ID="Microsoft.PowerToys"; Name="Microsoft PowerToys"}
            @{ID="Obsidian.Obsidian"; Name="Obsidian Notes"}
            @{ID="Git.CredentialManager"; Name="Git Credential Manager"}
        )
    }
    "choco" = @{
        "Editors & Utilities" = @("neovim", "7zip", "powershell-core", "gsudo", "bat", "eza", "devtoys", "winmerge", "keepassxc", "windirstat", "winscp", "tor-browser", "zoxide", "freedownloadmanager", "bandizip", "delta", "tokei") # ADIÇÃO: delta, tokei
        "Languages & Runtimes"  = @("python3", "nodejs-lts", "openjdk17", "dotnet-sdk", "bun") # ADIÇÃO: bun
        "Build Tools & Git"     = @("git.install", "gh", "github-desktop", "msys2", "ninja") # ADIÇÃO: ninja
        "Virtualization"        = @("docker-desktop", "virtualbox")
        "Databases & API"       = @("dbeaver", "postman", "mariadb", "nginx")
        "Hardware Diagnostics"  = @("cpu-z", "gpu-z", "hwmonitor", "crystaldiskinfo", "crystaldiskmark", "speccy", "prime95")
        "Communication"         = @("discord")
        "DevOps & Cloud"        = @("awscli", "azure-cli", "terraform", "kubernetes-cli")
        "Runtimes Essenciais"  = @("vcredist-all", "dotnet3.5", "dotnetfx", "jre8", "directx")
        "Cybersecurity & Pentest" = @("nmap", "wireshark", "burp-suite-free-edition", "ghidra", "post", "x64dbg.portable", "sysinternals", "hashcat", "autopsy", "putty", "zap", "ilspy", "cff-explorer-suite", "volatility3", "fiddler-classic", "proxifier", "cheatengine") # ADIÇÃO: cheatengine
        "Terminal Enhancements" = @("oh-my-posh", "nerd-fonts-cascadiacode")
    }
}
# ----------------------------------------------

# --- 0.1. Check for Pending Reboot (Initial Check) ---
if (Test-RebootRequired) {
    Write-Host "WARNING: A pending system reboot was detected." -ForegroundColor Red
    Write-Host "It is highly recommended to reboot the PC before continuing, as installation steps might fail." -ForegroundColor Yellow
    Read-Host "Press ENTER to continue anyway, or close the window to reboot..."
}

# --- 1. Administrator Check (gsudo fallback) ---
Write-Host "Checking for Administrator privileges..." -ForegroundColor Yellow
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Tenta relançar o script com gsudo se ele já estiver disponível no PATH
    if (Get-Command gsudo -ErrorAction SilentlyContinue) {
        Write-Host "Requesting Administrator privileges via gsudo..." -ForegroundColor Yellow
        # Relança este script como admin e sai do atual
        gsudo "$($PSCommandPath)"
        exit
    } else {
        # Fallback para instrução manual se gsudo não estiver disponível (uso inicial)
        Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
        Write-Host "Please right-click the script and 'Run as Administrator'." -ForegroundColor Red
        Read-Host "Press ENTER to exit..."
        exit
    }
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green

# --- 2. WSL 2 Check & Installation ---
Write-Host ""
Write-Host "Checking WSL 2 installation..." -ForegroundColor Yellow
try {
    wsl --status | Out-Null
    Write-Host "WSL 2 is already installed." -ForegroundColor Green
} catch {
    Write-Host "WSL 2 not found. Starting installation..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes..."
    
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
    exit
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
    choco feature enable -n=allowGlobalConfirmation
    Write-Host "Feature 'allowGlobalConfirmation' enabled." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to enable 'allowGlobalConfirmation'. Script may prompt for confirmation." -ForegroundColor Red
}

# --- 5. BEGINNING WINDOWS TOOL UPGRADES (Batch Loop) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING INSTALLATION/UPGRADE OF WINDOWS TOOLS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
$env:ChocolateyInstallArguments = "--yes" # Define for choco
$WingetArguments = "--accept-package-agreements --accept-source-agreements -h" # Define for winget

# 5.1: INSTALAÇÃO DE PACOTES GERAIS (CHOCOLATEY E WINGET)
foreach ($Manager in $PackageDefinitions.Keys) {
    Write-Host ""
    Write-Host ">>> Iniciando instalações via $Manager..." -ForegroundColor Yellow
    
    foreach ($category in $PackageDefinitions[$Manager].Keys) {
        $packages = $PackageDefinitions[$Manager][$category]
        if ($packages.Count -eq 0) { continue }
        
        Write-Host "[+] Upgrading $category..." -ForegroundColor Cyan
        
        try {
            if ($Manager -eq "choco") {
                $packageNames = $packages -join " "
                choco upgrade $packageNames -y -r --noprogress
            } elseif ($Manager -eq "winget") {
                foreach ($pkg in $packages) {
                    Write-Host "  -> Instalando $($pkg.Name) ($($pkg.ID))..."
                    winget install $($pkg.ID) $WingetArguments | Out-Null
                }
            }
        } catch {
            Write-Host "AVISO: Falha ao instalar/atualizar um ou mais pacotes na categoria '$category' via $Manager." -ForegroundColor Yellow
            # Não paramos o script aqui, apenas emitimos um aviso, pois é um lote grande.
        }
    }
}

# 5.2: INSTALAÇÕES MANUAIS / COMPLEXAS
Write-Host ""
Write-Host "================== LONG TASK WARNING (VS 2022) ==================" -ForegroundColor Yellow
Write-Host "Starting 'Visual Studio 2022 Community' upgrade/install."
Write-Host "This is the largest download and can take 30-60 minutes."
Write-Host "The terminal MAY APPEAR FROZEN. This is normal. Please wait..."
Write-Host "================================================================="
Write-Host "[+] Upgrading Visual Studio 2022 Community IDE (for C++)..." -ForegroundColor Cyan
choco upgrade visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet" -y --noprogress

Write-Host "[+] Upgrading CMake with Path set..." -ForegroundColor Cyan
choco upgrade cmake.install --install-arguments 'ADD_CMAKE_TO_PATH_System' -y --noprogress

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
        "firefox-devtools.vscode-firefox-debug",
        "dart-code.dart-code",
        "dart-code.flutter"
    )

    foreach ($ext in $extensions) {
        Write-Host "Installing $ext..."
        code --install-extension $ext --force
    }

    Write-Host "VS Code extensions installed/updated." -ForegroundColor Green
} else {
    Write-Host "ERROR: 'code.exe' not found in PATH. Skipping VS Code extension install." -ForegroundColor Red
    Write-Host "Please restart your terminal and run the script again if VS Code was just installed."
}


# --- 6.1: CONFIGURANDO POWERSHELL 7 PROFILE (Productivity Pack) ---
Write-Host "[+] Installing essential PowerShell Modules (Pester, PSReadLine)..." -ForegroundColor Yellow
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
Install-PSModuleSafely -Name "Pester"
Install-PSModuleSafely -Name "PSReadLine"
Install-PSModuleSafely -Name "Microsoft.PowerShell.Archive"

Write-Host "[+] Configuring PowerShell 7 Profile (Oh My Posh, Terminal-Icons, PSReadLine)..." -ForegroundColor Yellow
try {
    Write-Host "[+] Instalando 'Terminal-Icons' module..."
    Install-PSModuleSafely -Name "Terminal-Icons"

    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    $ProfilePath = Join-Path $ProfileDir "profile.ps1"
    
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
    
    $FileContent = if (Test-Path $ProfilePath) { Get-Content $ProfilePath -Raw } else { "" }

    $Marker = "# --- Productivity Pack Start ---"
    
    if ($FileContent -notlike "*$Marker*") {
        Write-Host "Adding Productivity Pack to $ProfilePath..."
        $ProfileContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Append
        Write-Host "PowerShell profile configured." -ForegroundColor Green
    } else {
        Write-Host "PowerShell profile already contains Productivity Pack. Skipping." -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: Failed to configure PowerShell profile." -ForegroundColor Red
    Write-Host $_.Exception.Message
}


# --- 7. EXECUTING WSL SCRIPT (Automated Section) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING AUTOMATED WSL (UBUNTU) SETUP..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

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
        wsl.exe -d Ubuntu sudo bash "$fullLinuxPath"
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
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-PSModuleSafely -Name "PSWindowsUpdate"
    Import-Module PSWindowsUpdate -Force
    
    Write-Host "[+] Searching, downloading, and installing all Windows Updates..." -ForegroundColor Yellow
    Write-Host "This is the other step that MAY TAKE A VERY LONG TIME. Please wait..."
    
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
