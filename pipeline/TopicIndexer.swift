import Foundation
import FoundationModels

@Generable(description: "An editorial topic card for a long-form radio archive")
struct EditorialTopic {
    @Guide(description: "A vivid factual headline, at most eight words, using names from the transcript")
    var title: String

    @Guide(description: "One factual sentence explaining what the speakers discuss, without inventing details")
    var summary: String
}

struct Input: Decodable {
    let start_time: Double
    let text: String
}

@main
struct TopicIndexer {
    static func main() async throws {
        let input = try JSONDecoder().decode(Input.self, from: FileHandle.standardInput.readDataToEndOfFile())
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            FileHandle.standardError.write(Data("Apple on-device model unavailable: \(model.availability)\n".utf8))
            Foundation.exit(69)
        }

        let session = LanguageModelSession(model: model, instructions: """
        You are the editorial indexer for a historic radio archive. Describe only the supplied transcript.
        Never infer identity from voice. Preserve the transcript's spelling of names. Avoid sensationalism.
        """)
        let response = try await session.respond(
            to: "Create one topic card for this transcript window:\n\n\(input.text)",
            generating: EditorialTopic.self,
            options: GenerationOptions(temperature: 0.2)
        )
        let output: [String: Any] = [
            "startTime": input.start_time,
            "title": response.content.title,
            "summary": response.content.summary,
        ]
        let data = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}
