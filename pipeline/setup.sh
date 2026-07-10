#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
MODEL_DIR="$ROOT/pipeline/models"
MODEL="$MODEL_DIR/ggml-small.en.bin"

mkdir -p "$MODEL_DIR"
if [ ! -f "$MODEL" ]; then
  curl -L --fail --continue-at - \
    -o "$MODEL" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin"
fi

echo "Ready: $MODEL"
