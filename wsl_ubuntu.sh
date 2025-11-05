#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 3.5 (Final Additions: Security, Diagnostics, Jupyter)
#
#  Installs a complete Development, DevOps, and Pentest environment.
#  Features:
#  - QoL: Zsh + P10k, eza, bat, fzf, fd, duf.
#  - Runtimes: SDKMAN (Java/Kotlin/Scala/Dart/Elixir), NVM (Node), Pyenv, etc.
#  - DevOps: Docker, Kubectl, Helm, Terraform, AWS, Azure, Lazydocker.
#  - Pentest: Kali-Linux toolset + Security Hardening (fail2ban, auditd).
#
# =============================================================================

# MELHORIA: Sai imediatamente se um comando falhar
set -e

# Ensures the script is non-interactive
export DEBIAN_FRONTEND=noninteractive

# Request administrator (sudo) privileges at the start
sudo -v

echo "=========================================="
echo "  Updating System (apt-get update/upgrade)..."
echo "=========================================="
sudo apt-get update
sudo apt-get upgrade -y

# -----------------------------------------------------------------------------
#  SECTION 1: CORE DEPENDENCIES & BUILD TOOLS (MAX APT SPEED)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing All Core APT Packages (One Batch for Speed)"
echo "=========================================="
sudo apt-get install -y \
  # Core Build Tools & Debugging (C/C++)
  build-essential gdb valgrind binutils \
  # Shell & Python Dev Deps
  shellcheck python3-dev \
  libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev \
  autoconf bison patch libyaml-dev libtool \
  # Runtimes via APT
  golang-go lua5.4 \
  php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath \
  php-composer \
  # Terminal QoL & Diagnostics
  tmux htop bat eza tldr \
  jq fzf ripgrep ncdu \
  neovim fd-find duf \
  # MELHORIA: Diagnóstico de Rede e Segurança
  mtr-tiny traceroute auditd fail2ban \
  # Kali Pack: Recon & Enumeration
  nmap net-tools dnsutils tcpdump amass \
  smbclient enum4linux-ng nbtscan onesixtyone masscan \
  # Kali Pack: Web Analysis
  gobuster dirb nikto whatweb ffuf sqlmap wfuzz \
  dirsearch mitmproxy \
  # Kali Pack: Password, Exploit & Sniffing
  john hashid seclists thc-hydra \
  exploitdb metasploit-framework \
  python3-impacket impacket-scripts dsniff aircrack-ng \
  bettercap reaver \
  # Kali Pack: RE, Forensics & GDB
  binwalk radare2 foremost radare2-r2pipe \
  sleuthkit volatility3 \
  # Dependências de Instalação (Docker, SDKMAN)
  zip unzip software-properties-common

# -----------------------------------------------------------------------------
#  SECTION 2: RUNTIMES & VERSION MANAGERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Rust (rustup)"
echo "=========================================="
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

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
echo "  Installing SDKMAN (for Java, Kotlin, Scala, Dart, Elixir, etc.)"
echo "=========================================="
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
echo "  Installing Pyenv, Poetry, e PIPX (Python)"
echo "=========================================="
if ! command -v pyenv &> /dev/null; then
    echo "Installing pyenv (Python Version Manager)..."
    curl https://pyenv.run | sudo -u $SUDO_USER bash
fi
if ! command -v poetry &> /dev/null; then
    echo "Installing Poetry (Project Manager)..."
    curl -sSL https://install.python-poetry.org | sudo -u $SUDO_USER python3 -
fi
echo "Installing pipx (for isolated Python CLIs)..."
sudo -u $SUDO_USER bash -c "export PATH=\"$PATH\" && pipx ensurepath"


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
#  SECTION 3: DEVOPS & PRODUTIVIDADE
# -----------------------------------------------------------------------------

# Nginx é instalado como um servidor de teste local
echo "=========================================="
echo "  Setting up Local Webserver (Nginx)"
echo "=========================================="
sudo apt-get install -y nginx

