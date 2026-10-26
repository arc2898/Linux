"""Profile schema, defaults, and validation for CUSTOM."""
from __future__ import annotations
from dataclasses import asdict, dataclass, field
from typing import Any
from pathlib import Path
from urllib.parse import urlparse
import json
import re

@dataclass
class GitHubComponent:
    url: str
    ref: str = "main"
    recipe: str = ""
    enabled: bool = True

@dataclass
class Profile:
    name: str = "custom"
    architecture: str = "auto"
    base: str = "debian"
    release: str = "stable"
    kernel: str = "latest-compatible-stable"
    packages: list[str] = field(default_factory=lambda: ["sudo", "network-manager", "ca-certificates"])
    desktop_environment: str = "none"
    display_manager: str = "none"
    bootloader: str = "grub"
    icon_pack: str = "default"
    shell: str = "bash"
    window_manager: str = "default"
    extra_repositories: list[str] = field(default_factory=list)
    github_components: list[GitHubComponent] = field(default_factory=list)
    hostname: str = "custom"
    username: str = ""
    locale: str = "en_US.UTF-8"
    timezone: str = "UTC"
    filesystem: str = "ext4"
    disk: str = ""
    uefi: str = "auto"
    network_install: bool = True

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> "Profile":
        allowed = set(cls.__dataclass_fields__)
        unknown = set(raw) - allowed
        if unknown:
            raise ValueError("Unknown profile field(s): " + ", ".join(sorted(unknown)))
        data = dict(raw)
        components = data.get("github_components", [])
        if not isinstance(components, list):
            raise ValueError("github_components must be a list")
        data["github_components"] = [
            item if isinstance(item, GitHubComponent) else GitHubComponent(**item)
            for item in components
        ]
        return cls(**data)

    @classmethod
    def load(cls, path: str | Path) -> "Profile":
        with Path(path).open(encoding="utf-8") as fh:
            raw = json.load(fh)
        if not isinstance(raw, dict):
            raise ValueError("Profile root must be a JSON object")
        return cls.from_dict(raw)

    def save(self, path: str | Path) -> None:
        Path(path).write_text(json.dumps(asdict(self), indent=2) + "\n", encoding="utf-8")

    def validate(self) -> list[str]:
        errors: list[str] = []
        if not isinstance(self.name, str) or not self.name.strip():
            errors.append("System name cannot be empty.")
        if self.base != "debian":
            errors.append(f"Base '{self.base}' has no installer adapter yet (Debian is first).")
        if self.release not in {"stable", "testing", "unstable", "bookworm", "trixie"}:
            errors.append("Unknown Debian release.")
        if self.kernel not in {"latest-compatible-stable", "debian-default", "linux-image-amd64"}:
            errors.append("Unknown kernel policy.")
        if self.bootloader not in {"grub", "systemd-boot", "refind", "none"}:
            errors.append("Unknown bootloader choice.")
        if self.desktop_environment not in {"none", "xfce", "kde-plasma", "gnome", "mate", "cinnamon", "lxqt"}:
            errors.append("Unknown desktop environment.")
        if self.display_manager not in {"none", "lightdm", "sddm", "gdm3", "greetd"}:
            errors.append("Unknown display manager.")
        if self.shell not in {"bash", "zsh", "fish", "dash", "nushell"}:
            errors.append("Unknown shell.")
        if self.filesystem not in {"ext4", "btrfs", "xfs"}:
            errors.append("Unknown filesystem.")
        if not self.network_install:
            errors.append("This first release supports network installation only.")
        if self.desktop_environment == "kde-plasma" and self.display_manager not in {"sddm", "none"}:
            errors.append("KDE Plasma normally uses SDDM; choose SDDM or none.")
        if self.desktop_environment == "gnome" and self.display_manager not in {"gdm3", "none"}:
            errors.append("GNOME normally uses GDM; choose GDM or none.")
        if self.desktop_environment in {"xfce", "mate", "cinnamon", "lxqt"} and self.display_manager == "gdm3":
            errors.append(f"Verify GDM compatibility with {self.desktop_environment}; it is not the suggested default.")
        if not isinstance(self.packages, list):
            errors.append("packages must be a list of package names.")
        else:
            for pkg in self.packages:
                if not isinstance(pkg, str) or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9+._:-]*", pkg):
                    errors.append(f"Invalid package name: {pkg!r}")
        for repo in self.extra_repositories:
            if not isinstance(repo, str):
                errors.append(f"Repository URL must be text: {repo!r}")
                continue
            u = urlparse(repo)
            if u.scheme != "https" or not u.netloc:
                errors.append(f"Repository must be an HTTPS URL: {repo}")
        for component in self.github_components:
            u = urlparse(component.url)
            if u.scheme != "https" or u.netloc.lower() not in {"github.com", "www.github.com"}:
                errors.append(f"Use an https://github.com URL: {component.url}")
            if not isinstance(component.ref, str) or not component.ref.strip() or component.ref.startswith("-"):
                errors.append(f"Invalid Git reference: {component.ref!r}")
            if component.recipe and (component.recipe.startswith("/") or ".." in Path(component.recipe).parts):
                errors.append(f"Unsafe recipe path: {component.recipe}")
        if self.username and not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_-]*", self.username):
            errors.append("Username must start with a letter or underscore and contain only letters, numbers, underscores, or hyphens.")
        if self.hostname and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9.-]{0,62}", self.hostname):
            errors.append("Hostname must be 1–63 characters and contain only letters, numbers, dots, and hyphens.")
        return errors

    def install_packages(self) -> list[str]:
        packages = list(dict.fromkeys(self.packages))
        de_map = {
            "xfce": ["xfce4", "xfce4-goodies"],
            "kde-plasma": ["task-kde-desktop"],
            "gnome": ["task-gnome-desktop"],
            "mate": ["task-mate-desktop"],
            "cinnamon": ["task-cinnamon-desktop"],
            "lxqt": ["task-lxqt-desktop"],
        }
        dm_map = {"lightdm": ["lightdm"], "sddm": ["sddm"], "gdm3": ["gdm3"], "greetd": ["greetd"]}
        packages.extend(de_map.get(self.desktop_environment, []))
        packages.extend(dm_map.get(self.display_manager, []))
        shell_map = {"zsh": "zsh", "fish": "fish", "nushell": "nushell"}
        if self.shell in shell_map:
            packages.append(shell_map[self.shell])
        if self.bootloader == "grub":
            # The install adapter must choose the correct GRUB platform package
            # only after target firmware mode and architecture are detected.
            packages.append("grub-common")
        elif self.bootloader == "refind":
            packages.append("refind")
        elif self.bootloader == "systemd-boot":
            packages.append("systemd-boot")
        return list(dict.fromkeys(packages))
