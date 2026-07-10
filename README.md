# Aircheck ’06

A native iOS listening room for the 2006 Howard Stern archive: 179 streams, month/day browsing, background playback, lock-screen controls, resume positions, editorial jump cards, synchronized transcripts, and full-text search.

The app is intentionally source-configured rather than content-hosting. The Internet Archive item does not declare a license or rights statement, so this project makes no public-domain claim and should receive a rights review before public distribution.

## Run on an iPhone

1. Open `Aircheck06.xcodeproj` in Xcode 26.
2. Select the **Aircheck06** target, open **Signing & Capabilities**, and choose your Apple developer team.
3. If needed, replace `com.aylon.aircheck06` with a unique bundle identifier.
4. Connect your iPhone, choose it as the run destination, and press Run.

The app targets iOS 18 and newer. `UIBackgroundModes = audio`, an `AVAudioSession` playback category, and MediaPlayer remote commands provide lock-screen, headphone, Control Center, and cross-app playback.

## Build and test

```sh
cd "/Users/aylon/CODING PROJECTS/aircheck-06"
xcodegen generate
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --enable-code-coverage
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project Aircheck06.xcodeproj -scheme Aircheck06 \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build
python3 -m unittest discover -s pipeline/tests -v
```

## Build the archive index

See [pipeline/README.md](pipeline/README.md). The installed stack is:

- `ffmpeg` for low-storage HTTP chunk extraction
- `whisper.cpp` 1.9.1 with `ggml-small.en` for local transcription
- Ollama with `gemma4:12b` for validated editorial topics
- Apple Foundation Models as an on-device fallback
- SQLite FTS5 for app-scale phrase search without loading the full corpus into memory

Queue state lives in `pipeline/data/<show-id>/`. Each 30-minute Whisper JSON is a checkpoint, so restarts do not repeat completed work. To run the whole queue while keeping the Mac awake:

```sh
caffeinate -dimsu ./pipeline/run-week.sh
```

Check progress with `python3 aircheck_pipeline.py status`.
