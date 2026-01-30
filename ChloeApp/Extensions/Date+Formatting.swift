import Foundation

extension Date {
    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var journalHeader: String {
        formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}
