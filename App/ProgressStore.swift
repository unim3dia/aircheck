import Foundation
import Observation

struct ArchiveProgress: Codable, Equatable {
    let completedShows: Int
    let totalShows: Int
    let completedSourceHours: Double
    let totalSourceHours: Double
    let latestCompletedShowID: String?
    let failedShows: [String]
    let generatedAt: Date?
    let activeShowID: String?
    let activeState: String?
    let activeChunksCompleted: Int
    let activeTotalChunks: Int

    var completionFraction: Double {
        guard totalShows > 0 else { return 0 }
        return min(max(Double(completedShows) / Double(totalShows), 0), 1)
    }

    static let empty = ArchiveProgress(
        completedShows: 0,
        totalShows: 179,
        completedSourceHours: 0,
        totalSourceHours: 0,
        latestCompletedShowID: nil,
        failedShows: [],
        generatedAt: nil,
        activeShowID: nil,
        activeState: nil,
        activeChunksCompleted: 0,
        activeTotalChunks: 0
    )
}

@Observable
final class ProgressStore {
    private(set) var snapshot: ArchiveProgress = .empty

    init() {
        reload()
    }

    func reload() {
        guard let url = Bundle.main.url(forResource: "archive_progress", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = decode(data) else { return }
        snapshot = decoded
    }

    private func decode(_ data: Data) -> ArchiveProgress? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ArchiveProgress.self, from: data)
    }
}
