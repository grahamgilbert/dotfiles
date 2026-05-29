#!/bin/sh
set -eu

config_file="$HOME/.codex/config.toml"
config_dir=$(dirname "$config_file")
mkdir -p "$config_dir"

touch "$config_file"

python3 - "$config_file" <<'PY'
import os
import re
import sys
from pathlib import Path

config_path = Path(sys.argv[1]).expanduser()
text = config_path.read_text(encoding="utf-8")
lines = text.splitlines(keepends=True)

key_re = re.compile(r'^(\s*)commit_attribution\s*=.*?(\r?\n)?$')
table_re = re.compile(r'^\s*\[[^\]]+\]\s*(?:#.*)?(?:\r?\n)?$')

first_table_index = None
for index, line in enumerate(lines):
    if table_re.match(line):
        first_table_index = index
        break

top_level_end = first_table_index if first_table_index is not None else len(lines)

updated = False
for index in range(top_level_end):
    line = lines[index]
    if key_re.match(line):
        newline = "\r\n" if line.endswith("\r\n") else "\n"
        lines[index] = 'commit_attribution = ""' + newline
        updated = True
        break

if not updated:
    insert_line = 'commit_attribution = ""\n'
    if first_table_index is None:
        if lines and not lines[-1].endswith(("\n", "\r\n")):
            lines[-1] = lines[-1] + "\n"
        if lines and any(line.strip() for line in lines):
            lines.append(insert_line)
        else:
            lines = [insert_line]
    else:
        lines.insert(first_table_index, insert_line)
        if first_table_index + 1 < len(lines) and lines[first_table_index + 1].strip():
            lines.insert(first_table_index + 1, "\n")

new_text = "".join(lines)
tmp_path = config_path.with_suffix(config_path.suffix + ".tmp")
tmp_path.write_text(new_text, encoding="utf-8")
os.replace(tmp_path, config_path)
PY
