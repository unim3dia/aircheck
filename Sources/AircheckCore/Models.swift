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
