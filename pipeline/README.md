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

Every completed show gets deterministic topic blocks immediately. A separate on-device Apple Foundation Models refinement stage is planned for editorial titles and summaries; this fallback keeps the transcription queue independent of Apple Intelligence availability.
