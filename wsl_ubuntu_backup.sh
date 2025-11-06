#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 4.2 (FINAL FIX: All comments corrected, Rizin/Cutter separated)
#
#  Installs a complete Development, DevOps, and Pentest environment.
#
# =============================================================================

# Exit immediately if a command fails
set -e

# Ensures the script is non-interactive
export DEBIAN_FRONTEND=noninteractive

# Variables - Fixed to handle both sudo and non-sudo execution
if [ -n "$SUDO_USER" ]; then
    CURRENT_USER="$SUDO_USER"
else
    CURRENT_USER="$(whoami)"
fi
USER_HOME="/home/$CURRENT_USER"
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
  build-essential gdb valgrind binutils \
  shellcheck \
  python3-dev python3-pip python3-setuptools \
  libssl-dev libffi-dev libbz2-dev libreadline-dev libsqlite3-dev liblzma-dev \
  autoconf bison patch libyaml-dev libtool \
  golang-go lua5.4 \
  php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath \
  php-composer \
  tmux htop bpytop bat eza tldr \
  jq fzf ripgrep ncdu \
  neovim fd-find duf \
  mtr-tiny traceroute auditd fail2ban sslyze \
  nmap net-tools dnsutils tcpdump amass \
  smbclient enum4linux-ng nbtscan onesixtyone masscan \
  gobuster dirb nikto whatweb ffuf sqlmap wfuzz \
  dirsearch mitmproxy \
  john hashid seclists thc-hydra \
  exploitdb metasploit-framework \
  python3-impacket impacket-scripts dsniff aircrack-ng \
  bettercap reaver \
  binwalk radare2 foremost radare2-r2pipe \
  sleuthkit volatility3 rizin cutter \
  zip unzip software-properties-common zsh curl wget git

echo "APT packages installed successfully."

# -----------------------------------------------------------------------------
#  SECTION 2: RUNTIMES & VERSION MANAGERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Rust (rustup)"
echo "=========================================="
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust (rustup)..."
    sudo -u "$CURRENT_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    source "$USER_HOME/.cargo/env" 2>/dev/null || true
fi

echo "=========================================="
echo "  Installing .NET SDK (Microsoft)"
echo "=========================================="
if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
    wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
    sudo dpkg -i /tmp/packages-microsoft-prod.deb
    rm /tmp/packages-microsoft-prod.deb
    sudo apt-get update
fi
sudo apt-get install -y dotnet-sdk-8.0

echo "=========================================="
echo "  Installing SDKMAN (for Java, Kotlin, Scala, Dart, Elixir, etc.)"
echo "=========================================="
if [ ! -d "$USER_HOME/.sdkman" ]; then
    echo "Installing SDKMAN..."
    sudo -u "$CURRENT_USER" bash -c 'curl -s "https://get.sdkman.io" | bash'
fi

echo "=========================================="
echo "  Installing NVM (Node Version Manager)"
echo "=========================================="
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    sudo -u "$CURRENT_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
fi

echo "=========================================="
echo "  Installing Pyenv, Poetry, and PIPX (Python)"
echo "=========================================="
if ! command -v pyenv &> /dev/null; then
    echo "Installing pyenv (Python Version Manager)..."
    sudo -u "$CURRENT_USER" bash -c 'curl https://pyenv.run | bash'
fi
if ! command -v poetry &> /dev/null; then
    echo "Installing Poetry (Project Manager)..."
    sudo -u "$CURRENT_USER" bash -c 'curl -sSL https://install.python-poetry.org | python3 -'
fi
echo "Installing pipx (for isolated Python CLIs)..."
sudo -u "$CURRENT_USER" bash -c 'python3 -m pip install --user pipx && python3 -m pipx ensurepath'

echo "=========================================="
echo "  Installing Rbenv (Ruby Version Manager)"
echo "=========================================="
if ! command -v rbenv &> /dev/null; then
    echo "Installing rbenv..."
    sudo -u "$CURRENT_USER" git clone https://github.com/rbenv/rbenv.git "$USER_HOME/.rbenv"
    sudo -u "$CURRENT_USER" git clone https://github.com/rbenv/ruby-build.git "$USER_HOME/.rbenv/plugins/ruby-build"
fi

# -----------------------------------------------------------------------------
#  SECTION 3: UTILITIES, DEVOPS & PRODUCTIVITY
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing QoL Tools and LinuxToys"
echo "=========================================="

echo "[+] Installing LinuxToys..."
sudo -u "$CURRENT_USER" bash -c '
    cd /tmp
    curl -fsSLJO https://linux.toys/install.sh
    chmod +x install.sh
    ./install.sh
    rm -f install.sh
'

