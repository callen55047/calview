import Testing
import Foundation
@testable import calview

/// Covers Member profile derived values, backward-compatible decoding, and the
/// service round-trip (save/upsert + survive reload).
struct MemberProfileTests {

    private func makeService() -> (LocalCalendarService, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("calview-test-\(UUID().uuidString).json")
        return (LocalCalendarService(store: LocalStore(fileURL: url)), url)
    }
    private func cleanup(_ url: URL) { try? FileManager.default.removeItem(at: url) }

    @Test func displayNameAndInitials() {
        let p = MemberProfile(id: "m1", firstName: "Ada", lastName: "Lovelace")
        #expect(p.displayName == "Ada Lovelace")
        #expect(p.initials == "AL")

        let firstOnly = MemberProfile(id: "m2", firstName: "Grace")
        #expect(firstOnly.displayName == "Grace")
        #expect(firstOnly.initials == "G")

        let empty = MemberProfile(id: "m3")
        #expect(empty.displayName.isEmpty)
        #expect(empty.initials.isEmpty)
    }

    @Test func profileDecodesWhenOptionalKeysMissing() throws {
        // Only id is present; everything else should fall back to defaults.
        let json = #"{ "id": "m1" }"#.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let p = try decoder.decode(MemberProfile.self, from: json)
        #expect(p.id == "m1")
        #expect(p.firstName.isEmpty)
        #expect(p.email.isEmpty)
        #expect(p.avatarURL.isEmpty)
        #expect(!p.timeZoneIdentifier.isEmpty)
    }

    @Test func calendarDataDecodesWhenProfilesKeyMissing() throws {
        // A document written before `profiles` existed must still load.
        let json = """
        {
          "events": [],
          "legend": [],
          "shiftDays": [],
          "localUserId": "abc",
          "schemaVersion": 1
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let doc = try decoder.decode(CalendarData.self, from: json)
        #expect(doc.profiles.isEmpty)
        #expect(doc.localUserId == "abc")
    }

    @Test func saveProfileUpsertsAndSurvivesReload() async throws {
        let (service, url) = makeService(); defer { cleanup(url) }
        let memberId = try await service.currentMemberId()
        #expect(!memberId.isEmpty)

        try await service.saveProfile(MemberProfile(id: memberId, firstName: "Ada",
                                                    lastName: "L", email: "ada@x.com"))
        // Edit the same profile — should upsert, not duplicate.
        try await service.saveProfile(MemberProfile(id: memberId, firstName: "Ada",
                                                    lastName: "Lovelace", email: "ada@x.com"))

        let reopened = LocalCalendarService(store: LocalStore(fileURL: url))
        let profiles = try await reopened.fetchProfiles()
        #expect(profiles.count == 1)
        #expect(profiles.first?.lastName == "Lovelace")
        #expect(profiles.first?.id == memberId)
    }
}
