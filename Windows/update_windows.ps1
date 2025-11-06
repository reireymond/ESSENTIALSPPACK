<#
.SYNOPSIS
    Script to update all Winget applications, Chocolatey packages, and clean system.
.DESCRIPTION
    1. Guarantees Administrator privileges (using gsudo) with a single prompt.
    2. Updates all Winget packages.
    3. Updates all Chocolatey packages.
    4. Cleans all temporary files and optimizes the drive.
.NOTES
    Version: 3.0 (Fully English. Merged cleanup & robust admin check)
    Author: Kaua
#>

# --- 1. Administrator Check (using gsudo) ---
# Check if gsudo is available
if (-not (Get-Command gsudo -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: 'gsudo' command not found." -ForegroundColor Red
    Write-Host "Please ensure 'gsudo' is installed (it's part of the main setup.ps1)." -ForegroundColor Red
    Read-Host "Press ENTER to exit..."
    exit
}

# Check if already admin. If not, re-launch using gsudo.
if (-not (gsudo -v 2>$null)) {
    Write-Host "Requesting Administrator privileges via gsudo..." -ForegroundColor Yellow
    # Re-launch this script as admin and exit the current one
    gsudo "$($PSCommandPath)"
    exit
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green


# --- 2. Winget Upgrade ---
Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  STARTING APPLICATION UPGRADE (WINGET)"
Write-Host "===================================================="
    
winget upgrade --all --accept-package-agreements --accept-source-agreements

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  WINGET UPGRADE COMPLETE."
Write-Host "  STARTING PACKAGE UPGRADE (CHOCOLATEY)"
Write-Host "===================================================="
Write-Host ""

# --- 3. Chocolatey Upgrade ---
# The '-y' (or '--yes') flag accepts all choco-specific prompts.
choco upgrade all -y

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  CHOCO UPGRADE COMPLETE."
Write-Host "  STARTING SYSTEM CLEANUP & OPTIMIZATION"
Write-Host "===================================================="
Write-Host ""

# --- 4. System Cleanup (from setup.ps1) ---
Write-Host "[+] Cleaning up Windows temporary files (User, System & Prefetch)..." -ForegroundColor Cyan
# Clear User Temp Folder (%temp%)
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
# Clear Windows Temp Folder (temp)
Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
# Clear Prefetch Folder (prefetch)
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "[+] Cleaning up Chocolatey package cache..." -ForegroundColor Cyan
choco cache remove --all

Write-Host "[+] Optimizing main drive (C:)... (TRIM or Defrag)" -ForegroundColor Cyan
Optimize-Volume -DriveLetter C -ErrorAction SilentlyContinue

Write-Host "System cleanup complete." -ForegroundColor Green
    
# --- 5. Finalization ---
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  SYSTEM FULLY UPDATED AND CLEANED"
Write-Host "===================================================="
Write-Host ""
Read-Host "Press ENTER to close..."
