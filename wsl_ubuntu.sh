#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 3.0 (Multi-Language, DevOps & Kali-fy)
#
#  Installs a complete Development, DevOps, and Pentest environment.
#  Features:
#  - QoL: Zsh + P10k, eza, bat, fzf, etc.
#  - Runtimes: SDKMAN (Java/Kotlin), NVM (Node), Pyenv (Python),
#              Rbenv (Ruby), Go, Rust, PHP, Lua, .NET.
#  - DevOps: Docker, Kubectl, Helm, Terraform, AWS, Azure.
#  - Pentest: Kali-Linux toolset + GDB Enhanced Features (GEF).
#
# =============================================================================

# Ensures the script is non-interactive
export DEBIAN_FRONTEND=noninteractive

# Request administrator (sudo) privileges at the start
sudo -v

# Keep sudo privileges alive throughout the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "=========================================="
echo "  Updating System (apt-get update/upgrade)..."
echo "=========================================="
sudo apt-get update
sudo apt-get upgrade -y

# -----------------------------------------------------------------------------
#  SECTION 1: CORE DEPENDENCIES & BUILD TOOLS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Core Build Tools (C/C++, Python, Shell)"
echo "=========================================="
# build-essential (gcc, g++, make), gdb (debugger), valgrind (memory)
# binutils (binary tools), shellcheck (shell linter)
# Python3 build dependencies (for pyenv)
# Ruby build dependencies (for rbenv)
sudo apt-get install -y \
  build-essential gdb valgrind binutils \
  shellcheck \
  libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev \
  autoconf bison patch libyaml-dev libtool

# -----------------------------------------------------------------------------
#  SECTION 2: RUNTIMES & VERSION MANAGERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Go (Golang)"
echo "=========================================="
sudo apt-get install -y golang-go

echo "=========================================="
echo "  Installing Rust (rustup)"
echo "=========================================="
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Add Rust to the current shell's PATH
    source "$HOME/.cargo/env"
fi

echo "=========================================="
echo "  Installing Lua"
echo "=========================================="
sudo apt-get install -y lua5.4

echo "=========================================="
echo "  Installing PHP (with common extensions)"
echo "=========================================="
sudo apt-get install -y php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath

echo "=========================================="
echo "  Installing .NET SDK (Microsoft)"
echo "=========================================="
# Add Microsoft package feed
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update
fi
sudo apt-get install -y dotnet-sdk-8.0

echo "=========================================="
echo "  Installing SDKMAN (for Java, Kotlin, etc.)"
echo "=========================================="
# Install dependencies
sudo apt-get install -y zip unzip
# Install SDKMAN
if [ ! -d "/home/${SUDO_USER}/.sdkman" ]; then
    echo "Installing SDKMAN..."
    sudo -u $SUDO_USER curl -s "https://get.sdkman.io" | sudo -u $SUDO_USER bash
fi

echo "=========================================="
echo "  Installing NVM (Node Version Manager)"
echo "=========================================="
export NVM_DIR="/home/${SUDO_USER}/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    sudo -u $SUDO_USER curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -u $SUDO_USER bash
fi

echo "=========================================="
echo "  Installing Pyenv & Poetry (Python)"
echo "=========================================="
if ! command -v pyenv &> /dev/null; then
    echo "Installing pyenv (Python Version Manager)..."
    curl https://pyenv.run | sudo -u $SUDO_USER bash
fi
if ! command -v poetry &> /dev/null; then
    echo "Installing Poetry (Project Manager)..."
    curl -sSL https://install.python-poetry.org | sudo -u $SUDO_USER python3 -
fi

echo "=========================================="
echo "  Installing Rbenv (Ruby Version Manager)"
echo "=========================================="
if ! command -v rbenv &> /dev/null; then
    echo "Installing rbenv..."
    # Install rbenv
    sudo -u $SUDO_USER git clone https://github.com/rbenv/rbenv.git /home/${SUDO_USER}/.rbenv
    # Install ruby-build (plugin for rbenv install)
    sudo -u $SUDO_USER git clone https://github.com/rbenv/ruby-build.git /home/${SUDO_USER}/.rbenv/plugins/ruby-build
fi

