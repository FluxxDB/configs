#!/bin/bash
# Runs inside the `vllm` container: starts `vllm serve` with the flags from the selected
# models/<name>.env (compose.yaml passes them in as environment variables), the same way the Mac's
# provider (mac/vllm/provider/docker-vllmmetal) builds its command line.
set -euo pipefail

args=(serve "${MODEL_PATH:?MODEL_PATH not set}" --host 0.0.0.0 --port 8000 --served-model-name "${SERVED_NAME:-model}")
[ -n "${CONTEXT_SIZE:-}" ]           && args+=(--max-model-len "$CONTEXT_SIZE")
[ -n "${MAX_NUM_SEQS:-}" ]           && args+=(--max-num-seqs "$MAX_NUM_SEQS")
[ -n "${MAX_NUM_BATCHED_TOKENS:-}" ] && args+=(--max-num-batched-tokens "$MAX_NUM_BATCHED_TOKENS")
[ -n "${GPU_MEMORY_UTILIZATION:-}" ] && args+=(--gpu-memory-utilization "$GPU_MEMORY_UTILIZATION")
[ -n "${TOOL_CALL_PARSER:-}" ]       && args+=(--enable-auto-tool-choice --tool-call-parser "$TOOL_CALL_PARSER")
[ -n "${REASONING_PARSER:-}" ]       && args+=(--reasoning-parser "$REASONING_PARSER")
# shellcheck disable=SC2206  # whitespace-split on purpose, like the Mac provider's extra-args
[ -n "${VLLM_EXTRA_ARGS:-}" ]        && args+=($VLLM_EXTRA_ARGS)

echo "starting: vllm ${args[*]}"
exec vllm "${args[@]}"
