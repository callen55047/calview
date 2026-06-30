import Foundation

/// Offline-first `CalendarService` backed by the on-device `LocalStore`.
///
/// Behavior mirrors the old in-memory mock, with two additions that prepare for
/// a future shared-cloud sync without a data migration:
///   - every write stamps `updatedAt` (record-level last-write-wins; see ADR 0001)
///   - `deleteEvent` soft-deletes (tombstone) instead of removing the record
/// Authorship is stamped here, in the service layer, so views never need the
/// Local User Id.
final class LocalCalendarService: CalendarService {
    private let store: LocalStore

    init(store: LocalStore = LocalStore()) {
        self.store = store
    }

    func fetchEvents(for month: Date) async throws -> [CalEvent] {
        try await store.load().events
            .filter { !$0.isDeleted }
            .filter { Calendar.current.isDate($0.startDate, equalTo: month, toGranularity: .month) }
    }

    func saveEvent(_ event: CalEvent) async throws {
        try await store.mutate { doc in
            var e = event
            e.updatedAt = Date()
            if e.createdBy.isEmpty { e.createdBy = doc.localUserId }
            if let idx = doc.events.firstIndex(where: { $0.id == e.id }) {
                doc.events[idx] = e
            } else {
                doc.events.append(e)
            }
        }
    }

    func deleteEvent(id: String) async throws {
        try await store.mutate { doc in
            if let idx = doc.events.firstIndex(where: { $0.id == id }) {
                doc.events[idx].isDeleted = true
                doc.events[idx].updatedAt = Date()
            }
        }
    }

    func fetchLegend() async throws -> [LegendEntry] {
        try await store.load().legend
    }

    func saveLegend(_ entries: [LegendEntry]) async throws {
        try await store.mutate { $0.legend = entries }
    }

    func fetchShiftDays(for month: Date) async throws -> [ShiftDay] {
        try await store.load().shiftDays
            .filter { Calendar.current.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    func toggleShiftDay(date: Date) async throws {
        let id = ShiftDay.dayId(for: date)
        try await store.mutate { doc in
            if let idx = doc.shiftDays.firstIndex(where: { $0.id == id }) {
                doc.shiftDays[idx].isNightShift.toggle()
                doc.shiftDays[idx].updatedAt = Date()
            } else {
                doc.shiftDays.append(ShiftDay(
                    id: id,
                    date: Calendar.current.startOfDay(for: date),
                    isNightShift: true))
            }
        }
    }
}
