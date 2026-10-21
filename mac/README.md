# configs — Mac

My Neovim, tmux, zsh and iTerm2 setup for macOS.

| Folder | Linked to | What it is |
|---|---|---|
| [`nvim/`](nvim) | `~/.config/nvim` | Neovim with lazy.nvim and the Kanagawa theme |
| [`tmux/`](tmux) | `~/.config/tmux` | tmux with an `Alt-a` prefix and a Catppuccin-colored status bar |
| [`zsh/`](zsh) | `~/.zshrc`, `~/.zprofile` | Oh My Zsh with the `af-magic` prompt |
| [`iterm2/`](iterm2) | loaded by iTerm2 | iTerm2 settings: font, colors, key bindings |
| [`vllm/`](vllm) | — | Template for serving an MLX model with vllm-metal from `docker compose` |

## Install

```bash
brew install neovim tmux fzf ripgrep fd tree-sitter-cli
brew install --cask iterm2 font-jetbrains-mono-nerd-font
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
git clone git@github.com:FluxxDB/configs.git ~/Projects/configs
~/Projects/configs/mac/install.sh
```

`install.sh` symlinks `nvim/` and `tmux/` into `~/.config` and the zsh files to
`~/.zshrc` and `~/.zprofile`. Anything already there is moved to
`<name>.backup-<timestamp>` first, and running it again is safe.
Start `nvim` once and lazy.nvim installs the plugins.

### iTerm2

In iTerm2, open Settings → General → Settings, turn on **Load settings from a
custom folder or URL**, and pick `~/Projects/configs/mac/iterm2`. Set **Save
changes** to *Automatically* so later tweaks land in the repo. Restart iTerm2.

What the settings give you:

- **Font:** *JetBrainsMonoNL Nerd Font Mono* at 26pt (the no-ligatures
  variant). Without a Nerd Font, file icons show up as `?` boxes.
- **Colors:** iTerm2's default palette with separate light and dark versions
  (dark: `#15191f` background, `#dcdcdc` text), no transparency or blur.
- **Option key:** the left Option key sends *Esc+*, so `Alt-j` / `Alt-k` can
  move lines in Neovim.
- **Three-finger swipes** switch tabs (left/right) and windows (up/down).

## zsh

[Oh My Zsh](https://ohmyz.sh) with the built-in `af-magic` theme and the `git`
plugin. `vim` runs Neovim, and `EDITOR` / `VISUAL` are set to `nvim`. The files
also set up machine-specific paths (Homebrew, Docker, OpenJDK, LM Studio, the
Hugging Face cache), so check them on a new machine.

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

- Prefix is `Alt-a`
- `prefix r` reloads the config
- Mouse support is on, and windows and panes are numbered from 1

## Making changes

`~/.config/nvim`, `~/.config/tmux`, `~/.zshrc` and `~/.zprofile` are symlinks
into this repo, and iTerm2 saves its settings here, so editing your config edits
the repo. Commit and push from here:

```bash
cd ~/Projects/configs && git add -A && git commit -m "Describe the change" && git push
```
