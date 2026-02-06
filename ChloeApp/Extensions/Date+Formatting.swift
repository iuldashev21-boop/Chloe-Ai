import Foundation

extension Date {
    private static let dayKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static var todayKey: String {
        dayKeyFormatter.string(from: Date())
    }

    var journalHeader: String {
        formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
}
