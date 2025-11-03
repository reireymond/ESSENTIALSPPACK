<#
.SYNOPSIS
    Script "Mestre" para configurar o ambiente Windows.
.DESCRIPTION
    1. Garante privilégios de Administrador.
    2. Instala o WSL 2 (se não estiver instalado) e solicita reinicialização.
    3. Instala o Chocolatey (se não estiver instalado).
    4. Habilita a autoconfirmação de scripts do Chocolatey.
    5. Executa o script principal 'essentials_w.ps1' para instalar as ferramentas.
.NOTES
    Versão: 1.2
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

# --- 2. Verificação e Instalação do WSL 2 (NOVA SEÇÃO) ---
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

# --- 5. Execução do Script Principal ---
Write-Host ""
Write-Host "Iniciando o script principal de instalação de ferramentas (essentials_w.ps1)..."
$scriptPath = Join-Path $PSScriptRoot "essentials_w.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERRO: Script 'essentials_w.ps1' não encontrado no mesmo diretório." -ForegroundColor Red
    Read-Host "Pressione ENTER para sair..."
    exit
}

# Executa o script principal
try {
    & $scriptPath
} catch {
    Write-Host "ERRO: Ocorreu um problema ao executar o essentials_w.ps1." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "Processo de setup do Windows finalizado." -ForegroundColor Green
Read-Host "Pressione ENTER para fechar..."
