#!/usr/bin/env bash
# Convert a Hugging Face checkpoint that is already in your HF cache (bf16/fp16 safetensors) into a
# 4-bit MLX checkpoint under $HF_HOME/mlx, ready to be served by compose via a models/<name>.env file.
#
#   scripts/convert-to-mlx-4bit.sh google/gemma-4-26B-A4B-it
#   scripts/convert-to-mlx-4bit.sh /path/to/hf/snapshot  [docker-model-ref]  [q-bits]  [group-size]
#
# Requirements:
#   * Homebrew vllm-metal (brew install vllm-project/vllm-metal/vllm-metal) — brings mlx-vlm/mlx-lm
#   * HF_HOME pointing at your cache (~/.zshrc sets ~/Projects/.huggingface); the repo must already
#     be downloaded (hf download <repo>), this script never goes online.
# Memory: mlx-vlm materialises whole layers while quantizing; on a 24 GB Mac a 26B model swaps
# heavily for ~5 minutes. Close memory-hungry apps first. Output: $HF_HOME/mlx/<name>-MLX-<bits>bit
set -euo pipefail

REPO="${1:?usage: $0 <hf-repo-id | local-dir> [docker-model-ref] [q-bits=4] [group-size=64]}"
REF="${2:-local/$(basename "${1%/}" | tr "[:upper:]" "[:lower:]"):4bit}"   # Docker Model Runner ref (optional step)
QBITS="${3:-4}"
GROUP="${4:-64}"
PY="${MLX_PYTHON:-/opt/homebrew/opt/vllm-metal/libexec/bin/python3.12}"
export HF_HOME="${HF_HOME:-$HOME/Projects/.huggingface}"
export HF_HUB_CACHE="${HF_HUB_CACHE:-$HF_HOME/models}"
export HF_HUB_OFFLINE=1

[ -x "$PY" ] || { echo "python with mlx-vlm not found at $PY (brew install vllm-project/vllm-metal/vllm-metal)"; exit 1; }

if [ -d "$REPO" ]; then
  SRC="$REPO"; NAME="$(basename "${REPO%/}")"
else
  SRC="$("$PY" -c 'import sys; from huggingface_hub import snapshot_download; print(snapshot_download(sys.argv[1], local_files_only=True))' "$REPO")"
  NAME="$(basename "$REPO")"
fi
OUT="${MLX_OUT_DIR:-$HF_HOME/mlx}/${NAME}-MLX-${QBITS}bit"
echo "source : $SRC"
echo "output : $OUT"
mkdir -p "$(dirname "$OUT")"

if [ ! -f "$OUT/model.safetensors.index.json" ]; then
  # mlx-vlm copies the source's read-only tokenizer files and then tries to overwrite them, which
  # makes it exit non-zero AFTER all weights are written. Tolerate that and verify the output instead.
  "$PY" -m mlx_vlm convert --hf-path "$SRC" --mlx-path "$OUT" -q --q-bits "$QBITS" --q-group-size "$GROUP" \
    || echo "converter exited non-zero (usually the read-only tokenizer copy) — verifying output..."
  [ -f "$OUT/model.safetensors.index.json" ] || { echo "conversion failed: no weights written"; exit 1; }
else
  echo "weights already present, skipping conversion"
fi
chmod u+w "$OUT"/* 2>/dev/null || true
rm -rf "$OUT/.eval_results"

# Make sure config.json carries the MLX quantization block; mlx-vlm can lose it when the copy step
# above fails. Bit widths are recovered from the packed tensor shapes, so this is exact.
"$PY" - "$OUT" "$GROUP" <<'PYEOF'
import json, struct, sys, collections
out, group = sys.argv[1], int(sys.argv[2])
cfg_path = f"{out}/config.json"
cfg = json.load(open(cfg_path))
if cfg.get("quantization"):
    print("config.json already has a quantization block:", {k: v for k, v in cfg["quantization"].items() if not isinstance(v, dict)})
    sys.exit(0)
wm = json.load(open(f"{out}/model.safetensors.index.json"))["weight_map"]
hdr = {}
for shard in sorted(set(wm.values())):
    with open(f"{out}/{shard}", "rb") as f:
        n = struct.unpack("<Q", f.read(8))[0]
        h = json.loads(f.read(n)); h.pop("__metadata__", None); hdr.update(h)
bits_by_module = {}
for k, meta in hdr.items():
    if not k.endswith(".scales"): continue
    mod = k[:-len(".scales")]; w = hdr.get(mod + ".weight")
    if w is None: continue
    in_features = meta["shape"][-1] * group
    bits_by_module[mod] = 32 * w["shape"][-1] // in_features
hist = collections.Counter(bits_by_module.values())
default_bits = hist.most_common(1)[0][0]
q = {"group_size": group, "bits": default_bits, "mode": "affine"}
for mod, b in sorted(bits_by_module.items()):
    if b != default_bits: q[mod] = {"group_size": group, "bits": b}
cfg["quantization"] = q; cfg["quantization_config"] = q
json.dump(cfg, open(cfg_path, "w"), indent=2)
print(f"wrote quantization block: default {default_bits}-bit, {len(q) - 3} per-module overrides, histogram {dict(hist)}")
PYEOF

# Optional: also package the checkpoint into Docker Model Runner (only if DMR is enabled), for the
# alternative `models:`-based path described in README. The compose stack here serves $OUT directly.
if docker model status >/dev/null 2>&1; then
  echo "packaging into Docker Model Runner as $REF ..."
  docker model package --safetensors-dir "$OUT" "$REF" && docker model inspect "$REF" | "$PY" -c 'import json,sys; print("DMR tag:", json.load(sys.stdin)["tags"][0])'
else
  echo "(Docker Model Runner is not enabled; skipping the optional DMR packaging step)"
fi
cat <<EOT

Done. Create models/<name>.env (copy models/model.env) and set:

  MODEL_PATH=$OUT
  SERVED_NAME=<name clients will use>

then:  docker compose -f <model>.compose.yaml --env-file models/<name>.env up -d
EOT
