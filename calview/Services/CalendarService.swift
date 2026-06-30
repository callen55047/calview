import Foundation

protocol CalendarService {
    func fetchEvents(for month: Date) async throws -> [CalEvent]
    func saveEvent(_ event: CalEvent) async throws
    func deleteEvent(id: String) async throws
    func fetchLegend() async throws -> [LegendEntry]
    func saveLegend(_ entries: [LegendEntry]) async throws
    func fetchShiftDays(for month: Date) async throws -> [ShiftDay]
    func toggleShiftDay(date: Date) async throws
    /// The Local User Id identifying this install's Member (used to find "my" profile).
    func currentMemberId() async throws -> String
    func fetchProfiles() async throws -> [MemberProfile]
    func saveProfile(_ profile: MemberProfile) async throws
}
