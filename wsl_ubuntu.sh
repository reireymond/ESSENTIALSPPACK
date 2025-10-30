#!/bin/bash

# =============================================================================
#
#  Script de Setup para WSL (Ubuntu)
#
#  Instala o ambiente de desenvolvimento C/C++ (build-essential),
#  um conjunto de ferramentas de pentesting (baseado no Kali)
#  e melhora o terminal com Zsh + Oh My Zsh.
#
#  COMO USAR:
#  1. Salve este arquivo (ex: meu_setup_wsl.sh)
#  2. Dê permissão de execução:  chmod +x meu_setup_wsl.sh
#  3. Execute o script:          ./meu_setup_wsl.sh
#
# =============================================================================

# Pede privilégios de administrador (sudo) logo no início
sudo -v

# Garante que o script continue rodando com sudo
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "=========================================="
echo "  Atualizando o Sistema (apt update/upgrade)..."
echo "=========================================="
sudo apt update
sudo apt upgrade -y

echo "=========================================="
echo "  Instalando Pacote de Desenvolvimento (C/C++, Java, Python)"
echo "=========================================="
# build-essential inclui: gcc, g++, make
sudo apt install -y build-essential gdb valgrind binutils
sudo apt install -y default-jdk      # Java (JDK)
sudo apt install -y python3-pip python3-venv # Python

echo "=========================================="
echo "  Instalando Ferramentas de Rede e Enumeração"
echo "=========================================="
# net-tools (para ifconfig, etc.), smbclient (pentest Windows)
sudo apt install -y net-tools smbclient enum4linux nbtscan onesixtyone

echo "=========================================="
echo "  Instalando Ferramentas de Análise Web"
echo "=========================================="
# gobuster (brute-force de diretórios), nikto (scanner de vulnerabilidades)
sudo apt install -y gobuster dirb nikto whatweb

echo "=========================================="
echo "  Instalando Ferramentas de Senha e Wordlists"
echo "=========================================="
# john the ripper, hashid (identifica hash), seclists (MELHORES wordlists)
sudo apt install -y john hashid seclists

echo "=========================================="
echo "  Instalando Ferramentas de Exploração"
echo "=========================================="
# searchsploit (banco de dados do Exploit-DB)
sudo apt install -y searchsploit exploitdb

echo "=========================================="
echo "  Instalando Zsh + Oh My Zsh (Melhoria do Terminal)"
echo "=========================================="

# Instala o Zsh
sudo apt install -y zsh

# Instala o Oh My Zsh sem interação manual
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Define o Zsh como shell padrão (para o usuário atual)
sudo chsh -s $(which zsh) $USER

echo "Instalando plugins Zsh (autosuggestions e syntax-highlighting)..."
# Clona os plugins
ZSH_CUSTOM_PLUGINS=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM_PLUGINS/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting

# Ativa os plugins automaticamente no arquivo .zshrc
# Isso encontra a linha 'plugins=(git)' e a substitui
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo "=========================================="
echo "  SETUP DO WSL (UBUNTU) CONCLUÍDO!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANTE:\033[0m"
echo "Feche e reabra seu terminal Ubuntu para que o Zsh (novo shell) seja carregado corretamente."
echo ""