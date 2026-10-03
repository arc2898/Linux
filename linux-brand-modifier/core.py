import os
import shutil
import subprocess
import re
import platform
from datetime import datetime

class BrandModifier:
    def __init__(self, name, image):
        self.new_name = name
        self.new_image = image
        self.backup_dir = f"/var/lib/lbm/backups/{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.base_distro = self.detect_base()
        self.bootloader = self.detect_bootloader()
        
        if not os.path.exists(self.backup_dir):
            os.makedirs(self.backup_dir, exist_ok=True)

    def detect_base(self):
        if os.path.exists("/etc/arch-release"): return "arch"
        if os.path.exists("/etc/debian_version"): return "debian"
        if os.path.exists("/etc/fedora-release"): return "fedora"
        if os.path.exists("/etc/redhat-release"): return "rhel"
        return "generic"

    def detect_bootloader(self):
        if os.path.exists("/boot/grub/grub.cfg") or os.path.exists("/boot/grub2/grub.cfg"):
            return "grub"
        if os.path.exists("/boot/loader/loader.conf"):
            return "systemd-boot"
        if os.path.exists("/boot/EFI/refind/refind.conf"):
            return "refind"
        return "unknown"

    def _backup_file(self, path):
        if os.path.exists(path):
            dest = os.path.join(self.backup_dir, os.path.basename(path).replace(".", "_") + "_" + str(hash(path))[:5])
            shutil.copy2(path, dest)
            # Store mapping for uninstaller
            with open(os.path.join(self.backup_dir, "mapping.txt"), "a") as f:
                f.write(f"{os.path.basename(dest)}:{path}\n")
            return True
        return False

    def update_os_release(self):
        path = "/etc/os-release"
        if not os.path.exists(path): return False
        self._backup_file(path)
        
        with open(path, 'r') as f: lines = f.readlines()
        new_lines = []
        for line in lines:
            if line.startswith("NAME="): new_lines.append(f'NAME="{self.new_name}"\n')
            elif line.startswith("PRETTY_NAME="): new_lines.append(f'PRETTY_NAME="{self.new_name} Linux"\n')
            elif line.startswith("ID="): new_lines.append(f'ID={self.new_name.lower().replace(" ", "_")}\n')
            else: new_lines.append(line)
            
        with open(path, 'w') as f: f.writelines(new_lines)
        return True

    def update_hostname(self):
        new_host = self.new_name.lower().replace(" ", "-")
        self._backup_file("/etc/hostname")
        self._backup_file("/etc/hosts")
        
        with open("/etc/hostname", 'w') as f: f.write(new_host + "\n")
        
        if os.path.exists("/etc/hosts"):
            current_host = platform.node()
            with open("/etc/hosts", 'r') as f: lines = f.readlines()
            with open("/etc/hosts", 'w') as f:
                for line in lines:
                    f.write(line.replace(current_host, new_host))
        return True

    def update_grub(self):
        if self.bootloader != "grub": return False
        grub_cfg = "/etc/default/grub"
        if not os.path.exists(grub_cfg): return False
        
        self._backup_file(grub_cfg)
        with open(grub_cfg, 'r') as f: lines = f.readlines()
        
        with open(grub_cfg, 'w') as f:
            for line in lines:
                if line.startswith("GRUB_DISTRIBUTOR="):
                    f.write(f'GRUB_DISTRIBUTOR="{self.new_name}"\n')
                else:
                    f.write(line)
        
        # Determine correct grub-mkconfig path
        mkconfig = "grub-mkconfig"
        if shutil.which("grub2-mkconfig"): mkconfig = "grub2-mkconfig"
        
        output_path = "/boot/grub/grub.cfg"
        if os.path.exists("/boot/grub2/grub.cfg"): output_path = "/boot/grub2/grub.cfg"
        
        try:
            if self.base_distro == "debian" and shutil.which("update-grub"):
                subprocess.run(["update-grub"], capture_output=True)
            else:
                subprocess.run([mkconfig, "-o", output_path], capture_output=True)
            return True
        except Exception: return False

    def update_systemd_boot(self):
        if self.bootloader != "systemd-boot": return False
        loader_conf = "/boot/loader/loader.conf"
        if not os.path.exists(loader_conf): return False
        
        self._backup_file(loader_conf)
        entries_dir = "/boot/loader/entries/"
        if os.path.exists(entries_dir):
            for entry in os.listdir(entries_dir):
                if entry.endswith(".conf"):
                    path = os.path.join(entries_dir, entry)
                    self._backup_file(path)
                    with open(path, 'r') as f: lines = f.readlines()
                    with open(path, 'w') as f:
                        for line in lines:
                            if line.startswith("title"):
                                f.write(f"title {self.new_name}\n")
                            else: f.write(line)
        return True

    def update_refind(self):
        if self.bootloader != "refind": return False
        refind_conf = "/boot/EFI/refind/refind.conf"
        if not os.path.exists(refind_conf): return False
        
        self._backup_file(refind_conf)
        with open(refind_conf, 'r') as f: content = f.read()
        new_content = re.sub(r'(menuentry\s+)"[^"]+"', rf'\1"{self.new_name}"', content)
        with open(refind_conf, 'w') as f: f.write(new_content)
        return True

    def update_dm(self):
        # Display Manager Rebranding
        dms = {
            "gdm": "/etc/gdm3/daemon.conf",
            "sddm": "/etc/sddm.conf",
            "lightdm": "/etc/lightdm/lightdm.conf"
        }
        
        success = False
        for dm, path in dms.items():
            if os.path.exists(path):
                self._backup_file(path)
                try:
                    with open(path, 'r') as f: content = f.read()
                    # Try to replace common labels if they exist
                    new_content = re.sub(r'(Label|Name|Greeting)=.*', rf'\1={self.new_name}', content)
                    if new_content != content:
                        with open(path, 'w') as f: f.write(new_content)
                    success = True
                except: pass
        
        # Check for SDDM theme metadata
        sddm_theme_dir = "/usr/share/sddm/themes/"
        if os.path.exists(sddm_theme_dir):
            for theme in os.listdir(sddm_theme_dir):
                meta = os.path.join(sddm_theme_dir, theme, "metadata.desktop")
                if os.path.exists(meta):
                    self._backup_file(meta)
                    try:
                        with open(meta, 'r') as f: m_content = f.read()
                        new_m = re.sub(r'Name=.*', f'Name={self.new_name} Login', m_content)
                        with open(meta, 'w') as f: f.write(new_m)
                    except: pass
        return success

    def update_machine_info(self):
        path = "/etc/machine-info"
        self._backup_file(path)
        content = f'PRETTY_HOSTNAME="{self.new_name}"\nICON_NAME="computer"\n'
        with open(path, 'w') as f: f.write(content)
        return True

    def update_issue(self):
        path = "/etc/issue"
        self._backup_file(path)
        with open(path, 'w') as f: f.write(f"{self.new_name} \\n \\l\n\n")
        return True

    def create_full_backup(self):
        """Backs up all potential targets without modifying them."""
        targets = [
            "/etc/os-release", "/etc/hostname", "/etc/hosts", 
            "/etc/machine-info", "/etc/issue", "/etc/default/grub",
            "/boot/loader/loader.conf", "/boot/EFI/refind/refind.conf",
            "/etc/gdm3/daemon.conf", "/etc/sddm.conf", "/etc/lightdm/lightdm.conf"
        ]
        
        # Add systemd-boot entries
        entries_dir = "/boot/loader/entries/"
        if os.path.exists(entries_dir):
            for entry in os.listdir(entries_dir):
                if entry.endswith(".conf"):
                    targets.append(os.path.join(entries_dir, entry))
                    
        count = 0
        for t in targets:
            if self._backup_file(t):
                count += 1
        return count
