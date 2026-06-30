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
