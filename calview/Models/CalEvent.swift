import Foundation

struct CalEvent: Identifiable, Codable {
    var id: String
    var title: String
    var startDate: Date
    var endDate: Date
    var colorKey: String
    /// Local User Id of the Member who authored this Event. Stamped by the service on first save.
    var createdBy: String = ""
    /// Last-write-wins clock for future sync (record-level merge by newest updatedAt).
    var updatedAt: Date = Date()
    /// Soft-delete tombstone: deleted Events are kept (filtered on fetch) so deletions can propagate when sync lands.
    var isDeleted: Bool = false
}
