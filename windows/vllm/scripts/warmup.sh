#!/bin/sh
# Runs inside the `warmup` container. compose.yaml sets VLLM_URL (reachable from containers),
# VLLM_HOST_URL (what you use from WSL or Windows) and VLLM_MODEL.
#  1. wait for /health (compose already did; this covers restarts)
#  2. send one long, varied prompt: the first request after a start pays one-time kernel
#     compilation (Triton JIT) costs, so pay them here instead of on your first real call
#  3. print the endpoint and idle (the engine itself keeps running until `docker compose down`)
set -u
URL="${VLLM_URL%/}"; MODEL="${VLLM_MODEL:?VLLM_MODEL not set}"; HOST_URL="${VLLM_HOST_URL:-http://localhost:${PORT:-8000}/v1}"

echo "[warmup] waiting for vLLM at $URL ..."
until curl -fsS -m 5 "${URL%/v1}/health" >/dev/null 2>&1; do sleep 2; done

prompt="Give a one-line answer to each question. "
prompt="${prompt}1) Explain how a bicycle derailleur shifts gears. 2) What causes the seasons on Earth? "
prompt="${prompt}3) Write a Python one-liner that reverses a list. 4) Translate 'good morning' to French, German and Japanese. "
prompt="${prompt}5) What is the time complexity of binary search? 6) Name three causes of the French Revolution. "
prompt="${prompt}7) How does TCP differ from UDP? 8) Summarize the plot of Hamlet. 9) What is a monad in functional programming? "
prompt="${prompt}10) Describe photosynthesis in one sentence. 11) What is 17 times 23? 12) Why is the sky blue? "
prompt="${prompt}13) Give a SQL query that counts rows per customer. 14) What does a central bank do? 15) Define entropy. "
prompt="${prompt}16) How do vaccines train the immune system? 17) What is the capital of Australia? 18) Explain recursion to a child. "
prompt="${prompt}19) What is a mixture-of-experts model? 20) Name the planets in order. 21) What is the Pythagorean theorem? "
prompt="${prompt}22) How does public-key cryptography work? 23) What is GDP? 24) Describe how a refrigerator cools food."
body=$(printf '{"model":"%s","messages":[{"role":"user","content":"%s"}],"max_tokens":96,"temperature":0}' "$MODEL" "$prompt")

echo "[warmup] warm-up request to $MODEL ..."
t0=$(date +%s)
code=$(curl -sS -m 900 -o /tmp/warmup-resp.json -w '%{http_code}' -X POST "$URL/chat/completions" -H 'Content-Type: application/json' -d "$body")
if [ "$code" != "200" ]; then
  echo "[warmup] FAILED (HTTP $code):"; cat /tmp/warmup-resp.json; echo
  echo "[warmup] engine log: docker compose logs vllm"
  exit 1
fi
echo "[warmup] done in $(( $(date +%s) - t0 ))s"
echo "[warmup] OpenAI-compatible API: $HOST_URL   model=\"$MODEL\"   (engine log: docker compose logs -f vllm)"
echo "[warmup] the engine keeps running until this stack is taken down (docker compose down)"
exec tail -f /dev/null
