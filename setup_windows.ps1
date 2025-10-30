<#
.SYNOPSIS
    Script "Mestre" para configurar o ambiente Windows.
.DESCRIPTION
    1. Garante privilégios de Administrador.
    2. Instala o Chocolatey (se não estiver instalado).
    3. Executa o script principal 'essentials_w.ps1' para instalar as ferramentas.
.NOTES
    Versão: 1.0
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

# --- 2. Verificação e Instalação do Chocolatey ---
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

# --- 3. Execução do Script Principal ---
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