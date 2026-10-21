# vllm — template for serving one model with vLLM on the RX 7900 GRE under WSL2

The engine is AMD's RDNA3 (gfx110X) build of vLLM in a container. It reaches the GPU through WSL's
`/dev/dxg` and the ROCDXG bridge that [`../setup.sh`](../setup.sh) installs, so `docker compose up`
/ `down` start and stop it. One model at a time. This is the WSL counterpart of
[`../../mac/vllm`](../../mac/vllm), where the engine has to be a host process because macOS
containers can't reach the GPU.

## Add a model

1. Pick a checkpoint that fits: 16 GB of VRAM, minus some for the Windows desktop, has to hold the
   weights and the KV cache, so ~10 GB of weights is the practical ceiling. RDNA3 has no FP8/FP4
   hardware, so use bf16, AWQ, GPTQ or compressed-tensors W4A16 checkpoints, not FP8/NVFP4/MXFP4.
2. `cp models/model.env models/<name>.env` and set `MODEL_PATH` (a Hugging Face repo id, downloaded
   into `HF_HOME` on first start, or a local directory under it), `SERVED_NAME` and the parsers.
3. Optionally `ln -s models/<name>.env .env` to make it the default (`.env` is gitignored).

```bash
docker compose --env-file models/<name>.env up -d --wait   # -> http://localhost:8000/v1
docker compose logs -f                                     # engine + warm-up logs
docker compose down                                        # stops the engine, frees the VRAM
```

The default model is [`models/qwen3.5-9b.env`](models/qwen3.5-9b.env): Qwen3.5-9B at 4 bits, text
only, with Qwen's tool-call and reasoning parsers. Test the endpoint (it works from Windows too):

```bash
curl -s http://localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "qwen3.5-9b",
  "messages": [{"role": "user", "content": "Explain mixture-of-experts in two sentences."}],
  "max_tokens": 400
}' | jq -r '.choices[0].message.content'
```

With Qwen3.5-9B: 7.9 GiB of weights, ~24–27k tokens of KV cache, ~50 tokens/s for one request, and
~3 minutes from `up` to healthy (~4.5 the very first time, while torch.compile and Triton fill
their caches, which live in the `vllm-cache` / `triton-cache` volumes). Thinking is on by default
and can be long; send `"chat_template_kwargs": {"enable_thinking": false}` for direct answers.

## Tuning

vLLM's budget is `GPU_MEMORY_UTILIZATION` x the card's total VRAM (reported as 17.1 GB), for
weights + KV cache + a start-up reservation that grows with `MAX_NUM_BATCHED_TOKENS`. Windows keeps
~2.5 GB for the desktop (more with games or a browser on the GPU), and vLLM refuses to start if its
share is more than what's free, so ~0.85 is the ceiling. If the log reports a KV cache error, lower
`CONTEXT_SIZE` / `MAX_NUM_BATCHED_TOKENS`.

Qwen3.5 uses hybrid attention (most layers are Gated DeltaNet with a fixed-size state), so its KV
cache per token is small and long contexts are cheap.

int4 kernels on ROCm: vLLM has Conch (group size 128, bf16 or fp16) and Exllama (any group size,
fp16 only). A checkpoint with another group size, like the default model's 32, needs
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
- The first start downloads the model into `HF_HOME` (`~/Projects/.huggingface`); `up --wait` waits
  up to 30 minutes for the health check.
- To try a different vLLM build, set `VLLM_IMAGE` in the env file. AMD publishes RDNA3 images as
  `rocm/vllm:*_gfx110X-*` and `rocm/vllm-dev:*_navi_*`.
