#!/usr/bin/env bash
set -euo pipefail

COMFYUI_HOST="${COMFYUI_HOST:-127.0.0.1}"
COMFYUI_PORT="${COMFYUI_PORT:-8188}"
COMFYUI_PATH="${COMFYUI_PATH:-/system_stats}"

URL="http://${COMFYUI_HOST}:${COMFYUI_PORT}${COMFYUI_PATH}"

echo "Testando endpoint do ComfyUI: ${URL}"
curl -fsS --max-time 5 "${URL}" >/dev/null

echo "ComfyUI alcançável"
