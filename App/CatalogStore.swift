import AircheckCore
import Foundation
import Observation

@Observable
final class CatalogStore {
    private(set) var shows: [Show] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let metadataURL = URL(string: "https://archive.org/metadata/howard-stern-24k-complete-2006")!
    private let parser = ArchiveMetadataParser(collectionYear: 2006)

    var months: [Int] {
        Array(Set(shows.map { Calendar(identifier: .gregorian).component(.month, from: $0.date) })).sorted()
    }

    func shows(in month: Int) -> [Show] {
        shows.filter { Calendar(identifier: .gregorian).component(.month, from: $0.date) == month }
    }

    func show(id: Show.ID) -> Show? { shows.first { $0.id == id } }

    func load() async {
        guard shows.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await metadataData()
            var parsed = try parser.parse(data)
            applyBundledEnrichments(to: &parsed)
            shows = parsed
            errorMessage = nil
        } catch {
            errorMessage = "The archive could not be reached. Check your connection and try again."
        }
    }

    private func metadataData() async throws -> Data {
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: "stern-2006-metadata.json")
        if let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path),
           let modified = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) < 86_400,
           let cached = try? Data(contentsOf: cacheURL) {
            return cached
        }
        let (data, response) = try await URLSession.shared.data(from: metadataURL)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        try? data.write(to: cacheURL, options: .atomic)
        return data
    }

    private func applyBundledEnrichments(to shows: inout [Show]) {
        guard let url = Bundle.main.url(forResource: "enrichments", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let enrichments = try? JSONDecoder().decode([Enrichment].self, from: data)
        else { return }

        let byID = Dictionary(uniqueKeysWithValues: enrichments.map { ($0.showID, $0) })
        for index in shows.indices {
            guard let enrichment = byID[shows[index].id] else { continue }
            shows[index].topics = enrichment.topics
            shows[index].transcript = enrichment.transcript
        }
    }
}

private struct Enrichment: Decodable {
    let showID: String
    let topics: [Topic]
    let transcript: [TranscriptSegment]
}
