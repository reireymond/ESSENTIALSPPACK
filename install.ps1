<#
.SYNOPSIS
    Script "Super Mestre" para configurar o ambiente Windows E WSL.
.DESCRIPTION
    1. Garante privilégios de Administrador.
    2. Instala o WSL 2 (se não estiver instalado) e solicita reinicialização.
    3. Instala o Chocolatey (se não estiver instalado).
    4. Habilita a autoconfirmação de scripts do Chocolatey.
    5. Instala/Atualiza TODAS as ferramentas do Windows via Chocolatey.
    6. Executa automaticamente o script 'wsl_ubuntu.sh' no final.
.NOTES
    Versão: 1.3 (Fundido)
    Autor: Kaua
#>

# --- 1. Verificação de Administrador ---
Write-Host "Verificando privilégios de Administrador..." -ForegroundColor Yellow
if (-NOT ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Este script precisa ser executado como Administrador." -ForegroundColor Red
    Write-Host "Por favor, clique com o botão direito no script e 'Executar como Administrador'." -ForegroundColor Red
    Read-Host "Pressione ENTER para sair..."
    exit
}
Write-Host "Privilégios de Administrador confirmados." -ForegroundColor Green

# --- 2. Verificação e Instalação do WSL 2 ---
Write-Host ""
Write-Host "Verificando instalação do WSL 2..." -ForegroundColor Yellow
try {
    # Tenta obter o status do WSL. Se falhar (ExitCode != 0), o WSL não está instalado.
    wsl --status | Out-Null
    Write-Host "WSL 2 já está instalado." -ForegroundColor Green
} catch {
    Write-Host "WSL 2 não encontrado. Iniciando instalação..." -ForegroundColor Yellow
    Write-Host "Isso pode demorar alguns minutos..."
    
    # Executa o comando de instalação do WSL
    wsl --install
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "  REINICIALIZAÇÃO NECESSÁRIA" -ForegroundColor Red
    Write-Host "============================================================"
    Write-Host "O WSL 2 foi instalado."
    Write-Host "POR FAVOR, REINICIE O COMPUTADOR AGORA."
    Write-Host "Após reiniciar, rode este script 'setup_windows.ps1' novamente."
    Write-Host "A instalação continuará de onde parou."
    Write-Host "============================================================"
    Read-Host "Pressione ENTER para fechar e reiniciar o PC..."
    exit # Encerra o script para forçar a reinicialização
}

# --- 3. Verificação e Instalação do Chocolatey ---
Write-Host ""
Write-Host "Verificando se o Chocolatey está instalado..."
$chocoPath = Get-Command choco -ErrorAction SilentlyContinue
if ($null -eq $chocoPath) {
    Write-Host "Chocolatey não encontrado. Instalando agora..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "Chocolatey instalado com sucesso!" -ForegroundColor Green
        
        # Adiciona o choco ao PATH da sessão atual
        $env:Path = "$($env:Path);$($env:ALLUSERSPROFILE)\chocolatey\bin"
    } catch {
        Write-Host "ERRO: Falha ao instalar o Chocolatey." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Read-Host "Pressione ENTER para sair..."
        exit
    }
} else {
    Write-Host "Chocolatey já está instalado." -ForegroundColor Green
}

# --- 4. Habilitando Autoconfirmação do Chocolatey ---
Write-Host ""
Write-Host "Habilitando a confirmação automática de scripts do Chocolatey (modo 100% automatizado)..." -ForegroundColor Yellow
try {
    # Este comando impede que o Choco pergunte "[Y]es/[A]ll/[N]o" para cada script
    choco feature enable -n=allowGlobalConfirmation
    Write-Host "Recurso 'allowGlobalConfirmation' habilitado." -ForegroundColor Green
} catch {
    Write-Host "ERRO: Falha ao habilitar 'allowGlobalConfirmation'. O script pode pedir confirmações." -ForegroundColor Red
}

