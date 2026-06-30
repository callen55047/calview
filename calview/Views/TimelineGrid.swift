import SwiftUI

/// Shared layout math + building blocks for the vertical hour-timeline used by
/// both the Day and Week views. Events are positioned and sized by their
/// start/end time against a midnight→midnight axis.
enum TimelineLayout {
    static let hourHeight: CGFloat = 56
    static let minBlockHeight: CGFloat = 24
    static let axisWidth: CGFloat = 52
    static let dayColumnWidth: CGFloat = 96
    static var totalHeight: CGFloat { hourHeight * 24 }

    /// Vertical offset of an event's top edge within `date`'s column.
    static func yOffset(for event: CalEvent, on date: Date) -> CGFloat {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let start = max(event.startDate, dayStart)
        let hours = start.timeIntervalSince(dayStart) / 3600
        return CGFloat(hours) * hourHeight
    }

    /// Height of an event's block, clamped to the bounds of `date`'s day.
    static func height(for event: CalEvent, on date: Date) -> CGFloat {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = dayStart.addingTimeInterval(24 * 3600)
        let start = max(event.startDate, dayStart)
        let end = min(event.endDate, dayEnd)
        let hours = max(0, end.timeIntervalSince(start)) / 3600
        return max(minBlockHeight, CGFloat(hours) * hourHeight)
    }

    /// Greedy side-by-side column assignment for time-overlapping events.
    /// Events are first grouped into clusters where overlap chains, then each
    /// cluster's events are packed into the fewest columns possible.
    static func layoutColumns(_ events: [CalEvent]) -> [PositionedEvent] {
        let sorted = events.sorted { $0.startDate < $1.startDate }
        var result: [PositionedEvent] = []
        var cluster: [CalEvent] = []
        var clusterEnd: Date?

        func flush(_ group: [CalEvent]) {
            var columnEnds: [Date] = []
            var assigned: [(CalEvent, Int)] = []
            for ev in group {
                var placed = false
                for i in columnEnds.indices where columnEnds[i] <= ev.startDate {
                    columnEnds[i] = ev.endDate
                    assigned.append((ev, i))
                    placed = true
                    break
                }
                if !placed {
                    columnEnds.append(ev.endDate)
                    assigned.append((ev, columnEnds.count - 1))
                }
            }
            let total = columnEnds.count
            for (ev, col) in assigned {
                result.append(PositionedEvent(event: ev, column: col, columnCount: total))
            }
        }

        for ev in sorted {
            if let end = clusterEnd, ev.startDate < end {
                cluster.append(ev)
                clusterEnd = max(end, ev.endDate)
            } else {
                if !cluster.isEmpty { flush(cluster) }
                cluster = [ev]
                clusterEnd = ev.endDate
            }
        }
        if !cluster.isEmpty { flush(cluster) }
        return result
    }

    static func hourLabel(_ hour: Int) -> String {
        let period = hour < 12 ? "AM" : "PM"
        let twelve = hour % 12 == 0 ? 12 : hour % 12
        return "\(twelve) \(period)"
    }
}

/// Identifiable wrapper so a tapped time can drive a `.sheet(item:)`.
struct TimeSlot: Identifiable {
    let date: Date
    var id: TimeInterval { date.timeIntervalSinceReferenceDate }
}

/// An event with its computed side-by-side column placement.
struct PositionedEvent {
    let event: CalEvent
    let column: Int
    let columnCount: Int
}

// MARK: - Hour axis (left gutter)

struct HourAxis: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { hour in
                Text(TimelineLayout.hourLabel(hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: TimelineLayout.axisWidth - 4,
                           height: TimelineLayout.hourHeight,
                           alignment: .topTrailing)
                    .padding(.trailing, 4)
                    .id(hour)
            }
        }
        .frame(width: TimelineLayout.axisWidth)
    }
}

// MARK: - Hour grid lines (background behind each day column)

struct HourGridLines: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<24, id: \.self) { _ in
                VStack(spacing: 0) {
                    Divider()
                    Spacer(minLength: 0)
                }
                .frame(height: TimelineLayout.hourHeight)
            }
        }
    }
}

// MARK: - The scrollable timeline grid (1 day for Day view, 7 for Week view)

