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

if [ -d /Applications/Xcode.app ] && [ ! -x "$ROOT/pipeline/topic-indexer" ]; then
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
    xcrun swiftc -parse-as-library "$ROOT/pipeline/TopicIndexer.swift" \
    -framework FoundationModels -o "$ROOT/pipeline/topic-indexer" || true
fi

echo "Ready: $MODEL"
