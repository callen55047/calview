import SwiftUI

struct DayView: View {
    @Environment(CalendarStore.self) private var store
    @State private var createSlot: TimeSlot?

    var body: some View {
        VStack(spacing: 0) {
            // Day navigation header
            HStack {
                Button { store.navigateDay(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                VStack(spacing: 1) {
                    Text(store.selectedDate, format: .dateTime.weekday(.wide))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(store.selectedDate, format: .dateTime.month().day().year())
                        .font(.headline)
                }
                Spacer()
                Button { store.navigateDay(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()

            // Shift banner
            if let shift = store.shiftDay(for: store.selectedDate) {
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

            // Hour-timeline grid
            TimelineGridView(days: [store.selectedDate]) { tapped in
                createSlot = TimeSlot(date: tapped)
            }
        }
        .task(id: store.displayedMonth) { await store.loadMonth() }
        .sheet(item: $createSlot) { slot in
            EventDetailView(event: nil, date: slot.date, defaultStart: slot.date)
        }
    }
}
