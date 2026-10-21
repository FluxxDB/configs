#!/usr/bin/env bash
# Symlink the configs in this repo into place, so editing your live config
# edits the repo. Anything already in the way (including ~/.tmux.conf) is
# moved aside, not deleted. Safe to run again. Run ./setup.sh first.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp="$(date +%Y%m%d-%H%M%S)"

link() {
  local src="$1" dest="$2"

  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    echo "already linked  $dest"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "$dest.backup-$stamp"
    echo "backed up       $dest -> $dest.backup-$stamp"
  fi

  ln -s "$src" "$dest"
  echo "linked          $dest -> $src"
}

mkdir -p "$config"
link "$repo/nvim" "$config/nvim"
link "$repo/tmux" "$config/tmux"
link "$repo/zsh/zshrc" "$HOME/.zshrc"
link "$repo/zsh/zprofile" "$HOME/.zprofile"

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so one there would win.
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup-$stamp"
  echo "backed up       $HOME/.tmux.conf -> $HOME/.tmux.conf.backup-$stamp"
fi

# The zshrc expects Oh My Zsh.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "note: Oh My Zsh isn't installed; run ./setup.sh first"
fi
