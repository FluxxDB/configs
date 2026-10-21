# vllm — template for serving one MLX model with vLLM on an Apple-silicon Mac

The engine is the Homebrew vllm-metal `vllm serve`, run on the host GPU by a Compose provider
(`provider/docker-vllmmetal`), so `docker compose up` / `down` start and stop it. One model at a time.

```bash
brew install vllm-project/vllm-metal/vllm-metal
```

## Add a model

1. Get an MLX checkpoint: a Hugging Face repo id (`mlx-community/...`), or convert a downloaded
   bf16 checkpoint with `scripts/convert-to-mlx-4bit.sh <hf-repo-id>`.
2. `cp models/model.env models/<name>.env` and set `MODEL_PATH`, `SERVED_NAME` and the parsers.
3. `cp model.compose.yaml <model>.compose.yaml` and set `name: <model>` plus the matching
   `vllm-log` state path.
4. Optionally `ln -s models/<name>.env .env` to make it the default.

```
docker compose -f <model>.compose.yaml --env-file models/<name>.env up -d   # -> http://localhost:8000/v1
docker compose -f <model>.compose.yaml logs -f                              # engine log is the vllm-log service
docker compose -f <model>.compose.yaml down                                 # stops the engine
```

Test the endpoint:

```bash
curl -s http://localhost:8000/v1/chat/completions -H 'Content-Type: application/json' -d '{
  "model": "<model>",
  "messages": [{"role": "user", "content": "Explain mixture-of-experts in two sentences."}],
  "max_tokens": 200
}' | jq -r '.choices[0].message.content'
```

## Tuning

vLLM's budget is `GPU_MEMORY_UTILIZATION` x the GPU working set, for weights + KV cache + a
start-up reservation that grows with `MAX_NUM_BATCHED_TOKENS`. If the log reports a KV error, lower
`CONTEXT_SIZE` / `MAX_NUM_BATCHED_TOKENS`, or raise utilization (0.92 max).

Keep Docker Desktop memory small (4-6 GB): the engine runs on the host, and a large Docker VM
starves it of memory so macOS swaps the model weights out between requests.

## Troubleshooting

- `up` says something already answers on /health: an old engine is running; `down` it or
  `pkill -f "vllm serve"`.
- Engine state and log: `~/.local/state/docker-vllmmetal/<name>/vllm/` (`vllm.log`, `pid`, `cmdline`).
