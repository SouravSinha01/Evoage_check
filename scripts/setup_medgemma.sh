#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.run"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/logs}"

MEDGEMMA_ENV_NAME="${MEDGEMMA_ENV_NAME:-sglang}"
MEDGEMMA_MODEL_PATH="${MEDGEMMA_MODEL_PATH:-$ROOT_DIR/scripts/medgemma-27b-local}"
MEDGEMMA_HOST="${MEDGEMMA_HOST:-0.0.0.0}"
MEDGEMMA_PORT="${MEDGEMMA_PORT:-30001}"
MEDGEMMA_MEM_FRACTION="${MEDGEMMA_MEM_FRACTION:-0.9}"
MEDGEMMA_CONTEXT_LENGTH="${MEDGEMMA_CONTEXT_LENGTH:-32000}"
MEDGEMMA_CHUNKED_PREFILL_SIZE="${MEDGEMMA_CHUNKED_PREFILL_SIZE:-2048}"
MEDGEMMA_SCHEDULE_POLICY="${MEDGEMMA_SCHEDULE_POLICY:-lpm}"

log() { printf '\n[%s] %s\n' "$1" "$2"; }
info() { log INFO "$1"; }
fail() { log ERROR "$1"; exit 1; }

have() {
  command -v "$1" >/dev/null 2>&1
}

usage() {
  cat <<'EOF'
Usage: scripts/setup_medgemma.sh

Starts the local MedGemma SGLang server in the background.

Run this only when Backend/.env uses:
  USE=medgemma
  MEDGEMMA_BASE_URL=http://localhost:30001/v1
  MEDGEMMA_MODEL=medgemma-27b-local

Before running:
  1. Create the SGLang env: bash scripts/setup.sh --medgemma
  2. Download the model:
     conda run -n sglang hf download google/medgemma-27b-text-it \
       --local-dir ./scripts/medgemma-27b-local \
       --token YOUR_HF_READ_TOKEN \
       --max-workers 4

Environment variables:
  MEDGEMMA_ENV_NAME                 Conda env name. Default: sglang
  MEDGEMMA_MODEL_PATH               Model path. Default: scripts/medgemma-27b-local
  MEDGEMMA_HOST                     Bind host. Default: 0.0.0.0
  MEDGEMMA_PORT                     Port. Default: 30001
  MEDGEMMA_MEM_FRACTION             Static GPU memory fraction. Default: 0.9
  MEDGEMMA_CONTEXT_LENGTH           Context length. Default: 32000
  MEDGEMMA_CHUNKED_PREFILL_SIZE     Chunked prefill size. Default: 2048
  MEDGEMMA_SCHEDULE_POLICY          Schedule policy. Default: lpm
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

have conda || fail "conda is required. Run bash scripts/setup.sh --medgemma first."
[[ -d "$MEDGEMMA_MODEL_PATH" ]] || fail "MedGemma model directory not found: $MEDGEMMA_MODEL_PATH"

mkdir -p "$RUN_DIR" "$LOG_DIR" "$HOME/tmp" "$HOME/triton_cache" "$HOME/torch_cache" "$HOME/hf_cache"

export TMPDIR="$HOME/tmp"
export TEMP="$HOME/tmp"
export TMP="$HOME/tmp"
export TRITON_CACHE_DIR="$HOME/triton_cache"
export TORCHINDUCTOR_CACHE_DIR="$HOME/torch_cache"
export HF_HOME="$HOME/hf_cache"
export HUGGINGFACE_HUB_CACHE="$HOME/hf_cache"
export LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LIBRARY_PATH:-}"
export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"

LOG_FILE="$LOG_DIR/medgemma_port${MEDGEMMA_PORT}.log"
PID_FILE="$RUN_DIR/medgemma.pid"

info "Starting MedGemma/SGLang server"
info "Model path: $MEDGEMMA_MODEL_PATH"
info "URL: http://localhost:${MEDGEMMA_PORT}/v1"
info "Log file: $LOG_FILE"

nohup conda run -n "$MEDGEMMA_ENV_NAME" python -m sglang.launch_server \
  --model-path "$MEDGEMMA_MODEL_PATH" \
  --port "$MEDGEMMA_PORT" \
  --host "$MEDGEMMA_HOST" \
  --mem-fraction-static "$MEDGEMMA_MEM_FRACTION" \
  --context-length "$MEDGEMMA_CONTEXT_LENGTH" \
  --schedule-policy "$MEDGEMMA_SCHEDULE_POLICY" \
  --chunked-prefill-size "$MEDGEMMA_CHUNKED_PREFILL_SIZE" \
  > "$LOG_FILE" 2>&1 &

server_pid=$!
printf '%s\n' "$server_pid" > "$PID_FILE"

info "Server started with PID: $server_pid"
info "Keep this terminal available for monitoring, or watch logs with: tail -f $LOG_FILE"
