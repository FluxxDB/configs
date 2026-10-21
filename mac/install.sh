#!/usr/bin/env bash
# Symlink each config folder in this repo into ~/.config, so editing your live
# config edits the repo. Anything already in the way is moved aside, not deleted.
# Safe to run again.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$config"

for name in nvim tmux; do
  src="$repo/$name"
  dest="$config/$name"

  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "already linked  $dest"
    continue
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup-$stamp"
    echo "backed up       $dest -> $dest.backup-$stamp"
  fi

  ln -s "$src" "$dest"
  echo "linked          $dest -> $src"
done

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so one there would win.
if [ -e "$HOME/.tmux.conf" ]; then
  echo "warning: ~/.tmux.conf exists and overrides tmux/tmux.conf; rename or remove it"
fi
