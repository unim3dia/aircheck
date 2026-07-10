import AircheckCore
import Foundation

extension Show {
    var formattedDate: String { date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()) }
    var shortDate: String { date.formatted(.dateTime.month(.abbreviated).day()) }
    var dayNumber: String { date.formatted(.dateTime.day(.twoDigits)) }
    var weekday: String { date.formatted(.dateTime.weekday(.abbreviated)).uppercased() }
    var displayTitle: String { id.hasSuffix("artie-roast") ? "The Artie Lange Roast" : "The Howard Stern Show" }
    var durationText: String { duration.aircheckDuration }
}

extension TimeInterval {
    var aircheckDuration: String {
        guard isFinite else { return "—" }
        let total = max(Int(self), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        return hours > 0 ? "\(hours) hr \(minutes) min" : "\(minutes) min"
    }

    var timecode: String {
        guard isFinite else { return "00:00" }
        let total = max(Int(self), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
    }
}
