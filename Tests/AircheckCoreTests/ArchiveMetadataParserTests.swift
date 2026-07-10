import Foundation
import XCTest
@testable import AircheckCore

final class ArchiveMetadataParserTests: XCTestCase {
    func testParsesPlayableMP3sAndSortsByBroadcastDate() throws {
        let data = try XCTUnwrap(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        XCTAssertEqual(shows.map(\.id), ["2006-01-09", "2006-04-20"])
        XCTAssertEqual(shows[0].duration, 18_706.13)
        XCTAssertTrue(shows[0].audioURL.absoluteString.contains("Howard_Stern_24k_01-09-06_cf.mp3"))
    }

    func testRepairsTheKnownNinetySixFilenameTypoUsingCollectionYear() throws {
        let data = try XCTUnwrap(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(shows[1].date, DateComponents(calendar: calendar, year: 2006, month: 4, day: 20).date)
    }

    func testIgnoresNonAudioDerivativesAndMalformedFiles() throws {
        let data = try XCTUnwrap(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        XCTAssertEqual(shows.count, 2)
    }

    private let sampleMetadata = #"""
    {
      "metadata": { "identifier": "howard-stern-24k-complete-2006" },
      "files": [
        { "name": "Howard_Stern_24k_04-20-96_cf.mp3", "size": "45000000", "length": "15000.5", "source": "original" },
        { "name": "Howard_Stern_24k_01-09-06_cf.mp3", "size": "56119033", "length": "18706.13", "source": "original" },
        { "name": "Howard_Stern_24k_01-09-06_cf.png", "size": "100", "source": "derivative" },
        { "name": "cover.mp3", "size": "100", "length": "2", "source": "original" }
      ]
    }
    """#
}
