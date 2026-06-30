import SwiftUI

private enum CalMode: String, CaseIterable {
    case month = "Month", week = "Week", day = "Day"
}

struct CalendarContainerView: View {
    @State private var mode: CalMode = .month

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $mode) {
                    ForEach(CalMode.allCases, id: \.self) { m in Text(m.rawValue).tag(m) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                switch mode {
                case .month: MonthView()
                case .week:  WeekView()
                case .day:   DayView()
                }
            }
            .navigationTitle("calview")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
