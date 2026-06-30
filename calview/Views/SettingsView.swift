import SwiftUI

struct SettingsView: View {
    @Environment(CalendarStore.self) private var store

    @AppStorage("isOfflineMode") private var isOfflineMode = true

    @AppStorage(ShiftWork.enabledKey) private var shiftWorkEnabled = false
    @AppStorage(ShiftWork.dayStartKey) private var dayStart = ShiftWork.defaultDayStart
    @AppStorage(ShiftWork.dayEndKey) private var dayEnd = ShiftWork.defaultDayEnd
    @AppStorage(ShiftWork.nightStartKey) private var nightStart = ShiftWork.defaultNightStart
    @AppStorage(ShiftWork.nightEndKey) private var nightEnd = ShiftWork.defaultNightEnd
    @AppStorage(ShiftWork.defaultLocationKey) private var defaultLocation = ""

    /// Bridges a minutes-since-midnight `Int` store value to the `Date` a
    /// `.hourAndMinute` DatePicker needs (anchored on an arbitrary day).
    private func timeBinding(_ minutes: Binding<Int>) -> Binding<Date> {
        let base = Calendar.current.startOfDay(for: Date())
        return Binding(
            get: { Calendar.current.date(byAdding: .minute, value: minutes.wrappedValue, to: base)! },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                minutes.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
            }
        )
    }

    /// Edits a reserved shift Category's color in place. Reads from the Legend and
    /// writes back through the store so shift Events recolor like any Category.
    private func shiftColorBinding(_ id: String, fallbackHex: String) -> Binding<Color> {
        Binding(
            get: { store.legendEntry(for: id)?.color ?? Color(hex: fallbackHex) },
            set: { newColor in
                var updated = store.legend
                if let idx = updated.firstIndex(where: { $0.id == id }) {
                    updated[idx].hex = newColor.hexString
                    Task { await store.saveLegend(updated) }
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ProfileEditView()
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(profile: store.myProfile, size: 48)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.myProfile.displayName.isEmpty
                                     ? "Set up your profile" : store.myProfile.displayName)
                                    .font(.body)
                                if !store.myProfile.email.isEmpty {
                                    Text(store.myProfile.email)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

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

                Section("Shift Work") {
                    Toggle("Shift Work", isOn: $shiftWorkEnabled)
                }

                if shiftWorkEnabled {
                    Section("Shift Colors") {
                        ColorPicker("Day Shift",
                                    selection: shiftColorBinding(ShiftWork.dayCategoryId,
                                                                 fallbackHex: ShiftWork.defaultDayHex),
                                    supportsOpacity: false)
                        ColorPicker("Night Shift",
                                    selection: shiftColorBinding(ShiftWork.nightCategoryId,
                                                                 fallbackHex: ShiftWork.defaultNightHex),
                                    supportsOpacity: false)
                    }

                    Section("Day Shift Hours") {
                        DatePicker("Start", selection: timeBinding($dayStart),
                                   displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: timeBinding($dayEnd),
                                   displayedComponents: .hourAndMinute)
                    }

                    Section("Night Shift Hours") {
                        DatePicker("Start", selection: timeBinding($nightStart),
                                   displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: timeBinding($nightEnd),
                                   displayedComponents: .hourAndMinute)
                    }

                    Section("Default Location") {
                        TextField("e.g. Riverside Hospital", text: $defaultLocation)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .task {
            if store.legend.isEmpty { await store.loadMonth() }
            if shiftWorkEnabled { await store.ensureShiftCategories() }
        }
        .onChange(of: shiftWorkEnabled) { _, enabled in
            if enabled { Task { await store.ensureShiftCategories() } }
        }
    }
}
