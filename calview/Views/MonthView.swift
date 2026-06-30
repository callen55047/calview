import SwiftUI

struct MonthView: View {
    @Environment(CalendarStore.self) private var store

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 1), count: 7)
    private let dayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button { store.navigateMonth(by: -1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(store.displayedMonth, format: .dateTime.year().month(.wide))
                    .font(.headline)
                Spacer()
                Button { store.navigateMonth(by: 1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Day name header row
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
            }
            Divider()

            // Day cells
            LazyVGrid(columns: columns, spacing: 1) {
                ForEach(Array(daysInGrid.enumerated()), id: \.offset) { _, date in
                    if let date {
                        DayCell(date: date)
                    } else {
                        Color.clear.frame(height: 56)
                    }
                }
            }
            .padding(.horizontal, 1)

            Spacer()
        }
        .task(id: store.displayedMonth) { await store.loadMonth() }
    }

    private var daysInGrid: [Date?] {
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: store.displayedMonth))!
        let firstWeekday = cal.component(.weekday, from: start) - 1  // 0 = Sun
        let dayCount = cal.range(of: .day, in: .month, for: start)!.count

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for i in 0..<dayCount {
            days.append(cal.date(byAdding: .day, value: i, to: start))
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }
}

private struct DayCell: View {
    @Environment(CalendarStore.self) private var store
    let date: Date
    @State private var showingDetail = false

    private var shift: ShiftDay? { store.shiftDay(for: date) }
    private var dayEvents: [CalEvent] { store.events(for: date) }
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    private var inMonth: Bool { Calendar.current.isDate(date, equalTo: store.displayedMonth, toGranularity: .month) }

    var body: some View {
        VStack(spacing: 2) {
            Text(date, format: .dateTime.day())
                .font(.callout)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? Color.white : (inMonth ? Color.primary : Color.secondary.opacity(0.5)))
                .frame(width: 28, height: 28)
                .background(isToday ? Color.accentColor : .clear, in: Circle())

            // Event dots (up to 3)
            HStack(spacing: 2) {
                ForEach(dayEvents.prefix(3)) { event in
                    Circle()
                        .fill(store.legendEntry(for: event.colorKey)?.color ?? .gray)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(height: 8)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(shiftBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            store.selectedDate = date
            showingDetail = true
        }
        .contextMenu {
            Button {
                Task { await store.toggleShiftDay(date: date) }
            } label: {
                let isNight = shift?.isNightShift == true
                Label(isNight ? "Clear Night Shift" : "Mark Night Shift", systemImage: "moon.fill")
            }
        }
        .sheet(isPresented: $showingDetail) {
            DayDetailSheet(date: date)
        }
    }

    @ViewBuilder
    private var shiftBackground: some View {
        if let shift {
            if shift.isNightShift { Color.pink.opacity(0.22) } else { Color.blue.opacity(0.13) }
        } else {
            Color.clear
        }
    }
}
