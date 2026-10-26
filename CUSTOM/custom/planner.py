"""Reviewable install plan generation; it makes no disk changes."""
from __future__ import annotations
from dataclasses import asdict
from datetime import datetime, timezone
from .profile import Profile

def make_plan(profile: Profile) -> dict:
    errors = profile.validate()
    return {"format_version":1,"builder":"CUSTOM","created_utc":datetime.now(timezone.utc).isoformat(),"status":"blocked" if errors else "plan-only","safety_note":"Descriptive plan only; no partitioning or package installation is performed.","profile":asdict(profile),"package_selection":profile.install_packages(),"steps":["Check network connectivity and detect architecture/firmware mode.","Resolve Debian mirror and release metadata.","Resolve package dependencies and download sizes.","Ask for explicit disk selection and confirm destructive action.","Partition and format only after explicit confirmation.","Install Debian base into target using the Debian adapter.","Install kernel, bootloader, packages, and selected desktop components.","Configure users, locale, hostname, networking, and boot entries.","Write CUSTOM manifest and offer reboot."],"errors":errors,"github_components":[{"url":c.url,"ref":c.ref,"recipe":c.recipe,"enabled":c.enabled,"execution_status":"not executed; requires reviewed recipe adapter"} for c in profile.github_components]}
