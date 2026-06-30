import Foundation

/// In-memory `CalendarService` double for tests and SwiftUI previews. Not wired into
/// the app — Offline Mode uses `LocalCalendarService`. Mutations are not persisted.
final class MockCalendarService: CalendarService {
    private var events: [CalEvent] = Mock.events
    private var legend: [LegendEntry] = Mock.legend
    private var shiftDays: [ShiftDay] = Mock.shiftDays

    func fetchEvents(for month: Date) async throws -> [CalEvent] {
        events.filter { Calendar.current.isDate($0.startDate, equalTo: month, toGranularity: .month) }
    }

    func saveEvent(_ event: CalEvent) async throws {
        if let idx = events.firstIndex(where: { $0.id == event.id }) {
            events[idx] = event
        } else {
            events.append(event)
        }
    }

    func deleteEvent(id: String) async throws {
        events.removeAll { $0.id == id }
    }

    func fetchLegend() async throws -> [LegendEntry] { legend }

    func saveLegend(_ entries: [LegendEntry]) async throws { legend = entries }

    func fetchShiftDays(for month: Date) async throws -> [ShiftDay] {
        shiftDays.filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func toggleShiftDay(date: Date) async throws {
        let id = ShiftDay.dayId(for: date)
        if let idx = shiftDays.firstIndex(where: { $0.id == id }) {
            shiftDays[idx].isNightShift.toggle()
        } else {
            shiftDays.append(ShiftDay(id: id, date: Calendar.current.startOfDay(for: date), isNightShift: true))
        }
    }
}

private enum Mock {
    static let legend: [LegendEntry] = [
        LegendEntry(id: "doctor",   label: "Doctor",     hex: "#E74C3C"),
        LegendEntry(id: "gym",      label: "Gym",        hex: "#2ECC71"),
        LegendEntry(id: "work",     label: "Work",       hex: "#3498DB"),
        LegendEntry(id: "family",   label: "Family",     hex: "#9B59B6"),
        LegendEntry(id: "travel",   label: "Travel",     hex: "#F39C12"),
        LegendEntry(id: "datenight",label: "Date Night", hex: "#E91E63"),
    ]

    static let events: [CalEvent] = [
        event("Doctor Appointment", 2026, 6, 5,  9, 0,  "doctor"),
        event("Gym",                2026, 6, 8,  18, 0, "gym"),
        event("Work Meeting",       2026, 6, 10, 10, 0, "work"),
        event("Family Dinner",      2026, 6, 14, 19, 0, "family"),
        event("Date Night",         2026, 6, 15, 20, 0, "datenight"),
        event("Gym",                2026, 6, 17, 18, 0, "gym"),
        event("Sprint Planning",    2026, 6, 19, 10, 0, "work"),
        event("Doctor Follow-up",   2026, 6, 22, 14, 0, "doctor"),
        event("Travel Start",       2026, 6, 25, 8,  0, "travel"),
        event("Travel Return",      2026, 6, 28, 18, 0, "travel"),
        event("Family Barbecue",    2026, 7, 4,  14, 0, "family"),
        event("Gym",                2026, 7, 5,  9,  0, "gym"),
        event("Date Night",         2026, 7, 11, 19, 0, "datenight"),
        event("Doctor Checkup",     2026, 7, 15, 11, 0, "doctor"),
        event("Work All-Hands",     2026, 7, 20, 15, 0, "work"),
    ]

    static let shiftDays: [ShiftDay] = nightShifts(
        (2026, 6, 3), (2026, 6, 6), (2026, 6, 7),
        (2026, 6, 10), (2026, 6, 17), (2026, 6, 18),
        (2026, 6, 19), (2026, 6, 24), (2026, 6, 25)
    )

    private static func event(_ title: String, _ y: Int, _ m: Int, _ d: Int,
                               _ h: Int, _ min: Int, _ colorKey: String) -> CalEvent {
        let start = date(y, m, d, h, min)
        let end = Calendar.current.date(byAdding: .hour, value: 1, to: start)!
        return CalEvent(id: UUID().uuidString, title: title, startDate: start,
                        endDate: end, colorKey: colorKey, createdBy: "preview")
    }

    private static func nightShifts(_ tuples: (Int, Int, Int)...) -> [ShiftDay] {
        tuples.map { (y, m, d) in
            let dt = date(y, m, d, 0, 0)
            return ShiftDay(id: ShiftDay.dayId(for: dt), date: dt, isNightShift: true)
        }
    }

    private static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }
}