echo "=========================================="
echo "  Setting up Local Webserver (Nginx)"
echo "=========================================="
sudo apt-get install -y nginx

# Create symbolic links for fd and bat
if [ ! -L /usr/bin/fd ]; then 
    sudo rm -f /usr/bin/fd 2>/dev/null || true
    sudo ln -s /usr/bin/fdfind /usr/bin/fd
fi
if [ ! -L /usr/bin/bat ]; then 
    sudo rm -f /usr/bin/bat 2>/dev/null || true
    sudo ln -s /usr/bin/batcat /usr/bin/bat
fi

echo "=========================================="
echo "  Installing QoL Git/Docker TUIs & DevOps Go Tools"
echo "=========================================="
# Ensure Go bin directory exists
mkdir -p "$USER_HOME/go/bin"

# Install Go tools as the correct user
sudo -u "$CURRENT_USER" bash -c '
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    go install github.com/jesseduffield/lazygit@latest
    go install github.com/jesseduffield/lazydocker@latest
    go install github.com/roboll/helmfile@latest
    go install github.com/aquasecurity/trivy/cmd/trivy@latest
    go install github.com/charmbracelet/gum@latest
    go install github.com/tomnomnom/gf@latest
    go install github.com/in-toto/go-witness/cmd/witness@latest
'

# Create system-wide symlinks
for tool in lazygit lazydocker helmfile trivy gum gf witness; do
    if [ -f "$USER_HOME/go/bin/$tool" ]; then
        sudo ln -sf "$USER_HOME/go/bin/$tool" /usr/local/bin/
    fi
done

echo "=========================================="
echo "  Installing Cloud & Infra Tools"
echo "=========================================="
# Docker setup
sudo install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
fi
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin

echo "[+] Adding $CURRENT_USER to the 'docker' group..."
sudo usermod -aG docker "$CURRENT_USER"

# Configure passwordless sudo for Docker service in WSL
if ! sudo grep -q "docker-nopasswd" /etc/sudoers.d/docker-nopasswd 2>/dev/null; then
    echo "[+] Configuring passwordless sudo for Docker service..."
    echo "%docker ALL=(ALL) NOPASSWD: /usr/sbin/service docker *" | sudo tee /etc/sudoers.d/docker-nopasswd > /dev/null
    sudo chmod 0440 /etc/sudoers.d/docker-nopasswd
fi

# Helm and Terraform
if [ ! -f /usr/share/keyrings/helm.gpg ]; then
    curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
fi

if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
fi

sudo apt-get update
sudo snap install kubectl --classic 2>/dev/null || sudo apt-get install -y kubectl
sudo apt-get install -y helm terraform

# -----------------------------------------------------------------------------
#  SECTION 4: SHELL UPGRADE (ZSH + POWERLEVEL10K + STARSHIP)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="
if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell for $CURRENT_USER..."
    sudo chsh -s "$(which zsh)" "$CURRENT_USER"
fi

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sudo -u "$CURRENT_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Zsh plugins..."
ZSH_CUSTOM_PLUGINS="$USER_HOME/.oh-my-zsh/custom/plugins"
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then 
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then 
    sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
fi

echo "Installing Powerlevel10k Theme (P10k)..."
P10K_PATH="$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_PATH" ]; then 
    sudo -u "$CURRENT_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_PATH"
fi

# Enable plugins and theme in .zshrc
if [ -f "$ZSHRC_PATH" ]; then
    if grep -q "plugins=(git)" "$ZSHRC_PATH"; then
        echo "Enabling Zsh plugins..."
        sudo -u "$CURRENT_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC_PATH"
    fi
    if grep -q 'ZSH_THEME="robbyrussell"' "$ZSHRC_PATH"; then
        echo "Setting Powerlevel10k theme..."
        sudo -u "$CURRENT_USER" sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"
    fi
fi

echo "Installing Starship Prompt (Modern/fast alternative)..."
if ! command -v starship &> /dev/null; then
    sudo -u "$CURRENT_USER" sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
fi

# -----------------------------------------------------------------------------
#  SECTION 5: KALI-STYLE ARSENAL (Pentest / RE)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Post-Exploitation & Go/Python Tools"
echo "=========================================="

echo "[+] Installing Python Pentest Tools (via pipx)..."
sudo -u "$CURRENT_USER" bash -c '
    export PATH="$HOME/.local/bin:$PATH"
    pipx install pwntools || true
    pipx install bloodhound-py || true
    pipx install sublist3r || true
    pipx install uncompyle6 || true
    pipx install wafw00f || true
    pipx install jupyter || true
    pipx install pwncat-cs || true
    pipx install interlace || true
    pipx install sslyze || true
    pipx install semgrep || true
    pipx install mycli || true
    pipx install pgcli || true
    pipx install pre-commit || true
