# configs

My Neovim and tmux setup for macOS and iTerm2.

| Folder | Linked to | What it is |
|---|---|---|
| [`nvim/`](nvim) | `~/.config/nvim` | Neovim with lazy.nvim and the Kanagawa theme |
| [`tmux/`](tmux) | `~/.config/tmux` | tmux with a `Ctrl-a` prefix and a Catppuccin-colored status bar |

## Install

```bash
brew install neovim tmux fzf ripgrep fd tree-sitter-cli
brew install --cask font-jetbrains-mono-nerd-font
git clone git@github.com:FluxxDB/configs.git ~/Projects/configs
~/Projects/configs/install.sh
```

`install.sh` symlinks each folder into `~/.config`. Anything already there is
moved to `<name>.backup-<timestamp>` first, and running it again is safe.
Start `nvim` once and lazy.nvim installs the plugins.

### iTerm2 settings

- **Font:** Settings → Profiles → Text → *JetBrainsMono Nerd Font Mono*.
  Without a Nerd Font, file icons show up as `?` boxes.
- **Option key:** Settings → Profiles → Keys → Left Option key → *Esc+*,
  so `Alt-j` / `Alt-k` can move lines.
- **Cmd-a as tmux prefix (optional):** add a key binding for ⌘A that sends hex
  code `0x01`.

## Neovim

Needs Neovim 0.12+, `tree-sitter-cli` 0.26.1+ and a C compiler (Xcode Command
Line Tools) for syntax highlighting.

| Plugin | Used for |
|---|---|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim) | Color theme |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | File explorer with Files / Buffers / Git tabs |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffer tabs along the top |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | Fuzzy finding files, text and buffers |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Popup hints for leader keys |
| [blink.cmp](https://github.com/saghen/blink.cmp) | Autocompletion |
| [mason.nvim](https://github.com/mason-org/mason.nvim) + [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Language servers |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting |

The leader key is Space. `Space ?` opens the cheat sheet
([`nvim/cheatsheet.md`](nvim/cheatsheet.md)), and `Space k` searches it along
with every keymap.

Plugin versions are pinned in `nvim/lazy-lock.json`. `:Lazy update` updates
them (commit the lockfile afterwards), and `:Lazy restore` goes back to the
pinned versions.

## tmux

- Prefix is `Ctrl-a`
- `prefix r` reloads the config
- Mouse support is on, and windows and panes are numbered from 1

## Making changes

`~/.config/nvim` and `~/.config/tmux` are symlinks into this repo, so editing
your config edits the repo. Commit and push from here:

```bash
cd ~/Projects/configs && git add -A && git commit -m "Describe the change" && git push
```
