import Foundation
import Testing
@testable import AircheckCore

struct ArchiveMetadataParserTests {
    @Test func parsesPlayableMP3sAndSortsByBroadcastDate() throws {
        let data = try #require(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        #expect(shows.map(\.id) == ["2006-01-09", "2006-04-20"])
        #expect(shows[0].duration == 18_706.13)
        #expect(shows[0].audioURL.absoluteString.contains("Howard_Stern_24k_01-09-06_cf.mp3"))
    }

    @Test func repairsTheKnownNinetySixFilenameTypoUsingCollectionYear() throws {
        let data = try #require(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        #expect(shows[1].date == DateComponents(calendar: .gregorian, year: 2006, month: 4, day: 20).date)
    }

    @Test func ignoresNonAudioDerivativesAndMalformedFiles() throws {
        let data = try #require(sampleMetadata.data(using: .utf8))
        let shows = try ArchiveMetadataParser(collectionYear: 2006).parse(data)

        #expect(shows.count == 2)
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
