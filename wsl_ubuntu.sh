#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 3.8 (Additions: LinuxToys, Starship, Trivy, Bpytop)
#
#  Installs a complete Development, DevOps, and Pentest environment.
#
# =============================================================================

# ENHANCEMENT: Exit immediately if a command fails
set -e

# Ensures the script is non-interactive
export DEBIAN_FRONTEND=noninteractive

# Variables
CURRENT_USER=${SUDO_USER}
USER_HOME="/home/${SUDO_USER}"
NVM_DIR="$USER_HOME/.nvm"
ZSHRC_PATH="$USER_HOME/.zshrc"
PYTHON_VERSION="3.11.8"
JAVA_VERSION="17.0.10-tem"
RUBY_VERSION="3.2.2"

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
  # Shell & Python Dev Deps (including dependencies for Pyenv)
  shellcheck \
  python3-dev python3-pip python3-setuptools \
  libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev \
  autoconf bison patch libyaml-dev libtool \
  # Runtimes via APT
  golang-go lua5.4 \
  php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath \
  php-composer \
  # Terminal QoL & Diagnostics
  tmux htop bpytop bat eza tldr \
  jq fzf ripgrep ncdu \
  neovim fd-find duf \
  # ENHANCEMENT: Network Diagnostics and Security
  mtr-tiny traceroute auditd fail2ban sslyze \
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
  sleuthkit volatility3 rizin-cutter \
  # Installation Dependencies (Docker, SDKMAN)
  zip unzip software-properties-common

# -----------------------------------------------------------------------------
#  SECTION 2: RUNTIMES & VERSION MANAGERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Rust (rustup)"
echo "=========================================="
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust (rustup)..."
    sudo -u $SUDO_USER curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sudo -u $SUDO_USER sh -s -- -y
    source "$USER_HOME/.cargo/env" || true
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
if [ ! -d "$USER_HOME/.sdkman" ]; then
    echo "Installing SDKMAN..."
    sudo -u $SUDO_USER curl -s "https://get.sdkman.io" | sudo -u $SUDO_USER bash
fi

echo "=========================================="
echo "  Installing NVM (Node Version Manager)"
echo "=========================================="
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    sudo -u $SUDO_USER curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -u $SUDO_USER bash
fi

echo "=========================================="
echo "  Installing Pyenv, Poetry, and PIPX (Python)"
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
    sudo -u $SUDO_USER git clone https://github.com/rbenv/rbenv.git "$USER_HOME/.rbenv"
    # Install ruby-build (plugin for rbenv install)
    sudo -u $SUDO_USER git clone https://github.com/rbenv/ruby-build.git "$USER_HOME/.rbenv/plugins/ruby-build"
fi

# -----------------------------------------------------------------------------
#  SECTION 3: UTILITIES, DEVOPS & PRODUCTIVITY
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing QoL Tools and LinuxToys"
echo "=========================================="

# Installing LinuxToys (Useful in WSL2 for terminal commands)
echo "[+] Installing LinuxToys..."
sudo -u $SUDO_USER bash -c '
    curl -fsSLJO https://linux.toys/install.sh
    chmod +x install.sh
    ./install.sh
    rm install.sh || true
'

# Nginx is installed as a local test server
echo "=========================================="
echo "  Setting up Local Webserver (Nginx)"
echo "=========================================="
sudo apt-get install -y nginx

# Fixes for APT installed commands
if [ ! -L /usr/bin/fd ]; then sudo rm -f /usr/bin/fd || true; sudo ln -s /usr/bin/fdfind /usr/bin/fd; fi
if [ ! -L /usr/bin/bat ]; then sudo rm -f /usr/bin/bat || true; sudo ln -s /usr/bin/batcat /usr/bin/bat; fi

echo "=========================================="
echo "  Installing QoL Git/Docker TUIs & DevOps Go Tools"
echo "=========================================="
go install github.com/jesseduffield/lazygit@latest
go install github.com/jesseduffield/lazydocker@latest
go install github.com/roboll/helmfile@latest
go install github.com/aquasecurity/trivy/cmd/trivy@latest
go install github.com/joshmedeski/gum@latest
go install github.com/tomnomnom/gf@latest
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/lazygit" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/lazydocker" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/helmfile" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/trivy" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/gum" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/gf" /usr/local/bin/


echo "=========================================="
echo "  Installing Cloud & Infra Tools"
echo "=========================================="
# Docker setup (keys and repository)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Docker plugin installation (CLI, Buildx)
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
echo "[+] Adding $CURRENT_USER to the 'docker' group..."
sudo usermod -aG docker "$CURRENT_USER"
echo "[+] Configuring passwordless sudo for Docker service..."
sudo cp -f /etc/sudoers /etc/sudoers.bak
echo "%docker ALL=(ALL) NOPASSWD: /usr/sbin/service docker *" | sudo tee /etc/sudoers.d/docker-nopasswd
sudo chmod 0440 /etc/sudoers.d/docker-nopasswd

# Helm and Terraform
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
# Pending binary installation
sudo snap install kubectl --classic || sudo apt-get install -y kubectl # Fallback to APT
sudo apt-get install -y helm terraform


# -----------------------------------------------------------------------------
#  SECTION 4: SHELL UPGRADE (ZSH + POWERLEVEL10K + STARSHIP)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="
if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell for $SUDO_USER..."
    sudo chsh -s $(which zsh) "$CURRENT_USER"
