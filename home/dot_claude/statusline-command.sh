#!/bin/bash
set -euo pipefail

input=$(cat)

used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')

BAR_WIDTH=20

if [ -n "$used" ] && [ -n "$remaining" ]; then
  used_int=$(printf "%.0f" "$used")
  filled=$(( used_int * BAR_WIDTH / 100 ))
  empty=$(( BAR_WIDTH - filled ))

  if [ "$used_int" -ge 90 ]; then
    bar_color="\033[0;31m"
  elif [ "$used_int" -ge 70 ]; then
    bar_color="\033[0;33m"
  else
    bar_color="\033[0;32m"
  fi

  bar=""
  for ((i = 0; i < filled; i++)); do bar="${bar}#"; done
  for ((i = 0; i < empty;  i++)); do bar="${bar}-"; done

  remaining_int=$(printf "%.0f" "$remaining")

  line=$(printf '%b[%s]\033[0m %d%% used · %d%% remaining' "$bar_color" "$bar" "$used_int" "$remaining_int")
else
  line=""
fi

# セグメント (model / cwd) を " · " で連結。先頭に余分な区切りは付けない。
[ -n "$model" ] && line="${line:+$line · }$model"
[ -n "$cwd" ]   && line="${line:+$line · }$cwd"
printf '%s\n' "$line"
