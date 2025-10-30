# Essential's Programming Pack - Scripts de Setup de Ambiente

Este repositório contém um conjunto de scripts para automatizar a configuração de um ambiente de desenvolvimento e cibersegurança em máquinas Windows, com foco na integração com o WSL 2 (Ubuntu).

## 🚀 O que ele faz?

Este projeto instala e configura automaticamente:

* **Ambiente Windows (via Chocolatey):**
    * **Editores e IDEs:** VS Code, Visual Studio 2022 Community, Neovim.
    * **Terminais:** Windows Terminal, PowerShell Core.
    * **Linguagens:** Python 3, Node.js, OpenJDK 17, .NET SDK.
    * **Ferramentas de Build:** Git, CMake, MSYS2.
    * **Virtualização:** Docker Desktop, VirtualBox.
    * **DevOps & Cloud:** AWS CLI, Azure CLI, Terraform.
    * **Diagnóstico de Hardware:** CPU-Z, GPU-Z, HWMonitor, CrystalDiskInfo, CrystalDiskMark, Speccy.
    * **Benchmark e Estresse:** Prime95, MSI Afterburner.
    * **Ferramentas de Cibersegurança:** Nmap, Wireshark, Burp Suite, SQLMap, Ghidra, Autopsy, Metasploit, x64dbg, Sysinternals, Hashcat.
    * **Utilitários:** 7-Zip, Postman, DBeaver, Firefox Developer Edition, Discord, KeePassXC, WinDirStat, WinSCP.
    * **Runtimes Essenciais:** vcredist-all (VC++ 2005-2022), .NET 3.5, .NET 4.x, JRE8, DirectX 9.0c.

* **Ambiente WSL (Ubuntu):**
    * **Compiladores C/C++:** `build-essential` (GCC, G++, Make), GDB, Valgrind.
    * **DevOps:** `kubectl` (Kubernetes).
    * **Ferramentas de Pentesting:** `masscan`, `ffuf`, `hydra`, `gobuster`, `nikto`, `john`, `seclists`, `searchsploit`, `smbclient`.
    * **RE & Forense:** `radare2`, `binwalk`, `foremost`.
    * **QoL do Terminal:** `tmux`, `htop`, `bat`, `exa`, `tldr`, `shellcheck`.
    * **Melhoria de Shell:** Zsh + Oh My Zsh com plugins de auto-sugestão e syntax highlighting.

---

## 📋 Pré-requisitos

1.  Windows 10 ou 11.
2.  **WSL 2 instalado:**
    * Abra o PowerShell como Administrador e rode: `wsl --install`
    * Reinicie o computador.

---

## ⚙️ Como Usar

### 1. Setup do Windows

1.  Clone este repositório:
    ```bash
    git clone https://github.com/reireymond/ESSENTIALSPPACK.git
    ```
2.  Navegue até a pasta:
    ```powershell
    cd ESSENTIALSPPACK
    ```
3.  Execute o script mestre **como Administrador**:
    * Clique com o botão direito em `setup_windows.ps1` e escolha "Executar com PowerShell".
    * *OU*, no terminal Admin, execute: `.\setup_windows.ps1`

O script cuidará da instalação do Chocolatey e de todas as ferramentas do Windows.

### 2. Setup do WSL (Ubuntu)

1.  Abra seu terminal **Ubuntu**.
2.  Navegue até a pasta do repositório (ela é montada automaticamente):
    ```bash
    # Exemplo de caminho (ajuste para o seu):
    cd /mnt/c/Users/SeuUsuario/caminho-para-repositorio/ESSENTIALSPPACK
    ```
3.  Dê permissão de execução ao script:
    ```bash
    chmod +x wsl_ubuntu.sh
    ```
4.  Execute o script:
    ```bash
    ./wsl_ubuntu.sh
    ```
5.  **Feche e reabra** o terminal Ubuntu para que o novo shell Zsh seja carregado.

Pronto! Seu ambiente completo está configurado.