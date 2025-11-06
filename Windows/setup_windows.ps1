<#
.SYNOPSIS
    "Super" Master Script to configure the entire Windows + WSL environment.
.DESCRIPTION
    1. Guarantees Administrator privileges (using gsudo if available, or manual check).
    2. Installs WSL 2 (if not installed) and prompts for a required reboot.
    3. Installs Chocolatey (if not installed).
    4. Enables Chocolatey's auto-confirmation for scripts.
    5. Installs/Upgrades ALL Windows tools via Winget (priority) and Chocolatey (fallback).
    6. Installs essential VS Code Extensions.
    7. Automatically executes the 'wsl_ubuntu.sh' script.
    8. Installs all pending Windows Updates.
    9. Cleans up all temp files and optimizes the system.
.NOTES
    Version: 5.0 (Refactored: JSON config, hybrid install, smart existence checks)
    Author: Kaua
    LOGIC: Uses hybrid Install-Package function with winget priority and choco fallback.
    IMPROVEMENTS: 
    - Externalized packages to packages_windows.json for easy maintenance
    - Hybrid Install-Package function with smart existence checks
    - Added hxd and cloc packages as requested
    - Maintains special handling for MariaDB and Visual Studio
    - Detailed logging with JSON summary saved to %LOCALAPPDATA%\ESSENTIALSPPACK\
#>

param(
    [string]$WslDistro = "Ubuntu"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- 0. Helper Functions & Global Variables ---
$Global:RebootIsNeeded = $false
$Global:InstallSummary = @{
    Succeeded = @()
    Failed = @()
    Skipped = @()
}

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
            Install-Module -Name $Name -Force -Scope AllUsers -AllowClobber -SkipPublisherCheck -ErrorAction Stop
        } catch {
            Write-Host "  WARNING: Failed to install $Name - $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "PowerShell module '$Name' already installed." -ForegroundColor Green
    }
}

