#!/usr/bin/env python3
"""Create the lazy-loaded data files used by the shareable Aircheck site."""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "web" / "data"
SOURCES = (ROOT / "pipeline" / "data", ROOT / "pipeline" / "data-2007")
WORDS = re.compile(r"[a-z0-9][a-z0-9']{2,}", re.I)
STOP_WORDS = frozenset({"about", "after", "again", "also", "been", "before", "being", "between", "could", "does", "from", "have", "into", "just", "like", "more", "most", "other", "over", "really", "said", "some", "than", "that", "their", "them", "then", "there", "they", "this", "those", "through", "very", "what", "when", "where", "which", "while", "with", "would", "your"})
MAX_HITS_PER_WORD = 14


def write(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, separators=(",", ":")))


def main() -> None:
    catalog: dict[str, list[dict]] = {"2006": [], "2007": []}
    # A compact, lazy-loaded index: word -> [show id, timestamp].  The full
    # transcript remains per-show, so opening the site never downloads it all.
    search: dict[str, defaultdict[str, list[list[object]]]] = {
        "2006": defaultdict(list), "2007": defaultdict(list)
    }

    def index_text(year: str, show_id: str, timestamp: float, text: str) -> None:
        for word in set(match.group(0).lower() for match in WORDS.finditer(text)):
            if word in STOP_WORDS:
                continue
            hits = search[year][word]
            reference = [show_id, round(timestamp, 2)]
            if len(hits) < MAX_HITS_PER_WORD and reference not in hits:
                hits.append(reference)

    for source in SOURCES:
        jobs_path = source / "jobs.json"
        if not jobs_path.exists():
            continue
        for job in json.loads(jobs_path.read_text()):
            show_id = job["show_id"]
            year = show_id[:4]
            enrichment_path = source / show_id / "enrichment.json"
            topics: list[dict] = []
            transcript_available = enrichment_path.exists()
            if transcript_available:
                enrichment = json.loads(enrichment_path.read_text())
                topics = enrichment.get("topics", [])
                for topic in topics:
                    index_text(year, show_id, float(topic.get("startTime", 0)), topic.get("title", ""))
                    index_text(year, show_id, float(topic.get("startTime", 0)), topic.get("summary", ""))
                for segment in enrichment.get("transcript", []):
                    index_text(year, show_id, float(segment.get("startTime", 0)), segment.get("text", ""))
                write(OUT / "shows" / f"{show_id}.json", {
                    "id": show_id,
                    "topics": topics,
                    "transcript": enrichment.get("transcript", []),
                })
            catalog.setdefault(year, []).append({
                "id": show_id,
                "date": job["date"],
                "duration": job.get("duration", 0),
                "url": job["url"],
                "topics": topics,
                "transcriptAvailable": transcript_available,
            })
    for shows in catalog.values():
        shows.sort(key=lambda show: show["id"])
    write(OUT / "catalog.json", catalog)
    for year, index in search.items():
        write(OUT / f"search-{year}.json", index)
    print(f"Wrote {sum(map(len, catalog.values()))} shows to {OUT}")


if __name__ == "__main__":
    main()
