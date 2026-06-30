import Foundation

/// A Member's shared profile: who they are on the calendar. Stored per-Member in
/// the synced document and edited only by its owner. `id` is the owner's Local
/// User Id, so a profile attaches to the same Member as the Events they author.
///
/// The avatar is a CDN URL (not stored image bytes); an empty URL renders a
/// placeholder. New fields here must decode on older documents — see `init(from:)`.
struct MemberProfile: Identifiable, Codable {
    var id: String
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var timeZoneIdentifier: String = TimeZone.current.identifier
    /// CDN link to the avatar image; empty means "show the placeholder".
    var avatarURL: String = ""
    /// Last-write-wins clock for future sync (record-level merge by newest updatedAt).
    var updatedAt: Date = Date()

    /// "First Last", trimmed; empty when no name has been set yet.
    var displayName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    /// Up to two initials from the name; empty when no name has been set.
    var initials: String {
        let parts = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return parts.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    init(id: String, firstName: String = "", lastName: String = "", email: String = "",
         timeZoneIdentifier: String = TimeZone.current.identifier, avatarURL: String = "",
         updatedAt: Date = Date()) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.timeZoneIdentifier = timeZoneIdentifier
        self.avatarURL = avatarURL
        self.updatedAt = updatedAt
    }

    // Decode the defaulted fields with `decodeIfPresent` so a profile written by
    // an older build (missing a field added later) still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        timeZoneIdentifier = try c.decodeIfPresent(String.self, forKey: .timeZoneIdentifier)
            ?? TimeZone.current.identifier
        avatarURL = try c.decodeIfPresent(String.self, forKey: .avatarURL) ?? ""
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