function Write-InstallSummary {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  INSTALLATION SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Host "✓ Succeeded ($($Global:InstallSummary.Succeeded.Count)):" -ForegroundColor Green
    if ($Global:InstallSummary.Succeeded.Count -gt 0) {
        foreach ($pkg in $Global:InstallSummary.Succeeded) {
            Write-Host "  - $pkg" -ForegroundColor Green
        }
    } else {
        Write-Host "  (none)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "✗ Failed ($($Global:InstallSummary.Failed.Count)):" -ForegroundColor Red
    if ($Global:InstallSummary.Failed.Count -gt 0) {
        foreach ($pkg in $Global:InstallSummary.Failed) {
            if ($pkg -is [hashtable]) {
                Write-Host "  - $($pkg.Package) (Exit: $($pkg.ExitCode), Error: $($pkg.Error))" -ForegroundColor Red
            } else {
                Write-Host "  - $pkg" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  (none)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "⊘ Skipped ($($Global:InstallSummary.Skipped.Count)):" -ForegroundColor Yellow
    if ($Global:InstallSummary.Skipped.Count -gt 0) {
        foreach ($pkg in $Global:InstallSummary.Skipped) {
            Write-Host "  - $pkg" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  (none)" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    
    # Create log directory
    $logDir = Join-Path $env:LOCALAPPDATA "ESSENTIALSPPACK"
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Generate log file name with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFile = Join-Path $logDir "install-log-$timestamp.json"
    
    # Prepare summary object for JSON
    $summaryObject = @{
        Timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        ScriptVersion = "5.0"
        Succeeded = $Global:InstallSummary.Succeeded
        Failed = $Global:InstallSummary.Failed
        Skipped = $Global:InstallSummary.Skipped
        Statistics = @{
            TotalSucceeded = $Global:InstallSummary.Succeeded.Count
            TotalFailed = $Global:InstallSummary.Failed.Count
            TotalSkipped = $Global:InstallSummary.Skipped.Count
        }
    }
    
    # Write to JSON file
    try {
        $summaryObject | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFile -Encoding UTF8
        Write-Host "Installation log saved to: $logFile" -ForegroundColor Green
    } catch {
        Write-Host "WARNING: Failed to write log file: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Install-PackageWithChoco {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$ExtraArgs = "",
        [scriptblock]$SpecialHandler = $null
    )
    
    Write-Host "  -> Installing/Upgrading: $PackageName" -ForegroundColor Cyan
    
    # Capture output and errors
    $output = ""
    $exitCode = 0
    
    try {
        if ($ExtraArgs) {
            $output = choco upgrade $PackageName -y --noprogress $ExtraArgs 2>&1 | Out-String
        } else {
            $output = choco upgrade $PackageName -y --noprogress 2>&1 | Out-String
        }
        $exitCode = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $exitCode = -1
    }
    
    # Run special handler if provided
    if ($null -ne $SpecialHandler) {
        & $SpecialHandler -ExitCode $exitCode -Output $output -PackageName $PackageName
    }
    
    # Standard exit code handling
    if ($exitCode -eq 0) {
        Write-Host "  ✓ $PackageName" -ForegroundColor Green
        $Global:InstallSummary.Succeeded += $PackageName
        return $true
    } elseif ($exitCode -eq 1605 -or $exitCode -eq 1614 -or $exitCode -eq 1641) {
        # 1605 = Product not found (already installed)
        # 1614 = Product already installed
        # 1641 = Restart initiated
        Write-Host "  ✓ $PackageName (already installed or requires restart)" -ForegroundColor Green
        $Global:InstallSummary.Succeeded += $PackageName
        return $true
    } elseif ($exitCode -eq 1603) {
        # MSI fatal error - common with database packages
        Write-Host "  ✗ $PackageName (MSI fatal error 1603)" -ForegroundColor Red
        Write-Host "    Hint: Check for conflicting installations or locked files" -ForegroundColor Yellow
        $Global:InstallSummary.Failed += @{
            Package = $PackageName
            ExitCode = $exitCode
            Error = "MSI fatal error 1603"
        }
        return $false
    } else {
        Write-Host "  ✗ $PackageName (exit code: $exitCode)" -ForegroundColor Yellow
        $Global:InstallSummary.Failed += @{
            Package = $PackageName
            ExitCode = $exitCode
            Error = if ($output -match "error|failed") { ($output -split "`n" | Select-Object -First 3) -join "; " } else { "Unknown error" }
        }
        return $false
    }
}

# Legacy wrapper for compatibility
function Install-ChocoPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$ExtraArgs = ""
    )
    Install-PackageWithChoco -PackageName $PackageName -ExtraArgs $ExtraArgs
}

# --- LOAD PACKAGE DEFINITIONS FROM JSON ---
$PackageJsonPath = Join-Path $PSScriptRoot "packages_windows.json"
if (-not (Test-Path $PackageJsonPath)) {
    Write-Host "ERROR: packages_windows.json not found at: $PackageJsonPath" -ForegroundColor Red
    Read-Host "Press ENTER to exit..."
    exit
}

try {
    $PackageDefinitions = Get-Content $PackageJsonPath -Raw | ConvertFrom-Json
    Write-Host "Package definitions loaded from JSON successfully." -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to parse packages_windows.json" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Read-Host "Press ENTER to exit..."
    exit
}

# --- HYBRID INSTALLATION FUNCTION ---
function Install-Package {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PackageName,
        [string]$WingetId = "",
        [scriptblock]$SpecialHandler = $null
    )
    
    Write-Host "  -> Installing: $PackageName" -ForegroundColor Cyan
    
    # Check if package is already installed (winget check)
    if ($WingetId) {
        try {
            $wingetList = winget list --id $WingetId 2>&1
            if ($LASTEXITCODE -eq 0 -and $wingetList -match $WingetId) {
                Write-Host "  ✓ $PackageName (already installed via winget)" -ForegroundColor Green
                $Global:InstallSummary.Succeeded += $PackageName
                return $true
            }
        } catch {
            # Continue to installation
        }
    }
    
    # Check if package is already installed (choco check)
    try {
        $chocoList = choco list --local-only $PackageName --exact 2>&1
        if ($LASTEXITCODE -eq 0 -and $chocoList -match "1 packages installed") {
            Write-Host "  ✓ $PackageName (already installed via choco)" -ForegroundColor Green
            $Global:InstallSummary.Succeeded += $PackageName
            return $true
        }
    } catch {
        # Continue to installation
    }
    
    # Try winget first if WingetId is provided
    if ($WingetId) {
        Write-Host "    Trying winget..." -ForegroundColor Gray
        $installResult = Start-Process -FilePath winget -ArgumentList "install --id $WingetId --accept-package-agreements --accept-source-agreements -h" -Wait -NoNewWindow -PassThru -ErrorAction SilentlyContinue
        
        if ($null -ne $installResult -and $installResult.ExitCode -eq 0) {
            Write-Host "  ✓ $PackageName (installed via winget)" -ForegroundColor Green
            $Global:InstallSummary.Succeeded += $PackageName
            return $true
        } elseif ($null -ne $installResult -and $installResult.ExitCode -eq -1978335189) {
            # Already up to date
            Write-Host "  ✓ $PackageName (already up to date via winget)" -ForegroundColor Green
            $Global:InstallSummary.Succeeded += $PackageName
            return $true
        }
        
        Write-Host "    Winget failed, trying chocolatey..." -ForegroundColor Yellow
    }
    
    # Try chocolatey as fallback or primary method
    $output = ""
    $exitCode = 0
    
    try {
        $output = choco upgrade $PackageName -y --noprogress 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } catch {
        $output = $_.Exception.Message
        $exitCode = -1
    }
    
    # Run special handler if provided
    if ($null -ne $SpecialHandler) {
        & $SpecialHandler -ExitCode $exitCode -Output $output -PackageName $PackageName
    }
    
    # Standard exit code handling
    if ($exitCode -eq 0) {
        Write-Host "  ✓ $PackageName (installed via choco)" -ForegroundColor Green
        $Global:InstallSummary.Succeeded += $PackageName
        return $true
    } elseif ($exitCode -eq 1605 -or $exitCode -eq 1614 -or $exitCode -eq 1641) {
        # Already installed or requires restart
        Write-Host "  ✓ $PackageName (already installed or requires restart)" -ForegroundColor Green
        $Global:InstallSummary.Succeeded += $PackageName
        return $true
    } elseif ($exitCode -eq 1603) {
        # MSI fatal error
        Write-Host "  ✗ $PackageName (MSI fatal error 1603)" -ForegroundColor Red
        $Global:InstallSummary.Failed += @{
            Package = $PackageName
            ExitCode = $exitCode
            Error = "MSI fatal error 1603"
        }
        return $false
    } else {
        Write-Host "  ✗ $PackageName (exit code: $exitCode)" -ForegroundColor Yellow
        $Global:InstallSummary.Failed += @{
            Package = $PackageName
            ExitCode = $exitCode
            Error = if ($output -match "error|failed") { ($output -split "`n" | Select-Object -First 3) -join "; " } else { "Unknown error" }
        }
        return $false
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
    
    # Verify the setting was applied
    $confirmSetting = choco config list | Select-String "allowGlobalConfirmation"
    if ($confirmSetting -match "Enabled") {
        Write-Host "Verification: allowGlobalConfirmation is confirmed enabled." -ForegroundColor Green
    }
} catch {
    Write-Host "WARNING: Failed to enable 'allowGlobalConfirmation'." -ForegroundColor Yellow
}

# --- 5. BEGINNING WINDOWS TOOL UPGRADES ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  STARTING INSTALLATION/UPGRADE OF WINDOWS TOOLS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

# 5.1: INSTALL WINGET PACKAGES (Priority: try winget first, fallback to choco)
Write-Host ">>> Starting Winget package installations (with Chocolatey fallback)..." -ForegroundColor Yellow
Write-Host ""
Write-Host "[+] Installing Winget packages (priority method)" -ForegroundColor Cyan

foreach ($packageId in $PackageDefinitions.winget) {
    Install-Package -PackageName $packageId -WingetId $packageId
}

# 5.2: INSTALL CHOCOLATEY-ONLY PACKAGES
Write-Host ""
Write-Host ">>> Starting Chocolatey-only package installations..." -ForegroundColor Yellow
Write-Host ""
Write-Host "[+] Installing Chocolatey packages" -ForegroundColor Cyan

# MariaDB special handler for exit code 1603
$mariadbHandler = {
    param($ExitCode, $Output, $PackageName)
    
    if ($ExitCode -eq 1603) {
        Write-Host ""
        Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  MariaDB Installation Failed (MSI Error 1603)" -ForegroundColor Red
        Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host "  Troubleshooting Steps:" -ForegroundColor Yellow
        Write-Host "  1. Uninstall any existing MySQL/MariaDB installations via Control Panel" -ForegroundColor Yellow
        Write-Host "  2. Delete C:\Program Files\MariaDB* and C:\ProgramData\MySQL folders" -ForegroundColor Yellow
        Write-Host "  3. Restart your computer" -ForegroundColor Yellow
        Write-Host "  4. Re-run this script to install MariaDB" -ForegroundColor Yellow
        Write-Host "  ════════════════════════════════════════════════════════" -ForegroundColor Red
        Write-Host ""
        
        $Global:InstallSummary.Skipped += "mariadb (conflict detected - manual intervention required)"
    }
}

foreach ($packageName in $PackageDefinitions.choco) {
    # Special handling for mariadb
    if ($packageName -eq "mariadb") {
        # Check for existing MySQL/MariaDB installations
        $existingMySQL = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*MySQL*" -or $_.Name -like "*MariaDB*" }
        
        if ($existingMySQL) {
            Write-Host "  ⚠ Existing MySQL/MariaDB installation detected:" -ForegroundColor Yellow
            foreach ($product in $existingMySQL) {
                Write-Host "    - $($product.Name) (v$($product.Version))" -ForegroundColor Yellow
            }
            Write-Host "  Attempting to install/upgrade MariaDB anyway..." -ForegroundColor Yellow
        }
        
        Install-Package -PackageName $packageName -SpecialHandler $mariadbHandler
    }
    # Special handling for Visual Studio 2022 with extra parameters
    elseif ($packageName -eq "visualstudio2022community") {
        Write-Host ""
        Write-Host "================== LONG TASK WARNING (VS 2022) ==================" -ForegroundColor Yellow
        Write-Host "Starting 'Visual Studio 2022 Community' upgrade/install."
        Write-Host "This is the largest download and can take 30-60 minutes."
        Write-Host "================================================================="
        Write-Host ""
        
        # For VS2022, we need to use the old function with special parameters
        Install-PackageWithChoco -PackageName $packageName -ExtraArgs "--package-parameters `"--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet`""
    }
    else {
        Install-Package -PackageName $packageName
    }
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  WINDOWS TOOLS UPGRADE COMPLETE!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""

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

# --- 9.1: WRITE INSTALLATION SUMMARY ---
Write-InstallSummary

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
