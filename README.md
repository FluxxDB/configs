# configs

My editor, terminal and local-LLM setup for two machines. Each machine has its
own folder with its own `install.sh` and README.

| Folder | Machine | What's in it |
|---|---|---|
| [`mac/`](mac) | MacBook Pro | Neovim, tmux, zsh, iTerm2 settings and vLLM (vllm-metal) for macOS |
| [`windows/`](windows) | Desktop PC | The same Neovim and tmux setup adapted for Ubuntu on WSL2, plus a template for vLLM on ROCm in Docker |

## Machines

| | Mac | Windows desktop |
|---|---|---|
| Model | MacBook Pro | Custom desktop |
| CPU | Apple M5 Pro | AMD Ryzen 7 7800X3D (8 cores / 16 threads) |
| GPU | M5 Pro integrated (Metal) | AMD Radeon RX 7900 GRE, 16 GB VRAM (RDNA3, `gfx1100`) |
| Memory | 24 GB unified | 64 GB DDR5 |
| OS | macOS | Windows 11 + WSL2 (Ubuntu 22.04) |
| Terminal | iTerm2 | Windows Terminal |
| LLM serving | vllm-metal on the host, managed by `docker compose` | vLLM ROCm container reaching the GPU through WSL's `/dev/dxg` |

## Install

```bash
git clone git@github.com:FluxxDB/configs.git ~/Projects/configs
~/Projects/configs/mac/install.sh       # on the Mac
~/Projects/configs/windows/install.sh   # in WSL on the desktop
```

Each `install.sh` symlinks that machine's configs into place.
See [`mac/README.md`](mac/README.md) and [`windows/README.md`](windows/README.md)
for the packages each machine needs first.

> **Mac, after pulling the `mac/` + `windows/` reorganization:** the old
> `~/.config/nvim` and `~/.config/tmux` symlinks point at `~/Projects/configs/nvim`
> and `~/Projects/configs/tmux`, which no longer exist. Run
> `~/Projects/configs/mac/install.sh` once to re-point them.
