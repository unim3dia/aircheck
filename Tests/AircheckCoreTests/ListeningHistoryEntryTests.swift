import XCTest
@testable import AircheckCore

final class ListeningHistoryEntryTests: XCTestCase {
    func testRecordingPlaybackTracksPositionReachAndActualListeningTime() {
        let start = Date(timeIntervalSince1970: 1_000)
        var entry = ListeningHistoryEntry(
            showID: "show-1",
            lastPosition: 120,
            furthestPosition: 300,
            secondsListened: 90,
            duration: 1_000,
            lastListenedAt: start
        )

        entry.record(position: 240, listenedDelta: 10, at: start.addingTimeInterval(10))

        XCTAssertEqual(entry.lastPosition, 240)
        XCTAssertEqual(entry.furthestPosition, 300)
        XCTAssertEqual(entry.secondsListened, 100)
        XCTAssertEqual(entry.completionFraction, 0.3)
        XCTAssertEqual(entry.lastListenedAt, start.addingTimeInterval(10))
    }

    func testRecordingClampsInvalidValuesAndAdvancesFurthestPosition() {
        var entry = ListeningHistoryEntry(
            showID: "show-1",
            lastPosition: 0,
            furthestPosition: 0,
            secondsListened: 0,
            duration: 1_000,
            lastListenedAt: .distantPast
        )

        entry.record(position: 1_200, listenedDelta: -5, at: .now)

        XCTAssertEqual(entry.lastPosition, 1_000)
        XCTAssertEqual(entry.furthestPosition, 1_000)
        XCTAssertEqual(entry.secondsListened, 0)
        XCTAssertEqual(entry.completionFraction, 1)
    }

    func testHistoryOrdersMostRecentlyListenedFirst() {
        let older = ListeningHistoryEntry(
            showID: "older", lastPosition: 20, furthestPosition: 20,
            secondsListened: 20, duration: 100,
            lastListenedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = ListeningHistoryEntry(
            showID: "newer", lastPosition: 10, furthestPosition: 10,
            secondsListened: 10, duration: 100,
            lastListenedAt: Date(timeIntervalSince1970: 200)
        )

        XCTAssertEqual(ListeningHistoryEntry.mostRecentFirst([older, newer]).map(\.showID), ["newer", "older"])
    }
}
