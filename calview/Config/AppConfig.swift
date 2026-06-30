import Foundation

enum AppConfig {
    private static let offlineKey = "isOfflineMode"

    /// Deliberate intent: when true, the app uses on-device storage only and never
    /// contacts the backend. Read once at startup to pick the data source; changes
    /// take effect on the next launch (live service-swapping is unsupported).
    ///
    /// This is distinct from future connectivity-driven sync degradation — a dropped
    /// network must never flip this flag. Graceful offline-when-online behavior will
    /// be owned by the local-first sync layer, not by this setting.
    static var isOfflineMode: Bool {
        get { UserDefaults.standard.object(forKey: offlineKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: offlineKey) }
    }
}

/// Which preset a shift Event uses. `none` means an ordinary Event (no preset).
enum ShiftType: String, CaseIterable, Identifiable {
    case none, day, night
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none:  return "None"
        case .day:   return "Day"
        case .night: return "Night"
        }
    }
    /// The reserved Category id a shift Event of this type points at (nil for `.none`).
    var categoryId: String? {
        switch self {
        case .none:  return nil
        case .day:   return ShiftWork.dayCategoryId
        case .night: return ShiftWork.nightCategoryId
        }
    }
    /// Reverse lookup: which preset (if any) a Category id represents.
    static func from(categoryId: String) -> ShiftType {
        switch categoryId {
        case ShiftWork.dayCategoryId:   return .day
        case ShiftWork.nightCategoryId: return .night
        default:                        return .none
        }
    }
}

/// Constants and pure helpers for the Shift Work feature, shared by SettingsView
/// and EventDetailView so there is one source of truth. Preferences themselves
/// live in UserDefaults via `@AppStorage` (device-local, like Offline Mode); the
/// day/night colors live on two reserved Categories in the Legend so shift Events
/// color the same way every other Event does.
enum ShiftWork {
    // Reserved Category ids (stable so Events can reference them across launches).
    static let dayCategoryId = "shift-day"
    static let nightCategoryId = "shift-night"

    // Default Category colors (match the sun/moon Shift-Day overlay palette).
    static let defaultDayHex = "#F1C40F"
    static let defaultNightHex = "#5B2C91"

    // @AppStorage keys.
    static let enabledKey = "shiftWorkEnabled"
    static let dayStartKey = "shiftDayStartMinutes"
    static let dayEndKey = "shiftDayEndMinutes"
    static let nightStartKey = "shiftNightStartMinutes"
    static let nightEndKey = "shiftNightEndMinutes"
    static let defaultLocationKey = "shiftDefaultLocation"

    // Default times, stored as minutes since midnight.
    static let defaultDayStart = 7 * 60    // 07:00
    static let defaultDayEnd = 19 * 60     // 19:00
    static let defaultNightStart = 19 * 60 // 19:00
    static let defaultNightEnd = 7 * 60    // 07:00 (next day)

    /// Builds the start/end Dates for a shift `type` anchored on `date`. Returns
    /// nil for `.none`. If end ≤ start (a night shift crossing midnight), the end
    /// rolls over to the next day.
    static func window(for type: ShiftType,
                       on date: Date,
                       dayStart: Int, dayEnd: Int,
                       nightStart: Int, nightEnd: Int) -> (start: Date, end: Date)? {
        let cal = Calendar.current
        let base = cal.startOfDay(for: date)
        let (startMin, endMin): (Int, Int)
        switch type {
        case .none:  return nil
        case .day:   (startMin, endMin) = (dayStart, dayEnd)
        case .night: (startMin, endMin) = (nightStart, nightEnd)
        }
        let start = cal.date(byAdding: .minute, value: startMin, to: base)!
        var end = cal.date(byAdding: .minute, value: endMin, to: base)!
        if end <= start { end = cal.date(byAdding: .day, value: 1, to: end)! }
        return (start, end)
    }
}
