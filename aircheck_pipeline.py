#!/usr/bin/env python3
"""Resumable, local-first transcription pipeline for Aircheck ’06."""

from __future__ import annotations

import argparse
import json
import math
import os
import re
import shutil
import subprocess
import tempfile
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path
from typing import Any, Iterable

ARCHIVE_IDENTIFIER = "howard-stern-24k-complete-2006"
METADATA_URL = f"https://archive.org/metadata/{ARCHIVE_IDENTIFIER}"
DOWNLOAD_ROOT = f"https://archive.org/download/{ARCHIVE_IDENTIFIER}"
DATE_PATTERN = re.compile(r"_(\d{2})-(\d{2})-(\d{2})_")
KNOWN_TRANSCRIPT_CORRECTIONS = {
    r"\bGeorge DeKay\b": "George Takei",
    r"\bGary Delabati\b": "Gary Dell'Abate",
    r"\bArtie Lang\b": "Artie Lange",
    r"\bBenji Brock\b": "Benjy Bronk",
    r"\bfragile eagle\b": "fragile ego",
}


def build_jobs(metadata: dict[str, Any], collection_year: int) -> list[dict[str, Any]]:
    identifier = metadata.get("metadata", {}).get("identifier", ARCHIVE_IDENTIFIER)
    jobs: list[dict[str, Any]] = []
    for file in metadata.get("files", []):
        name = file.get("name", "")
        match = DATE_PATTERN.search(name)
        if not name.lower().endswith(".mp3") or not match:
            continue
        month, day = int(match.group(1)), int(match.group(2))
        if not 1 <= month <= 12 or not 1 <= day <= 31:
            continue
        date = f"{collection_year:04d}-{month:02d}-{day:02d}"
        suffix = "-artie-roast" if "artie_roast" in name.lower() else ""
        jobs.append({
            "show_id": date + suffix,
            "date": date,
            "filename": name,
            "url": f"https://archive.org/download/{identifier}/{urllib.parse.quote(name)}",
            "duration": float(file.get("length", 0) or 0),
            "bytes": int(file.get("size", 0) or 0),
        })
    return sorted(jobs, key=lambda job: job["show_id"])


def merge_chunk_transcripts(chunks: Iterable[tuple[float, dict[str, Any]]]) -> list[dict[str, Any]]:
    merged: list[dict[str, Any]] = []
    for chunk_start, payload in chunks:
        entries = payload.get("transcription") or payload.get("segments") or []
        for entry in entries:
            offsets = entry.get("offsets", {})
            start_ms = offsets.get("from", entry.get("start", 0) * 1000)
            end_ms = offsets.get("to", entry.get("end", 0) * 1000)
            text = normalize_known_names(str(entry.get("text", "")).strip())
            if not text or end_ms <= start_ms:
                continue
            merged.append({
                "id": len(merged),
                "startTime": round(chunk_start + float(start_ms) / 1000, 3),
                "endTime": round(chunk_start + float(end_ms) / 1000, 3),
                "speaker": None,
                "text": text,
            })
    return merged


def normalize_known_names(text: str) -> str:
    for pattern, replacement in KNOWN_TRANSCRIPT_CORRECTIONS.items():
        text = re.sub(pattern, replacement, text)
    return text


def topic_windows(segments: list[dict[str, Any]], max_characters: int = 9000) -> list[dict[str, Any]]:
    windows: list[dict[str, Any]] = []
    current: list[str] = []
    current_size = 0
    start_time = 0.0
    for segment in segments:
        line = f"[{timecode(segment['startTime'])}] {segment['text']}"
        if current and current_size + len(line) + 1 > max_characters:
            windows.append({"start_time": start_time, "text": "\n".join(current)})
            current, current_size = [], 0
        if not current:
            start_time = segment["startTime"]
        current.append(line)
        current_size += len(line) + 1
    if current:
        windows.append({"start_time": start_time, "text": "\n".join(current)})
    return windows


def timecode(seconds: float) -> str:
    total = max(int(seconds), 0)
    return f"{total // 3600:02d}:{(total % 3600) // 60:02d}:{total % 60:02d}"