# --- 5. INÍCIO DAS INSTALAÇÕES/ATUALIZAÇÕES (Fundido de essentials_w.ps1) ---
# --- 
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INICIANDO INSTALAÇÃO/ATUALIZAÇÃO DE FERRAMENTAS DO WINDOWS" -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

# Define o Chocolatey para aceitar todas as confirmações automaticamente (redundante, mas seguro)
$env:ChocolateyInstallArguments = "--yes"

# --- Seção 5.1: Editores, Terminais e Utilitários ---
Write-Host "[+] Atualizando Editores, Terminais e Utilitários..." -ForegroundColor Cyan
choco upgrade vscode
choco upgrade microsoft-windows-terminal
choco upgrade neovim
choco upgrade 7zip
choco upgrade powershell-core

# --- Seção 5.2: Navegadores ---
Write-Host "[+] Atualizando Navegadores..." -ForegroundColor Cyan
choco upgrade firefox-developer-edition
choco upgrade googlechrome

# --- Seção 5.3: Linguagens de Programação e Runtimes ---
Write-Host "[+] Atualizando Linguagens e Runtimes..." -ForegroundColor Cyan
choco upgrade python3
choco upgrade nodejs-lts
choco upgrade openjdk17
choco upgrade dotnet-sdk

# --- Seção 5.4: Ferramentas de Build e Controle de Versão ---
Write-Host "[+] Atualizando Ferramentas de Build e Controle de Versão..." -ForegroundColor Cyan
choco upgrade git.install
choco upgrade cmake.install --installargs 'ADD_CMAKE_TO_PATH=System'
choco upgrade msys2

# --- Seção 5.5: Ferramentas de Build C++ da Microsoft (MSVC) ---
Write-Host "[+] Atualizando IDE Visual Studio 2022 Community (para C++)..." -ForegroundColor Cyan
choco upgrade visualstudio2022community --package-parameters "--add Microsoft.VisualStudio.Workload.NativeDesktop --quiet"

# --- Seção 5.6: Virtualização e Contêineres ---
Write-Host "[+] Atualizando Ferramentas de Virtualização..." -ForegroundColor Cyan
choco upgrade docker-desktop
choco upgrade virtualbox

# --- Seção 5.7: Banco de Dados e APIs ---
Write-Host "[+] Atualizando Clientes de API e Banco de Dados..." -ForegroundColor Cyan
choco upgrade dbeaver
choco upgrade postman

# --- Seção 5.8: Diagnóstico, Benchmark e Monitoramento de Hardware ---
Write-Host "[+] Atualizando Kit de Diagnóstico e Benchmark de Hardware..." -ForegroundColor Cyan
choco upgrade cpu-z
choco upgrade gpu-z
choco upgrade hwmonitor
choco upgrade crystaldiskinfo
choco upgrade crystaldiskmark
choco upgrade speccy
choco upgrade msi-afterburner
choco upgrade prime95

# --- Seção 5.9: Produtividade e Comunicação ---
Write-Host "[+] Atualizando Ferramentas de Comunicação..." -ForegroundColor Cyan
choco upgrade discord

# --- Seção 5.10: DevOps e Ferramentas de Nuvem (Cloud) ---
Write-Host "[+] Atualizando Ferramentas de DevOps e Cloud..." -ForegroundColor Cyan
choco upgrade aws-cli
choco upgrade azure-cli
choco upgrade terraform

# --- Seção 5.11: Utilitários Avançados e Segurança Pessoal ---
Write-Host "[+] Atualizando Utilitários Avançados e Segurança..." -ForegroundColor Cyan
choco upgrade gsudo
choco upgrade keepassxc
choco upgrade windirstat
choco upgrade winscp

