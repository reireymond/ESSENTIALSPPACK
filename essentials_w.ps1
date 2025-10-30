<#
.SYNOPSIS
    Script de configuração de ambiente de Desenvolvimento e Cibersegurança.
    Usa o Chocolatey para instalar todas as ferramentas.
.DESCRIPTION
    Este script automatiza a instalação de IDEs, linguagens,
    ferramentas de build, um conjunto de ferramentas de pentesting
    e todos os runtimes e dependências essenciais do Windows.
.NOTES
    Versão: 1.2
    Autor: Kaua
    REQUISITO: Execute este script como ADMINISTRADOR.
    REQUISITO: Instale o Chocolatey primeiro!
#>

# --- Configuração Inicial ---
# Define o Chocolatey para aceitar todas as confirmações automaticamente.
$env:ChocolateyInstallArguments = "--yes"

Clear-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INICIANDO A CONFIGURAÇÃO DO AMBIENTE (DEV & PENTESTING)" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""
Write-Host "IMPORTANTE:" -ForegroundColor Yellow
Write-Host "1. Este script DEVE ser executado como Administrador." -ForegroundColor Yellow
Write-Host "2. O WSL2 (com Ubuntu) deve ser instalado ANTES de rodar." -ForegroundColor Yellow
Write-Host "   (Use 'wsl --install' no PowerShell Admin e reinicie)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pressione ENTER para continuar ou CTRL+C para cancelar..." -ForegroundColor Gray
Read-Host

# --- 1. Editores, Terminais e Utilitários ---
Write-Host ""
Write-Host "[+] Instalando Editores, Terminais e Utilitários..." -ForegroundColor Cyan
choco install vscode
choco install microsoft-windows-terminal
choco install neovim
choco install 7zip
choco install powershell-core

# --- 2. Navegadores ---
Write-Host ""
Write-Host "[+] Instalando Navegadores..." -ForegroundColor Cyan
choco install firefox-developer-edition
choco install googlechrome

# --- 3. Linguagens de Programação e Runtimes ---
Write-Host ""
Write-Host "[+] Instalando Linguagens e Runtimes..." -ForegroundColor Cyan
choco install python3
choco install nodejs-lts
choco install openjdk17
choco install dotnet-sdk

# --- 4. Ferramentas de Build e Controle de Versão ---
Write-Host ""
Write-Host "[+] Instalando Ferramentas de Build e Controle de Versão..." -ForegroundColor Cyan
choco install git.install
choco install cmake.install --installargs 'ADD_CMAKE_TO_PATH=System'
choco install msys2

# --- 5. Ferramentas de Build C++ da Microsoft (MSVC) ---
Write-Host ""
Write-Host "[+] Instalando IDE Visual Studio 2022 Community (para C++)..." -ForegroundColor Cyan
choco install visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet"

# --- 6. Virtualização e Contêineres ---
Write-Host ""
Write-Host "[+] Instalando Ferramentas de Virtualização..." -ForegroundColor Cyan
choco install docker-desktop
choco install virtualbox

# --- 7. Banco de Dados e APIs ---
Write-Host ""
Write-Host "[+] Instalando Clientes de API e Banco de Dados..." -ForegroundColor Cyan
choco install dbeaver
choco install postman

# --- 8. Diagnóstico de Hardware ---
Write-Host ""
Write-Host "[+] Instalando Ferramentas de Diagnóstico de Hardware..." -ForegroundColor Cyan
choco install cpu-z
choco install gpu-z
choco install hwmonitor

# --- 9. CIBERSEGURANÇA E PENTESTING (Host) ---
Write-Host ""
Write-Host "[+] Instalando Arsenal de Cibersegurança e Pentesting..." -ForegroundColor Magenta

# 9.1. Análise de Rede
Write-Host "  -> Análise de Rede..." -ForegroundColor Magenta
choco install nmap
choco install wireshark
choco install zenmap

# 9.2. Análise de Aplicações Web
Write-Host "  -> Análise Web..." -ForegroundColor Magenta
choco install burpsuite
choco install sqlmap
choco install owasp-zap

# 9.3. Engenharia Reversa e Forense
Write-Host "  -> Engenharia Reversa e Forense..." -ForegroundColor Magenta
choco install ghidra
choco install x64dbg
choco install sysinternals
choco install hashcat
choco install autopsy                 # Nova adição: Plataforma de análise forense

# 9.4. Exploração e Frameworks
Write-Host "  -> Frameworks de Exploração..." -ForegroundColor Magenta
choco install metasploit-framework
choco install putty

# --- 10. DEPENDÊNCIAS ESSENCIAIS (Runtimes) ---
Write-Host ""
Write-Host "[+] Instalando Runtimes e Dependências Essenciais..." -ForegroundColor Yellow

# 10.1. Visual C++ Redistributables (Equivalente ao All-in-One)
Write-Host "  -> Instalando todos os Runtimes do Visual C++ (2005-2022)..." -ForegroundColor Yellow
choco install vcredist-all

# 10.2. .NET Frameworks Legados (o .NET SDK moderno já está na seção 3)
Write-Host "  -> Instalando .NET Frameworks legados (3.5 e 4.x)..." -ForegroundColor Yellow
choco install dotnet3.5
choco install dotnetfx

# 10.3. Java Runtime (JRE)
Write-Host "  -> Instalando Java Runtime Environment 8 (JRE)..." -ForegroundColor Yellow
choco install jre8


# --- Finalização ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  SCRIPT DO WINDOWS CONCLUÍDO!" -ForegroundColor Green
Write-Host "================================================="
Write-Host "Reinicie seu terminal para que as alterações de PATH tenham efeito." -ForegroundColor Yellow
Write-Host "Pode ser necessário REINICIAR O COMPUTADOR para que todos os"
Write-Host "runtimes (VC++ e .NET) sejam corretamente registrados." -ForegroundColor Yellow
Write-Host "Próximo passo: Execute o script 'meu_setup_wsl.sh' dentro do Ubuntu." -ForegroundColor Cyan