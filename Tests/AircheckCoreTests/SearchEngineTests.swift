import Foundation
import Testing
@testable import AircheckCore

struct SearchEngineTests {
    private let show = Show(
        id: "2006-01-09",
        date: DateComponents(calendar: .gregorian, year: 2006, month: 1, day: 9).date!,
        duration: 18_706,
        audioURL: URL(string: "https://example.com/show.mp3")!,
        topics: [Topic(id: "revelations", title: "The Revelations Game", summary: "The staff shares secrets.", startTime: 420)],
        transcript: [
            TranscriptSegment(id: 0, startTime: 410, endTime: 430, speaker: "Howard", text: "We are about to play the revelations game."),
            TranscriptSegment(id: 1, startTime: 4_200, endTime: 4_210, speaker: "Robin", text: "Let's talk about the Knicks.")
        ]
    )

    @Test func searchesTopicsAndReturnsJumpTime() {
        let hits = CatalogSearch.search(query: "revelations", shows: [show])
        #expect(hits.count == 1)
        #expect(hits[0].time == 420)
        #expect(hits[0].kind == .topic)
    }

    @Test func searchesTranscriptCaseInsensitively() {
        let hits = CatalogSearch.search(query: "KNICKS", shows: [show])
        #expect(hits.count == 1)
        #expect(hits[0].time == 4_200)
        #expect(hits[0].kind == .transcript)
    }

    @Test func emptySearchReturnsNoHits() {
        #expect(CatalogSearch.search(query: "   ", shows: [show]).isEmpty)
    }

    @Test func activeTranscriptSegmentUsesTimeBoundaries() {
        #expect(TranscriptTimeline.activeSegment(at: 409, in: show.transcript) == nil)
        #expect(TranscriptTimeline.activeSegment(at: 415, in: show.transcript)?.id == 0)
        #expect(TranscriptTimeline.activeSegment(at: 430, in: show.transcript) == nil)
    }
}