# --- Seção 5.12: CIBERSEGURANÇA E PENTESTING (Host) ---
Write-Host "[+] Atualizando Arsenal de Cibersegurança e Pentesting..." -ForegroundColor Magenta
choco upgrade nmap
choco upgrade wireshark
choco upgrade zenmap
choco upgrade burpsuite
choco upgrade sqlmap
choco upgrade owasp-zap
choco upgrade ghidra
choco upgrade x64dbg
choco upgrade sysinternals
choco upgrade hashcat
choco upgrade autopsy
choco upgrade metasploit-framework
choco upgrade putty

# --- Seção 5.13: DEPENDÊNCIAS ESSENCIAIS (Runtimes) ---
Write-Host "[+] Atualizando Runtimes e Dependências Essenciais..." -ForegroundColor Yellow
choco upgrade vcredist-all
choco upgrade dotnet3.5
choco upgrade dotnetfx
choco upgrade jre8
choco upgrade directx

Write-Host "=================================================" -ForegroundColor Green
Write-Host "  INSTALAÇÕES DO WINDOWS CONCLUÍDAS!" -ForegroundColor Green
Write-Host "================================================="
Write-Host ""

# --- 6. EXECUTANDO SCRIPT DO WSL (NOVA SEÇÃO AUTOMATIZADA) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  INICIANDO SETUP AUTOMÁTICO DO WSL (UBUNTU)..." -ForegroundColor Green
Write-Host "============================================================"
Write-Host ""

# Encontra o caminho do script wsl_ubuntu.sh que está no mesmo diretório
$wslScriptPath = Join-Path $PSScriptRoot "wsl_ubuntu.sh"

if (-not (Test-Path $wslScriptPath)) {
    Write-Host "ERRO: Script 'wsl_ubuntu.sh' não encontrado no mesmo diretório." -ForegroundColor Red
    Write-Host "Setup do WSL terá que ser feito manualmente." -ForegroundColor Red
} else {
    Write-Host "Encontrado script 'wsl_ubuntu.sh'."
    Write-Host "Convertendo caminho do Windows para o formato WSL..." -ForegroundColor Yellow
    
    # Converte C:\Users\... para /mnt/c/Users/...
    # Primeiro, obtém o caminho completo (ex: C:\...)
    $fullWinPath = (Resolve-Path $wslScriptPath).Path
    
    # Converte
    $driveLetter = $fullWinPath.Substring(0, 1).ToLower()
    $linuxPath = $fullWinPath.Substring(2) -replace '\\', '/'
    $fullLinuxPath = "/mnt/$driveLetter$linuxPath"
    
    Write-Host "Caminho do script WSL: $fullLinuxPath"
    Write-Host "Iniciando 'wsl.exe' para executar o script... (Isso vai pedir a senha do sudo no Ubuntu)" -ForegroundColor Yellow
    
    try {
        # Executa o script bash usando wsl.exe
        # O sudo pedirá a senha do usuário LINUX
        wsl.exe sudo bash "$fullLinuxPath"
        
        Write-Host "=================================================" -ForegroundColor Green
        Write-Host "  SETUP DO WSL (UBUNTU) CONCLUÍDO!" -ForegroundColor Green
        Write-Host "================================================="
    } catch {
        Write-Host "ERRO: Falha ao executar o script do WSL." -ForegroundColor Red
        Write-Host "Você terá que executá-lo manualmente: ./wsl_ubuntu.sh" -ForegroundColor Red
    }
}

# --- 7. Finalização ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  SETUP COMPLETO (WINDOWS + WSL)!" -ForegroundColor Green
Write-Host "================================================="
Write-Host "Por favor, FECHE E REABRA seu terminal (Windows Terminal) para que"
Write-Host "todas as alterações de PATH e o novo shell Zsh do Ubuntu tenham efeito." -ForegroundColor Yellow
Write-Host "Pode ser necessário REINICIAR O COMPUTADOR para que todos os"
Write-Host "runtimes (VC++ e .NET) sejam corretamente registrados." -ForegroundColor Yellow
Read-Host "Pressione ENTER para fechar..."
