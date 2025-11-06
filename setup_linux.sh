#!/bin/bash
# =============================================================================
#
#  Essential's Pack - LINUX (Ubuntu/Debian) Setup Script
#  Version 1.2 - Additions: LinuxToys, Starship, Flatpak, QoL Desktop, Trivy.
#
#  Installs a complete Development, DevOps, and Pentest environment.
#
# =============================================================================

# Exit immediately if a command fails
set -e

# Ensures the script is non-interactive for APT installations
export DEBIAN_FRONTEND=noninteractive

# Variables
CURRENT_USER=$(whoami)
USER_HOME="/home/$CURRENT_USER"
NVM_DIR="$USER_HOME/.nvm"
ZSHRC_PATH="$USER_HOME/.zshrc"
PYTHON_VERSION="3.11.8"
JAVA_VERSION="17.0.10-tem"
RUBY_VERSION="3.2.2"

# Request administrator privileges at the start
sudo -v

echo "=========================================="
echo "  Updating System (apt-get update/upgrade)..."
echo "=========================================="
sudo apt-get update
sudo apt-get upgrade -y

# -----------------------------------------------------------------------------
#  SECTION 1: CORE DEPENDENCIES & BUILD TOOLS (APT BATCH)
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
  # DevOps & Code Quality
  hadolint \
  # Network Diagnostics and Security
  mtr-tiny traceroute auditd fail2ban sslyze \
  # Common User / Multimedia / Compatibility
  vlc neofetch libfuse2 libgtk-3-dev \
  tlp tlp-rdw gnome-tweaks flatpak \
  # Kali Pack: Recon & Exploitation
  nmap net-tools dnsutils tcpdump amass \
  smbclient enum4linux-ng nbtscan onesixtyone masscan \
  gobuster dirb nikto whatweb ffuf sqlmap wfuzz \
  dirsearch mitmproxy \
  john hashid seclists thc-hydra \
  exploitdb metasploit-framework \
  python3-impacket impacket-scripts dsniff aircrack-ng \
  bettercap reaver \
  # Kali Pack: Reverse Engineering & Forensics
  binwalk radare2 foremost radare2-r2pipe \
  sleuthkit volatility3 rizin-cutter \
  # Installation Dependencies (Docker, SDKMAN)
  zip unzip software-properties-common

# -----------------------------------------------------------------------------
#  SECTION 2: IDEs, Browsers & Advanced Tools (DEB/Snap)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Visual Studio Code (APT Repo)"
echo "=========================================="
# Adds Microsoft keys and repository for VS Code
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
    rm microsoft.gpg
    sudo apt-get update
fi
sudo apt-get install -y code

echo "=========================================="
echo "  Installing VS Code Extensions (Linux)"
echo "=========================================="
code --install-extension pkief.material-icon-theme --force
code --install-extension eamodio.gitlens --force
code --install-extension formulahendry.code-runner --force
code --install-extension visualstudioexptteam.vscodeintellicode --force
code --install-extension github.copilot --force
code --install-extension esbenp.prettier-vscode --force
code --install-extension dbaeumer.vscode-eslint --force
code --install-extension ritwickdey.liveserver --force
code --install-extension ms-vscode.cpptools --force
code --install-extension ms-vscode.cmake-tools --force
code --install-extension ms-python.python --force
code --install-extension ms-python.vscode-pylance --force
code --install-extension vscjava.vscode-java-pack --force
code --install-extension ms-azuretools.vscode-docker --force
code --install-extension dart-code.dart-code --force
code --install-extension dart-code.flutter --force

echo "=========================================="
echo "  Installing Browsers and Desktop Apps (Snap/APT)"
echo "=========================================="
# Installs Brave Browser via APT
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
sudo apt-get update
sudo apt-get install -y brave-browser

# Others
sudo snap install google-chrome --classic || sudo apt-get install -y google-chrome-stable
sudo snap install firefox
sudo snap install discord
sudo snap install beekeeper-studio
sudo snap install sublime-text --classic

