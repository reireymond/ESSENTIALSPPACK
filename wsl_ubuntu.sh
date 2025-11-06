#!/bin/bash
# =============================================================================
#
#  Essential's Pack - WSL (Ubuntu) Setup Script
#  Version 5.0 (REFACTORED: Modular functions, JSON config, existence checks)
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_JSON="$SCRIPT_DIR/packages_linux.json"

# Track failed installations
FAILED_PACKAGES=()

# Request administrator (sudo) privileges at the start
sudo -v

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Check if a package JSON file exists and is valid
check_json_file() {
    if [ ! -f "$PACKAGES_JSON" ]; then
        echo "ERROR: packages_linux.json not found at: $PACKAGES_JSON"
        exit 1
    fi
    
    if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
        echo "ERROR: packages_linux.json is not valid JSON"
        exit 1
    fi
    
    echo "Package definitions loaded from JSON successfully."
}

# Report failed packages at the end
report_failures() {
    if [ ${#FAILED_PACKAGES[@]} -gt 0 ]; then
        echo ""
        echo "=========================================="
        echo "  INSTALLATION SUMMARY - FAILURES"
        echo "=========================================="
        echo "The following packages failed to install:"
        for pkg in "${FAILED_PACKAGES[@]}"; do
            echo "  ✗ $pkg"
        done
        echo "=========================================="
    fi
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

# Install APT packages with existence check
install_apt_packages() {
    echo "=========================================="
    echo "  Installing APT Packages"
    echo "=========================================="
    
    # Read packages from JSON
    local packages=$(jq -r '.apt[]' "$PACKAGES_JSON")
    local to_install=()
    
    # Check which packages need to be installed
    for pkg in $packages; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo "  ✓ $pkg (already installed)"
        else
            to_install+=("$pkg")
        fi
    done
    
    # Install only missing packages
    if [ ${#to_install[@]} -gt 0 ]; then
        echo "Installing ${#to_install[@]} new packages..."
        if sudo apt-get install -y "${to_install[@]}"; then
            echo "  ✓ APT packages installed successfully"
        else
            echo "  ✗ Some APT packages failed to install"
            FAILED_PACKAGES+=("apt-batch")
        fi
    else
        echo "All APT packages already installed."
    fi
}

# Install snap packages with existence check
install_snap_packages() {
    echo "=========================================="
    echo "  Installing Snap Packages"
    echo "=========================================="
    
    local packages=$(jq -r '.snap[]' "$PACKAGES_JSON")
    
    for pkg in $packages; do
        if snap list 2>/dev/null | grep -q "^$pkg "; then
            echo "  ✓ $pkg (already installed)"
        else
            echo "  → Installing $pkg via snap..."
            if sudo snap install "$pkg" --classic 2>/dev/null; then
                echo "  ✓ $pkg installed"
            else
                echo "  ✗ $pkg failed to install via snap, trying apt..."
                if sudo apt-get install -y "$pkg" 2>/dev/null; then
                    echo "  ✓ $pkg installed via apt"
                else
                    echo "  ✗ $pkg failed to install"
                    FAILED_PACKAGES+=("$pkg")
                fi
            fi
        fi
    done
}

# Install pip tools with existence check
install_pip_tools() {
    echo "=========================================="
    echo "  Installing Python Tools (via pipx)"
    echo "=========================================="
    
    # Ensure pipx is available
    if ! command -v pipx &> /dev/null; then
        echo "Installing pipx..."
        sudo -u "$CURRENT_USER" bash -c 'python3 -m pip install --user pipx && python3 -m pipx ensurepath'
    fi
    
    local packages=$(jq -r '.pip[]' "$PACKAGES_JSON")
    
    for pkg in $packages; do
        if sudo -u "$CURRENT_USER" pipx list 2>/dev/null | grep -q "package $pkg "; then
            echo "  ✓ $pkg (already installed)"
        else
            echo "  → Installing $pkg via pipx..."
            if sudo -u "$CURRENT_USER" bash -c "export PATH=\"\$HOME/.local/bin:\$PATH\" && pipx install $pkg" 2>/dev/null; then
                echo "  ✓ $pkg installed"
            else
                echo "  ✗ $pkg failed to install"
                FAILED_PACKAGES+=("$pkg")
            fi
        fi
    done
}

# Clone git repositories with existence check
clone_git_repos() {
    echo "=========================================="
    echo "  Cloning Git Repositories"
    echo "=========================================="
    
    local tools_dir="$USER_HOME/tools"
    sudo -u "$CURRENT_USER" mkdir -p "$tools_dir"
    
    # Get all git repository keys and URLs
    local repos=$(jq -r '.git | to_entries[] | "\(.key)|\(.value)"' "$PACKAGES_JSON")
    
    while IFS='|' read -r name url; do
        local repo_path="$tools_dir/$name"
        if [ -d "$repo_path/.git" ]; then
            echo "  ✓ $name (already cloned)"
        else
            echo "  → Cloning $name..."
            if sudo -u "$CURRENT_USER" git clone "$url" "$repo_path"; then
                echo "  ✓ $name cloned successfully"
            else
                echo "  ✗ $name failed to clone"
                FAILED_PACKAGES+=("$name")
            fi
        fi
    done <<< "$repos"
}

# Install radare2 from source
install_radare2() {
    echo "=========================================="
    echo "  Installing Radare2 (from source)"
    echo "=========================================="
    
    if command -v radare2 &> /dev/null; then
        echo "  ✓ radare2 (already installed)"
        return 0
    fi
    
    local r2_dir="$USER_HOME/tools/radare2"
    
    if [ ! -d "$r2_dir" ]; then
        echo "  → Cloning radare2..."
        sudo -u "$CURRENT_USER" git clone https://github.com/radareorg/radare2 "$r2_dir"
    fi
    
    echo "  → Building and installing radare2..."
    (
        cd "$r2_dir"
        if sudo -u "$CURRENT_USER" sys/install.sh; then
            echo "  ✓ radare2 installed successfully"
        else
            echo "  ✗ radare2 failed to install"
            FAILED_PACKAGES+=("radare2")
        fi
    )
}

# Install Rust
install_rust() {
    echo "=========================================="
    echo "  Installing Rust (rustup)"
    echo "=========================================="
    
    if command -v rustup &> /dev/null; then
        echo "  ✓ Rust (already installed)"
        return 0
    fi
    
    echo "Installing Rust (rustup)..."
    sudo -u "$CURRENT_USER" bash -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    source "$USER_HOME/.cargo/env" 2>/dev/null || true
    echo "  ✓ Rust installed"
}

# Install .NET SDK
install_dotnet() {
    echo "=========================================="
    echo "  Installing .NET SDK (Microsoft)"
    echo "=========================================="
    
    if command -v dotnet &> /dev/null; then
        echo "  ✓ .NET SDK (already installed)"
        return 0
    fi
    
    if [ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]; then
        wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
        sudo dpkg -i /tmp/packages-microsoft-prod.deb
        rm /tmp/packages-microsoft-prod.deb
        sudo apt-get update
    fi
    
    sudo apt-get install -y dotnet-sdk-8.0
    echo "  ✓ .NET SDK installed"
}

# Install SDKMAN
install_sdkman() {
    echo "=========================================="
    echo "  Installing SDKMAN (Java, Kotlin, Scala, etc.)"
    echo "=========================================="
    
    if [ -d "$USER_HOME/.sdkman" ]; then
        echo "  ✓ SDKMAN (already installed)"
        return 0
    fi
    
    echo "Installing SDKMAN..."
    sudo -u "$CURRENT_USER" bash -c 'curl -s "https://get.sdkman.io" | bash'
    echo "  ✓ SDKMAN installed"
}

# Install NVM
install_nvm() {
    echo "=========================================="
    echo "  Installing NVM (Node Version Manager)"
    echo "=========================================="
    
    if [ -d "$NVM_DIR" ]; then
        echo "  ✓ NVM (already installed)"
        return 0
    fi
    
    echo "Installing NVM..."
    sudo -u "$CURRENT_USER" bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash'
    echo "  ✓ NVM installed"
}

# Install Pyenv and Poetry
install_python_managers() {
    echo "=========================================="
    echo "  Installing Pyenv, Poetry, and PIPX"
    echo "=========================================="
    
    if ! command -v pyenv &> /dev/null; then
        echo "Installing pyenv..."
        sudo -u "$CURRENT_USER" bash -c 'curl https://pyenv.run | bash'
    else
        echo "  ✓ pyenv (already installed)"
    fi
    
    if ! command -v poetry &> /dev/null; then
        echo "Installing Poetry..."
        sudo -u "$CURRENT_USER" bash -c 'curl -sSL https://install.python-poetry.org | python3 -'
    else
        echo "  ✓ Poetry (already installed)"
    fi
    
    if ! command -v pipx &> /dev/null; then
        echo "Installing pipx..."
        sudo -u "$CURRENT_USER" bash -c 'python3 -m pip install --user pipx && python3 -m pipx ensurepath'
    else
        echo "  ✓ pipx (already installed)"
    fi
}

# Install Rbenv
install_rbenv() {
    echo "=========================================="
    echo "  Installing Rbenv (Ruby Version Manager)"
    echo "=========================================="
    
    if command -v rbenv &> /dev/null; then
        echo "  ✓ Rbenv (already installed)"
        return 0
    fi
    
    echo "Installing rbenv..."
    sudo -u "$CURRENT_USER" git clone https://github.com/rbenv/rbenv.git "$USER_HOME/.rbenv"
    sudo -u "$CURRENT_USER" git clone https://github.com/rbenv/ruby-build.git "$USER_HOME/.rbenv/plugins/ruby-build"
    echo "  ✓ Rbenv installed"
}

# Install Docker
install_docker() {
    echo "=========================================="
    echo "  Installing Docker"
    echo "=========================================="
    
    if command -v docker &> /dev/null; then
        echo "  ✓ Docker (already installed)"
        return 0
    fi
    
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
    
    echo "  ✓ Docker installed"
}

# Install Helm and Terraform
install_cloud_tools() {
    echo "=========================================="
    echo "  Installing Helm and Terraform"
    echo "=========================================="
    
    if ! command -v helm &> /dev/null; then
        if [ ! -f /usr/share/keyrings/helm.gpg ]; then
            curl https://baltocdn.com/helm/signing.asc | sudo gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
        fi
    else
        echo "  ✓ Helm (already installed)"
    fi
    
    if ! command -v terraform &> /dev/null; then
        if [ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]; then
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        fi
    else
        echo "  ✓ Terraform (already installed)"
    fi
    
    sudo apt-get update
    sudo apt-get install -y helm terraform
}

# Install Go tools
install_go_tools() {
    echo "=========================================="
    echo "  Installing Go DevOps Tools"
    echo "=========================================="
    
    # Ensure Go bin directory exists
    mkdir -p "$USER_HOME/go/bin"
    
    local go_tools=(
        "github.com/jesseduffield/lazygit@latest"
        "github.com/jesseduffield/lazydocker@latest"
        "github.com/roboll/helmfile@latest"
        "github.com/aquasecurity/trivy/cmd/trivy@latest"
        "github.com/charmbracelet/gum@latest"
        "github.com/tomnomnom/gf@latest"
        "github.com/in-toto/go-witness/cmd/witness@latest"
        "github.com/projectdiscovery/httpx/cmd/httpx@latest"
        "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
        "github.com/epi052/feroxbuster@latest"
        "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
    )
    
    for tool in "${go_tools[@]}"; do
        local tool_name=$(basename "$tool" | cut -d'@' -f1)
        if [ -f "$USER_HOME/go/bin/$tool_name" ]; then
            echo "  ✓ $tool_name (already installed)"
        else
            echo "  → Installing $tool_name..."
            sudo -u "$CURRENT_USER" bash -c "export PATH=\"\$PATH:/usr/local/go/bin:\$HOME/go/bin\" && go install $tool"
        fi
    done
    
    # Create system-wide symlinks
    for tool_path in "$USER_HOME/go/bin"/*; do
        if [ -f "$tool_path" ]; then
            local tool_name=$(basename "$tool_path")
            if [ ! -L "/usr/local/bin/$tool_name" ]; then
                sudo ln -sf "$tool_path" /usr/local/bin/
            fi
        fi
    done
}

# Setup Zsh and Oh My Zsh
setup_oh_my_zsh() {
    echo "=========================================="
    echo "  Installing Zsh + Oh My Zsh + Powerlevel10k"
    echo "=========================================="
    
    # Set Zsh as default shell
    if [ "$(getent passwd "$CURRENT_USER" | cut -d: -f7)" != "$(which zsh)" ]; then
        echo "Setting Zsh as default shell for $CURRENT_USER..."
        sudo chsh -s "$(which zsh)" "$CURRENT_USER"
    fi
    
    # Install Oh My Zsh
    if [ ! -d "$USER_HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sudo -u "$CURRENT_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "  ✓ Oh My Zsh (already installed)"
    fi
    
    # Install Zsh plugins
    echo "Installing Zsh plugins..."
    local ZSH_CUSTOM_PLUGINS="$USER_HOME/.oh-my-zsh/custom/plugins"
    
    if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions" ]; then 
        sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM_PLUGINS/zsh-autosuggestions"
    fi
    if [ ! -d "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then 
        sudo -u "$CURRENT_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM_PLUGINS/zsh-syntax-highlighting"
    fi
    
    # Install Powerlevel10k Theme
    echo "Installing Powerlevel10k Theme..."
    local P10K_PATH="$USER_HOME/.oh-my-zsh/custom/themes/powerlevel10k"
    if [ ! -d "$P10K_PATH" ]; then 
        sudo -u "$CURRENT_USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_PATH"
    else
        echo "  ✓ Powerlevel10k (already installed)"
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
}

# Install Starship
install_starship() {
    echo "=========================================="
    echo "  Installing Starship Prompt"
    echo "=========================================="
    
    if command -v starship &> /dev/null; then
        echo "  ✓ Starship (already installed)"
        return 0
    fi
    
    sudo -u "$CURRENT_USER" sh -c 'curl -sS https://starship.rs/install.sh | sh -s -- -y'
    echo "  ✓ Starship installed"
}

# Configure shell aliases and loaders
configure_shell() {
    echo "=========================================="
    echo "  Configuring Shell Aliases and Loaders"
    echo "=========================================="
    
    local ALIAS_MARKER="# --- Custom Aliases ---"
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
    
    local LOADER_MARKER="# --- Runtime Loaders ---"
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
}

# Install language versions
install_language_versions() {
    echo "=========================================="
    echo "  Installing Default Language Versions"
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
    
    # Install Evil-WinRM after Ruby is ready
    echo "[+] Installing Evil-WinRM (via Ruby gem)..."
    sudo -u "$CURRENT_USER" bash -c "
        export PATH=\"$USER_HOME/.rbenv/bin:\$PATH\"
        eval \"\$(rbenv init -)\"
        gem install evil-winrm
    "
}

# Install miscellaneous tools
install_misc_tools() {
    echo "=========================================="
    echo "  Installing Miscellaneous Tools"
    echo "=========================================="
    
    # LinuxToys
    if ! command -v linux-toys &> /dev/null; then
        echo "[+] Installing LinuxToys..."
        sudo -u "$CURRENT_USER" bash -c '
            cd /tmp
            curl -fsSLJO https://linux.toys/install.sh
            chmod +x install.sh
            ./install.sh
            rm -f install.sh
        '
    else
        echo "  ✓ LinuxToys (already installed)"
    fi
    
    # Setup Nginx
    echo "[+] Setting up Nginx..."
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
    
    # Install GEF (GDB Enhanced Features)
    if [ ! -f "$USER_HOME/.gdbinit-gef.py" ]; then
        echo "Installing GEF for GDB..."
        sudo -u "$CURRENT_USER" bash -c "$(curl -fsSL https://gef.blah.cat/sh)"
    else
        echo "  ✓ GEF (already installed)"
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    echo "=========================================="
    echo "  Essential's Pack - WSL Setup v5.0"
    echo "=========================================="
    echo ""
    
    # Check JSON file
    check_json_file
    
    # Update system
    echo "=========================================="
    echo "  Updating System"
    echo "=========================================="
    sudo apt-get update
    sudo apt-get upgrade -y
    
    # Run all installation functions
    install_apt_packages
    install_snap_packages
    install_rust
    install_dotnet
    install_sdkman
    install_nvm
    install_python_managers
    install_rbenv
    install_docker
    install_cloud_tools
    install_go_tools
    install_pip_tools
    clone_git_repos
    install_radare2
    setup_oh_my_zsh
    install_starship
    configure_shell
    install_language_versions
    install_misc_tools
    
    # Cleanup
    echo "=========================================="
    echo "  Cleaning up APT cache"
    echo "=========================================="
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    # Report failures
    report_failures
    
    echo ""
    echo "=========================================="
    echo "  WSL (UBUNTU) SETUP V5.0 COMPLETE!"
    echo "=========================================="
    echo ""
    echo -e "\033[1;33mIMPORTANT:\033[0m"
    echo "1. Please close and reopen your Ubuntu terminal."
    echo "2. The Powerlevel10k (p10k) wizard will run on first launch."
    echo "3. If using Starship, disable P10k in .zshrc to avoid conflicts."
    echo "4. Run 'source ~/.zshrc' or restart your terminal to load all changes."
    echo ""
}

# Run main function
main
