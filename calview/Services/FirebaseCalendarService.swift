import Foundation

// ponytail: stub — add firebase-ios-sdk via Xcode SPM then implement for prod
final class FirebaseCalendarService: CalendarService {
    func fetchEvents(for month: Date) async throws -> [CalEvent] { [] }
    func saveEvent(_ event: CalEvent) async throws {}
    func deleteEvent(id: String) async throws {}
    func fetchLegend() async throws -> [LegendEntry] { [] }
    func saveLegend(_ entries: [LegendEntry]) async throws {}
    func fetchShiftDays(for month: Date) async throws -> [ShiftDay] { [] }
    func toggleShiftDay(date: Date) async throws {}
}
