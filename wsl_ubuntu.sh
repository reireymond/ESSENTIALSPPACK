#!/bin/bash

# =============================================================================
#
#  Setup Script for WSL (Ubuntu) - Version 1.8 (Fixed package names)
#
#  Installs the C/C++ development environment (build-essential),
#  a suite of pentesting tools (Kali-like),
#  terminal QoL utilities, DevOps tools (kubectl),
#  enhances the terminal with Zsh + Oh My Zsh,
#  and applies custom aliases idempotently.
#
#  CRITICAL: This file MUST be saved with Unix (LF) line endings, not (CRLF).
#
# =============================================================================

# Request administrator (sudo) privileges at the start
sudo -v

# Keep sudo privileges alive throughout the script
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo "=========================================="
echo "  Updating System (apt update/upgrade)..."
echo "=========================================="
sudo apt update
sudo apt upgrade -y

echo "=========================================="
echo "  Installing Development Pack (C/C++, Java, Python, Shell)"
echo "=========================================="
# build-essential includes: gcc, g++, make
sudo apt install -y build-essential gdb valgrind binutils
sudo apt install -y default-jdk      # Java (JDK)
sudo apt install -y python3-pip python3-venv # Python
sudo apt install -y shellcheck       # Shell script linter

echo "=========================================="
echo "  Installing Terminal QoL (Quality of Life) Utilities"
echo "=========================================="
# tmux (multiplexer), htop (monitor), bat (cat w/ colors)
# FIXED: 'exa' foi substituído por 'eza' (substituto moderno)
# FIXED: 'tldr' (pacote principal)
sudo apt install -y tmux htop bat eza tldr

# Fix 'bat' command name on Ubuntu (batcat -> bat)
# Remove link if it exists (to prevent error) and create the new one
if [ ! -L /usr/bin/bat ]; then
  sudo rm -f /usr/bin/bat
  sudo ln -s /usr/bin/batcat /usr/bin/bat
fi

echo "=========================================="
echo "  Installing Network & Enumeration Tools"
echo "=========================================="
# net-tools (for ifconfig, etc.), smbclient (Windows pentest)
# masscan (ultra-fast port scanner)
# FIXED: 'enum4linux' foi substituído por 'enum4linux-ng' (moderno)
sudo apt install -y net-tools smbclient enum4linux-ng nbtscan onesixtyone masscan

echo "=========================================="
echo "  Installing Web Analysis Tools"
echo "=========================================="
# gobuster (directory brute-force), nikto (vulnerability scanner)
# ffuf (fast web fuzzer), sqlmap (SQL injection tool)
sudo apt install -y gobuster dirb nikto whatweb ffuf sqlmap

echo "=========================================="
echo "  Installing Password Tools & Wordlists"
echo "=========================================="
# john the ripper, hashid (hash identifier), seclists (BEST wordlists)
# FIXED: 'hydra' foi substituído por 'thc-hydra' (nome correto do pacote)
sudo apt install -y john hashid seclists thc-hydra

echo "=========================================="
echo "  Installing Exploit, RE & Forensics Tools"
echo "=========================================="
# FIXED: 'searchsploit' é incluído no pacote 'exploitdb'
# binwalk (firmware & file analysis)
# radare2 (reverse engineering)
# foremost (forensics, file carving)
# metasploit-framework (Exploitation framework)
sudo apt install -y exploitdb binwalk radare2 foremost metasploit-framework

echo "=========================================="
echo "  Installing DevOps Tools (Kubernetes)"
echo "=========================================="
# kubectl (Kubernetes cluster manager)
# Install via snap, the recommended method on Ubuntu
sudo snap install kubectl --classic

echo "=========================================="
echo "  Installing Zsh + Oh My Zsh (Terminal Upgrade)"
echo "=========================================="

# Install Zsh
sudo apt install -y zsh

# Set Zsh as the default shell for the user (if not already set)
# $SUDO_USER is the user who *ran* sudo
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
else
    echo "zsh-autosuggestions plugin already installed. Skipping."
fi
if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
    sudo -u $SUDO_USER git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting
else
    echo "zsh-syntax-highlighting plugin already installed. Skipping."
fi

# Robustly enable plugins in .zshrc
if grep -q "plugins=(git)" "$ZSHRC_PATH"; then
    echo "Enabling Zsh plugins..."
    sudo -u $SUDO_USER sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC_PATH"
else
    echo "Could not find default 'plugins=(git)' line. Plugins must be added manually."
fi

# --- ADDING CUSTOM ALIASES (Idempotent) ---
echo "=========================================="
echo "  Applying custom Zsh aliases..."
echo "=========================================="

ALIAS_MARKER="# --- Custom Aliases ---"

if ! grep -q "$ALIAS_MARKER" "$ZSHRC_PATH"; then
    echo "Adding custom aliases to $ZSHRC_PATH..."
    # Appends custom aliases to the end of .zshrc
    # We use 'tee -a' to append as the user, not as root
    echo '
# --- Custom Aliases ---
alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias update="sudo apt update && sudo apt upgrade -y"
alias cleanup="sudo apt autoremove -y && sudo apt clean"
alias open="explorer.exe ."
' | sudo -u $SUDO_USER tee -a $ZSHRC_PATH > /dev/null
else
    echo "Custom aliases already found in $ZSHRC_PATH. Skipping."
fi


# --- APT CLEANUP ---
echo "=========================================="
echo "  Cleaning up APT cache and unused packages..."
echo "=========================================="
sudo apt autoremove -y
sudo apt clean

echo "=========================================="
echo "  WSL (UBUNTU) SETUP COMPLETE!"
echo "=========================================="
echo ""
echo -e "\033[1;33mIMPORTANT:\033[0m"
echo "Please close and reopen your Ubuntu terminal for Zsh (the new shell) and new aliases to load correctly."
echo ""
