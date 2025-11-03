#!/bin/bash

# =============================================================================
#
#  Setup Script for WSL (Ubuntu) - Version 1.4 (Added Cleanup)
#
#  Installs the C/C++ development environment (build-essential),
#  a suite of pentesting tools (Kali-like),
#  terminal QoL utilities, DevOps tools (kubectl),
#  and enhances the terminal with Zsh + Oh My Zsh.
#
#  HOW TO USE (Manual):
#  1. Save this file (e.g., wsl_ubuntu.sh)
#  2. Give execute permission:  chmod +x wsl_ubuntu.sh
#  3. Run the script:          ./wsl_ubuntu.sh
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
# tmux (multiplexer), htop (monitor), bat (cat w/ colors), exa (modern ls)
# tldr (simplified man pages)
sudo apt install -y tmux htop bat exa tldr

# Fix 'bat' command name on Ubuntu (batcat -> bat)
# Remove link if it exists (to prevent error) and create the new one
sudo rm -f /usr/bin/bat
sudo ln -s /usr/bin/batcat /usr/bin/bat

echo "=========================================="
echo "  Installing Network & Enumeration Tools"
echo "=========================================="
# net-tools (for ifconfig, etc.), smbclient (Windows pentest)
# masscan (ultra-fast port scanner)
sudo apt install -y net-tools smbclient enum4linux nbtscan onesixtyone masscan

echo "=========================================="
echo "  Installing Web Analysis Tools"
echo "=========================================="
# gobuster (directory brute-force), nikto (vulnerability scanner)
# ffuf (fast web fuzzer)
sudo apt install -y gobuster dirb nikto whatweb ffuf

echo "=========================================="
echo "  Installing Password Tools & Wordlists"
echo "=========================================="
# john the ripper, hashid (hash identifier), seclists (BEST wordlists)
# hydra (service brute-forcer)
sudo apt install -y john hashid seclists hydra

echo "=========================================="
echo "  Installing Exploit, RE & Forensics Tools"
echo "=========================================="
# searchsploit (Exploit-DB offline database)
# binwalk (firmware & file analysis)
# radare2 (reverse engineering)
# foremost (forensics, file carving)
sudo apt install -y searchsploit exploitdb binwalk radare2 foremost

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

# Install Oh My Zsh non-interactively
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Set Zsh as the default shell for the current user
sudo chsh -s $(which zsh) $USER

echo "Installing Zsh plugins (autosuggestions and syntax-highlighting)..."
# Clone plugins
ZSH_CUSTOM_PLUGINS=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM_PLUGINS/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting

# Automatically enable plugins in .zshrc
# This finds the line 'plugins=(git)' and replaces it
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# --- APT CLEANUP (NEW SECTION) ---
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
echo "Please close and reopen your Ubuntu terminal for Zsh (the new shell) to load correctly."
echo ""