fi

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sudo -u $SUDO_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Zsh plugins..."
ZSH_CUSTOM_PLUGINS="$USER_HOME/.oh-my-zsh/custom/plugins"
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then sudo -u $SUDO_USER git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"; fi
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then sudo -u $SUDO_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"; fi

echo "Installing Powerlevel10k Theme (P10k)..."
P10K_PATH="$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_PATH" ]; then sudo -u $SUDO_USER git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_PATH"; fi

# Enable plugins and theme in .zshrc
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

echo "Installing Starship Prompt (Modern/fast alternative)..."
if ! command -v starship &> /dev/null; then
    sudo -u $SUDO_USER curl -sS https://starship.rs/install.sh | sudo -u $SUDO_USER sh -s -- -y
fi


# -----------------------------------------------------------------------------
#  SECTION 5: KALI-STYLE ARSENAL (Pentest / RE)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Post-Exploitation & Go/Python Tools"
echo "=========================================="

echo "[+] Installing Evil-WinRM (via Ruby)..."
sudo -u $SUDO_USER bash -c "eval \"\$(rbenv init -)\" && gem install evil-winrm"

echo "[+] Installing Python Pentest Tools (via pipx)..."
sudo -u $SUDO_USER bash -c "
    pipx install pwntools
    pipx install bloodhound-py
    pipx install sublist3r
    pipx install uncompyle6
    pipx install wafw0f
    pipx install jupyter
    pipx install pwncat-cs
    pipx install interlace
    pipx install sslyze
"

echo "[+] Installing Go Recon Tools (httpx, subfinder, feroxbuster, nuclei, gf)..."
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/epi052/feroxbuster/cmd/feroxbuster@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/httpx" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/subfinder" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/feroxbuster" /usr/local/bin/
sudo -u $SUDO_USER ln -sf "$USER_HOME/go/bin/nuclei" /usr/local/bin/

# Install GEF (GDB Enhanced Features)
if [ ! -f "$USER_HOME/.gdbinit-gef.py" ]; then
    echo "Installing GEF for GDB..."
    sudo -u $SUDO_USER bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
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
alias top='bpytop'                     # Uses bpytop as the default monitor

# QoL
alias update='sudo apt-get update && sudo apt-get upgrade -y && $USER_HOME/update_linux.sh'
alias cleanup='sudo apt-get autoremove -y && sudo apt-get clean'
alias open='explorer.exe .' # Open directory in Windows Explorer
alias c='clear'
alias df='duf'
alias z='zoxide'
" | sudo -u $SUDO_USER tee -a "$ZSHRC_PATH" > /dev/null
fi

echo "=========================================="
echo "  Adding Runtimes to Zsh (.zshrc)..."
echo "=========================================="
# SDKMAN, NVM, Pyenv and Rbenv loaders must be added to .zshrc
LOADERS='
# --- Starship Prompt Loader (Alternative to P10k) ---
if command -v starship 1>/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# --- SDKMAN Loader ---
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

# --- NVM Loader ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# --- Pyenv & Poetry Loader ---
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi
export PATH="$HOME/.local/bin:$PATH"

# --- Rbenv Loader ---
export PATH="$HOME/.rbenv/bin:$PATH"
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
'
echo "$LOADERS" | sudo -u $SUDO_USER tee -a "$ZSHRC_PATH" > /dev/null

# -----------------------------------------------------------------------------
#  SECTION 7: AUTOMATED LANGUAGE INSTALLATION
# -----------------------------------------------------------------------------
# Necessary to load NVM for immediate use in the script
source "$NVM_DIR/nvm.sh" || true 

echo "=========================================="
echo "  Installing Default Language Versions..."
echo "=========================================="
# Node.js LTS (via NVM)
sudo -u $SUDO_USER bash -c "source $NVM_DIR/nvm.sh && nvm install 'lts/*' && nvm alias default 'lts/*' && npm install -g typescript"

# Java, Kotlin, Scala, Dart, Elixir (via SDKMAN)
if [ -s "$USER_HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$USER_HOME/.sdkman/bin/sdkman-init.sh"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install java $JAVA_VERSION"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install kotlin"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install maven"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install dart"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install scala"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install erlang"
    sudo -u $SUDO_USER bash -c "source $USER_HOME/.sdkman/bin/sdkman-init.sh && sdk install elixir"
fi

# Python 3.11.8 (via Pyenv)
sudo -u $SUDO_USER bash -c "eval \"\$(pyenv init -)\" || true && pyenv install $PYTHON_VERSION && pyenv global $PYTHON_VERSION"

# Ruby 3.2.2 (via Rbenv)
sudo -u $SUDO_USER bash -c "eval \"\$(rbenv init -)\" || true && rbenv install $RUBY_VERSION && rbenv global $RUBY_VERSION"


# --- FINAL CLEANUP ---
echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "=========================================="
echo "  WSL (UBUNTU) SETUP V3.8 COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your Ubuntu terminal."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "   - Answer 'y' (yes) if you see icons (like a diamond, lock)."
echo "   - Choose your preferred look ('Rainbow', 'Lean' recommended)."
echo "   (If using Starship, disable P10k in .zshrc to avoid conflicts.)"
echo ""