# -----------------------------------------------------------------------------
#  SECTION 3: TERMINAL QOL & DEVOPS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Terminal QoL (Utilities)"
echo "=========================================="
sudo apt-get install -y \
  tmux htop bat eza tldr \
  jq fzf ripgrep ncdu \
  neovim

# Fix 'bat' command name on Ubuntu
if [ ! -L /usr/bin/bat ]; then
  sudo rm -f /usr/bin/bat
  sudo ln -s /usr/bin/batcat /usr/bin/bat
fi

echo "=========================================="
echo "  Installing QoL Git TUI (lazygit)"
echo "=========================================="
go install github.com/jesseduffield/lazygit@latest
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/lazygit /usr/local/bin/

echo "=========================================="
echo "  Installing DevOps & Cloud Tools"
echo "=========================================="

# 1. Kubectl (Kubernetes manager)
sudo snap install kubectl --classic

# 2. Docker CLI (to connect to Docker Desktop)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
echo "[+] Adding $SUDO_USER to the 'docker' group..."
sudo usermod -aG docker $SUDO_USER
echo "[+] Configuring passwordless sudo for Docker service..."
sudo cp -f /etc/sudoers /etc/sudoers.bak
echo "%docker ALL=(ALL) NOPASSWD: /usr/sbin/service docker *" | sudo tee /etc/sudoers.d/docker-nopasswd
sudo chmod 0440 /etc/sudoers.d/docker-nopasswd

# 3. Helm (Kubernetes Package Manager)
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# 4. Terraform
sudo apt-get install -y software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo apt-get install -y terraform

# 5. Cloud CLIs (AWS, Azure)
sudo apt-get install -y awscli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# -----------------------------------------------------------------------------
#  SECTION 4: SHELL UPGRADE (ZSH + POWERLEVEL10K)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="
sudo apt-get install -y zsh zsh-completions
ZSHRC_PATH="/home/${SUDO_USER}/.zshrc"

