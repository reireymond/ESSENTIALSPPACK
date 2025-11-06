#!/bin/bash
# =============================================================================
#
#  Essential's Pack - LINUX UPDATE Script
#  Version 1.0 - Atualiza todos os pacotes e runtimes instalados.
#
# =============================================================================

# Sai imediatamente se um comando falhar
set -e

echo "=========================================="
echo "  STARTING SYSTEM MAINTENANCE (Linux)"
echo "=========================================="

# 1. Atualizar Pacotes do Sistema (APT)
echo ""
echo ">>> 1. Updating APT Packages..."
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y

# 2. Atualizar Gerenciadores de Versão e Runtimes
echo ""
echo ">>> 2. Updating Runtimes and Version Managers..."
USER_HOME="/home/$(whoami)"

# Carregar Loaders para NVM/SDKMAN/Pyenv/Rbenv
# Tenta carregar o .zshrc se o usuário estiver usando zsh
if [ -f "$USER_HOME/.zshrc" ]; then
    source "$USER_HOME/.zshrc"
elif [ -f "$USER_HOME/.bashrc" ]; then
    source "$USER_HOME/.bashrc"
fi


# SDKMAN
if command -v sdk &> /dev/null; then
    echo "  -> Updating SDKMAN..."
    sdk selfupdate
    # Atualiza todas as linguagens instaladas via SDKMAN
    sdk list java | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
    sdk list kotlin | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
    sdk list dart | grep installed | awk '{print $NF}' | xargs -I {} sdk upgrade {} || true
fi

# NVM (Node.js)
if command -v nvm &> /dev/null; then
    echo "  -> Updating Node.js LTS (via NVM)..."
    nvm install 'lts/*' --reinstall-packages-from="$(nvm current)" # Reinstala a LTS mais recente e migra pacotes
fi

# Pyenv
if command -v pyenv &> /dev/null; then
    echo "  -> Updating Pyenv..."
    pyenv update
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


# 3. Atualizar Ferramentas Globais (Go, Pipx)
echo ""
echo ">>> 3. Updating Go and Python CLI Tools..."

# Go Tools (Lazygit, Lazydocker, Nuclei, Gf, Helmfile, etc.)
# Usa 'go install' com -u para atualizar, iterando sobre a pasta bin
if [ -d "$USER_HOME/go/bin" ]; then
    echo "  -> Updating Go Tools..."
    find "$USER_HOME/go/bin" -type f -exec bash -c '
        path=$(command -v $(basename {}))
        if [[ $path == "$HOME/go/bin/"* ]]; then
            echo "    -> Updating $(basename {})..."
            go install -u $(basename {})@latest || true # Tenta atualizar
        fi
    ' \;
fi

# Python Tools (Pipx)
if command -v pipx &> /dev/null; then
    echo "  -> Updating Python CLI Tools (via pipx)..."
    pipx upgrade-all || true
fi


# 4. Limpeza Final
echo ""
echo "=========================================="
echo "  Cleaning up System and Caches"
echo "=========================================="
sudo apt-get autoremove -y
sudo apt-get clean

echo "System maintenance complete."
