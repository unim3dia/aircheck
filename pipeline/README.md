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

Run the entire queue with `caffeinate -dimsu ./pipeline/run-week.sh`. The small English model is the default because the M4 Pro can plausibly finish this 826-hour corpus within roughly a week. After sampling quality, individual low-quality shows can be re-run with a larger Whisper model by deleting their `raw` directory and passing `--model`.

`pipeline/data` and model weights are ignored by Git. Completed app-ready data is exported to `App/Resources/enrichments.json`.

## Topic quality

Every completed show gets deterministic topic blocks immediately. A separate on-device Apple Foundation Models refinement stage is planned for editorial titles and summaries; this fallback keeps the transcription queue independent of Apple Intelligence availability.
