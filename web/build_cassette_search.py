#!/usr/bin/env python3
"""Build the lazy cassette transcript index used by Aircheck search.

The browser loads this only after a listener submits a search.  The audio and
individual transcript files remain separate, so visiting the archive stays
lightweight.
"""

from __future__ import annotations

import json
import re
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SHOWS = ROOT / "data" / "shows"
OUTPUT = ROOT / "data" / "search-cassettes.json"
WORDS = re.compile(r"[a-z0-9][a-z0-9']{2,}", re.I)
STOP_WORDS = frozenset({
    "about", "after", "again", "also", "been", "before", "being", "between",
    "could", "does", "from", "have", "into", "just", "like", "more", "most",
    "other", "over", "really", "said", "some", "than", "that", "their", "them",
    "then", "there", "they", "this", "those", "through", "very", "what", "when",
    "where", "which", "while", "with", "would", "your",
})
MAX_TOPIC_HITS_PER_WORD = 500
MAX_TRANSCRIPT_HITS_PER_WORD = 12
SEARCH_ALIASES = {"kennison": ("kinison",), "kinison": ("kennison",)}


def add_text(index: dict[str, dict[str, list[list[object]]]], show_id: str, timestamp: float, text: str, kind: str) -> None:
    reference = [show_id, round(timestamp, 2)]
    words = {match.group(0).lower() for match in WORDS.finditer(text)}
    words.update(alias for word in tuple(words) for alias in SEARCH_ALIASES.get(word, ()))
    for word in words:
        if word in STOP_WORDS:
            continue
        hits = index[word][kind]
        limit = MAX_TOPIC_HITS_PER_WORD if kind == "topic" else MAX_TRANSCRIPT_HITS_PER_WORD
        if len(hits) < limit and reference not in hits:
            hits.append(reference)


def main() -> None:
    index: dict[str, dict[str, list[list[object]]]] = defaultdict(lambda: {"topic": [], "transcript": []})
    count = 0
    for path in sorted(SHOWS.glob("cassette-*.json")):
        data = json.loads(path.read_text())
        show_id = data.get("id", path.stem)
        for topic in data.get("topics", []):
            timestamp = float(topic.get("startTime", 0))
            add_text(index, show_id, timestamp, topic.get("title", ""), "topic")
            add_text(index, show_id, timestamp, topic.get("summary", ""), "topic")
        for segment in data.get("transcript", []):
            add_text(index, show_id, float(segment.get("startTime", 0)), segment.get("text", ""), "transcript")
        count += 1
    flattened = {word: groups["topic"] + groups["transcript"] for word, groups in index.items()}
    OUTPUT.write_text(json.dumps(flattened, ensure_ascii=False, separators=(",", ":")))
    print(f"Indexed {count} cassette recordings into {OUTPUT} ({OUTPUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
