import SwiftUI

struct DayDetailSheet: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let date: Date

    @State private var showingAddEvent = false

    private var dayEvents: [CalEvent] {
        store.events(for: date).sorted { $0.startDate < $1.startDate }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let shift = store.shiftDay(for: date) {
                    HStack(spacing: 6) {
                        Image(systemName: shift.isNightShift ? "moon.stars.fill" : "sun.max.fill")
                            .foregroundStyle(shift.isNightShift ? .purple : .yellow)
                        Text(shift.isNightShift ? "Night Shift" : "Day Shift")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(shift.isNightShift ? Color.pink.opacity(0.22) : Color.blue.opacity(0.13))
                }

                if dayEvents.isEmpty {
                    ContentUnavailableView("No Events", systemImage: "calendar.badge.plus",
                                           description: Text("Tap + to add one"))
                        .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(dayEvents) { event in
                            EventRow(event: event)
                        }
                        .onDelete { indexSet in
                            let ids = indexSet.map { dayEvents[$0].id }
                            Task { for id in ids { await store.deleteEvent(id: id) } }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(date.formatted(.dateTime.weekday(.wide).month().day()))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddEvent = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                EventDetailView(event: nil, date: date)
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct EventRow: View {
    @Environment(CalendarStore.self) private var store
    let event: CalEvent
    @State private var showingEdit = false

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(store.legendEntry(for: event.colorKey)?.color ?? .gray)
                .frame(width: 4, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title).font(.body)
                HStack(spacing: 4) {
                    Text(event.startDate, format: .dateTime.hour().minute())
                    if !event.location.isEmpty {
                        Text("·")
                        Text(event.location)
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) {
            EventDetailView(event: event, date: event.startDate)
        }
    }
}
