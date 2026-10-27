#!/bin/sh
set -eu

config_file="$HOME/.codex/config.toml"
mkdir -p "$(dirname "$config_file")"

python3 - "$config_file" <<'PY'
import os
import re
import sys
import tempfile
import tomllib
from pathlib import Path

settings = '''\
commit_attribution = ""
sandbox_mode = "workspace-write"
approval_policy = "on-request"
approvals_reviewer = "auto_review"
web_search = "live"

[features]
js_repl = false
memories = true

[memories]
generate_memories = true
use_memories = true

[sandbox_workspace_write]
network_access = true

[desktop]
conversationDetailMode = "STEPS_PROSE"
ambient-suggestions-enabled = true
followUpQueueMode = "steer"
mac-menu-bar-enabled = false
show-context-window-usage = true
open-link-in-target-preference = "external-browser"
open-local-url-in-target-preference = "external-browser"
browser-show-full-url = true
git-branch-prefix = ""

[apps.connector_76869538009648d5b282a4bb21c3d157.tools."github.create_pull_request"]
approval_mode = "approve"
'''

plugins = {
    "openai-bundled": (
        "codex-app-tools", "browser", "visualize", "computer-use", "chrome",
        "unified-computer-use",
    ),
    "openai-primary-runtime": (
        "documents", "pdf", "spreadsheets", "presentations", "template-creator",
    ),
}
for marketplace, names in plugins.items():
    for name in names:
        settings += f'\n[plugins."{name}@{marketplace}"]\nenabled = true\n'

config_path = Path(sys.argv[1]).expanduser()
text = config_path.read_text(encoding="utf-8") if config_path.exists() else ""
tomllib.loads(text)
tomllib.loads(settings)

table_re = re.compile(r'^\s*(\[[^\n]+\])\s*(?:#.*)?$')
key_re = re.compile(r'^\s*([A-Za-z0-9_-]+)\s*=')


def sections(content):
    result = {"": []}
    current = ""
    for line in content.splitlines(keepends=True):
        table = table_re.match(line)
        if table:
            current = table.group(1)
            result[current] = [line]
        else:
            result[current].append(line)
    return result


existing = sections(text)
for table, desired_lines in sections(settings).items():
    target = existing.setdefault(table, [table + "\n"] if table else [])
    desired = {}
    for line in desired_lines:
        match = key_re.match(line)
        if match:
            desired[match.group(1)] = line
    updated = []
    for line in target:
        match = key_re.match(line)
        key = match.group(1) if match else None
        if not table and key in {"model", "model_reasoning_effort"}:
            continue
        updated.append(desired.pop(key, line))
    if updated and not updated[-1].endswith("\n"):
        updated[-1] += "\n"
    while updated and not updated[-1].strip():
        updated.pop()
    updated.extend(desired.values())
    existing[table] = updated

new_text = "\n".join("".join(lines).rstrip("\n") for lines in existing.values()) + "\n"
tomllib.loads(new_text)
if new_text != text:
    descriptor, temporary = tempfile.mkstemp(dir=config_path.parent, prefix="config.", suffix=".tmp")
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as output:
            output.write(new_text)
        os.replace(temporary, config_path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
PY
