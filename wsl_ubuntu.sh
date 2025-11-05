#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 2.0 (Kali-fy & Powerlevel10k)
#
#  This script installs a complete Development and Pentest environment,
#  combining QoL, modern Runtimes, and a Kali Linux-inspired
#  arsenal of tools.
#
#  CRITICAL: This file MUST be saved with (LF) line endings.
#
# =============================================================================

# Ensures the script is non-interactive (won't ask questions)
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
#  SECTION 1: DEVELOPMENT PACKAGES
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Development Pack (C/C++, Java, Python, Shell)"
echo "=========================================="
# build-essential (gcc, g++, make), gdb (debugger), valgrind (memory)
# binutils (binary tools), default-jdk (Java)
# python3-pip (pip manager), python3-venv (virtual envs)
# shellcheck (shell linter)
sudo apt-get install -y \
  build-essential gdb valgrind binutils \
  default-jdk \
  python3-pip python3-venv \
  shellcheck

echo "=========================================="
echo "  Installing Additional Runtimes (Go, Rust, Node.js)"
echo "=========================================="

# Install Go (Google's Language)
sudo apt-get install -y golang-go

# Install Rust (Systems Language)
if ! command -v rustup &> /dev/null; then
    echo "Installing Rust (rustup)..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    # Add Rust to the current shell's PATH
    source "$HOME/.cargo/env"
fi

# Install NVM (Node Version Manager) - ESSENTIAL for JS dev
export NVM_DIR="/home/${SUDO_USER}/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM (Node Version Manager)..."
    # Installs NVM
    sudo -u $SUDO_USER curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -u $SUDO_USER bash
else
    echo "NVM is already installed. Skipping."
fi

# -----------------------------------------------------------------------------
#  SECTION 2: TERMINAL QOL & DEVOPS
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Terminal QoL (Utilities)"
echo "=========================================="
# tmux (multiplexer), htop (monitor), bat (cat with colors)
# eza (ls replacement), tldr (simplified man pages)
# jq (the 'sed' for JSON), fzf (fuzzy finder), ripgrep (fast grep)
# ncdu (disk usage analyzer)
sudo apt-get install -y \
  tmux htop bat eza tldr \
  jq fzf ripgrep ncdu

# Fix 'bat' command name on Ubuntu (batcat -> bat)
if [ ! -L /usr/bin/bat ]; then
  sudo rm -f /usr/bin/bat
  sudo ln -s /usr/bin/batcat /usr/bin/bat
fi

echo "=========================================="
echo "  Installing DevOps Tools (Docker, Kubectl, Helm)"
echo "=========================================="

# 1. Kubectl (Kubernetes manager)
sudo snap install kubectl --classic

# 2. Docker CLI (to connect to Docker Desktop on Windows)
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Install ONLY the client (CLI) and buildx
sudo apt-get install -y docker-ce-cli docker-buildx-plugin

# 3. Helm (Kubernetes Package Manager)
curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

# -----------------------------------------------------------------------------
#  SECTION 3: SHELL UPGRADE (ZSH + POWERLEVEL10K)
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
echo "=========================================="

# Install Zsh and zsh-completions (BETTER AUTOCOMPLETE)
sudo apt-get install -y zsh zsh-completions

# Set Zsh as the default shell for the user (if not already set)
if [ "$(getent passwd $SUDO_USER | cut -d: -f7)" != "$(which zsh)" ]; then
    echo "Setting Zsh as default shell for $SUDO_USER..."
    sudo chsh -s $(which zsh) $SUDO_USER
else
    echo "Zsh is already the default shell."
fi

# Set path for Zsh config
ZSHRC_PATH="/home/${SUDO_USER}/.zshrc"

