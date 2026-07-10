import Foundation

public enum CatalogSearch {
    public static func search(query: String, shows: [Show]) -> [SearchHit] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }

        var results: [SearchHit] = []
        for show in shows {
            var topicHits: [SearchHit] = []
            for topic in show.topics {
                let titleMatches = topic.title.localizedCaseInsensitiveContains(needle)
                let summaryMatches = topic.summary.localizedCaseInsensitiveContains(needle)
                guard titleMatches || summaryMatches else { continue }
                var hitID = show.id
                hitID.append("-topic-")
                hitID.append(topic.id)
                topicHits.append(SearchHit(
                    id: hitID,
                    showID: show.id,
                    time: topic.startTime,
                    title: topic.title,
                    excerpt: topic.summary,
                    kind: .topic
                ))
            }

            results.append(contentsOf: topicHits)
            for segment in show.transcript {
                guard segment.text.localizedCaseInsensitiveContains(needle) else { continue }
                var isCoveredByTopic = false
                for hit in topicHits where abs(hit.time - segment.startTime) < 120 {
                    isCoveredByTopic = true
                    break
                }
                guard !isCoveredByTopic else { continue }
                let showID: String = show.id
                let segmentID: String = segment.id.description
                var hitID = showID
                hitID.append("-transcript-")
                hitID.append(segmentID)
                let title = segment.speaker ?? "Transcript"
                results.append(SearchHit(
                    id: hitID,
                    showID: show.id,
                    time: segment.startTime,
                    title: title,
                    excerpt: segment.text,
                    kind: .transcript
                ))
            }
        }

        return results.sorted { lhs, rhs in
            lhs.showID == rhs.showID ? lhs.time < rhs.time : lhs.showID < rhs.showID
        }
    }
}

public enum TranscriptTimeline {
    public static func activeSegment(at time: TimeInterval, in segments: [TranscriptSegment]) -> TranscriptSegment? {
        var lower = 0
        var upper = segments.count
        while lower < upper {
            let middle = (lower + upper) / 2
            if segments[middle].startTime <= time { lower = middle + 1 } else { upper = middle }
        }
        guard lower > 0 else { return nil }
        let candidate = segments[lower - 1]
        return time < candidate.endTime ? candidate : nil
    }
}
