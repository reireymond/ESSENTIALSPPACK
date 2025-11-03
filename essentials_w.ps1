<#
.SYNOPSIS
    Script de configuração de ambiente de Desenvolvimento e Cibersegurança.
    Usa o Chocolatey para instalar ou atualizar todas as ferramentas.
.DESCRIPTION
    Este script automatiza a instalação de IDEs, linguagens,
    ferramentas de build, um conjunto de ferramentas de pentesting,
    diagnóstico de hardware e todos os runtimes essenciais do Windows.
.NOTES
    Versão: 1.7
    Autor: Kaua
    LÓGICA: Usa 'choco upgrade' para instalar (se ausente) ou atualizar (se existente).
    REQUISITO: Execute este script como ADMINISTRADOR.
    REQUISITO: Instale o Chocolatey primeiro! (O setup_windows.ps1 faz isso)
#>

# --- Configuração Inicial ---
# Define o Chocolatey para aceitar todas as confirmações automaticamente.
$env:ChocolateyInstallArguments = "--yes"

Clear-Host
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INICIANDO INSTALAÇÃO/ATUALIZAÇÃO DO AMBIENTE (DEV & PENTESTING)" -ForegroundColor Green
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
Write-Host "[+] Atualizando Editores, Terminais e Utilitários..." -ForegroundColor Cyan
choco upgrade vscode
choco upgrade microsoft-windows-terminal
choco upgrade neovim
choco upgrade 7zip
choco upgrade powershell-core

# --- 2. Navegadores ---
Write-Host ""
Write-Host "[+] Atualizando Navegadores..." -ForegroundColor Cyan
choco upgrade firefox-developer-edition
choco upgrade googlechrome

# --- 3. Linguagens de Programação e Runtimes ---
Write-Host ""
Write-Host "[+] Atualizando Linguagens e Runtimes..." -ForegroundColor Cyan
choco upgrade python3
choco upgrade nodejs-lts
choco upgrade openjdk17
choco upgrade dotnet-sdk

# --- 4. Ferramentas de Build e Controle de Versão ---
Write-Host ""
Write-Host "[+] Atualizando Ferramentas de Build e Controle de Versão..." -ForegroundColor Cyan
choco upgrade git.install
choco upgrade cmake.install --installargs 'ADD_CMAKE_TO_PATH=System'
choco upgrade msys2

# --- 5. Ferramentas de Build C++ da Microsoft (MSVC) ---
Write-Host ""
Write-Host "[+] Atualizando IDE Visual Studio 2022 Community (para C++)..." -ForegroundColor Cyan
choco upgrade visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet"

# --- 6. Virtualização e Contêineres ---
Write-Host ""
Write-Host "[+] Atualizando Ferramentas de Virtualização..." -ForegroundColor Cyan
choco upgrade docker-desktop
choco upgrade virtualbox

# --- 7. Banco de Dados e APIs ---
Write-Host ""
Write-Host "[+] Atualizando Clientes de API e Banco de Dados..." -ForegroundColor Cyan
choco upgrade dbeaver
choco upgrade postman

# --- 8. Diagnóstico, Benchmark e Monitoramento de Hardware ---
Write-Host ""
Write-Host "[+] Atualizando Kit de Diagnóstico e Benchmark de Hardware..." -ForegroundColor Cyan
choco upgrade cpu-z
choco upgrade gpu-z
choco upgrade hwmonitor
choco upgrade crystaldiskinfo         # Saúde de SSD/HD (S.M.A.R.T.)
choco upgrade crystaldiskmark         # Benchmark de velocidade de disco
choco upgrade speccy                  # Sumário detalhado do sistema
choco upgrade msi-afterburner         # Monitoramento de FPS e Overclocking
choco upgrade prime95                 # Teste de estresse de CPU

# --- 9. Produtividade e Comunicação ---
Write-Host ""
Write-Host "[+] Atualizando Ferramentas de Comunicação..." -ForegroundColor Cyan
choco upgrade discord

# --- 10. DevOps e Ferramentas de Nuvem (Cloud) ---
Write-Host ""
Write-Host "[+] Atualizando Ferramentas de DevOps e Cloud..." -ForegroundColor Cyan
choco upgrade aws-cli
choco upgrade azure-cli
choco upgrade terraform

# --- 11. Utilitários Avançados e Segurança Pessoal ---
Write-Host ""
Write-Host "[+] Atualizando Utilitários Avançados e Segurança..." -ForegroundColor Cyan
choco upgrade gsudo                   
choco upgrade keepassxc             # Gerenciador de senhas local
choco upgrade windirstat            # Analisador gráfico de espaço em disco
choco upgrade winscp                # Cliente gráfico SFTP/FTP

# --- 12. CIBERSEGURANÇA E PENTESTING (Host) ---
Write-Host ""
Write-Host "[+] Atualizando Arsenal de Cibersegurança e Pentesting..." -ForegroundColor Magenta

# 12.1. Análise de Rede
Write-Host "  -> Análise de Rede..." -ForegroundColor Magenta
choco upgrade nmap
choco upgrade wireshark
choco upgrade zenmap

# 12.2. Análise de Aplicações Web
Write-Host "  -> Análise Web..." -ForegroundColor Magenta
choco upgrade burpsuite
choco upgrade sqlmap
choco upgrade owasp-zap

# 12.3. Engenharia Reversa e Forense
Write-Host "  -> Engenharia Reversa e Forense..." -ForegroundColor Magenta
choco upgrade ghidra
choco upgrade x64dbg
choco upgrade sysinternals
choco upgrade hashcat
choco upgrade autopsy

# 12.4. Exploração e Frameworks
Write-Host "  -> Frameworks de Exploração..." -ForegroundColor Magenta
choco upgrade metasploit-framework
choco upgrade putty

# --- 13. DEPENDÊNCIAS ESSENCIAIS (Runtimes) ---
Write-Host ""
Write-Host "[+] Atualizando Runtimes e Dependências Essenciais..." -ForegroundColor Yellow

# 13.1. Visual C++ Redistributables (Equivalente ao All-in-One)
Write-Host "  -> Instalando/Atualizando todos os Runtimes do Visual C++ (2005-2022)..." -ForegroundColor Yellow
choco upgrade vcredist-all

# 13.2. .NET Frameworks Legados (o .NET SDK moderno já está na seção 3)
Write-Host "  -> Instalando/Atualizando .NET Frameworks legados (3.5 e 4.x)..." -ForegroundColor Yellow
choco upgrade dotnet3.5
choco upgrade dotnetfx

# 13.3. Java Runtime (JRE)
Write-Host "  -> Instalando/Atualizando Java Runtime Environment 8 (JRE)..." -ForegroundColor Yellow
choco upgrade jre8

# 13.4. DirectX Legado
Write-Host "  -> Instalando/Atualizando DirectX 9.0c End-User Runtime..." -ForegroundColor Yellow
choco upgrade directx

# --- Finalização ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  SCRIPT DO WINDOWS CONCLUÍDO!" -ForegroundColor Green
Write-Host "================================================="
Write-Host "Reinicie seu terminal para que as alterações de PATH tenham efeito." -ForegroundColor Yellow
Write-Host "Pode ser necessário REINICIAR O COMPUTADOR para que todos os"
Write-Host "runtimes (VC++ e .NET) sejam corretamente registrados." -ForegroundColor Yellow
Write-Host "Próximo passo: Execute o script 'wsl_ubuntu.sh' dentro do Ubuntu." -ForegroundColor Cyan
