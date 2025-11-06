# Essential's Programming Pack - Scripts de Configuração de Ambiente

Este projeto de código aberto oferece um conjunto de scripts mestres criados para configurar automaticamente um ambiente de trabalho profissional em diversas plataformas, com foco em **Desenvolvimento de Software**, **DevOps** e **Cibersegurança/Bug Bounty**.

O objetivo é transformar um sistema operacional limpo em uma estação de trabalho completa com todas as linguagens, ferramentas de linha de comando (CLI) e aplicativos essenciais em uma única execução.

## 🚀 O que este pacote instala? (Versão Final)

O projeto utiliza o melhor gerenciador de pacotes de cada plataforma (Chocolatey/Winget no Windows, APT/Snap no Linux, e gerenciadores de versão como SDKMAN, Pyenv, NVM no subsistema) para instalar, configurar e manter mais de 100 ferramentas.

### 💻 1. Ambiente Windows (via PowerShell) - v4.0

O script `setup_windows.ps1` foca na integração perfeita entre o Host Windows e o Linux via WSL 2.

| Categoria | Ferramentas Chave (Instalação e Upgrade via Choco/Winget) |
| :--- | :--- |
| **Desenvolvimento Core** | VS Code, Visual Studio 2022 Community (com Workload C++), Neovim, Python 3, OpenJDK 17, .NET SDK. |
| **Web & Runtimes** | Node.js (LTS), **Bun (Runtime JS/TS Ultra-rápido)**, MariaDB, Nginx. |
| **DevOps & Cloud** | Docker Desktop, VirtualBox, Git, Git Credential Manager, AWS CLI, Azure CLI, Terraform, Kubernetes CLI (kubectl), **Helmfile**. |
| **C/C++ & Build** | CMake, MSYS2, **Ninja Build** (para builds rápidos). |
| **Cibersegurança & RE** | Nmap, Wireshark, Burp Suite Free, Ghidra, Volatility3, **Cheat Engine**, **IDA Free**, **Rizin-Cutter**, OllyDbg. |
| **Produtividade & QoL** | Windows Terminal, PowerShell 7 (com `Set-StrictMode`), **gsudo** (para elevação de privilégios), `eza`, `bat`, `zoxide`, **`delta` (diff Git aprimorado)**, `DevToys`. |

### 🐧 2. Ambiente Linux (WSL 2 e Nativo) - v4.0 / v2.0

Os scripts `wsl_ubuntu.sh` e `linux_setup.sh` focam em CLI moderna, gerenciamento de versão e um arsenal completo de Pentest.

| Categoria | Ferramentas Chave (Instalação via APT/Snap/Source) |
| :--- | :--- |
| **Linguagens (Gerenciadores)** | **SDKMAN** (Java, Kotlin, Scala, Dart, Elixir), **Pyenv** (Python 3.11), **NVM** (Node.js), **Rbenv** (Ruby), **Miniconda** (Ambientes Conda/Data Science). |
| **Shell & QoL** | Zsh, Oh My Zsh, Powerlevel10k, **Starship (Prompt moderno)**, `tmux`, `bpytop` (monitor de sistema), **LinuxToys**, `neofetch`, **`gum`** (scripts de terminal interativos). |
| **DevOps & Containers** | Docker, Helm, Terraform, **Trivy (Scanner de Vulnerabilidades)**, **Hadolint** (Linter de Dockerfile), **pre-commit**, LazyGit, Lazydocker, **Go Witness** (Segurança Supply Chain). |
| **Cibersegurança & Recon** | Metasploit-Framework, John, Seclists, **Nuclei (Scanner de Vulnerabilidades)**, **`sslyze` (Análise SSL/TLS)**, **`semgrep` (SAST)**, **`pwncat-cs` (Netcat Avançado)**, **`interlace` (Automação de Workflow)**, **Gf (Go Templates)**. |
| **Manutenção (Nativo)** | **TLP** (Gerenciamento de Energia - para notebooks), **Flatpak**, **Gnome Tweaks**, `vlc`, **Brave Browser**. |

---

## 📋 Como Usar

### 1. No Windows (Host & WSL 2)

O script mestre para Windows cuida do Host e chama o script WSL automaticamente.

1.  Clone este repositório.
2.  Navegue até a pasta: `cd ESSENTIALSPPACK`
3.  Execute o script **como Administrador**:
    ```powershell
    # O script tentará usar 'gsudo' para elevar privilégios, se disponível.
    .\setup_windows.ps1
    
    # Se você precisar especificar uma distribuição WSL diferente de 'Ubuntu':
    .\setup_windows.ps1 -WslDistro Debian
    ```
4.  O script solicitará a reinicialização se o WSL 2 for instalado pela primeira vez.
5.  Quando solicitado, forneça sua **senha Linux (sudo)** para iniciar a configuração do WSL.

### 2. No Linux (Nativo - Debian/Ubuntu)

Use o script unificado `setup_linux.sh` para sistemas operacionais Linux nativos.

1.  Clone este repositório: `git clone [https://github.com/reireymond/ESSENTIALSPPACK](https://github.com/reireymond/ESSENTIALSPPACK)`
2.  Navegue até a pasta: `cd ESSENTIALSPPACK`
3.  Execute o script **como Administrador**:
    ```bash
    chmod +x setup_linux.sh
    ./setup_linux.sh
    ```

---

## 🔧 Manutenção (Atualização de Software)

O projeto inclui scripts dedicados para manter o ambiente atualizado.

### Windows
```powershell
# Atualiza Chocolatey, Winget e limpa o sistema
.\update_windows.ps1
```

### Linux
```
chmod +x update_linux.sh
.\update_linux.sh
```

---

⚠️ Aviso Importante e Status do Projeto

Este código está em constante atualização e aprimoramento. Novas ferramentas e otimizações são adicionadas regularmente, baseadas nas melhores práticas de desenvolvimento e cibersegurança.

## ⚠️ Aviso Importante e Status do Projeto

Este código está em **constante atualização** e aprimoramento. Novas ferramentas e otimizações são adicionadas regularmente, baseadas nas melhores práticas de desenvolvimento e cibersegurança.

| Script | Versão | Status de Estabilidade | Aviso |
| :--- | :--- | :--- | :--- |
| `setup_windows.ps1` | **v4.0** | **✅ Estável/Maduro** | Testado amplamente na integração Host Windows + WSL. |
| `wsl_ubuntu.sh` | **v4.0** | **✅ Estável/Maduro** | Testado em várias versões do Ubuntu no WSL 2. |
| `setup_linux.sh` | **v2.0** | **⚠️ BETA - Requer Teste** | O instalador nativo para Linux **não foi 100% testado** em todos os ambientes de Desktop. **Pode apresentar falhas** na instalação de softwares que dependem de repositórios externos ou *snaps*. Use com cautela e esteja preparado para solucionar erros manualmente. |
