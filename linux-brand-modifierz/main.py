import sys
import os
import subprocess
from rich.console import Console
from rich.panel import Panel
from rich.prompt import Prompt, Confirm
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from core import BrandModifier

console = Console()

def show_header():
    console.clear()
    console.print(Panel(
        "[bold cyan]Linux Brand Modifier[/bold cyan]\n"
        "[italic]Rebrand your system from scratch (GRUB, systemd, refind, hostname)[/italic]",
        expand=False,
        border_style="bright_blue"
    ))

def get_user_input():
    distro_name = Prompt.ask("[bold yellow]Enter the new Distro Name[/bold yellow]")
    distro_image = Prompt.ask("[bold yellow]Enter the path to the Distro Image (Logo/Splash)[/bold yellow]", default="/usr/share/backgrounds/default.png")
    return distro_name, distro_image

def run_backup():
    console.print("[bold blue]Initiating Full System Identity Backup...[/bold blue]")
    modifier = BrandModifier("Backup", "")
    count = modifier.create_full_backup()
    console.print(f"[bold green]✓ Backup complete![/bold green] {count} files secured in [cyan]{modifier.backup_dir}[/cyan]")

def run_uninstall():
    uninstall_script = "/opt/linux-brand-modifier/uninstall.sh"
    if os.path.exists(uninstall_script):
        subprocess.run(["sudo", "bash", uninstall_script])
    else:
        console.print("[bold red]Error: Uninstall script not found in /opt/linux-brand-modifier/[/bold red]")

def main():
    if os.geteuid() != 0:
        console.print("[bold red]Error: This script must be run as root (sudo).[/bold red]")
        sys.exit(1)
    
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg == "--backup":
            run_backup()
            return
        elif arg == "--uninstall":
            run_uninstall()
            return
        elif arg == "--help" or arg == "-h":
            console.print("[bold cyan]Usage:[/bold cyan]")
            console.print("  sudo lbm              Launch rebranding TUI")
            console.print("  sudo lbm --backup     Create a system identity backup")
            console.print("  sudo lbm --uninstall  Remove tool and restore from backup")
            return

    show_header()
    name, image = get_user_input()
    
    modifier = BrandModifier(name, image)
    
    console.print(f"\n[bold green]System Detection:[/bold green]")
    console.print(f"  Base Distro: [cyan]{modifier.base_distro}[/cyan]")
    console.print(f"  Bootloader:  [cyan]{modifier.bootloader}[/cyan]")
    console.print(f"\n[bold green]Starting rebranding to '{name}'...[/bold green]\n")

    tasks = [
        (modifier.update_os_release, "Updating /etc/os-release"),
        (modifier.update_hostname, "Updating Hostname and Hosts"),
        (modifier.update_machine_info, "Configuring systemd machine-info"),
        (modifier.update_grub, "Updating GRUB Branding"),
        (modifier.update_systemd_boot, "Updating systemd-boot Entries"),
        (modifier.update_refind, "Updating rEFInd Configuration"),
        (modifier.update_dm, "Rebranding Display Manager (GDM/SDDM/LightDM)"),
        (modifier.update_issue, "Updating TTY Login Screen"),
    ]

    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        BarColumn(),
        TaskProgressColumn(),
        console=console,
    ) as progress:
        overall_task = progress.add_task("[green]Overall Progress", total=len(tasks))
        
        for task_func, desc in tasks:
            step_task = progress.add_task(f"[cyan]{desc}...", total=100)
            success = task_func()
            for i in range(100):
                import time
                time.sleep(0.01)
                progress.update(step_task, advance=1)
            
            if success:
                progress.update(step_task, description=f"[green]✓ {desc}")
            else:
                progress.update(step_task, description=f"[yellow]! {desc} (Skipped/Failed)")
            
            progress.update(overall_task, advance=1)

    console.print("\n")
    console.print(Panel(
        "[bold green]Rebranding Complete![/bold green]\n\n"
        "Changes applied to:\n"
        " - /etc/os-release & /etc/issue\n"
        " - Hostname & Machine Info\n"
        " - Bootloader configuration\n"
        " - Display Manager labels\n\n"
        "[bold yellow]Please reboot your system to see the full effect.[/bold yellow]",
        border_style="green"
    ))

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        console.print("\n[bold red]Operation cancelled by user.[/bold red]")
        sys.exit(0)
