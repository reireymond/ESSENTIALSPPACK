# Essential's Programming Pack - Environment Setup Scripts

This repository contains a set of scripts to automate the setup of a comprehensive development, DevOps, and cybersecurity environment on Windows machines, with a focus on WSL 2 (Ubuntu) integration.

## 🚀 What does it do? (Final Version)

This project automatically installs, configures, and updates over 90 essential tools, frameworks, and languages.

* **Windows Environment (via Chocolatey & Winget):**
    * **Editors & IDEs:** VS Code, Visual Studio 2022 Community (w/ C++), Neovim.
    * **Terminal & QoL:** Windows Terminal, PowerShell 7, Oh My Posh, nerd-fonts-cascadiacode, gsudo, zoxide (jumps), bat, eza, DevToys.
    * **Networking & Files:** 7-Zip, WinSCP, WinDirStat, **Bandizip**, **Free Download Manager (FDM)** (Torrent/Downloads).
    * **Languages & Runtimes:** Python 3, Node.js (LTS), OpenJDK 17, .NET SDK.
    * **Web Dev:** MariaDB, Nginx (via Choco).
    * **Build Tools:** Git, Git Credential Manager, CMake, MSYS2.
    * **Virtualization:** Docker Desktop, VirtualBox.
    * **DevOps & Cloud:** AWS CLI, Azure CLI, Terraform, Kubernetes CLI (kubectl).
    * **Security (Host):** Nmap, Wireshark, Burp Suite Free, Ghidra, Autopsy, x64dbg, Sysinternals, Hashcat, Proxifier, Volatility3.
    * **System Maintenance:** Runs **Windows Update** and **cleans all temp/prefetch files** at the end.
    * **Automated Configuration:** Configures VS Code extensions (including **Dart/Flutter**) and the PowerShell 7 profile (using `Terminal-Icons`).

* **WSL (Ubuntu) Environment:**
    * **Core Stack:** C/C++ Compilers, GDB, Valgrind, **set -e (robustness)**.
    * **Runtimes & Languages (Managed by Pyenv, SDKMAN, NVM, Rbenv):**
        * **JVM:** Java 17, Kotlin, **Scala**, Maven.
        * **Mobile/Web:** Node.js, **TypeScript**, **Dart**, **Elixir** (via Erlang).
        * **Scripting:** Python 3.10 (w/ Pyenv, Poetry), Ruby 3.2 (w/ Rbenv), Go, Rust, PHP, Lua.
    * **Terminal QoL (Modern):** Zsh/Oh My Zsh, `fd-find` (fast search), `duf` (disk usage), `tmux`, `htop`, custom aliases.
    * **DevOps TUI:** **Lazydocker**, LazyGit.
    * **Pentesting/Cybersecurity (Go/Pipx):**
        * **Recon:** `httpx`, `subfinder`, `feroxbuster` (fast fuzzing), `wafw00f`.
        * **Exploitation:** `metasploit-framework`, `john`, `seclists`, `evil-winrm`.
        * **RE/Forensics:** `radare2` (w/ r2pipe), `binwalk`, `foremost`, GEF, `volatility3`.
    * **System Diagnostics/Hardening:** **mtr**, **traceroute**, **auditd**, **fail2ban**.
    * **Data Science:** **Jupyter** (via pipx).

---

## 📋 Prerequisites

1.  Windows 10 or 11.
2.  **WSL 2 Installed:**
    * The main script handles this, but if you want to do it first:
    * Open PowerShell as Administrator and run: `wsl --install`
    * Reboot your computer.

---

## ⚙️ How to Use

The entire process is automated by a single master script.

1.  Clone this repository:
    ```bash
    git clone [https://github.com/reireymond/ESSENTIALSPPACK](https://github.com/reireymond/ESSENTIALSPPACK)
    ```
2.  Navigate into the folder:
    ```powershell
    cd ESSENTIALSPPACK
    ```
3.  Run the master script **as Administrator**:
    * Right-click `setup_windows.ps1` and choose "Run with PowerShell".
    * *OR*, in an Admin terminal, run: `.\setup_windows.ps1`

---

**What will happen:**

1.  The script will check if **WSL 2** is installed. If not, it will install it and **prompt you to reboot**. After rebooting, just run `setup_windows.ps1` again.
2.  It will install/verify **Chocolatey** and enable auto-confirmation, and use performance optimizations like `--noprogress`.
3.  It will install/upgrade **all Windows tools** and **VS Code extensions**.
4.  It will automatically call the **`wsl_ubuntu.sh`** script. You will only need to type your **Linux (sudo) password** when prompted. The WSL script runs **APT installation in one batch** for maximum speed.
5.  It will run **Windows Update** to install all pending security patches.
6.  It will **clean up** temp files and **optimize** your drive.
7.  **Close and reopen** your terminal at the very end.

Done! Your full environment is now configured.

---

## 🔧 Maintenance (Updating Software)

The main `setup.ps1` script will update all the software listed in the script *when you run it*.

However, this repository also includes a separate, lightweight script just for daily or weekly maintenance. This script will update **all** packages on your system from **both Winget and Chocolatey**.

1.  Navigate into the repository folder.
2.  Run the update script **as Administrator**:
    ```powershell
    .\update_windows.ps1
    ```
