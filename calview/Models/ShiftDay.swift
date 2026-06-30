import Foundation

struct ShiftDay: Identifiable, Codable {
    var id: String
    var date: Date
    var isNightShift: Bool
    /// Last-write-wins clock for future sync.
    var updatedAt: Date = Date()

    static func dayId(for date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        return fmt.string(from: Calendar.current.startOfDay(for: date))
    }
}
