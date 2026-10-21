#!/usr/bin/env bash
# Install everything this folder's configs need on Ubuntu 22.04 under WSL2: Neovim and the
# tools its config calls (fzf, ripgrep, fd, tree-sitter, a clipboard bridge), tmux, zsh with
# Oh My Zsh, Docker Engine, and ROCm + ROCDXG (+ its AMD SMI) so containers can reach the
# Radeon GPU through WSL's /dev/dxg. The Windows Terminal side is in terminal/.
# Runs as you and calls sudo where needed. Each step checks whether it's already done, so
# running it again is safe. Afterwards run ./install.sh to link the configs.
set -euo pipefail

NVIM_VERSION=v0.12.6
FZF_VERSION=0.74.5
WIN32YANK_VERSION=v0.1.1
TREE_SITTER_MIN=0.26.1
# ROCm on the host only provides rocminfo and the WSL GPU bridge (librocdxg) that the vLLM
# container mounts; the container brings its own ROCm. 7.2.x pairs with librocdxg 1.2.x.
ROCM_VERSION=7.2.4
AMDGPU_INSTALL_DEB=amdgpu-install_7.2.4.70204-1_all.deb
ROCDXG_VERSION=1.2.2

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
step() { printf '\n==> %s\n' "$1"; }
# version_ge A B: true when version A >= B
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }

step "apt packages"
sudo apt-get update -qq
sudo apt-get install -y -qq build-essential curl wget unzip git jq ripgrep fd-find tmux \
  ca-certificates gnupg >/dev/null
# Ubuntu names the fd binary fdfind
sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

step "Neovim $NVIM_VERSION"
if [ "$(nvim --version 2>/dev/null | head -n1)" = "NVIM $NVIM_VERSION" ]; then
  echo "already installed"
else
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/nvim-linux-x86_64.tar.gz"
  sudo rm -rf /opt/nvim-linux-x86_64
  sudo tar -C /opt -xzf "$tmp/nvim.tar.gz"
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  nvim --version | head -n1
fi

step "fzf $FZF_VERSION (apt's 0.29 is too old for fzf-lua)"
if [ "$(fzf --version 2>/dev/null | cut -d' ' -f1)" = "$FZF_VERSION" ]; then
  echo "already installed"
else
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/v$FZF_VERSION/fzf-$FZF_VERSION-linux_amd64.tar.gz" \
    | tar -xz -C "$tmp"
  sudo install -m 755 "$tmp/fzf" /usr/local/bin/fzf
fi

step "win32yank $WIN32YANK_VERSION (Windows clipboard for Neovim and tmux)"
if command -v win32yank.exe >/dev/null; then
  echo "already installed"
else
  curl -fsSL -o "$tmp/win32yank.zip" \
    "https://github.com/equalsraf/win32yank/releases/download/$WIN32YANK_VERSION/win32yank-x64.zip"
  unzip -q -o "$tmp/win32yank.zip" win32yank.exe -d "$tmp"
  sudo install -m 755 "$tmp/win32yank.exe" /usr/local/bin/win32yank.exe
fi

step "tree-sitter CLI >= $TREE_SITTER_MIN (nvim-treesitter compiles parsers with it)"
# Built from source: the prebuilt binaries can need a newer glibc than Ubuntu 22.04's.
ts_version="$(tree-sitter --version 2>/dev/null | cut -d' ' -f2 || true)"
if [ -n "$ts_version" ] && version_ge "$ts_version" "$TREE_SITTER_MIN"; then
  echo "already installed ($ts_version)"
else
  if ! command -v cargo >/dev/null; then
    curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
    . "$HOME/.cargo/env"
  fi
  cargo install --locked tree-sitter-cli
fi

step "zsh + Oh My Zsh (the Mac's shell; static zsh in ~/.local, no root needed)"
if [ -x "$HOME/.local/bin/zsh" ]; then
  echo "zsh already installed ($("$HOME/.local/bin/zsh" --version))"
else
  # romkatv/zsh-bin's installer checks the archive's hash before extracting
  curl -fsSL https://raw.githubusercontent.com/romkatv/zsh-bin/master/install -o "$tmp/zsh-bin-install"
  sh "$tmp/zsh-bin-install" -q -d "$HOME/.local" -e no </dev/null
fi
if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh already installed"
else
  git clone -q --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
fi

step "Docker Engine"
if command -v docker >/dev/null; then
  echo "already installed ($(docker --version))"
