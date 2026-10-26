"""GitHub metadata inspector. Never executes remote repository commands."""
from __future__ import annotations
import json
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from urllib.parse import urlparse

def parse_repo_url(url: str) -> tuple[str, str]:
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.netloc.lower() not in {"github.com", "www.github.com"}:
        raise ValueError("Only https://github.com/OWNER/REPO URLs are accepted.")
    parts = [p for p in parsed.path.strip("/").split("/") if p]
    if len(parts) < 2: raise ValueError("URL must identify a repository, e.g. https://github.com/OWNER/REPO.")
    owner, repo = parts[0], parts[1].removesuffix(".git")
    if not owner.replace("-", "").replace("_", "").isalnum() or not repo.replace("-", "").replace("_", "").isalnum(): raise ValueError("Unsupported repository owner/name.")
    return owner, repo

def inspect_repo(url: str, timeout: float = 8.0) -> dict:
    owner, repo = parse_repo_url(url)
    req = Request(f"https://api.github.com/repos/{owner}/{repo}", headers={"Accept":"application/vnd.github+json","User-Agent":"CUSTOM-Linux-Builder/0.1","X-GitHub-Api-Version":"2022-11-28"})
    try:
        with urlopen(req, timeout=timeout) as response:
            data = json.loads(response.read(1_000_000).decode("utf-8"))
    except HTTPError as exc:
        if exc.code == 404: raise ValueError("Repository not found or private; this prototype inspects public repositories only.") from exc
        raise ValueError(f"GitHub API returned HTTP {exc.code}.") from exc
    except (URLError, TimeoutError) as exc: raise ValueError(f"Could not reach GitHub: {exc}") from exc
    license_info = data.get("license") or {}
    return {"full_name":data.get("full_name",f"{owner}/{repo}"),"description":data.get("description") or "(no description)","default_branch":data.get("default_branch","main"),"html_url":data.get("html_url",url),"license":license_info.get("spdx_id") or "unspecified","archived":bool(data.get("archived")),"stars":int(data.get("stargazers_count",0)),"warning":"Metadata only: no repository commands were executed."}
