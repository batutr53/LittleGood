"""Pinned, isolated LibreKO sources and optional offline asset baking.

The upstream programs remain in builds/research (not in the game export).
No upstream game, server, extension or installation script is started by sync.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    "LibreKO": "e5f0e4200fd42f69934f55557f92f2ee2ccfafde",
    "LibreKO-Assets": "b44cf9ddf5c3c0b703db0db5d7fe505b582cab66",
    "LibreKO-vscode": "4c4597a3a6a150755a7020d82a88a7ff6b78b1d3",
}


def git(folder: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(folder), *args], text=True).strip()


def inspect(folder: Path, revision: str) -> dict:
    actual = git(folder, "rev-parse", "HEAD")
    if actual != revision:
        raise ValueError(f"{folder.name}: expected {revision}, found {actual}; checkout left untouched")
    if git(folder, "status", "--porcelain"):
        raise ValueError(f"{folder.name}: local changes; checkout left untouched")
    files = git(folder, "ls-files", "-z").split("\0")
    paths = [folder / f for f in files if f]
    extensions = Counter(p.suffix.lower() or "<none>" for p in paths)
    license_file = folder / "LICENSE"
    return {"url": f"https://github.com/ZeusAFK/{folder.name}", "revision": actual,
            "path": str(folder), "tracked_files": len(paths),
            "bytes": sum(p.stat().st_size for p in paths),
            "extensions": dict(sorted(extensions.items())), "license": "AGPL-3.0",
            "license_sha256": hashlib.sha256(license_file.read_bytes()).hexdigest()}


def bake_command(client: Path, output: Path, stages: list[str], dry_run: bool) -> list[str]:
    client, output = client.resolve(), output.resolve()
    missing = [name for name in ("Data", "Zones", "DTex") if not (client / name).is_dir()]
    if missing:
        raise ValueError("Not a KO client installation; missing: " + ", ".join(missing))
    # Converted content is kept out of the production asset tree and source checkout.
    allowed = (ROOT / "builds" / "external-assets").resolve()
    if not output.is_relative_to(allowed) or output == allowed:
        raise ValueError(f"Bake output must be a subdirectory of {allowed}")
    command = [sys.executable, str(ROOT / "builds/research/LibreKO-Assets/bake.py"),
               "--ko", str(client), "--out", str(output), "--server-data",
               str(ROOT / "builds/research/LibreKO/Server/LibreKO.Game/Seed/Data")]
    if stages:
        command += ["--only", *stages]
    if dry_run:
        command.append("--dry-run")
    return command


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fetch", action="store_true", help="download missing pinned source snapshots")
    parser.add_argument("--ko", type=Path, help="optional installed KO client; never downloaded here")
    parser.add_argument("--only", nargs="+", choices=["tables", "items", "quests", "terrain", "objects", "characters", "weapons", "fx", "skills", "ui", "sky", "sound", "imports"])
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    base = ROOT / "builds/research"
    base.mkdir(parents=True, exist_ok=True)
    reports = []
    for name, revision in SOURCES.items():
        folder = base / name
        if not folder.exists() and args.fetch:
            folder.mkdir()
            subprocess.run(["git", "init", str(folder)], check=True, capture_output=True)
            subprocess.run(["git", "-C", str(folder), "fetch", "--depth", "1",
                            f"https://github.com/ZeusAFK/{name}.git", revision], check=True)
            subprocess.run(["git", "-C", str(folder), "checkout", "--detach", "FETCH_HEAD"], check=True)
        reports.append(inspect(folder, revision))
    report = ROOT / "builds/libreko-sources.json"
    report.write_text(json.dumps({"sources": reports, "runtime_code_copied": False,
                                 "baked_content_included": False}, indent=2), encoding="utf8")
    print(f"Verified {len(reports)} pinned checkouts; inventory: {report}")
    if args.ko:
        command = bake_command(args.ko, ROOT / "builds/external-assets/LibreKO", args.only or [], args.dry_run)
        subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
