import Foundation

struct CalEvent: Identifiable, Codable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var colorKey: String
    /// Free-text place for this Event (e.g. a shift's worksite). Empty when unset.
    var location: String = ""
    /// Local User Id of the Member who authored this Event. Stamped by the service on first save.
    var createdBy: String = ""
    /// Last-write-wins clock for future sync (record-level merge by newest updatedAt).
    var updatedAt: Date = Date()
    /// Soft-delete tombstone: deleted Events are kept (filtered on fetch) so deletions can propagate when sync lands.
    var isDeleted: Bool = false

    init(id: String, title: String, startDate: Date, endDate: Date, colorKey: String,
         location: String = "", createdBy: String = "", updatedAt: Date = Date(),
         isDeleted: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.colorKey = colorKey
        self.location = location
        self.createdBy = createdBy
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
    }

    // Synthesized Decodable does NOT backfill defaults for missing keys, so a
    // document written before a defaulted field existed would fail to decode and
    // take the whole store down with it. Decode the optional/defaulted fields
    // with `decodeIfPresent` so older on-disk Events still load.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        startDate = try c.decode(Date.self, forKey: .startDate)
        endDate = try c.decode(Date.self, forKey: .endDate)
        colorKey = try c.decode(String.self, forKey: .colorKey)
        location = try c.decodeIfPresent(String.self, forKey: .location) ?? ""
        createdBy = try c.decodeIfPresent(String.self, forKey: .createdBy) ?? ""
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        isDeleted = try c.decodeIfPresent(Bool.self, forKey: .isDeleted) ?? false
    }
}
