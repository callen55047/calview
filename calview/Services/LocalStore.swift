import Foundation

/// The entire on-device calendar, serialized as one JSON document.
///
/// This is the durable source of truth in Offline Mode and the cache the future
/// sync layer will reconcile against. New sync-related fields here must default
/// so older documents decode without migration (see `schemaVersion`).
struct CalendarData: Codable {
    var events: [CalEvent] = []
    var legend: [LegendEntry] = []
    var shiftDays: [ShiftDay] = []
    /// Stable Member identity for this install, generated on first launch and stamped on authored Events.
    var localUserId: String = UUID().uuidString
    /// Watermark for the future sync engine: records with `updatedAt > lastSyncedAt` are pending.
    /// Nil until the first successful sync, so everything reads as pending. (Engine deferred.)
    var lastSyncedAt: Date? = nil
    /// Bump when the document shape changes in a way that needs migration.
    var schemaVersion: Int = 1
}

/// First-launch defaults. Only the Legend is seeded so Events can be created
/// immediately (the Event editor requires a Category); no sample Events or Shift Days.
enum Seed {
    static let defaultLegend: [LegendEntry] = [
        LegendEntry(id: "doctor",    label: "Doctor",     hex: "#E74C3C"),
        LegendEntry(id: "gym",       label: "Gym",        hex: "#2ECC71"),
        LegendEntry(id: "work",      label: "Work",       hex: "#3498DB"),
        LegendEntry(id: "family",    label: "Family",     hex: "#9B59B6"),
        LegendEntry(id: "travel",    label: "Travel",     hex: "#F39C12"),
        LegendEntry(id: "datenight", label: "Date Night", hex: "#E91E63"),
    ]
}

/// Serializes all access to the on-disk calendar document. No in-memory cache:
/// `load()` decodes the file on each call and `mutate` is a read-modify-write,
/// so disk and any UI copy can never silently drift. At family scale the file
/// is tiny, so the extra reads are immaterial.
actor LocalStore {
    private let fileURL: URL

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let dir = try! FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true)
            self.fileURL = dir.appendingPathComponent("calview-store.json")
        }
    }

    /// Loads the document, seeding it on first launch (file absent).
    func load() throws -> CalendarData {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let seeded = CalendarData(legend: Seed.defaultLegend)
            try persist(seeded)
            return seeded
        }
        var doc = try decoder.decode(CalendarData.self, from: Data(contentsOf: fileURL))
        if doc.localUserId.isEmpty {
            doc.localUserId = UUID().uuidString
            try persist(doc)
        }
        return doc
    }

    /// Read-modify-write the document atomically.
    func mutate(_ body: (inout CalendarData) -> Void) throws {
        var doc = try load()
        body(&doc)
        try persist(doc)
    }

    private func persist(_ doc: CalendarData) throws {
        let data = try encoder.encode(doc)
        try data.write(to: fileURL, options: .atomic)
    }
}
