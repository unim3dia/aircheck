# Local indexing pipeline

The archive contains 179 MP3s and about 826.5 hours of audio. The pipeline uses `ffmpeg` and `whisper.cpp` locally, processes one 30-minute chunk at a time, deletes temporary WAV files, and treats each raw Whisper JSON file as a checkpoint. Restarting never repeats completed chunks.

## Quick start

```sh
cd "/Users/aylon/CODING PROJECTS/aircheck-06"
./pipeline/setup.sh
python3 aircheck_pipeline.py init
python3 aircheck_pipeline.py transcribe --show-id 2006-01-09
python3 aircheck_pipeline.py export
```

Run the entire queue with `caffeinate -dimsu ./pipeline/run-week.sh`. A real ten-minute sample ran in 13 seconds on this M4 Pro (about 46× real time), making the 826-hour corpus roughly 18 hours of model compute before transfer and topic work. The small English model preserved more overlapping speech than the tested large-v3-turbo-q5 model; a normalization layer repairs recurring proper-name errors. Individual low-quality shows can still be re-run with another model by deleting their `raw` directory and passing `--model`.

`pipeline/data` and model weights are ignored by Git. Completed app-ready data is exported to `App/Resources/enrichments.json`.

## Topic quality

When Apple Intelligence is available, `setup.sh` compiles `TopicIndexer.swift` and each completed transcript is packaged into structured editorial titles and summaries by Apple's on-device model. Headings are deterministically capped at eight words. If the model is disabled, unavailable, times out, or rejects a window, the same job receives a deterministic fallback so transcription never stalls.
