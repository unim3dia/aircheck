# Architecture

```text
Internet Archive metadata + MP3 ranges
                 │
                 ▼
   30-minute ffmpeg PCM window (temporary)
                 │
                 ▼
 whisper.cpp JSON checkpoint ───────┐
                 │                  │ restart-safe
                 ▼                  │
 normalized timestamped transcript ◀┘
                 │
         ┌───────┴────────┐
         ▼                ▼
 Gemma topic cards   SQLite FTS rows
         │                │
         └───────┬────────┘
                 ▼
       bundled archive.sqlite
                 │
         ┌───────┴────────┐
         ▼                ▼
 calendar/topics     on-demand transcript
 in app memory        + global FTS search
```

The catalog itself is fetched from Internet Archive metadata and cached for 24 hours. Audio always streams from the configured item; the app does not re-host it. Only topics are attached to in-memory `Show` values. Transcript rows are read from SQLite when a show’s Transcript tab opens.

The player is a single MainActor-owned `AVPlayer`. It configures the playback audio session once, records position every half-second, updates Now Playing state, and exposes remote play/pause, ±15/30-second skip, and position changes.

Topic generation is intentionally downstream from transcription. Every stage is idempotent and a failed topic window falls back without blocking the audio or transcript.
