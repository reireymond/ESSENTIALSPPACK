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
    Version: 4.3 (OPTIMIZED: Fixed broken packages - zap->owaspzap, freedownloadmanager->motrix, removed hiew/tokei, added error tracking)
    Author: Kaua
    LOGIC: Uses 'choco upgrade' to install (if missing) or upgrade (if existing).
#>

param(
    [string]$WslDistro = "Ubuntu"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- 0. Helper Functions & Global Variables ---
$Global:RebootIsNeeded = $false
$Global:FailedPackages = @()  # Track failed package installations

function Test-RebootRequired {
    try {
        if (Get-Command Test-PendingReboot -ErrorAction SilentlyContinue) {
            if (Test-PendingReboot -ErrorAction SilentlyContinue) { return $true }
        }
    } catch {}
    
    $RegKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
    )
    
    foreach ($key in $RegKeys) {
        if (Test-Path $key) { return $true }
    }
    
    if (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue) {
        return $true
    }
    
    return $false
}

function Install-PSModuleSafely {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    if (-not (Get-Module -ListAvailable -Name $Name)) {
        Write-Host "Installing PowerShell module: $Name..." -ForegroundColor Yellow
        try {
            Install-Module -Name $Name -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck -ErrorAction Stop
        } catch {
            Write-Host "  WARNING: Failed to install $Name - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "PowerShell module '$Name' already installed." -ForegroundColor Green
    }
}

function Install-ChocoPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$ExtraArgs = ""
    )
    
    Write-Host "  -> Installing/Upgrading: $PackageName" -ForegroundColor Cyan
    
    if ($ExtraArgs) {
        choco upgrade $PackageName -y --noprogress $ExtraArgs 2>&1 | Out-Null
    } else {
        choco upgrade $PackageName -y --noprogress 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $PackageName" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ✗ $PackageName (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
        # Track failed packages for final summary
        $Global:FailedPackages += @{Package = $PackageName; ExitCode = $LASTEXITCODE}
        return $false
    }
}

# --- CENTRALIZED PACKAGE DEFINITIONS ---
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
            @{ID="Git.Git"; Name="Git for Windows"}
        )
    }
    "choco" = @{
        # Fixed: Replaced freedownloadmanager -> motrix, removed tokei (no alternative)
        "Editors & Utilities" = @("neovim", "7zip", "powershell-core", "gsudo", "bat", "eza", "devtoys", "winmerge", "keepassxc", "windirstat", "winscp", "tor-browser", "zoxide", "motrix", "bandizip", "delta")
        "Languages & Runtimes"  = @("python3", "nodejs-lts", "openjdk17", "dotnet-sdk", "bun")
        "Build Tools & Git"     = @("gh", "github-desktop", "msys2", "ninja", "cmake.install")
        "Virtualization"        = @("docker-desktop", "virtualbox")
        "Databases & API"       = @("dbeaver", "postman", "mariadb", "nginx")
        "Hardware Diagnostics"  = @("cpu-z", "gpu-z", "hwmonitor", "crystaldiskinfo", "crystaldiskmark", "speccy", "prime95")
        "Communication"         = @("discord")
        "DevOps & Cloud"        = @("awscli", "azure-cli", "terraform", "kubernetes-cli")
        "Runtimes Essentials"  = @("vcredist-all", "dotnetfx", "directx")
        # Fixed: Replaced zap -> owaspzap
        "Cybersecurity & Pentest" = @("nmap", "wireshark", "burp-suite-free-edition", "ghidra", "x64dbg.portable", "sysinternals", "hashcat", "autopsy", "putty.install", "owaspzap", "ilspy", "volatility", "fiddler", "proxifier", "cheatengine")
        # Fixed: Removed hiew (obsolete, no alternative)
        "Reverse Engineering Pack" = @("ida-free", "rizin", "cutter", "ollydbg", "hxd")
        "Terminal Enhancements" = @("oh-my-posh", "nerd-fonts-cascadiacode")
    }
}

# --- 0.1. Check for Pending Reboot (Initial Check) ---
if (Test-RebootRequired) {
    Write-Host "WARNING: A pending system reboot was detected." -ForegroundColor Red
    Write-Host "It is highly recommended to reboot the PC before continuing." -ForegroundColor Yellow
    Read-Host "Press ENTER to continue anyway, or close the window to reboot..."
}

