<#
.SYNOPSIS
    Script to update all Winget applications and Chocolatey packages.
    Uses 'gsudo' to request administrator privileges for each command.
#>

Write-Host "====================================================" -ForegroundColor Green
Write-Host "  STARTING APPLICATION UPGRADE (WINGET)"
Write-Host "===================================================="
Write-Host "Admin (UAC) permission will be requested for 'gsudo'..."
Write-Host ""

# 1. Winget command using gsudo
gsudo winget upgrade --all --accept-package-agreements --accept-source-agreements

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "  WINGET UPGRADE COMPLETE."
Write-Host "  STARTING PACKAGE UPGRADE (CHOCOLATEY)"
Write-Host "===================================================="
Write-Host ""

# 2. Chocolatey command (choco upgrade all) using gsudo
# The '-y' (or '--yes') flag accepts all choco-specific prompts.
gsudo choco upgrade all -y

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  SYSTEM FULLY UPDATED (WINGET + CHOCO)"
Write-Host "===================================================="
Write-Host ""
Read-Host "Press ENTER to close..."