if [ "$(getent passwd $SUDO_USER | cut -d: -f7)" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell for $SUDO_USER..."
    sudo chsh -s $(which zsh) $SUDO_USER
fi

if [ ! -d "/home/${SUDO_USER}/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sudo -u $SUDO_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Zsh plugins (autosuggestions and syntax-highlighting)..."
ZSH_CUSTOM_PLUGINS="/home/${SUDO_USER}/.oh-my-zsh/custom/plugins"
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
    sudo -u $SUDO_USER git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM_PLUGINS/zsh-autosuggestions
fi
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
    sudo -u $SUDO_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting
fi

echo "Installing Powerlevel10k Theme (P10k)..."
P10K_PATH="/home/${SUDO_USER}/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_PATH" ]; then
    sudo -u $SUDO_USER git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_PATH"
fi

# Enable plugins and P10k theme in .zshrc
if [ -f "$ZSHRC_PATH" ]; then
    if grep -q "plugins=(git)" "$ZSHRC_PATH"; then
        echo "Enabling Zsh plugins..."
        sudo -u $SUDO_USER sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC_PATH"
    fi
    if grep -q 'ZSH_THEME="robbyrussell"' "$ZSHRC_PATH"; then
        echo "Setting Powerlevel10k theme..."
        sudo -u $SUDO_USER sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"
    fi
fi

# -----------------------------------------------------------------------------
#  SECTION 5: KALI-STYLE ARSENAL
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Recon & Enumeration"
echo "=========================================="
sudo apt-get install -y \
  nmap net-tools dnsutils tcpdump amass \
  smbclient enum4linux-ng nbtscan onesixtyone masscan

echo "=========================================="
echo "  KALI PACK: Web Analysis"
echo "=========================================="
sudo apt-get install -y \
  gobuster dirb nikto whatweb ffuf sqlmap wfuzz \
  dirsearch mitmproxy

echo "=========================================="
echo "  KALI PACK: Password, Exploit & Sniffing"
echo "=========================================="
sudo apt-get install -y \
  john hashid seclists thc-hydra \
  exploitdb metasploit-framework \
  python3-impacket impacket-scripts dsniff aircrack-ng \
  bettercap reaver

echo "=========================================="
echo "  KALI PACK: RE, Forensics & GDB"
echo "=========================================="
sudo apt-get install -y \
  binwalk radare2 foremost \
  sleuthkit volatility3

echo "=========================================="
echo "  KALI PACK: Post-Exploitation & Python Tools"
echo "=========================================="

echo "[+] Installing Evil-WinRM (via Ruby)..."
sudo -u $SUDO_USER bash -c "eval \"\$(rbenv init -)\" && gem install evil-winrm"

echo "[+] Installing Python Pentest Tools (pwntools, bloodhound, sublist3r)..."
sudo -u $SUDO_USER bash -c "eval \"\$(pyenv init -)\" && \
    pip install pwntools && \
    pip install bloodhound-py && \
    pip install sublist3r \
    pip install uncompyle6"

# Install GEF (GDB Enhanced Features)
if [ ! -f "/home/${SUDO_USER}/.gdbinit-gef.py" ]; then
    echo "Installing GEF for GDB..."
    sudo -u $SUDO_USER bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
else
    echo "GEF already installed. Skipping."
fi



# -----------------------------------------------------------------------------
#  SECTION 6: ALIASES & SHELL LOADERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Applying custom Zsh aliases..."
echo "=========================================="

ALIAS_MARKER="# --- Custom Aliases ---"
if ! grep -q "$ALIAS_MARKER" "$ZSHRC_PATH"; then
    echo "Adding custom aliases to $ZSHRC_PATH..."
    echo "
$ALIAS_MARKER
# Replace 'ls' with 'eza' (modern, with icons)
alias ls='eza --icons --git'
alias ll='eza -l --icons --git --all' # List all, long format
alias lt='eza -T'                      # 'tree' mode

# QoL
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias cleanup='sudo apt-get autoremove -y && sudo apt-get clean'
alias open='explorer.exe .' # Open directory in Windows Explorer
" | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi

echo "=========================================="
echo "  Adding Runtimes to Zsh (.zshrc)..."
echo "=========================================="

# SDKMAN Loader
if ! grep -q "sdkman" "$ZSHRC_PATH"; then
    echo "Adding SDKMAN loader to $ZSHRC_PATH..."
    echo '
# --- SDKMAN Loader ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi

# NVM Loader
if ! grep -q "nvm.sh" "$ZSHRC_PATH"; then
    echo "Adding NVM loader to $ZSHRC_PATH..."
    echo '
# --- NVM Loader ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi

# Pyenv & Poetry Loader
if ! grep -q "pyenv" "$ZSHRC_PATH"; then
    echo "Adding Pyenv & Poetry loader to $ZSHRC_PATH..."
    echo '
# --- Pyenv & Poetry Loader ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
export PATH="$HOME/.local/bin:$PATH"
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi

# Rbenv Loader
if ! grep -q "rbenv" "$ZSHRC_PATH"; then
    echo "Adding Rbenv loader to $ZSHRC_PATH..."
    echo '
# --- Rbenv Loader ---
export PATH="$HOME/.rbenv/bin:$PATH"
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi

# -----------------------------------------------------------------------------
#  SECTION 7: AUTOMATED LANGUAGE INSTALLATION
# -----------------------------------------------------------------------------
# This section runs the final setup for our version managers.

echo "=========================================="
echo "  Installing Default Language Versions..."
echo "=========================================="

echo "[+] Installing Node.js LTS (via NVM)..."
sudo -u $SUDO_USER bash -c "source $NVM_DIR/nvm.sh && nvm install --lts && nvm alias default 'lts/*'"

echo "[+] Installing Java 17 & Kotlin (via SDKMAN)..."
sudo -u $SUDO_USER bash -c "source $HOME/.sdkman/bin/sdkman-init.sh && sdk install java 17.0.10-tem && sdk install kotlin"

echo "[+] Installing Python 3.10 (via Pyenv)..."
sudo -u $SUDO_USER bash -c "eval \"\$(pyenv init -)\" && pyenv install 3.10.13 && pyenv global 3.10.13"

echo "[+] Installing Ruby 3.2.2 (via Rbenv)..."
sudo -u $SUDO_USER bash -c "eval \"\$(rbenv init -)\" && rbenv install 3.2.2 && rbenv global 3.2.2"

# --- FINAL CLEANUP ---
echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "=========================================="
echo "  WSL (UBUNTU) SETUP V3.0 COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your Ubuntu terminal."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "   - Answer 'y' (yes) if you see icons (like a diamond, lock)."
echo "   - Choose your preferred look ('Rainbow', 'Lean' recommended)."
echo ""
