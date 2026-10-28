# vllm — template for serving one model with vLLM on the RX 7900 GRE under WSL2

Templates only, like [`../../mac/vllm`](../../mac/vllm). Nothing runs from this folder. The working
setup lives in its own project, `~/Projects/vllm-serve`, which is made from these files and is where
you run `docker compose`, add model env files and pick the default model.

The engine is AMD's RDNA3 (gfx110X) build of vLLM in a container. It reaches the GPU through WSL's
`/dev/dxg` and the ROCDXG bridge that [`../setup.sh`](../setup.sh) installs, so `docker compose up`
/ `down` start and stop it. One model at a time. This is the WSL counterpart of the Mac setup, where
the engine has to be a host process because macOS containers can't reach the GPU.

| File | Copied to | What it is |
|---|---|---|
| [`compose.yaml`](compose.yaml) | `~/Projects/vllm-serve/compose.yaml` | The `vllm` engine container and a `warmup` container |
| [`scripts/serve.sh`](scripts/serve.sh) | `~/Projects/vllm-serve/scripts/` | Builds the `vllm serve` command line from the env file |
| [`scripts/warmup.sh`](scripts/warmup.sh) | `~/Projects/vllm-serve/scripts/` | Sends one prompt after start-up, then prints the endpoint |
| [`models/model.env`](models/model.env) | `~/Projects/vllm-serve/models/<name>.env` | One model's settings, with every option explained |

## Set up a new machine

Run [`../setup.sh`](../setup.sh) first: it installs Docker Engine, ROCm, ROCDXG and the WSL build of
amdsmi in `/opt/rocm-wsl`, which `compose.yaml` mounts into the container, and sets `HF_HOME`.

If `~/Projects/vllm-serve` is already a GitHub repo, clone it instead. Otherwise create it from the
templates:

```bash
t=~/Projects/configs/windows/vllm
mkdir -p ~/Projects/vllm-serve/models
cp -r "$t/compose.yaml" "$t/scripts" ~/Projects/vllm-serve/
cp "$t/models/model.env" ~/Projects/vllm-serve/models/<name>.env   # then fill it in, see below
cd ~/Projects/vllm-serve
ln -s models/<name>.env .env                                       # the default model
docker compose up -d --wait                                        # -> http://localhost:8000/v1
docker compose logs -f                                             # engine + warm-up logs
docker compose down                                                # stops the engine, frees the VRAM
```

Keep `name: vllm` in `compose.yaml`: the compose project name also names the torch.compile and
Triton cache volumes (`vllm_vllm-cache`, `vllm_triton-cache`). Model weights download into
`HF_HOME` (`~/Projects/.huggingface`) on the first start. `up --wait` waits up to 30 minutes for the
health check, which covers that download.

## Pick a model

1. It has to fit: 16 GB of VRAM, minus some for the Windows desktop, has to hold the weights and the
   KV cache, so ~10 GB of weights is the practical ceiling. RDNA3 has no FP8/FP4 hardware, so use
   bf16, AWQ, GPTQ or compressed-tensors W4A16 checkpoints, not FP8/NVFP4/MXFP4.
2. In its `models/<name>.env`, set `MODEL_PATH` (a Hugging Face repo id, or a local directory under
   `HF_HOME`), `SERVED_NAME` and the parsers.
3. Run it with `docker compose --env-file models/<name>.env up -d --wait`, or `ln -sfn` it to `.env`
   to make it the default.

Known good on this card (the default in `~/Projects/vllm-serve`): Qwen3.5-9B at 4 bits, text only.
These lines in a copy of `model.env`, with everything else left as it is:

```bash
MODEL_PATH=cyankiwi/Qwen3.5-9B-AWQ-4bit
SERVED_NAME=qwen3.5-9b
CONTEXT_SIZE=32768
TOOL_CALL_PARSER=qwen3_coder
REASONING_PARSER=qwen3
VLLM_EXTRA_ARGS=--language-model-only --dtype float16
```

