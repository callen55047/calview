import SwiftUI

@main
struct calviewApp: App {
    @State private var store = makeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}

private func makeStore() -> CalendarStore {
    // Offline Mode is read once at startup. In offline mode the backend service is
    // never even instantiated, so the no-network guarantee is structural.
    // Future: the online branch will wrap local + remote in a local-first
    // SyncingCalendarService(local:remote:) so offline edits sync when connectivity returns.
    let service: any CalendarService = AppConfig.isOfflineMode
        ? LocalCalendarService()
        : FirebaseCalendarService()
    return CalendarStore(service: service)
}