def fetch_json(url: str) -> dict[str, Any]:
    request = urllib.request.Request(url, headers={"User-Agent": "Aircheck06/1.0 personal archive indexer"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(path.suffix + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n")
    temporary.replace(path)


def initialize(data_root: Path) -> list[dict[str, Any]]:
    metadata_path = data_root / "archive-metadata.json"
    metadata = fetch_json(METADATA_URL)
    write_json(metadata_path, metadata)
    jobs = build_jobs(metadata, 2006)
    write_json(data_root / "jobs.json", jobs)
    for job in jobs:
        manifest = data_root / job["show_id"] / "manifest.json"
        if not manifest.exists():
            write_json(manifest, {**job, "state": "queued", "pipeline_version": 1})
    return jobs


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def transcribe_job(job: dict[str, Any], data_root: Path, model: Path, chunk_seconds: int) -> None:
    show_root = data_root / job["show_id"]
    raw_root = show_root / "raw"
    raw_root.mkdir(parents=True, exist_ok=True)
    total_chunks = math.ceil(job["duration"] / chunk_seconds)
    update_manifest(show_root, state="transcribing", total_chunks=total_chunks)

    for index in range(total_chunks):
        raw_json = raw_root / f"{index:04d}.json"
        if raw_json.exists():
            continue
        start = index * chunk_seconds
        length = min(chunk_seconds, job["duration"] - start)
        with tempfile.TemporaryDirectory(prefix="aircheck06-") as temporary:
            wav = Path(temporary) / "chunk.wav"
            output_base = Path(temporary) / "whisper"
            subprocess.run([
                "ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", str(start), "-t", str(length),
                "-i", job["url"], "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", "-y", str(wav),
            ], check=True)
            subprocess.run([
                "whisper-cli", "-m", str(model), "-f", str(wav), "-l", "en", "-oj", "-of", str(output_base),
                "-t", str(max((os.cpu_count() or 8) - 2, 4)),
            ], check=True)
            generated = output_base.with_suffix(".json")
            if not generated.exists():
                raise RuntimeError(f"whisper-cli did not create {generated}")
            raw_json.write_bytes(generated.read_bytes())
        update_manifest(show_root, completed_chunks=index + 1)

    chunks = [(index * chunk_seconds, json.loads((raw_root / f"{index:04d}.json").read_text())) for index in range(total_chunks)]
    transcript = merge_chunk_transcripts(chunks)
    write_json(show_root / "transcript.json", transcript)
    topics = heuristic_topics(transcript)
    write_json(show_root / "topics.json", topics)
    write_json(show_root / "enrichment.json", {"showID": job["show_id"], "topics": topics, "transcript": transcript})
    update_manifest(show_root, state="complete", segment_count=len(transcript), topic_count=len(topics))


def heuristic_topics(segments: list[dict[str, Any]]) -> list[dict[str, Any]]:
    topics: list[dict[str, Any]] = []
    stop = {"Howard", "Robin", "That", "This", "They", "What", "When", "Yeah", "Okay", "Right", "Well"}
    for index, window in enumerate(topic_windows(segments, max_characters=7000)):
        plain = re.sub(r"\[[^]]+\]\s*", "", window["text"])
        sentences = re.split(r"(?<=[.!?])\s+", plain)
        summary = " ".join(sentences[:2]).strip()[:360]
        names = Counter(word for word in re.findall(r"\b[A-Z][a-z]{2,}\b", plain) if word not in stop)
        labels = [word for word, _ in names.most_common(2)]
        title = " & ".join(labels) if labels else (sentences[0][:72].strip() or "Studio conversation")
        topics.append({
            "id": f"topic-{index:03d}",
            "title": title,
            "summary": summary,
            "startTime": window["start_time"],
            "imageURL": None,
        })
    return topics


def update_manifest(show_root: Path, **changes: Any) -> None:
    path = show_root / "manifest.json"
    value = json.loads(path.read_text()) if path.exists() else {}
    value.update(changes)
    write_json(path, value)


def export_enrichments(data_root: Path, output: Path) -> int:
    values = []
    for enrichment in sorted(data_root.glob("*/enrichment.json")):
        values.append(json.loads(enrichment.read_text()))
    write_json(output, values)
    return len(values)


def load_jobs(data_root: Path) -> list[dict[str, Any]]:
    path = data_root / "jobs.json"
    return json.loads(path.read_text()) if path.exists() else initialize(data_root)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--data-root", type=Path, default=Path("pipeline/data"))
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("init", help="Fetch archive metadata and create idempotent job manifests")
    transcribe = subparsers.add_parser("transcribe", help="Transcribe one show or the next queued show")
    transcribe.add_argument("--show-id")
    transcribe.add_argument("--model", type=Path, default=Path("pipeline/models/ggml-small.en.bin"))
    transcribe.add_argument("--chunk-seconds", type=int, default=1800)
    export = subparsers.add_parser("export", help="Build the JSON bundle consumed by the iOS app")
    export.add_argument("--output", type=Path, default=Path("App/Resources/enrichments.json"))
    subparsers.add_parser("status", help="Print queue progress")
    args = parser.parse_args()

    if args.command == "init":
        jobs = initialize(args.data_root)
        print(f"Initialized {len(jobs)} shows in {args.data_root}")
    elif args.command == "transcribe":
        if not command_exists("ffmpeg") or not command_exists("whisper-cli"):
            raise SystemExit("ffmpeg and whisper-cli are required")
        if not args.model.exists():
            raise SystemExit(f"Missing model: {args.model}. Run pipeline/setup.sh")
        jobs = load_jobs(args.data_root)
        job = next((value for value in jobs if value["show_id"] == args.show_id), None) if args.show_id else next(
            (value for value in jobs if not (args.data_root / value["show_id"] / "enrichment.json").exists()), None
        )
        if not job:
            print("No matching queued show")
            return
        transcribe_job(job, args.data_root, args.model, args.chunk_seconds)
        print(f"Completed {job['show_id']}")
    elif args.command == "export":
        print(f"Exported {export_enrichments(args.data_root, args.output)} shows to {args.output}")
    elif args.command == "status":
        jobs = load_jobs(args.data_root)
        complete = sum((args.data_root / job["show_id"] / "enrichment.json").exists() for job in jobs)
        hours = sum(job["duration"] for job in jobs) / 3600
        print(f"{complete}/{len(jobs)} shows complete · {hours:.1f} source hours total")


if __name__ == "__main__":
    main()
