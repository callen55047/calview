import SwiftUI

struct WeekView: View {
    @Environment(CalendarStore.self) private var store
    @State private var createSlot: TimeSlot?

    private var weekDays: [Date] {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: store.selectedDate) - 1  // 0 = Sun
        let sunday = cal.date(byAdding: .day, value: -weekday, to: store.selectedDate)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: sunday) }
    }

    private var weekRangeTitle: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let fmt: Date.FormatStyle = .dateTime.month(.abbreviated).day()
        return "\(first.formatted(fmt)) – \(last.formatted(fmt))"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { store.navigateWeek(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(weekRangeTitle).font(.headline)
                Spacer()
                Button { store.navigateWeek(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding()

            // Column headers, aligned with the day columns below via a matching
            // leading inset for the hour axis.
            HStack(alignment: .top, spacing: 0) {
                Color.clear.frame(width: TimelineLayout.axisWidth)
                ForEach(weekDays, id: \.self) { day in
                    WeekDayHeader(date: day)
                        .frame(maxWidth: .infinity)
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            // Timeline: pinned hour axis + 7 day columns sharing one vertical scroll.
            TimelineGridView(days: weekDays) { tapped in
                createSlot = TimeSlot(date: tapped)
            }
        }
        .task(id: store.displayedMonth) { await store.loadMonth() }
        .sheet(item: $createSlot) { slot in
            EventDetailView(event: nil, date: slot.date, defaultStart: slot.date)
        }
    }
}

private struct WeekDayHeader: View {
    @Environment(CalendarStore.self) private var store
    let date: Date

    private var shift: ShiftDay? { store.shiftDay(for: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.day())
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : .primary)
                .frame(width: 28, height: 28)
                .background(isToday ? Color.accentColor : .clear, in: Circle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(headerBg)
    }

    private var headerBg: Color {
        guard let shift else { return .clear }
        return shift.isNightShift ? .pink.opacity(0.22) : .blue.opacity(0.13)
    }
}