# --- 1. Administrator Check (gsudo fallback) ---
Write-Host "Checking for Administrator privileges..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    if (Get-Command gsudo -ErrorAction SilentlyContinue) {
        Write-Host "Requesting Administrator privileges via gsudo..." -ForegroundColor Yellow
        gsudo "$PSCommandPath" -WslDistro $WslDistro
        exit
    } else {
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
    wsl -d $WslDistro --status | Out-Null
    Write-Host "WSL 2 is already installed. Distribution: $WslDistro" -ForegroundColor Green
} catch {
    Write-Host "WSL 2 or distribution '$WslDistro' not found. Starting installation..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes..."
    
    wsl --install -d $WslDistro
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  REBOOT REQUIRED" -ForegroundColor Red
    Write-Host "============================================================"
    Write-Host "WSL 2 has been installed."
    Write-Host "PLEASE RESTART YOUR COMPUTER NOW."
    Write-Host "After rebooting, run this 'setup_windows.ps1' script again."
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
Write-Host "Enabling Chocolatey's automatic script confirmation..." -ForegroundColor Yellow
try {
    choco feature enable -n=allowGlobalConfirmation | Out-Null
    Write-Host "Feature 'allowGlobalConfirmation' enabled." -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to enable 'allowGlobalConfirmation'." -ForegroundColor Yellow
}

# --- 5. BEGINNING WINDOWS TOOL UPGRADES ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING INSTALLATION/UPGRADE OF WINDOWS TOOLS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

# 5.1: CHOCOLATEY INSTALLATIONS (ONE BY ONE FOR PROPER ERROR HANDLING)
Write-Host ">>> Starting Chocolatey installations..." -ForegroundColor Yellow

foreach ($category in $PackageDefinitions["choco"].Keys) {
    $packages = $PackageDefinitions["choco"][$category]
    if ($packages.Count -eq 0) { continue }
    
    Write-Host ""
    Write-Host "[+] Category: $category" -ForegroundColor Cyan
    
    foreach ($pkg in $packages) {
        Install-ChocoPackage -PackageName $pkg
    }
}

# 5.2: WINGET INSTALLATIONS
Write-Host ""
Write-Host ">>> Starting Winget installations..." -ForegroundColor Yellow
$WingetArguments = "--accept-package-agreements --accept-source-agreements -h"

foreach ($category in $PackageDefinitions["winget"].Keys) {
    $packages = $PackageDefinitions["winget"][$category]
    if ($packages.Count -eq 0) { continue }
    
    Write-Host ""
    Write-Host "[+] Category: $category" -ForegroundColor Cyan
    
    foreach ($pkg in $packages) {
        Write-Host "  -> Installing $($pkg.Name) ($($pkg.ID))..." -ForegroundColor Cyan
        
        $installResult = Start-Process -FilePath winget -ArgumentList "install $($pkg.ID) $WingetArguments" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        
        # Winget exit codes:
        # 0 = Success
        # -1978335189 (0x8A15000B) = No applicable update found (already up to date)
        # -1978335212 (0x8A150014) = Package not found
        
        if ($null -eq $installResult) {
            Write-Host "  ✗ Failed to launch Winget for $($pkg.Name)" -ForegroundColor Yellow
        }
        elseif ($installResult.ExitCode -eq 0) {
            Write-Host "  ✓ $($pkg.Name) installed/updated" -ForegroundColor Green
        }
        elseif ($installResult.ExitCode -eq -1978335189) {
            Write-Host "  ✓ $($pkg.Name) (already up to date)" -ForegroundColor Green
        }
        elseif ($installResult.ExitCode -eq -1978335212) {
            Write-Host "  ✗ $($pkg.Name) not found in Winget repository" -ForegroundColor Yellow
        }
        else {
            Write-Host "  ✗ $($pkg.Name) (exit code: $($installResult.ExitCode))" -ForegroundColor Yellow
        }
    }
}

# 5.3: VISUAL STUDIO 2022 (SEPARATE INSTALLATION)
Write-Host ""
Write-Host "================== LONG TASK WARNING (VS 2022) ==================" -ForegroundColor Yellow
Write-Host "Starting 'Visual Studio 2022 Community' upgrade/install."
Write-Host "This is the largest download and can take 30-60 minutes."
Write-Host "================================================================="
Write-Host ""

Install-ChocoPackage -PackageName "visualstudio2022community" -ExtraArgs "--package-parameters `"--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet`""

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  WINDOWS TOOLS UPGRADE COMPLETE!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""

# Display failed packages summary
if ($Global:FailedPackages.Count -gt 0) {
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host "  PACKAGE INSTALLATION FAILURES SUMMARY" -ForegroundColor Yellow
    Write-Host "================================================="
    Write-Host "The following packages failed to install:" -ForegroundColor Yellow
    foreach ($failure in $Global:FailedPackages) {
        Write-Host "  - $($failure.Package) (Exit Code: $($failure.ExitCode))" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "NOTE: Some packages may have been renamed, deprecated, or require" -ForegroundColor Yellow
    Write-Host "manual installation. Please check the package documentation." -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host ""
}

# --- 6. INSTALLING VS CODE EXTENSIONS ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INSTALLING VS CODE EXTENSIONS..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "[+] Installing/Updating extensions..." -ForegroundColor Cyan
    
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
        code --install-extension $ext --force 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $ext" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $ext" -ForegroundColor Yellow
        }
    }

    Write-Host "VS Code extensions installed/updated." -ForegroundColor Green
} else {
    Write-Host "WARNING: 'code.exe' not found in PATH." -ForegroundColor Yellow
}

# --- 6.1: CONFIGURING POWERSHELL 7 PROFILE ---
Write-Host ""
Write-Host "[+] Configuring PowerShell 7 Profile..." -ForegroundColor Yellow

# Setup NuGet with better error handling
try {
    Write-Host "  -> Setting up NuGet provider..." -ForegroundColor Cyan
    
    # Try to get PackageProvider first
    $nuget = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    
    if (-not $nuget) {
        # Force TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        
        # Install with minimal version
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction Stop | Out-Null
        Write-Host "  ✓ NuGet provider installed" -ForegroundColor Green
    } else {
        Write-Host "  ✓ NuGet provider already available" -ForegroundColor Green
    }
    
    # Set PSGallery as trusted
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "  ✗ NuGet setup failed (not critical): $($_.Exception.Message)" -ForegroundColor Yellow
}

# Install PowerShell modules
Write-Host "  -> Installing PowerShell modules..." -ForegroundColor Cyan
Install-PSModuleSafely -Name "PSReadLine"
Install-PSModuleSafely -Name "Terminal-Icons"
Install-PSModuleSafely -Name "Pester"

# Configure PowerShell Profile
try {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    $ProfilePath = Join-Path $ProfileDir "profile.ps1"
    
    if (-not (Test-Path $ProfileDir)) {
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
    }

    $ProfileContent = @"

# --- Productivity Pack ---
# Oh My Posh theme
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config `$env:POSH_THEMES_PATH\powerlevel10k_rainbow.omp.json | Invoke-Expression
}

