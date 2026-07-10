import Foundation

public struct ArchiveMetadataParser: Sendable {
    public enum ParseError: Error { case missingIdentifier }

    private let collectionYear: Int

    public init(collectionYear: Int) {
        self.collectionYear = collectionYear
    }

    public func parse(_ data: Data) throws -> [Show] {
        let response = try JSONDecoder().decode(ArchiveResponse.self, from: data)
        guard !response.metadata.identifier.isEmpty else { throw ParseError.missingIdentifier }

        return response.files.compactMap { file in
            makeShow(file: file, identifier: response.metadata.identifier)
        }
        .sorted { lhs, rhs in
            lhs.date == rhs.date ? lhs.id < rhs.id : lhs.date < rhs.date
        }
    }

    private func makeShow(file: ArchiveFile, identifier: String) -> Show? {
        guard file.name.lowercased().hasSuffix(".mp3"),
              let duration = TimeInterval(file.length),
              let parts = dateParts(in: file.name),
              let date = DateComponents(
                calendar: Calendar(identifier: .gregorian),
                timeZone: TimeZone(secondsFromGMT: 0),
                year: collectionYear,
                month: parts.month,
                day: parts.day
              ).date
        else { return nil }

        let dateID = String(format: "%04d-%02d-%02d", collectionYear, parts.month, parts.day)
        let suffix = file.name.localizedCaseInsensitiveContains("Artie_Roast") ? "-artie-roast" : ""
        guard let encodedName = file.name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://archive.org/download/\(identifier)/\(encodedName)")
        else { return nil }

        return Show(id: dateID + suffix, date: date, duration: duration, audioURL: url)
    }

    private func dateParts(in filename: String) -> (month: Int, day: Int)? {
        let pattern = #"_(\d{2})-(\d{2})-(\d{2})_"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: filename, range: NSRange(filename.startIndex..., in: filename)),
              let monthRange = Range(match.range(at: 1), in: filename),
              let dayRange = Range(match.range(at: 2), in: filename),
              let month = Int(filename[monthRange]),
              let day = Int(filename[dayRange]),
              (1...12).contains(month),
              (1...31).contains(day)
        else { return nil }
        return (month, day)
    }
}

private struct ArchiveResponse: Decodable {
    let metadata: ArchiveMetadata
    let files: [ArchiveFile]
}

private struct ArchiveMetadata: Decodable { let identifier: String }

private struct ArchiveFile: Decodable {
    let name: String
    let length: String

    private enum CodingKeys: String, CodingKey { case name, length }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        length = (try? container.decode(String.self, forKey: .length)) ?? ""
    }
}
