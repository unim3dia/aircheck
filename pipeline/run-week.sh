#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

./pipeline/setup.sh
python3 aircheck_pipeline.py init

while python3 aircheck_pipeline.py transcribe; do
  python3 aircheck_pipeline.py export
  if [ "$(python3 -c 'import json; from pathlib import Path; j=json.loads(Path("pipeline/data/jobs.json").read_text()); print(sum((Path("pipeline/data")/x["show_id"]/"enrichment.json").exists() for x in j) == len(j))')" = "True" ]; then
    break
  fi
done