# Terminal Icons
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module -Name Terminal-Icons
}

# PSReadLine improvements
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
"@
    
    $Marker = "# --- Productivity Pack ---"
    
    if (Test-Path $ProfilePath) {
        $FileContent = Get-Content $ProfilePath -Raw
        if ($FileContent -notlike "*$Marker*") {
            $ProfileContent | Out-File -FilePath $ProfilePath -Encoding UTF8 -Append
            Write-Host "  ✓ PowerShell profile configured" -ForegroundColor Green
        } else {
            Write-Host "  ✓ PowerShell profile already configured" -ForegroundColor Green
        }
    } else {
        $ProfileContent | Out-File -FilePath $ProfilePath -Encoding UTF8
        Write-Host "  ✓ PowerShell profile created" -ForegroundColor Green
    }
} catch {
    Write-Host "  ✗ PowerShell profile configuration failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# --- 7. EXECUTING WSL SCRIPT ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING AUTOMATED WSL ($WslDistro) SETUP..." -ForegroundColor Green
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
    Write-Host "The script will now run the $WslDistro (WSL) setup."
    Write-Host "PLEASE TYPE YOUR UBUNTU PASSWORD AND PRESS ENTER."
    Write-Host "============================================================="
    Write-Host ""
    
    try {
        wsl.exe -d $WslDistro sudo bash "$fullLinuxPath"
        Write-Host ""
        Write-Host "=================================================" -ForegroundColor Green
        Write-Host "  WSL ($WslDistro) SETUP COMPLETE!" -ForegroundColor Green
        Write-Host "================================================="
    } catch {
        Write-Host "ERROR: Failed to execute WSL script." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# --- 8. RUNNING WINDOWS UPDATE ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  CHECKING FOR WINDOWS UPDATES..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

Write-Host "[+] Installing 'PSWindowsUpdate' module..." -ForegroundColor Cyan
Install-PSModuleSafely -Name "PSWindowsUpdate"

try {
    Import-Module PSWindowsUpdate -Force -ErrorAction Stop
    Write-Host "[+] Searching and installing Windows Updates..." -ForegroundColor Yellow
    Write-Host "This may take a long time. Please wait..."
    
    Install-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue | Out-Null
    
    if (Test-RebootRequired) {
        $Global:RebootIsNeeded = $true
    }
    
    Write-Host "Windows Update check complete." -ForegroundColor Green
} catch {
    Write-Host "WARNING: Failed to run Windows Update." -ForegroundColor Yellow
    Write-Host "Please run Windows Update manually." -ForegroundColor Yellow
}

# --- 9. SYSTEM CLEANUP & OPTIMIZATION ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING SYSTEM CLEANUP & OPTIMIZATION..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

Write-Host "[+] Cleaning up Windows temporary files..." -ForegroundColor Cyan
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[+] Cleaning up Chocolatey cache..." -ForegroundColor Cyan
choco cache remove --all 2>&1 | Out-Null

Write-Host "[+] Optimizing drive C:..." -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -ErrorAction SilentlyContinue | Out-Null

Write-Host "System cleanup complete." -ForegroundColor Green

# --- 10. Finalization ---
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
    Write-Host "Please CLOSE AND RE-OPEN your terminal for all"
    Write-Host "PATH changes to take effect." -ForegroundColor Yellow
}

Read-Host "Press ENTER to close..."
