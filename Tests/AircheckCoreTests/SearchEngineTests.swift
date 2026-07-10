import Foundation
import XCTest
@testable import AircheckCore

final class SearchEngineTests: XCTestCase {
    private let show = Show(
        id: "2006-01-09",
        date: DateComponents(calendar: Calendar(identifier: .gregorian), year: 2006, month: 1, day: 9).date!,
        duration: 18_706,
        audioURL: URL(string: "https://example.com/show.mp3")!,
        topics: [Topic(id: "revelations", title: "The Revelations Game", summary: "The staff shares secrets.", startTime: 420)],
        transcript: [
            TranscriptSegment(id: 0, startTime: 410, endTime: 430, speaker: "Howard", text: "We are about to play the revelations game."),
            TranscriptSegment(id: 1, startTime: 4_200, endTime: 4_210, speaker: "Robin", text: "Let's talk about the Knicks.")
        ]
    )

    func testSearchesTopicsAndReturnsJumpTime() {
        let hits = CatalogSearch.search(query: "revelations", shows: [show])
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits[0].time, 420)
        XCTAssertEqual(hits[0].kind, SearchHit.Kind.topic)
    }

    func testSearchesTranscriptCaseInsensitively() {
        let hits = CatalogSearch.search(query: "KNICKS", shows: [show])
        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits[0].time, 4_200)
        XCTAssertEqual(hits[0].kind, SearchHit.Kind.transcript)
    }

    func testEmptySearchReturnsNoHits() {
        XCTAssertTrue(CatalogSearch.search(query: "   ", shows: [show]).isEmpty)
    }

    func testActiveTranscriptSegmentUsesTimeBoundaries() {
        XCTAssertNil(TranscriptTimeline.activeSegment(at: 409, in: show.transcript))
        XCTAssertEqual(TranscriptTimeline.activeSegment(at: 415, in: show.transcript)?.id, 0)
        XCTAssertNil(TranscriptTimeline.activeSegment(at: 430, in: show.transcript))
    }
}
