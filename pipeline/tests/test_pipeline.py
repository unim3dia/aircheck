import unittest

from aircheck_pipeline import (
    build_jobs,
    editorial_title,
    merge_chunk_transcripts,
    normalize_known_names,
    topic_windows,
    validate_topic_draft,
)


class CatalogJobsTests(unittest.TestCase):
    def test_builds_sorted_unique_jobs_and_repairs_source_typo(self):
        metadata = {
            "metadata": {"identifier": "howard-stern-24k-complete-2006"},
            "files": [
                {"name": "Howard_Stern_24k_04-20-96_cf.mp3", "length": "100"},
                {"name": "Howard_Stern_24k_01-09-06_cf.mp3", "length": "200"},
                {"name": "Howard_Stern_24k_06-08-06_Artie_Roast_cf.mp3", "length": "300"},
                {"name": "cover.png"},
            ],
        }

        jobs = build_jobs(metadata, 2006)

        self.assertEqual([job["show_id"] for job in jobs], ["2006-01-09", "2006-04-20", "2006-06-08-artie-roast"])
        self.assertEqual(jobs[1]["date"], "2006-04-20")


class TranscriptMergeTests(unittest.TestCase):
    def test_normalizes_recurring_stern_names_without_changing_unrelated_text(self):
        text = "George DeKay introduced Artie Lang and Gary Delabati. The fragile eagle joke landed."
        self.assertEqual(
            normalize_known_names(text),
            "George Takei introduced Artie Lange and Gary Dell'Abate. The fragile ego joke landed.",
        )

    def test_offsets_chunk_segments_and_assigns_stable_ids(self):
        chunks = [
            (0, {"transcription": [{"offsets": {"from": 1000, "to": 3000}, "text": " First line. "}]}),
            (1800, {"transcription": [{"offsets": {"from": 500, "to": 1500}, "text": "Second line."}]}),
        ]

        segments = merge_chunk_transcripts(chunks)

        self.assertEqual(segments[0], {"id": 0, "startTime": 1.0, "endTime": 3.0, "speaker": None, "text": "First line."})
        self.assertEqual(segments[1]["startTime"], 1800.5)
        self.assertEqual(segments[1]["id"], 1)

    def test_drops_empty_and_non_monotonic_segments(self):
        chunks = [(0, {"transcription": [
            {"offsets": {"from": 1000, "to": 500}, "text": "bad"},
            {"offsets": {"from": 1000, "to": 2000}, "text": "   "},
        ]})]
        self.assertEqual(merge_chunk_transcripts(chunks), [])


class TopicWindowTests(unittest.TestCase):
    def test_rejects_unverified_named_speaker_claims(self):
        self.assertIsNone(validate_topic_draft({"title": "Bush on Sirius", "summary": "George Bush discusses Sirius Radio."}))

    def test_accepts_show_level_summary_and_caps_title(self):
        self.assertEqual(
            validate_topic_draft({
                "title": "A Very Long Headline About The First Satellite Broadcast Today",
                "summary": "The show discusses its first satellite broadcast and technical problems.",
            }),
            {
                "title": "A Very Long Headline About The First Satellite",
                "summary": "The show discusses its first satellite broadcast and technical problems.",
            },
        )

    def test_editorial_title_removes_sentence_punctuation_and_limits_words(self):
        self.assertEqual(
            editorial_title("Howard and Robin discover technical problems in the new studio."),
            "Howard and Robin discover technical problems in the",
        )

    def test_groups_transcript_into_prompt_sized_windows_with_timestamps(self):
        segments = [
            {"id": 0, "startTime": 0, "endTime": 10, "speaker": None, "text": "a" * 30},
            {"id": 1, "startTime": 11, "endTime": 20, "speaker": None, "text": "b" * 30},
            {"id": 2, "startTime": 21, "endTime": 30, "speaker": None, "text": "c" * 30},
        ]

        windows = topic_windows(segments, max_characters=90)

        self.assertEqual(len(windows), 2)
        self.assertEqual(windows[0]["start_time"], 0)
        self.assertEqual(windows[1]["start_time"], 21)


if __name__ == "__main__":
    unittest.main()
