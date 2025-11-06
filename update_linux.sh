#!/bin/bash
# =============================================================================
#
#  Essential's Pack - LINUX UPDATE Script
#  Version 1.3 - Updates Snap, APT, Go, Pipx, Flatpak, Starship, and Conda.
#
# =============================================================================

# Exit immediately if a command fails
set -e

echo "=========================================="
echo "  STARTING SYSTEM MAINTENANCE (Linux)"
echo "=========================================="

# 0. Define Variables and Load Shell
USER_HOME="/home/$(whoami)"
# Tries to load .zshrc if the user is using zsh
if [ -f "$USER_HOME/.zshrc" ]; then
    source "$USER_HOME/.zshrc" || true
elif [ -f "$USER_HOME/.bashrc" ]; then
    source "$USER_HOME/.bashrc" || true
fi


# 1. Update System Packages (APT)
echo ""
echo ">>> 1. Updating APT Packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# 2. Update Snap Packages
echo ""
echo ">>> 2. Updating Snap Packages..."
sudo snap refresh || true

# 2.1. Update Flatpak
echo ""
echo ">>> 2.1. Updating Flatpak Packages..."
flatpak update || true


# 3. Update Version Managers and Runtimes
echo ""
echo ">>> 3. Updating Runtimes and Version Managers..."

# SDKMAN
if command -v sdk &> /dev/null; then
    echo "  -> Updating SDKMAN..."
    sdk selfupdate
    # Attempts to update all languages installed via SDKMAN
    sdk list java | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
    sdk list kotlin | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
    sdk list dart | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
fi

# NVM (Node.js)
if command -v nvm &> /dev/null; then
    echo "  -> Updating Node.js LTS (via NVM)..."
    # Reinstall the latest LTS and migrate packages.
    LTS_CURRENT=$(nvm current)
    if [ "$LTS_CURRENT" != "none" ]; then
        nvm install 'lts/*' --reinstall-packages-from="$LTS_CURRENT"
    else
        echo "  -> No LTS version installed for automatic update."
    fi
fi

# Pyenv
if command -v pyenv &> /dev/null; then
    echo "  -> Updating Pyenv..."
    pyenv update
fi

# Conda/Miniconda
if [ -f "$USER_HOME/miniconda3/bin/conda" ]; then
    echo "  -> Updating Conda/Miniconda..."
    "$USER_HOME/miniconda3/bin/conda" update --all --yes || true
fi

# Rbenv
if command -v rbenv &> /dev/null; then
    echo "  -> Updating Rbenv..."
    git -C "$(rbenv root)"/plugins/ruby-build pull
fi

# Oh My Zsh
if [ -d "$USER_HOME/.oh-my-zsh" ]; then
    echo "  -> Updating Oh My Zsh..."
    /bin/bash -c "source $USER_HOME/.oh-my-zsh/oh-my-zsh.sh && omz update"
fi


# 4. Update Global Tools (Go, Pipx)
echo ""
echo ">>> 4. Updating Go and Python CLI Tools..."

# Go Tools (Lazygit, Lazydocker, Nuclei, Gf, Helmfile, Trivy, Gum, Witness, etc.)
if command -v go &> /dev/null; then
    echo "  -> Updating Go Tools..."
    # Updates all Go packages (usually installed in $HOME/go/bin)
    go get -u all || true
    go clean -cache
fi

# Starship
if command -v starship &> /dev/null; then
    echo "  -> Updating Starship Prompt..."
    starship self-update || true
fi

# Python Tools (Pipx)
if command -v pipx &> /dev/null; then
    echo "  -> Updating Python CLI Tools (via pipx)..."
    pipx upgrade-all || true
fi


# 5. Final Cleanup
echo ""
echo "=========================================="
echo "  Cleaning up APT cache and unused packages"
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "System maintenance complete."
