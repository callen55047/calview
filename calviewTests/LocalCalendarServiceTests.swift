import Testing
import Foundation
@testable import calview

/// Exercises the offline persistence layer against a throwaway file so each test
/// starts from a clean, seeded store.
struct LocalCalendarServiceTests {

    private func makeService() -> (LocalCalendarService, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("calview-test-\(UUID().uuidString).json")
        return (LocalCalendarService(store: LocalStore(fileURL: url)), url)
    }

    private func cleanup(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    @Test func seedsDefaultLegendOnFirstLaunch() async throws {
        let (service, url) = makeService(); defer { cleanup(url) }
        let legend = try await service.fetchLegend()
        #expect(legend.count == Seed.defaultLegend.count)
        let events = try await service.fetchEvents(for: Date())
        #expect(events.isEmpty)
    }

    @Test func savedEventSurvivesReload() async throws {
        let (service, url) = makeService(); defer { cleanup(url) }
        let month = Date()
        let event = CalEvent(id: "e1", title: "Dentist", startDate: month,
                             endDate: month.addingTimeInterval(3600), colorKey: "doctor")
        try await service.saveEvent(event)

        // Reopen the same file with a fresh service — simulates an app restart.
        let reopened = LocalCalendarService(store: LocalStore(fileURL: url))
        let events = try await reopened.fetchEvents(for: month)
        #expect(events.count == 1)
        #expect(events.first?.title == "Dentist")
    }

    @Test func newEventIsStampedWithLocalUserId() async throws {
        let (_, url) = makeService(); defer { cleanup(url) }
        let store = LocalStore(fileURL: url)
        let stamped = LocalCalendarService(store: store)
        let month = Date()
        try await stamped.saveEvent(CalEvent(id: "e1", title: "Gym", startDate: month,
                                             endDate: month, colorKey: "gym"))
        let expectedId = try await store.load().localUserId
        let event = try await stamped.fetchEvents(for: month).first
        #expect(event?.createdBy == expectedId)
        #expect(!(expectedId.isEmpty))
    }

    @Test func deleteSoftDeletesAndHidesEvent() async throws {
        let (_, url) = makeService(); defer { cleanup(url) }
        let store = LocalStore(fileURL: url)
        let svc = LocalCalendarService(store: store)
        let month = Date()
        try await svc.saveEvent(CalEvent(id: "e1", title: "Travel", startDate: month,
                                         endDate: month, colorKey: "travel"))
        try await svc.deleteEvent(id: "e1")

        // Hidden from fetch...
        #expect(try await svc.fetchEvents(for: month).isEmpty)
        // ...but retained as a tombstone in the document.
        let raw = try await store.load().events
        #expect(raw.count == 1)
        #expect(raw.first?.isDeleted == true)
    }
}