# -----------------------------------------------------------------------------
#  SECTION 3: RUNTIMES & VERSION MANAGERS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Rust (rustup)"
echo "=========================================="
if ! command -v rustup &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
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
if [ ! -d "$USER_HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
    echo "SDKMAN installed. Please close and reopen the terminal and run this script again."
    exit
fi

echo "=========================================="
echo "  Installing NVM (Node Version Manager)"
echo "=========================================="
if [ ! -d "$NVM_DIR" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

echo "=========================================="
echo "  Installing Pyenv, Poetry, and PIPX (Python)"
echo "=========================================="
if ! command -v pyenv &> /dev/null; then
    curl https://pyenv.run | bash
fi
if ! command -v poetry &> /dev/null; then
    curl -sSL https://install.python-poetry.org | python3 -
fi
echo "Installing pipx (for isolated Python CLIs)..."
export PATH="$PATH" && pipx ensurepath


echo "=========================================="
echo "  Installing Rbenv (Ruby Version Manager)"
echo "=========================================="
if ! command -v rbenv &> /dev/null; then
    # Install rbenv
    git clone https://github.com/rbenv/rbenv.git "$USER_HOME/.rbenv"
    # Install ruby-build (plugin for rbenv install)
    git clone https://github.com/rbenv/ruby-build.git "$USER_HOME/.rbenv/plugins/ruby-build"
fi

# -----------------------------------------------------------------------------
#  SECTION 4: UTILITIES, DEVOPS & QoL CONFIG
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing QoL Tools and LinuxToys"
echo "=========================================="

# Installing LinuxToys
echo "[+] Installing LinuxToys..."
curl -fsSLJO https://linux.toys/install.sh
chmod +x install.sh
./install.sh
rm install.sh || true

# TLP Configuration (Power management for notebooks)
echo "=========================================="
echo "  Configuring TLP (Power Management)"
echo "=========================================="
sudo systemctl enable tlp

# Flatpak Configuration
echo "=========================================="
echo "  Setting up Flatpak"
echo "=========================================="
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true

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
sudo ln -sf "$USER_HOME/go/bin/lazygit" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/lazydocker" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/helmfile" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/trivy" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/gum" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/gf" /usr/local/bin/

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
sudo apt-get install -y docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin
echo "[+] Adding $CURRENT_USER to the 'docker' group..."
sudo usermod -aG docker "$CURRENT_USER"

# Helm and Terraform (maintained repositories)
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update
sudo snap install kubectl --classic
sudo apt-get install -y helm terraform

# -----------------------------------------------------------------------------
#  SECTION 5: KALI-STYLE ARSENAL (Pentest / RE)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Post-Exploitation & Go/Python Tools"
echo "=========================================="
# Evil-WinRM (via Ruby)
eval "$(rbenv init -)" && gem install evil-winrm

# Python Pentest Tools (via pipx)
pipx install pwntools
pipx install bloodhound-py
pipx install sublist3r
pipx install uncompyle6
pipx install wafw0f
pipx install jupyter
pipx install pwncat-cs
pipx install interlace
pipx install sslyze

# Go Recon Tools (httpx, subfinder, feroxbuster, nuclei)
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/epi052/feroxbuster/cmd/feroxbuster@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
sudo ln -sf "$USER_HOME/go/bin/httpx" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/subfinder" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/feroxbuster" /usr/local/bin/
sudo ln -sf "$USER_HOME/go/bin/nuclei" /usr/local/bin/

# Install GEF (GDB Enhanced Features)
if [ ! -f "$USER_HOME/.gdbinit-gef.py" ]; then
    echo "Installing GEF for GDB..."
    bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
fi

# -----------------------------------------------------------------------------
#  SECTION 6: SHELL UPGRADE (ZSH + POWERLEVEL10K + STARSHIP)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="
if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$(which zsh)" ]; then
    sudo apt-get install -y zsh
    sudo chsh -s $(which zsh) "$CURRENT_USER"
fi

if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

echo "Installing Zsh plugins..."
ZSH_CUSTOM_PLUGINS="$USER_HOME/.oh-my-zsh/custom/plugins"
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"; fi
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"; fi

echo "Installing Powerlevel10k Theme (P10k)..."
P10K_PATH="$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_PATH" ]; then git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_PATH"; fi

# Enables plugins and theme in .zshrc
if [ -f "$ZSHRC_PATH" ]; then
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC_PATH"
    sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"
fi

echo "Installing Starship Prompt (Modern/fast alternative)..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# -----------------------------------------------------------------------------
#  SECTION 7: ALIASES & SHELL LOADERS
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
alias c='clear'
alias df='duf'
alias z='zoxide'
" | tee -a "$ZSHRC_PATH" > /dev/null
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
echo "$LOADERS" | tee -a "$ZSHRC_PATH" > /dev/null

# -----------------------------------------------------------------------------
#  SECTION 8: AUTOMATED LANGUAGE INSTALLATION
# -----------------------------------------------------------------------------

# Necessary to load NVM for immediate use in the script
source "$NVM_DIR/nvm.sh" || true 

echo "=========================================="
echo "  Installing Default Language Versions..."
echo "=========================================="
# Node.js LTS (via NVM)
nvm install 'lts/*' && nvm alias default 'lts/*' && npm install -g typescript

# Java, Kotlin, Scala, Dart, Elixir (via SDKMAN)
if [ -s "$USER_HOME/.sdkman/bin/sdkman-init.sh" ]; then
    source "$USER_HOME/.sdkman/bin/sdkman-init.sh"
    sdk install java "$JAVA_VERSION"
    sdk install kotlin
    sdk install maven
    sdk install dart
    sdk install scala
    sdk install erlang
    sdk install elixir
fi

# Python 3.11.8 (via Pyenv)
eval "$(pyenv init -)" || true
pyenv install "$PYTHON_VERSION" && pyenv global "$PYTHON_VERSION"

# Ruby 3.2.2 (via Rbenv)
eval "$(rbenv init -)" || true
rbenv install "$RUBY_VERSION" && rbenv global "$RUBY_VERSION"


# --- FINAL CLEANUP ---
echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "=========================================="
echo "  LINUX SETUP V1.2 COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your terminal (it will be Zsh, not Bash)."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "3. You can disable P10k and use Starship for an even lighter/more customizable prompt."
echo ""
