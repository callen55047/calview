import SwiftUI

struct EventDetailView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let event: CalEvent?
    let date: Date
    /// Optional explicit start time (e.g. an hour tapped in the timeline grid).
    /// When nil, new events default to the start of `date`.
    var defaultStart: Date? = nil

    @State private var title = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var colorKey = ""

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
                    DatePicker("Start", selection: $startDate)
                    DatePicker("End", selection: $endDate)
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
                            // New Events are stamped with the Local User Id by the service;
                            // edits preserve the original author.
                            createdBy: event?.createdBy ?? ""
                        )
                        Task { await store.saveEvent(saved); dismiss() }
                    }
                    .disabled(title.isEmpty || colorKey.isEmpty)
                }
            }
            .onAppear {
                if let event {
                    title = event.title
                    startDate = event.startDate
                    endDate = event.endDate
                    colorKey = event.colorKey
                } else {
                    startDate = defaultStart ?? Calendar.current.startOfDay(for: date)
                    endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
                    colorKey = store.legend.first?.id ?? ""
                }
            }
        }
    }
}
