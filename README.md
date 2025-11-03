# Essential's Programming Pack - Environment Setup Scripts

This repository contains a set of scripts to automate the setup of a development and cybersecurity environment on Windows machines, with a focus on WSL 2 (Ubuntu) integration.

## 🚀 What does it do?

This project automatically installs and configures:

* **Windows Environment (via Chocolatey):**
    * **Editors & IDEs:** VS Code, Visual Studio 2022 Community, Neovim.
    * **Terminals:** Windows Terminal, PowerShell Core.
    * **Languages:** Python 3, Node.js, OpenJDK 17, .NET SDK.
    * **Build Tools:** Git, CMake, MSYS2.
    * **Virtualization:** Docker Desktop, VirtualBox.
    * **DevOps & Cloud:** AWS CLI, Azure CLI, Terraform.
    * **Hardware Diagnostics:** CPU-Z, GPU-Z, HWMonitor, CrystalDiskInfo, CrystalDiskMark, Speccy.
    * **Benchmark & Stress:** Prime95, MSI Afterburner.
    * **Cybersecurity Tools:** Nmap, Wireshark, Burp Suite, SQLMap, Ghidra, Autopsy, Metasploit, x64dbg, Sysinternals, Hashcat.
    * **Utilities:** 7-Zip, Postman, DBeaver, Firefox Developer Edition, Discord, KeePassXC, WinDirStat, WinSCP, gsudo.
    * **Essential Runtimes:** vcredist-all (VC++ 2005-2022), .NET 3.5, .NET 4.x, JRE8, DirectX 9.0c.

* **WSL (Ubuntu) Environment:**
    * **C/C++ Compilers:** `build-essential` (GCC, G++, Make), GDB, Valgrind.
    * **DevOps:** `kubectl` (Kubernetes).
    * **Pentesting Tools:** `masscan`, `ffuf`, `hydra`, `gobuster`, `nikto`, `john`, `seclists`, `searchsploit`, `smbclient`.
    * **RE & Forensics:** `radare2`, `binwalk`, `foremost`.
    * **Terminal QoL:** `tmux`, `htop`, `bat`, `exa`, `tldr`, `shellcheck`.
    * **Shell Upgrade:** Zsh + Oh My Zsh with auto-suggestion and syntax-highlighting plugins.

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
    git clone [https://github.com/YOUR-USER/YOUR-REPO.git](https://github.com/YOUR-USER/YOUR-REPO.git)
    ```
2.  Navigate into the folder:
    ```powershell
    cd YOUR-REPO
    ```
3.  Run the master script **as Administrator**:
    * Right-click `setup_windows.ps1` and choose "Run with PowerShell".
    * *OR*, in an Admin terminal, run: `.\setup_windows.ps1`

**What will happen:**

1.  The script will check if **WSL 2** is installed. If not, it will install it and **prompt you to reboot**. After rebooting, just run `setup_windows.ps1` again.
2.  It will install/verify **Chocolatey**.
3.  It will install/upgrade **all 70+ Windows tools**.
4.  At the end, it will automatically call the **`wsl_ubuntu.sh`** script. You will only need to type your **Linux (sudo) password** when prompted.
5.  **Close and reopen** your terminal at the very end.

Done! Your full environment is now configured.