else
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin >/dev/null
fi
sudo systemctl enable --now docker >/dev/null 2>&1
if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "added $USER to the docker group (takes effect in new shells)"
fi

step "ROCm $ROCM_VERSION (no kernel driver: WSL talks to the Windows driver)"
if [ -x /opt/rocm/bin/rocminfo ]; then
  echo "already installed ($(cat /opt/rocm/.info/version 2>/dev/null))"
else
  curl -fsSL -o "$tmp/$AMDGPU_INSTALL_DEB" \
    "https://repo.radeon.com/amdgpu-install/$ROCM_VERSION/ubuntu/jammy/$AMDGPU_INSTALL_DEB"
  sudo apt-get install -y -qq "$tmp/$AMDGPU_INSTALL_DEB" >/dev/null
  sudo amdgpu-install -y --usecase=rocm --no-dkms
fi
for group in render video; do
  id -nG "$USER" | grep -qw "$group" || sudo usermod -aG "$group" "$USER"
done

step "ROCDXG $ROCDXG_VERSION (ROCm's bridge to the GPU through /dev/dxg)"
if [ "$(dpkg-query -W -f='${Version}' rocdxg-roct 2>/dev/null)" = "$ROCDXG_VERSION" ]; then
  echo "already installed"
else
  curl -fsSL -o "$tmp/rocdxg-roct.deb" \
    "https://github.com/ROCm/librocdxg/releases/download/v$ROCDXG_VERSION/rocdxg-roct_${ROCDXG_VERSION}_amd64.deb"
  sudo apt-get install -y -qq "$tmp/rocdxg-roct.deb" >/dev/null
fi

step "AMD SMI for WSL $ROCDXG_VERSION (vLLM asks amdsmi which GPU it's on)"
# The stock amdsmi can't see a GPU through /dev/dxg; this build can. The vLLM container mounts
# /opt/rocm-wsl. Unpacked rather than installed: the package's postinst rewrites
# the system logrotate timer, and nothing here needs that.
if [ "$(cat /opt/rocm-wsl/.rocdxg-amd-smi-version 2>/dev/null)" = "$ROCDXG_VERSION" ]; then
  echo "already installed"
else
  curl -fsSL -o "$tmp/rocdxg-amd-smi-lib.deb" \
    "https://github.com/ROCm/librocdxg/releases/download/v$ROCDXG_VERSION/rocdxg-amd-smi-lib_${ROCDXG_VERSION}_amd64.deb"
  sudo rm -rf /opt/rocm-wsl
  mkdir -p "$tmp/amd-smi"
  dpkg-deb -x "$tmp/rocdxg-amd-smi-lib.deb" "$tmp/amd-smi"
  sudo cp -r "$tmp/amd-smi/opt/rocm-wsl" /opt/rocm-wsl
  echo "$ROCDXG_VERSION" | sudo tee /opt/rocm-wsl/.rocdxg-amd-smi-version >/dev/null
fi

step "shell setup"
mkdir -p "$HOME/Projects/.huggingface"
if grep -q '>>> configs/windows >>>' "$HOME/.bashrc"; then
  echo "~/.bashrc already has the configs/windows block"
else
  cat >>"$HOME/.bashrc" <<'EOF'

# >>> configs/windows >>>
export EDITOR=nvim
export HF_HOME="$HOME/Projects/.huggingface"
export PATH="/opt/rocm/bin:$PATH"
# ROCm before 7.13 only looks for the GPU through WSL's /dev/dxg (librocdxg) when this is set.
export HSA_ENABLE_DXG_DETECTION=1
# <<< configs/windows <<<
EOF
  echo "added the configs/windows block to ~/.bashrc"
fi

step "GPU check"
# (captured first: under pipefail, grep -q quitting early would fail the pipeline)
agents="$(HSA_ENABLE_DXG_DETECTION=1 /opt/rocm/bin/rocminfo 2>/dev/null || true)"
if grep -q 'gfx1100' <<<"$agents"; then
  echo "rocminfo sees the Radeon (gfx1100)"
else
  echo "warning: rocminfo does not list a gfx1100 agent. Update the Windows driver (AMD Software:"
  echo "Adrenalin 26.2.2 or newer), reboot Windows, and run this script again."
fi

echo
echo "Done. Open a new shell (or run 'newgrp docker'), then run ./install.sh to link the configs."
