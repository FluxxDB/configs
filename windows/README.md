# configs — Windows (WSL2)

The Neovim, tmux, zsh and terminal setup from [`../mac`](../mac), adapted for
Ubuntu 22.04 on WSL2 and Windows Terminal so it looks the same as the Mac, plus
vLLM serving on the Radeon RX 7900 GRE.

| Folder | Linked to | What it is |
|---|---|---|
| [`nvim/`](nvim) | `~/.config/nvim` | Neovim with lazy.nvim and the Kanagawa theme (same plugins and pinned versions as the Mac) |
| [`tmux/`](tmux) | `~/.config/tmux` | tmux with an `Alt-a` prefix and a Catppuccin-colored status bar; copies go to the Windows clipboard |
| [`zsh/`](zsh) | `~/.zshrc`, `~/.zprofile` | Oh My Zsh with the `af-magic` prompt, like the Mac |
| [`terminal/`](terminal) | Windows Terminal settings | The Mac's iTerm2 font, size and colors for the Ubuntu tab |
| [`vllm/`](vllm) | — | Template for serving a model with vLLM on ROCm in Docker, through WSL's GPU bridge |

## Install

```bash
git clone git@github.com:FluxxDB/configs.git ~/Projects/configs
~/Projects/configs/windows/setup.sh     # system packages; asks for your sudo password
~/Projects/configs/windows/install.sh   # symlink the configs
```

`setup.sh` installs everything the configs need and is safe to run again:

| What | Why |
|---|---|
| Neovim 0.12 (release tarball in `/opt`) | Ubuntu 22.04's apt only has 0.6 |
| fzf (release binary), ripgrep, fd | fzf-lua; apt's fzf 0.29 is too old |
| tree-sitter CLI (built with cargo) and build-essential | nvim-treesitter compiles parsers with them |
| [win32yank](https://github.com/equalsraf/win32yank) | Clipboard bridge: Neovim's `unnamedplus` and tmux copies reach Windows |
| tmux | apt's 3.2a handles this config |
| zsh ([zsh-bin](https://github.com/romkatv/zsh-bin), static, in `~/.local`) + Oh My Zsh | The Mac's shell and prompt, without root |
| Docker Engine (Docker's apt repo) | Runs the vLLM container. Docker Desktop is not needed |
| ROCm 7.2.x + [ROCDXG](https://github.com/ROCm/librocdxg) and its WSL amdsmi (`/opt/rocm-wsl`) | `rocminfo` on the host, and the `/dev/dxg` bridge + GPU detection that the vLLM container mounts |
| A block in `~/.bashrc` | `EDITOR`, `HF_HOME`, ROCm on `PATH`, `HSA_ENABLE_DXG_DETECTION=1` |

`install.sh` symlinks `nvim/` and `tmux/` into `~/.config` and the zsh files to
`~/.zshrc` and `~/.zprofile`. Anything already there,
including an old `~/.tmux.conf` (which tmux would read first), is moved to
`<name>.backup-<timestamp>`. Start `nvim` once and lazy.nvim installs the
plugins.

### Windows side

- **GPU driver:** WSL uses the normal Windows AMD driver (AMD Software:
  Adrenalin 26.2.2 or newer). Nothing GPU-related gets installed into WSL's
  kernel. `rocminfo | grep gfx1100` should list the 7900 GRE.
- **Looks like the Mac's iTerm2:** [`terminal/windows-terminal.json`](terminal/windows-terminal.json)
  holds the Windows Terminal side. Merge it into Windows Terminal's
  `settings.json`, with the scheme under `schemes` and the rest in the Ubuntu
  profile. It sets:
  - **Font:** *JetBrainsMonoNL Nerd Font Mono* (the no-ligatures variant the Mac
    uses), installed for your Windows user from the
    [Nerd Fonts release](https://github.com/ryanoasis/nerd-fonts/releases). The
    size is **19.5pt**: macOS and Windows count points differently, and at this
    PC's 125% display scaling, 19.5pt in Windows Terminal is the same on-screen
    size (in display pixels) as 26pt in iTerm2.
  - **Colors:** the iTerm2 dark palette (`#15191f` background, `#dcdcdc` text,
    the same 16 ANSI colors), a white block cursor, bold drawn in bright colors,
    and iTerm2's 5px/2px margins.
  - **Shell:** the tab starts zsh. The login shell stays bash, since changing it
    needs root, so `install.sh` also adds a few lines to `~/.bashrc` that switch
    any interactive terminal to zsh: the Start menu's WSL entry, `ssh` from the
    Mac, editor terminals. Scripts and agents' shells without a terminal keep
    bash. Set `NO_ZSH=1` to stay in bash. Typing `wsl` in PowerShell, cmd or
    Win+R opens in `~` rather than `/mnt/c/Users/ledan` (or System32); `wsl`
    started from any other Windows folder keeps that folder.
  - **Default profile:** Ubuntu, so opening Windows Terminal gets this look.
    The Start menu's *WSL* entry opens with Windows Terminal's default look,
    not this profile's; open Windows Terminal itself instead.
- **Alt key:** Windows Terminal sends Alt as Meta already, so `Alt-j` / `Alt-k`
  move lines with no setup.
- **Memory:** `C:\Users\ledan\.wslconfig` caps the WSL VM at 56 GB of the 64 GB,
  with 16 GB of swap. The cap is a ceiling, not a reservation, and
  `autoMemoryReclaim=gradual` hands Linux's file cache back to Windows when WSL
  is idle. Changes apply after `wsl --shutdown` in PowerShell.

## Neovim

Same config and plugins as the Mac (see [`../mac/README.md`](../mac/README.md)
for the plugin list). Differences:

- `clipboard = "unnamedplus"` goes through `win32yank.exe`, which Neovim finds by
  itself. Don't install `wl-clipboard` or `xclip`: Neovim would prefer them, and
  they only reach WSLg's clipboard.
- `nvim/lazy-lock.json` is kept identical to the Mac's, so both machines run the
  same plugin versions. After `:Lazy update` on one machine, copy the lockfile to
  the other folder.

The leader key is Space. `Space ?` opens the cheat sheet
([`nvim/cheatsheet.md`](nvim/cheatsheet.md)), and `Space k` searches it along
with every keymap.

## tmux

- Prefix is `Alt-a`
- `prefix r` reloads the config
- Mouse support is on, and windows and panes are numbered from 1
- Mouse-drag, double-click and triple-click copies go to the Windows clipboard
  through `win32yank.exe` (the `copy-command` option)

## vLLM

See [`vllm/README.md`](vllm/README.md).

## Making changes

`~/.config/nvim` and `~/.config/tmux` are symlinks into this repo, so editing
your config edits the repo. Commit and push from here:

```bash
cd ~/Projects/configs && git add -A && git commit -m "Describe the change" && git push
```
