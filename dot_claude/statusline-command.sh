#!/bin/bash
input=$(cat)

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

workspace=$(hostname -s)

# Shorten path like .zshrc: ~/f/i/r/s/t/full_dirname
shorten_path() {
  local path="$1"
  path="${path/#$HOME/~}"

  if [ "$path" = "~" ]; then
    echo "~"
    return
  fi

  local prefix rest
  if [[ "$path" == "~/"* ]]; then
    prefix="~"
    rest="${path:2}"
  elif [[ "$path" == "~" ]]; then
    echo "~"
    return
  else
    prefix=""
    rest="${path:1}"
  fi

  IFS='/' read -ra parts <<< "$rest"
  local num_parts=${#parts[@]}
  local result="$prefix"

  for (( i=0; i<num_parts; i++ )); do
    local part="${parts[$i]}"
    if [ $((i + 1)) -lt $num_parts ]; then
      result="$result/${part:0:1}"
    else
      result="$result/$part"
    fi
  done

  echo "$result"
}

# Git branch (with * suffix if dirty)
git_info=""
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  if [ -n "$branch" ]; then
    if [ -n "$(git -C "$cwd" status --porcelain 2>/dev/null)" ]; then
      git_info=" [$branch*]"
    else
      git_info=" [$branch]"
    fi
  fi
fi

# Build output
out="$workspace"

if [ -n "$cwd" ]; then
  short_path=$(shorten_path "$cwd")
  out="$out | $short_path$git_info"
fi

if [ -n "$used_pct" ]; then
  used_rounded=$(printf "%.0f" "$used_pct")
  out="$out | Context: ${used_rounded}%"
fi

if [ -n "$cost" ]; then
  cost_fmt=$(awk -v c="$cost" 'BEGIN { printf "$%.2f", c }')
  out="$out | $cost_fmt"
fi

echo "$out"