# Install Oh My Zsh non-interactively
if [ ! -d "/home/${SUDO_USER}/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    # Run as the regular user, not as root
    sudo -u $SUDO_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "Oh My Zsh is already installed. Skipping."
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
else
    echo "Powerlevel10k theme already installed. Skipping."
fi

# Enable plugins and P10k theme in .zshrc
if [ -f "$ZSHRC_PATH" ]; then
    # Enable Plugins (git, suggestions, highlight, completions)
    if grep -q "plugins=(git)" "$ZSHRC_PATH"; then
        echo "Enabling Zsh plugins..."
        sudo -u $SUDO_USER sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$ZSHRC_PATH"
    fi
    # Set the Powerlevel10k theme
    if grep -q 'ZSH_THEME="robbyrussell"' "$ZSHRC_PATH"; then
        echo "Setting Powerlevel10k theme..."
        sudo -u $SUDO_USER sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC_PATH"
    fi
fi

# -----------------------------------------------------------------------------
#  SECTION 4: KALI-STYLE ARSENAL
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  KALI PACK: Recon & Enumeration"
echo "=========================================="
# nmap (network scanner), net-tools (ifconfig), dnsutils (dig)
# tcpdump (sniffer), amass (subdomain enum)
# smbclient (Windows pentest), enum4linux-ng (Windows enum)
# nbtscan (NetBIOS scan), onesixtyone (SNMP scanner)
# masscan (fast scanner)
sudo apt-get install -y \
  nmap net-tools dnsutils tcpdump amass \
  smbclient enum4linux-ng nbtscan onesixtyone masscan

echo "=========================================="
echo "  KALI PACK: Web Analysis"
echo "=========================================="
# gobuster (directory fuzzer), dirb (fuzzer)
# nikto (web scanner), whatweb (web fingerprint)
# ffuf (fast fuzzer), sqlmap (SQL injection)
# wfuzz (web fuzzer)
sudo apt-get install -y \
  gobuster dirb nikto whatweb ffuf sqlmap wfuzz

echo "=========================================="
echo "  KALI PACK: Password, Exploit & Sniffing"
echo "=========================================="
# john (John the Ripper), hashid (hash identifier)
# seclists (wordlists), thc-hydra (brute force)
# exploitdb (searchsploit), metasploit-framework
# impacket-scripts (AD/Windows pentest), dsniff (arpspoof)
# aircrack-ng (Wi-Fi analysis)
sudo apt-get install -y \
  john hashid seclists thc-hydra \
  exploitdb metasploit-framework \
  python3-impacket impacket-scripts dsniff aircrack-ng

echo "=========================================="
echo "  KALI PACK: RE & Forensics"
echo "=========================================="
# binwalk (firmware analysis), radare2 (reverse engineering)
# foremost (file carving)
sudo apt-get install -y \
  binwalk radare2 foremost

# -----------------------------------------------------------------------------
#  SECTION 5: ALIASES & CLEANUP
# -----------------------------------------------------------------------------

echo "=========================================="
echo "  Applying custom Zsh aliases..."
echo "=========================================="

ALIAS_MARKER="# --- Custom Aliases ---"

if ! grep -q "$ALIAS_MARKER" "$ZSHRC_PATH"; then
    echo "Adding custom aliases to $ZSHRC_PATH..."
    # Appends custom aliases to the end of .zshrc
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
else
    echo "Custom aliases already found in $ZSHRC_PATH. Skipping."
fi

# Add the NVM loader to .zshrc (if not already present)
if ! grep -q "nvm.sh" "$ZSHRC_PATH"; then
    echo "Adding NVM to $ZSHRC_PATH..."
    echo '
# --- NVM Loader ---
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
fi


# --- FINAL CLEANUP ---
echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "=========================================="
echo "  WSL (UBUNTU) SETUP COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "1. Please close and reopen your Ubuntu terminal."
echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
echo "   - Answer 'y' (yes) if you see icons (like a diamond, lock)."
echo "   - Choose your preferred look ('Rainbow', 'Lean' recommended)."
echo "   - The 'nerd-fonts-cascadiacode' you installed on Windows should work perfectly."
echo ""
