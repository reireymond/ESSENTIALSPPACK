# 💻 Essential Developer & Cyber Pack

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/reireymond/ESSENTIALSPPACK/refs/heads/main/LICENSE)
[![Project Status](https://img.shields.io/badge/status-Active%20%7C%20v5.0-brightgreen.svg)]()

This open-source project provides a set of master scripts designed to automatically configure a professional working environment across multiple platforms. It is specifically focused on **Software Development**, **DevOps**, and **Cybersecurity/Bug Bounty**.

The primary goal is to quickly transform a clean operating system into a full-featured workstation, complete with all essential languages, Command Line Interface (CLI) tools, and applications, all in a single, automated execution.

---

## 🚀 Key Features & Installed Arsenal

The project leverages the best package manager for each platform (Chocolatey/Winget on Windows, APT/Snap on Linux, and version managers like SDKMAN, Pyenv, and NVM in the subsystem) to install, configure, and maintain over 100 essential tools.

### 💻 1. Windows Host & WSL 2 Setup (`setup_windows.ps1`) - v5.0

**New in v5.0:** 
- 🎯 **JSON-based package configuration** - All packages now defined in `packages_windows.json` for easy maintenance
- 🔄 **Hybrid installation** - Intelligent fallback from winget to chocolatey
- ✅ **Smart existence checks** - Skips already installed packages for faster re-runs
- 📦 **Added packages**: HxD (hex editor) and CLOC (code counter)

This PowerShell script focuses on seamlessly integrating the Windows Host with the Linux environment via WSL 2, managing system updates and cleanup.

| Category | Key Tools (Choco/Winget Installation) |
| :--- | :--- |
| **Core Development** | VS Code, Visual Studio 2022 Community (C++ Workload), Neovim, Python 3, OpenJDK 17, .NET SDK. |
| **Web & Runtimes** | Node.js (LTS), **Bun (Ultra-fast JS/TS Runtime)**, MariaDB, Nginx. |
| **DevOps & Cloud** | Docker Desktop, VirtualBox, Git, AWS CLI, Azure CLI, Terraform, Kubernetes CLI (`kubectl`), **Helmfile**. |
| **Cybersecurity & RE** | Nmap, Wireshark, Burp Suite Free, Ghidra, Volatility3, **Cheat Engine**, **IDA Free**, **Rizin-Cutter**, OllyDbg. |
| **Productivity & QoL** | Windows Terminal, PowerShell 7, **gsudo** (seamless privilege elevation), `eza`, `bat`, `zoxide`, **`delta` (Enhanced Git diff)**, `DevToys`. |

### 🐧 2. Linux & WSL Environment (`wsl_ubuntu.sh` / `setup_linux.sh`) - v5.0 / v2.0

**New in v5.0 (wsl_ubuntu.sh):**
- 🎯 **JSON-based package configuration** - All packages now defined in `packages_linux.json`
- 🧩 **Modular functions** - Clean, maintainable code structure with dedicated functions
- ✅ **Smart existence checks** - Prevents reinstallation of existing packages
- 🔧 **Radare2 reintroduced** - Installed via official source method
- 📊 **Better failure tracking** - Clear summary of what succeeded and what failed

These Bash scripts prioritize a modern CLI experience, language version management, and a complete Pentesting arsenal.

| Category | Key Tools (APT/Snap/Source Installation) |
| :--- | :--- |
| **Languages (Managers)** | **SDKMAN** (Java, Kotlin, Scala, Dart, Elixir), **Pyenv** (Python 3.11), **NVM** (Node.js), **Rbenv** (Ruby), **Miniconda** (Conda/Data Science). |
| **Shell & QoL** | Zsh, Oh My Zsh, Powerlevel10k, **Starship (Modern Prompt)**, `tmux`, `bpytop`, **LinuxToys**, **`gum`** (interactive terminal scripts). |
| **DevSecOps & Containers** | Docker, Helm, Terraform, **Trivy (Vulnerability Scanner)**, **Hadolint**, **pre-commit**, LazyGit, Lazydocker, **Go Witness** (Supply Chain Security). |
| **Cybersecurity & Recon** | Metasploit, John, Seclists, **Nuclei (Vulnerability Scanner)**, **`sslyze` (SSL/TLS Analysis)**, **`semgrep` (SAST)**, **`pwncat-cs` (Advanced Netcat)**, **`interlace` (Workflow Automation)**, **Gf (Go Templates)**. |

---

## 🛠️ Installation Guide

### Prerequisites

* A fresh installation of **Windows 10/11** or **Ubuntu/Debian Linux**.
* Git installed on the host system.

### 1. Windows (Host & WSL 2)

The Windows script is the main entry point and automatically triggers the WSL setup.

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/reireymond/ESSENTIALSPPACK
    cd ESSENTIALSPPACK
    ```
2.  **Execute the Script (as Administrator):**
    ```powershell
    # The script will handle Admin elevation via 'gsudo' if available.
    .\setup_windows.ps1
    
    # Optional: Specify a different WSL distribution (e.g., Debian)
    .\setup_windows.ps1 -WslDistro Debian
    ```
3.  **Follow Prompts:** The script will handle the WSL installation (which may require a reboot) and prompt for your **Linux (sudo) password** to execute the WSL setup script (`wsl_ubuntu.sh`).

### 2. Linux (Native - Debian/Ubuntu)

Use the dedicated script for native Linux environments.

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/reireymond/ESSENTIALSPPACK
    cd ESSENTIALSPPACK
    ```
2.  **Execute the Script (as Administrator):**
    ```bash
    chmod +x setup_linux.sh
    sudo ./setup_linux.sh
    ```

---

## 📝 Package Configuration (New in v5.0)

The scripts now use JSON configuration files for easy package management:

### `packages_windows.json`
Contains all Windows packages organized by package manager:
- **winget**: Packages to install via Windows Package Manager (preferred method)
- **choco**: Packages to install via Chocolatey (fallback or exclusive)

**To add/remove packages:**
```json
{
  "winget": [
    "Microsoft.VisualStudioCode",
    "Git.Git"
  ],
  "choco": [
    "neovim",
    "7zip",
    "hxd",
    "cloc"
  ]
}
```

### `packages_linux.json`
Contains all Linux packages organized by installation method:
- **apt**: System packages via apt-get
- **snap**: Packages via snap
- **pip**: Python tools installed via pipx
- **git**: Repositories to clone (name → URL mapping)

**To add/remove packages:**
```json
{
  "apt": ["zsh", "nmap", "docker-ce"],
  "snap": ["kubectl"],
  "pip": ["pwntools", "semgrep"],
  "git": {
    "seclists": "https://github.com/danielmiessler/SecLists.git"
  }
}
```

**Benefits:**
- ✅ Easy to maintain - just edit JSON files
- ✅ No need to modify scripts
- ✅ Clear organization by package manager
- ✅ Version control friendly

---

## 🔄 Maintenance and Updating

Use the dedicated update scripts to keep all your packages and version managers current.

### Windows
```powershell
# Updates Chocolatey, Winget, and cleans the system cache
.\update_windows.ps1
```

### Linux
```bash
# Updates APT, Snap, Go, Pipx, Flatpak, and version managers
chmod +x update_linux.sh
./update_linux.sh
```

⚠️ Stability Status & Disclaimer

This project is built for automation and learning in areas like C/C++, Java, Web Development (JS/PHP), and Python, aligning with the author's current studies and cybersecurity interests.

 | Script | Version | Status de Estabilidade | Aviso |

| :--- | :--- | :--- | :--- |

| `setup_windows.ps1` | **v5.0** | **✅ Stable/Mature** | Refactored with JSON config, hybrid install, and smart checks. Tested extensively with Windows Host + WSL 2. |

| `wsl_ubuntu.sh` | **v5.0** | **✅ Stable/Mature** | Refactored with modular functions, JSON config, and existence checks. Tested on various Ubuntu versions within WSL 2. |

| `setup_linux.sh` | **v2.0** | **⚠️ BETA - Requires Testing** | The native Linux installer **has not been 100% tested** in all Desktop environments. **May encounter failures** with external repos/snaps. Use with caution. | 
