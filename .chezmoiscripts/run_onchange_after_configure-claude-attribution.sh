#!/bin/sh
set -eu

settings_file="$HOME/.claude/settings.json"
settings_dir=$(dirname "$settings_file")
mkdir -p "$settings_dir"

python3 - "$settings_file" <<'PY'
import json
import os
import sys
from pathlib import Path

settings_path = Path(sys.argv[1]).expanduser()

if settings_path.exists():
    with settings_path.open("r", encoding="utf-8") as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError as e:
            raise SystemExit(f"{settings_path} contains invalid JSON: {e}")
else:
    settings = {}

if not isinstance(settings, dict):
    raise SystemExit(f"{settings_path} must contain a JSON object")

attribution = settings.get("attribution")
if attribution is None:
    attribution = {}
elif not isinstance(attribution, dict):
    raise SystemExit(f"{settings_path}: attribution must be a JSON object")

attribution["commit"] = ""
attribution["pr"] = ""
settings["attribution"] = attribution

tmp_path = settings_path.with_suffix(settings_path.suffix + ".tmp")
with tmp_path.open("w", encoding="utf-8") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

os.replace(tmp_path, settings_path)
PY