# Fix 'fd' command name on Ubuntu (ignora erro se o arquivo não existir)
if [ ! -L /usr/bin/fd ]; then
  sudo rm -f /usr/bin/fd || true
  sudo ln -s /usr/bin/fdfind /usr/bin/fd
fi
# Fix 'bat' command name on Ubuntu (ignora erro se o arquivo não existir)
if [ ! -L /usr/bin/bat ]; then
  sudo rm -f /usr/bin/bat || true
  sudo ln -s /usr/bin/batcat /usr/bin/bat
fi

echo "=========================================="
echo "  Installing QoL Git/Docker TUIs"
echo "=========================================="
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/lazygit /usr/local/bin/
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/lazydocker /usr/local/bin/

echo "=========================================="
echo "  Installing Cloud & Infra Tools"
echo "=========================================="

# Docker setup (chaves e repositório)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Instalação dos plugins Docker (CLI, Buildx)
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
echo "[+] Adding $SUDO_USER to the 'docker' group..."
sudo usermod -aG docker $SUDO_USER
echo "[+] Configuring passwordless sudo for Docker service..."
sudo cp -f /etc/sudoers /etc/sudoers.bak
echo "%docker ALL=(ALL) NOPASSWD: /usr/sbin/service docker *" | sudo tee /etc/sudoers.d/docker-nopasswd
sudo chmod 0440 /etc/sudoers.d/docker-nopasswd

# Helm setup (chaves e repositório)
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
# Terraform setup (chaves e repositório)
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update

# Instalação dos binários pendentes (Kubectl via snap, Helm e Terraform via APT)
sudo snap install kubectl --classic
sudo apt-get install -y helm terraform

# -----------------------------------------------------------------------------
#  SECTION 4: SHELL UPGRADE (ZSH + POWERLEVEL10K)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="
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
#  SECTION 5: KALI-STYLE ARSENAL (Instalações Específicas)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Post-Exploitation & Python Tools"
echo "=========================================="

echo "[+] Installing Evil-WinRM (via Ruby)..."
sudo -u $SUDO_USER bash -c "eval \"\$(rbenv init -)\" && gem install evil-winrm"

echo "[+] Installing Python Pentest Tools (via pipx)..."
sudo -u $SUDO_USER bash -c "
    pipx install pwntools
    pipx install bloodhound-py
    pipx install sublist3r
    pipx install uncompyle6
    pipx install wafw00f
    pipx install jupyter
"

echo "[+] Installing Go Recon Tools (httpx, subfinder, feroxbuster)..."
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/epi052/feroxbuster/cmd/feroxbuster@latest
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/httpx /usr/local/bin/
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/subfinder /usr/local/bin/
sudo -u $SUDO_USER ln -sf /home/${SUDO_USER}/go/bin/feroxbuster /usr/local/bin/


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
alias c='clear'
alias df='duf'
alias z='zoxide'
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

echo "=========================================="
echo "  Installing Default Language Versions..."
echo "=========================================="

echo "[+] Installing Node.js LTS (via NVM) and TypeScript (Global)..."
sudo -u $SUDO_USER bash -c "
    source $NVM_DIR/nvm.sh && 
    nvm install --lts && 
    nvm alias default 'lts/*' &&
    npm install -g typescript
"

echo "[+] Installing Java 17, Kotlin, Scala, Dart, Elixir/Erlang, and Maven (via SDKMAN)..."
sudo -u $SUDO_USER bash -c "
    source $HOME/.sdkman/bin/sdkman-init.sh && 
    sdk install java 17.0.10-tem && 
    sdk install kotlin &&
    sdk install maven &&
    sdk install dart &&
    sdk install scala &&
    sdk install erlang &&
    sdk install elixir
"

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
echo "  WSL (UBUNTU) SETUP V3.5 COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your Ubuntu terminal."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "   - Answer 'y' (yes) if you see icons (like a diamond, lock)."
echo "   - Choose your preferred look ('Rainbow', 'Lean' recommended)."
echo ""
