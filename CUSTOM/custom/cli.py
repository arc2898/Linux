"""CUSTOM terminal UI and CLI."""
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
from dataclasses import asdict
from .profile import Profile, GitHubComponent
from .planner import make_plan
from .github_recipes import inspect_repo

try:
    from rich.console import Console
    from rich.panel import Panel
    from rich.prompt import Prompt, Confirm
    from rich.table import Table
    RICH = True
    console = Console()
except ImportError:
    RICH = False
    console = None

def say(text=""):
    console.print(text) if RICH else print(text)

def ask(label, default=""):
    if RICH:
        return Prompt.ask(label, default=default)
    value = input(f"{label} [{default}]: ").strip()
    return value or default

def choose(label, options, default):
    say(f"\n{label}")
    for i, item in enumerate(options, 1):
        say(f"  {i}. {item}{' (default)' if item == default else ''}")
    raw = ask("Choose number or type value", str(options.index(default)+1))
    if raw.isdigit() and 1 <= int(raw) <= len(options):
        return options[int(raw)-1]
    if raw in options:
        return raw
    say("Unrecognized choice; keeping default.")
    return default

def confirm(label, default=False):
    if RICH:
        return Confirm.ask(label, default=default)
    suffix = "Y/n" if default else "y/N"
    answer = input(f"{label} [{suffix}]: ").strip().lower()
    return answer in {"y","yes"} if answer else default

def interactive():
    profile = Profile()
    if RICH:
        console.print(Panel.fit("[bold cyan]CUSTOM Linux[/bold cyan]\nYour system. Your components. Your choice.\n[dim]Network installer prototype · No disk changes in this version[/dim]", border_style="cyan"))
    else:
        say("="*54+"\n CUSTOM Linux — configurable network installer\n This prototype will not modify disks.\n"+"="*54)
    profile.name = ask("System name", profile.name)
    profile.base = choose("Base system", ["debian"], "debian")
    profile.release = choose("Debian release", ["stable","testing","unstable","bookworm","trixie"], "stable")
    profile.kernel = choose("Kernel policy", ["latest-compatible-stable","debian-default"], "latest-compatible-stable")
    profile.desktop_environment = choose("Desktop environment", ["none","xfce","kde-plasma","gnome","mate","cinnamon","lxqt"], "none")
    default_dm = {"kde-plasma":"sddm","gnome":"gdm3"}.get(profile.desktop_environment,"lightdm")
    profile.display_manager = choose("Display manager", ["none","lightdm","sddm","gdm3","greetd"], default_dm)
    profile.window_manager = ask("Window manager (package/profile name)", "default")
    profile.bootloader = choose("Bootloader", ["grub","systemd-boot","refind","none"], "grub")
    profile.icon_pack = ask("Icon pack (package/theme name)", "default")
    profile.shell = choose("Login shell", ["bash","zsh","fish","nushell"], "bash")
    raw_packages = ask("Extra Debian package names (comma-separated; blank for defaults)", "")
    if raw_packages:
        profile.packages.extend(p.strip() for p in raw_packages.split(",") if p.strip())
    profile.username = ask("Initial username (optional for plan)", "")
    repo_url = ask("GitHub component repository URL (optional)", "")
    if repo_url:
        try:
            metadata = inspect_repo(repo_url)
            say(f"Found {metadata['full_name']}: {metadata['description']}")
            say(f"Branch: {metadata['default_branch']} · License: {metadata['license']} · Stars: {metadata['stars']}")
            say(metadata["warning"])
            if confirm("Add repository metadata as an unexecuted component?", True):
                profile.github_components.append(GitHubComponent(url=metadata["html_url"], ref=metadata["default_branch"]))
        except Exception as exc:
            say(f"GitHub inspection failed: {exc}")
    errors = profile.validate()
    if errors:
        say("\nValidation errors:")
        for error in errors:
            say(f"  - {error}")
        return 2
    plan = make_plan(profile)
    say("\nSelected configuration:")
    if RICH:
        table = Table("Setting","Value")
        for key, value in asdict(profile).items():
            table.add_row(key, json.dumps(value, ensure_ascii=False) if isinstance(value,(list,dict)) else str(value))
        console.print(table)
    else:
        for key, value in asdict(profile).items():
            say(f"  {key}: {value}")
    output = ask("Save profile path", "custom-profile.json")
    profile.save(output)
    plan_path = str(Path(output).with_suffix(".plan.json"))
    Path(plan_path).write_text(json.dumps(plan, indent=2)+"\n", encoding="utf-8")
    say(f"Saved profile: {output}\nSaved reviewable plan: {plan_path}\nNo packages installed and no disks changed. This build creates the plan only.")
    return 0

def main(argv=None):
    parser = argparse.ArgumentParser(prog="custom", description="CUSTOM Linux profile builder")
    parser.add_argument("--profile", help="Load profile JSON")
    parser.add_argument("--validate", action="store_true", help="Validate selected or default profile")
    parser.add_argument("--plan", metavar="FILE", help="Write plan JSON")
    parser.add_argument("--inspect-github", metavar="OWNER/REPO", help="Inspect public GitHub repository metadata")
    args = parser.parse_args(argv)
    if args.inspect_github:
        try:
            url = args.inspect_github if args.inspect_github.startswith("https://") else f"https://github.com/{args.inspect_github}"
            print(json.dumps(inspect_repo(url), indent=2))
            return 0
        except Exception as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
    try:
        profile = Profile.load(args.profile) if args.profile else Profile()
    except Exception as exc:
        print(f"error loading profile: {exc}", file=sys.stderr)
        return 2
    if args.validate:
        errors = profile.validate()
        if errors:
            print("\n".join(f"ERROR: {x}" for x in errors), file=sys.stderr)
            return 2
        print("Profile valid.")
        return 0
    if args.plan:
        Path(args.plan).write_text(json.dumps(make_plan(profile), indent=2)+"\n", encoding="utf-8")
        print(f"Wrote {args.plan} (plan only; no disk modifications).")
        return 0
    return interactive()