It gives 7.9 GiB of weights, ~24–27k tokens of KV cache, ~50 tokens/s for one request, and ~3
minutes from `up` to healthy (~4.5 the very first time, while torch.compile and Triton fill their
cache volumes). `--language-model-only` skips the vision encoder to free VRAM for the KV cache.
Thinking is on by default and can be long; send `"chat_template_kwargs": {"enable_thinking": false}`
for direct answers. Test the endpoint (it works from Windows too):

```bash
curl -s http://localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3.5-9b",
  "messages": [{"role": "user", "content": "Explain mixture-of-experts in two sentences."}],
  "max_tokens": 400
}' | jq -r '.choices[0].message.content'
```

## Tuning

vLLM's budget is `GPU_MEMORY_UTILIZATION` x the card's total VRAM (reported as 17.1 GB), for
weights + KV cache + a start-up reservation that grows with `MAX_NUM_BATCHED_TOKENS`. Windows keeps
~2.5 GB for the desktop (more with games or a browser on the GPU), and vLLM refuses to start if its
share is more than what's free, so ~0.85 is the ceiling. If the log reports a KV cache error, lower
`CONTEXT_SIZE` / `MAX_NUM_BATCHED_TOKENS`.

Qwen3.5 uses hybrid attention (most layers are Gated DeltaNet with a fixed-size state), so its KV
cache per token is small and long contexts are cheap.

int4 kernels on ROCm: vLLM has Conch (group size 128, bf16 or fp16) and Exllama (any group size,
fp16 only). A checkpoint with another group size, like Qwen3.5-9B-AWQ's 32, needs
`--dtype float16`.

## How the WSL GPU access works

- `/dev/dxg` is the paravirtualized GPU WSL exposes; there is no `/dev/kfd`. Use `rocminfo` on the
  host (it needs `HSA_ENABLE_DXG_DETECTION=1`, which `~/.bashrc` sets).
- The container gets `/dev/dxg`, Windows' `libdxcore.so` and the host's `librocdxg.so` +
  `dids.conf` (see `compose.yaml`). ROCm releases before 7.13 also need
  `HSA_ENABLE_DXG_DETECTION=1`, which compose sets.
- vLLM asks amdsmi which GPU it's on, and the image's amdsmi can't see one through `/dev/dxg`
  (vLLM 0.19 then dies with `cannot import name 'current_platform'`). The container uses the WSL
  build of amdsmi from `/opt/rocm-wsl` instead, via `PYTHONPATH`; `../setup.sh` unpacks it from
  ROCDXG's `rocdxg-amd-smi-lib` package. With it, no patching of vLLM is needed. (vLLM labels the
  card "RX7900XTX" in its log, from a device-ID table; it is the same gfx1100 chip.)
- [`scripts/serve.sh`](scripts/serve.sh) builds the `vllm serve` command line from the env file.

## Troubleshooting

- `up` fails with a port in use: another engine is running; `docker compose down` it, or change `PORT`.
- No GPU / `HIP error` at start-up: run `rocminfo | grep gfx1100` on the host. If the card isn't
  listed, update the Windows AMD driver, reboot Windows, and re-run `../setup.sh`.
- `Free memory on device ... is less than desired GPU memory utilization`: something else on
  Windows is using VRAM; lower `GPU_MEMORY_UTILIZATION`.
- To try a different vLLM build, set `VLLM_IMAGE` in the env file. AMD publishes RDNA3 images as
  `rocm/vllm:*_gfx110X-*` and `rocm/vllm-dev:*_navi_*`.

## Changing the templates

Fixes found while running `~/Projects/vllm-serve` (in `compose.yaml`, the scripts, or a better
default in an env file) belong here too, so the next machine gets them. `compose.yaml` here is the
working one plus the `TEMPLATE` lines at the top.
