# Linux Brand Modifier (LBM) 🚀

**Linux Brand Modifier (LBM)** is a professional, TUI-driven utility designed to deep-rebrand any Linux distribution. It identifies core system identity markers and replaces them with your custom branding, providing a seamless transition for custom OS builders or enthusiasts who want a personalized system experience.

---

## 🛠 How It Works

LBM operates by scanning your system's underlying architecture and bootloader configuration. It uses a **detect-and-modify** pattern to ensure compatibility across various Linux families.

### 1. System Detection
The core logic (`core.py`) probes for specific release files to determine if the base system is **Arch**, **Debian**, **Fedora**, or **RHEL**. It also identifies the active bootloader (GRUB, systemd-boot, or rEFInd) by checking for configuration paths in `/boot`.

### 2. Identity Transformation
Once the user provides a new name and logo path via the **Rich-powered TUI**, LBM performs the following:
- **OS Identity**: Rewrites `/etc/os-release` and `/etc/issue` to reflect the new distribution name.
- **Networking**: Updates `/etc/hostname` and `/etc/hosts` to synchronize the machine's network identity.
- **Boot Experience**: 
    - **GRUB**: Modifies `GRUB_DISTRIBUTOR` and executes `grub-mkconfig`.
    - **systemd-boot**: Updates entry titles in `/boot/loader/entries/`.
    - **rEFInd**: Patches `refind.conf` using regex to update menu entries.
- **UI Branding**: Scans for Display Managers (GDM, SDDM, LightDM) and updates greeting labels and theme metadata.

### 3. Safety First (Backup & Restore)
Before any modification, LBM creates a timestamped backup in `/var/lib/lbm/backups/`. It maintains a `mapping.txt` file to ensure that the uninstaller can precisely restore every modified file to its original state.

---

## 🏗 How It's Built

LBM is built with a focus on modularity and user experience:
- **Language**: Python 3
- **Interface**: Built using the [Rich](https://github.com/Textualize/rich) library for high-quality terminal formatting, progress bars, and status spinners.
- **Architecture**: 
    - `main.py`: Handles the TUI, user input, and task orchestration.
    - `core.py`: Contains the `BrandModifier` class which encapsulates all system-level logic and file operations.
- **Installation**: A Bash-based `install.sh` script handles dependency management (via `pip3`), creates a system-wide binary link (`lbm`), and sets up the environment in `/opt/linux-brand-modifier`.

---

## 🚀 Installation & Usage

### Prerequisites
- Python 3.x
- `pip3` (Python package manager)

### Installation
```bash
git clone https://github.com/arc2898/linux-brand-modifier.git
cd linux-brand-modifier
chmod +x install.sh
sudo ./install.sh
```

### Usage
Launch the interactive TUI:
```bash
sudo lbm
```

### Advanced Commands
- **Create Backup**: `sudo lbm --backup`
- **Restore & Uninstall**: `sudo lbm --uninstall`

---

## 📊 System Targets

| Component | Target Path | Modification Action |
| :--- | :--- | :--- |
| **Distro Name** | `/etc/os-release` | Updates `NAME`, `ID`, `PRETTY_NAME` |
| **Hostname** | `/etc/hostname` | Updates system network name |
| **Login Banner** | `/etc/issue` | Customizes TTY login screen |
| **Desktop Info** | `/etc/machine-info` | Updates `PRETTY_HOSTNAME` for DEs |
| **Bootloader** | `/boot/...` | Updates menu entries for GRUB/systemd-boot/rEFInd |
| **Display Mgr** | `/etc/X11/...` | Updates greeting labels for GDM/SDDM/LightDM |

---
## 🛠️ I used To Build This

<div align="center">

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logologo=python&logoColor=white)
![Shell](https://img.shields.io/badge/Shell-4EAA25?style=for-the-badge&logologo=gnubash&logoColor=white)
</div>


---
*Maintained by [@arc2898](https://github.com/arc2898)*

## Safety

Back up system branding files before running the installer. Use the uninstall script to restore the previous state, and review shell commands before granting elevated privileges.
