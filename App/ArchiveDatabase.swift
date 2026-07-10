import AircheckCore
import Foundation
import SQLite3

final class ArchiveDatabase {
    private var database: OpaquePointer?

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "archive", withExtension: "sqlite") else { return }
        if sqlite3_open_v2(url.path, &database, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            database = nil
        }
    }

    var isAvailable: Bool { database != nil }

    func topics(showID: String) -> [Topic] {
        query(
            "SELECT id, title, summary, start_time, image_url FROM topics WHERE show_id = ? ORDER BY start_time",
            bindings: [showID]
        ) { statement in
            Topic(
                id: text(statement, 0),
                title: text(statement, 1),
                summary: text(statement, 2),
                startTime: sqlite3_column_double(statement, 3),
                imageURL: optionalText(statement, 4).flatMap(URL.init(string:))
            )
        }
    }

    func transcript(showID: String) -> [TranscriptSegment] {
        query(
            "SELECT segment_id, start_time, end_time, speaker, text FROM segments WHERE show_id = ? ORDER BY segment_id",
            bindings: [showID]
        ) { statement in
            TranscriptSegment(
                id: Int(sqlite3_column_int64(statement, 0)),
                startTime: sqlite3_column_double(statement, 1),
                endTime: sqlite3_column_double(statement, 2),
                speaker: optionalText(statement, 3),
                text: text(statement, 4)
            )
        }
    }

    func search(_ rawQuery: String, limit: Int = 100) -> [SearchHit] {
        let match = ftsQuery(rawQuery)
        guard !match.isEmpty else { return [] }
        let topicSQL = """
            SELECT show_id, CAST(start_time AS REAL), title, summary, topic_id
            FROM topic_fts WHERE topic_fts MATCH ? LIMIT ?
            """
        let topicHits: [SearchHit] = query(topicSQL, bindings: [match, limit]) { statement in
            SearchHit(
                id: text(statement, 0) + "-topic-" + text(statement, 4),
                showID: text(statement, 0),
                time: sqlite3_column_double(statement, 1),
                title: text(statement, 2),
                excerpt: text(statement, 3),
                kind: .topic
            )
        }
        guard topicHits.count < limit else { return topicHits }

        let transcriptSQL = """
            SELECT f.show_id, s.start_time, COALESCE(s.speaker, 'Transcript'), s.text, f.segment_id
            FROM transcript_fts f
            JOIN segments s ON s.show_id = f.show_id AND s.segment_id = CAST(f.segment_id AS INTEGER)
            WHERE transcript_fts MATCH ? LIMIT ?
            """
        let transcriptHits: [SearchHit] = query(transcriptSQL, bindings: [match, limit - topicHits.count]) { statement in
            SearchHit(
                id: text(statement, 0) + "-transcript-" + text(statement, 4),
                showID: text(statement, 0),
                time: sqlite3_column_double(statement, 1),
                title: text(statement, 2),
                excerpt: text(statement, 3),
                kind: .transcript
            )
        }
        return topicHits + transcriptHits
    }

    private func ftsQuery(_ raw: String) -> String {
        let tokens = raw.split { !$0.isLetter && !$0.isNumber }.prefix(8)
        return tokens.map { token in
            let escaped = token.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\"*"
        }.joined(separator: " AND ")
    }

    private func query<T>(_ sql: String, bindings: [Any], row: (OpaquePointer) -> T) -> [T] {
        guard let database else { return [] }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK, let statement else { return [] }
        defer { sqlite3_finalize(statement) }
        for (offset, value) in bindings.enumerated() {
            let index = Int32(offset + 1)
            if let string = value as? String {
                sqlite3_bind_text(statement, index, string, -1, SQLITE_TRANSIENT)
            } else if let integer = value as? Int {
                sqlite3_bind_int64(statement, index, sqlite3_int64(integer))
            }
        }
        var values: [T] = []
        while sqlite3_step(statement) == SQLITE_ROW { values.append(row(statement)) }
        return values
    }
}

private func text(_ statement: OpaquePointer, _ column: Int32) -> String {
    guard let value = sqlite3_column_text(statement, column) else { return "" }
    return String(cString: value)
}

private func optionalText(_ statement: OpaquePointer, _ column: Int32) -> String? {
    sqlite3_column_type(statement, column) == SQLITE_NULL ? nil : text(statement, column)
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
