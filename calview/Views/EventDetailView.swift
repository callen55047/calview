import SwiftUI

struct EventDetailView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let event: CalEvent?
    let date: Date
    /// Optional explicit start time (e.g. an hour tapped in the timeline grid).
    /// When nil, new events default to the start of `date`.
    var defaultStart: Date? = nil

    @AppStorage(ShiftWork.enabledKey) private var shiftWorkEnabled = false
    @AppStorage(ShiftWork.dayStartKey) private var dayStart = ShiftWork.defaultDayStart
    @AppStorage(ShiftWork.dayEndKey) private var dayEnd = ShiftWork.defaultDayEnd
    @AppStorage(ShiftWork.nightStartKey) private var nightStart = ShiftWork.defaultNightStart
    @AppStorage(ShiftWork.nightEndKey) private var nightEnd = ShiftWork.defaultNightEnd
    @AppStorage(ShiftWork.defaultLocationKey) private var defaultLocation = ""

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var colorKey = ""
    @State private var location = ""
    @State private var shiftType: ShiftType = .none

    @ViewBuilder
    private func legendRow(_ entry: LegendEntry) -> some View {
        HStack {
            Circle()
                .fill(entry.color)
                .frame(width: 20, height: 20)
            Text(entry.label)
            Spacer()
            if colorKey == entry.id {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { colorKey = entry.id }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Location", text: $location)
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
                }

                if shiftWorkEnabled {
                    Section("Shift") {
                        Picker("Shift", selection: $shiftType) {
                            ForEach(ShiftType.allCases) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Section("Category") {
                    ForEach(store.legend, id: \.id) { entry in
                        legendRow(entry)
                    }
                }

                if event != nil {
                    Section {
                        Button("Delete Event", role: .destructive) {
                            if let event {
                                Task { await store.deleteEvent(id: event.id); dismiss() }
                            }
                        }
                    }
                }
            }
            .navigationTitle(event == nil ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let saved = CalEvent(
                            id: event?.id ?? UUID().uuidString,
                            title: title,
                            startDate: startDate,
                            endDate: endDate,
                            colorKey: colorKey,
                            location: location,
                            // New Events are stamped with the Local User Id by the service;
                            // edits preserve the original author.
                            createdBy: event?.createdBy ?? ""
                        )
                        Task { await store.saveEvent(saved); dismiss() }
                    }
                    .disabled(title.isEmpty || colorKey.isEmpty)
                }
            }
            .onChange(of: shiftType) { _, newType in
                applyShiftPreset(newType)
            }
            .onAppear {
                if let event {
                    title = event.title
                    startDate = event.startDate
                    endDate = event.endDate
                    colorKey = event.colorKey
                    location = event.location
                    shiftType = ShiftType.from(categoryId: event.colorKey)
                } else {
                    startDate = defaultStart ?? Calendar.current.startOfDay(for: date)
                    endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
                    colorKey = store.legend.first?.id ?? ""
                    location = defaultLocation
                }
            }
        }
    }

    /// Pre-fills the time window, Category color, and (if empty) location when a
    /// Day/Night shift is chosen. `.none` leaves the fields as the Member left them.
    private func applyShiftPreset(_ type: ShiftType) {
        guard let categoryId = type.categoryId else { return }
        if let window = ShiftWork.window(for: type, on: startDate,
                                         dayStart: dayStart, dayEnd: dayEnd,
                                         nightStart: nightStart, nightEnd: nightEnd) {
            startDate = window.start
            endDate = window.end
        }
        colorKey = categoryId
        if location.isEmpty { location = defaultLocation }
    }
}
