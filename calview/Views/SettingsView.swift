import SwiftUI

struct SettingsView: View {
    @AppStorage("isOfflineMode") private var isOfflineMode = true

    var body: some View {
        NavigationStack {
            List {
                Section("Data") {
                    Toggle("Offline Mode", isOn: $isOfflineMode)
                }
                Section {
                    Text(isOfflineMode
                         ? "All data stays on this device and survives restarts. Restart to apply changes."
                         : "Will connect to the backend on next launch. Restart to apply changes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