/// A single vertical hour grid: a pinned hour axis plus one column per day, with
/// events positioned by both day (x) and time (y) inside one container. Using a
/// single grid rather than stacking N tall columns side-by-side keeps the
/// vertical-scroll layout stable (avoids spurious empty space at the top).
struct TimelineGridView: View {
    @Environment(CalendarStore.self) private var store
    let days: [Date]
    var onCreate: (Date) -> Void

    private static let inset: CGFloat = 2
    private static let gap: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let colWidth = max(0, (geo.size.width - TimelineLayout.axisWidth) / CGFloat(days.count))
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        HourAxis()
                        columns(colWidth: colWidth)
                    }
                }
                .onAppear {
                    let hour = max(Calendar.current.component(.hour, from: Date()), 7)
                    proxy.scrollTo(max(hour - 1, 0), anchor: .top)
                }
            }
        }
    }

    @ViewBuilder
    private func columns(colWidth: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            HourGridLines()

            // Day separators between columns.
            ForEach(1..<days.count, id: \.self) { i in
                Rectangle()
                    .fill(Color(.separator).opacity(0.4))
                    .frame(width: 0.5)
                    .offset(x: CGFloat(i) * colWidth)
            }

            // Empty-space tap layer → create an event at the tapped day + hour.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { location in
                    let dayIndex = min(max(Int(location.x / colWidth), 0), days.count - 1)
                    let hour = min(max(Int(location.y / TimelineLayout.hourHeight), 0), 23)
                    if let d = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0,
                                                     of: days[dayIndex]) {
                        onCreate(d)
                    }
                }

            // Positioned event blocks for every day.
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let positioned = TimelineLayout.layoutColumns(store.events(for: day))
                ForEach(positioned, id: \.event.id) { p in
                    let w = blockWidth(p, colWidth: colWidth)
                    TimedEventBlock(event: p.event)
                        .frame(width: w, height: TimelineLayout.height(for: p.event, on: day))
                        .offset(x: CGFloat(index) * colWidth + blockX(p, colWidth: colWidth, blockW: w),
                                y: TimelineLayout.yOffset(for: p.event, on: day))
                }

                if Calendar.current.isDateInToday(day) {
                    NowIndicator()
                        .frame(width: colWidth)
                        .offset(x: CGFloat(index) * colWidth, y: nowOffset(for: day))
                }
            }
        }
        .frame(height: TimelineLayout.totalHeight)
    }

    private func nowOffset(for day: Date) -> CGFloat {
        let dayStart = Calendar.current.startOfDay(for: day)
        let hours = Date().timeIntervalSince(dayStart) / 3600
        return CGFloat(hours) * TimelineLayout.hourHeight
    }

    private func blockWidth(_ p: PositionedEvent, colWidth: CGFloat) -> CGFloat {
        let usable = colWidth - Self.inset * 2 - Self.gap * CGFloat(p.columnCount - 1)
        return max(0, usable / CGFloat(p.columnCount))
    }

    private func blockX(_ p: PositionedEvent, colWidth: CGFloat, blockW: CGFloat) -> CGFloat {
        Self.inset + CGFloat(p.column) * (blockW + Self.gap)
    }
}

// MARK: - Event block

struct TimedEventBlock: View {
    @Environment(CalendarStore.self) private var store
    let event: CalEvent
    @State private var showingEdit = false

    var body: some View {
        let color = store.legendEntry(for: event.colorKey)?.color ?? .gray
        VStack(alignment: .leading, spacing: 1) {
            Text(event.title)
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(2)
            Text(event.startDate, format: .dateTime.hour().minute())
                .font(.system(size: 9))
                .opacity(0.9)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(color.opacity(0.85), in: RoundedRectangle(cornerRadius: 4))
        .foregroundStyle(.white)
        .contentShape(Rectangle())
        .onTapGesture { showingEdit = true }
        .sheet(isPresented: $showingEdit) {
            EventDetailView(event: event, date: event.startDate)
        }
    }
}

// MARK: - Current-time indicator

struct NowIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(.red)
                .frame(width: 6, height: 6)
            Rectangle()
                .fill(.red)
                .frame(height: 1)
        }
    }
}
