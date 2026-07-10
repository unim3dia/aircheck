import Foundation

public struct Show: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let date: Date
    public let duration: TimeInterval
    public let audioURL: URL
    public var topics: [Topic]
    public var transcript: [TranscriptSegment]

    public init(
        id: String,
        date: Date,
        duration: TimeInterval,
        audioURL: URL,
        topics: [Topic] = [],
        transcript: [TranscriptSegment] = []
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.audioURL = audioURL
        self.topics = topics
        self.transcript = transcript
    }
}

public struct Topic: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let startTime: TimeInterval
    public let imageURL: URL?

    public init(id: String, title: String, summary: String, startTime: TimeInterval, imageURL: URL? = nil) {
        self.id = id
        self.title = title
        self.summary = summary
        self.startTime = startTime
        self.imageURL = imageURL
    }
}

public struct TranscriptSegment: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let startTime: TimeInterval
    public let endTime: TimeInterval
    public let speaker: String?
    public let text: String

    public init(id: Int, startTime: TimeInterval, endTime: TimeInterval, speaker: String?, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.speaker = speaker
        self.text = text
    }
}

public struct SearchHit: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable { case topic, transcript }

    public let id: String
    public let showID: Show.ID
    public let time: TimeInterval
    public let title: String
    public let excerpt: String
    public let kind: Kind

    public init(id: String, showID: Show.ID, time: TimeInterval, title: String, excerpt: String, kind: Kind) {
        self.id = id
        self.showID = showID
        self.time = time
        self.title = title
        self.excerpt = excerpt
        self.kind = kind
    }
}

public struct ListeningHistoryEntry: Identifiable, Codable, Hashable, Sendable {
    public var id: Show.ID { showID }
    public let showID: Show.ID
    public private(set) var lastPosition: TimeInterval
    public private(set) var furthestPosition: TimeInterval
    public private(set) var secondsListened: TimeInterval
    public let duration: TimeInterval
    public private(set) var lastListenedAt: Date

    public var completionFraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(furthestPosition / duration, 0), 1)
    }

    public init(
        showID: Show.ID,
        lastPosition: TimeInterval,
        furthestPosition: TimeInterval,
        secondsListened: TimeInterval,
        duration: TimeInterval,
        lastListenedAt: Date
    ) {
        self.showID = showID
        self.duration = max(duration, 0)
        self.lastPosition = min(max(lastPosition, 0), self.duration)
        self.furthestPosition = min(max(furthestPosition, 0), self.duration)
        self.secondsListened = max(secondsListened, 0)
        self.lastListenedAt = lastListenedAt
    }

    public mutating func record(position: TimeInterval, listenedDelta: TimeInterval, at date: Date) {
        let position = min(max(position, 0), duration)
        lastPosition = position
        furthestPosition = max(furthestPosition, position)
        secondsListened += max(listenedDelta, 0)
        lastListenedAt = date
    }

    public static func mostRecentFirst(_ entries: [Self]) -> [Self] {
        entries.sorted { $0.lastListenedAt > $1.lastListenedAt }
    }
}