'

echo "[+] Installing Go Recon Tools..."
sudo -u "$CURRENT_USER" bash -c '
    export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/epi052/feroxbuster@latest
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
'

# Create symlinks for recon tools
for tool in httpx subfinder feroxbuster nuclei; do
    if [ -f "$USER_HOME/go/bin/$tool" ]; then
        sudo ln -sf "$USER_HOME/go/bin/$tool" /usr/local/bin/
    fi
done

# Install GEF (GDB Enhanced Features)
if [ ! -f "$USER_HOME/.gdbinit-gef.py" ]; then
    echo "Installing GEF for GDB..."
    sudo -u "$CURRENT_USER" bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
fi

# Install Evil-WinRM after Ruby is installed
echo "[+] Deferring Evil-WinRM installation (requires Ruby to be installed first)..."

# -----------------------------------------------------------------------------
#  SECTION 6: ALIASES & SHELL LOADERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Applying custom Zsh aliases..."
echo "=========================================="
ALIAS_MARKER="# --- Custom Aliases ---"
if ! grep -q "$ALIAS_MARKER" "$ZSHRC_PATH"; then
    echo "Adding custom aliases to $ZSHRC_PATH..."
    sudo -u "$CURRENT_USER" tee -a "$ZSHRC_PATH" > /dev/null << 'EOF'

# --- Custom Aliases ---
# Replace 'ls' with 'eza' (modern, with icons)
alias ls='eza --icons --git'
alias ll='eza -l --icons --git --all'
alias lt='eza -T'
alias top='bpytop'

# QoL
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias cleanup='sudo apt-get autoremove -y && sudo apt-get clean'
alias open='explorer.exe .'
alias c='clear'
alias df='duf'
alias z='zoxide'
EOF
fi

echo "=========================================="
echo "  Adding Runtimes to Zsh (.zshrc)..."
echo "=========================================="
LOADER_MARKER="# --- Runtime Loaders ---"
if ! grep -q "$LOADER_MARKER" "$ZSHRC_PATH"; then
    echo "Adding runtime loaders to $ZSHRC_PATH..."
    sudo -u "$CURRENT_USER" tee -a "$ZSHRC_PATH" > /dev/null << 'EOF'

# --- Runtime Loaders ---

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

# --- Go Environment ---
export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
EOF
fi

# -----------------------------------------------------------------------------
#  SECTION 7: AUTOMATED LANGUAGE INSTALLATION
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Default Language Versions..."
echo "=========================================="

# Node.js LTS (via NVM)
echo "[+] Installing Node.js LTS..."
sudo -u "$CURRENT_USER" bash -c "
    export NVM_DIR=\"$USER_HOME/.nvm\"
    [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\"
    nvm install 'lts/*'
    nvm alias default 'lts/*'
    nvm use default
    npm install -g typescript
"

# Java and other JVM languages (via SDKMAN)
echo "[+] Installing Java and JVM languages..."
sudo -u "$CURRENT_USER" bash -c "
    export SDKMAN_DIR=\"$USER_HOME/.sdkman\"
    [[ -s \"\$SDKMAN_DIR/bin/sdkman-init.sh\" ]] && source \"\$SDKMAN_DIR/bin/sdkman-init.sh\"
    sdk install java $JAVA_VERSION
    sdk install kotlin
    sdk install maven
    sdk install gradle
"

# Python (via Pyenv)
echo "[+] Installing Python $PYTHON_VERSION..."
sudo -u "$CURRENT_USER" bash -c "
    export PYENV_ROOT=\"$USER_HOME/.pyenv\"
    export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
    eval \"\$(pyenv init -)\"
    pyenv install -s $PYTHON_VERSION
    pyenv global $PYTHON_VERSION
"

# Ruby (via Rbenv)
echo "[+] Installing Ruby $RUBY_VERSION..."
sudo -u "$CURRENT_USER" bash -c "
    export PATH=\"$USER_HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    rbenv install -s $RUBY_VERSION
    rbenv global $RUBY_VERSION
"

# Now install Evil-WinRM after Ruby is ready
echo "[+] Installing Evil-WinRM (via Ruby gem)..."
sudo -u "$CURRENT_USER" bash -c "
    export PATH=\"$USER_HOME/.rbenv/bin:\$PATH\"
    eval \"\$(rbenv init -)\"
    gem install evil-winrm
"

# -----------------------------------------------------------------------------
#  FINAL CLEANUP
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "=========================================="
echo "  WSL (UBUNTU) SETUP V4.2 COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your Ubuntu terminal."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "3. If using Starship, disable P10k in .zshrc to avoid conflicts."
echo "4. Run 'source ~/.zshrc' or restart your terminal to load all changes."
echo ""
