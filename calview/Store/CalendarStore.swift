import Foundation

@Observable
final class CalendarStore {
    var events: [CalEvent] = []
    var legend: [LegendEntry] = []
    var shiftDays: [ShiftDay] = []
    var selectedDate: Date = Date()
    var displayedMonth: Date = Date()

    private let service: any CalendarService

    init(service: any CalendarService) {
        self.service = service
    }

    func loadMonth() async {
        do {
            async let e = service.fetchEvents(for: displayedMonth)
            async let s = service.fetchShiftDays(for: displayedMonth)
            async let l = service.fetchLegend()
            events = try await e
            shiftDays = try await s
            legend = try await l
        } catch {}
    }

    func saveEvent(_ event: CalEvent) async {
        try? await service.saveEvent(event)
        await loadMonth()
    }

    func deleteEvent(id: String) async {
        try? await service.deleteEvent(id: id)
        await loadMonth()
    }

    func saveLegend(_ entries: [LegendEntry]) async {
        try? await service.saveLegend(entries)
        legend = entries
    }

    func toggleShiftDay(date: Date) async {
        try? await service.toggleShiftDay(date: date)
        await loadMonth()
    }

    func navigateMonth(by value: Int) {
        displayedMonth = Calendar.current.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    func navigateDay(by value: Int) {
        let cal = Calendar.current
        let newDate = cal.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
        selectedDate = newDate
        let newMonthStart = cal.date(from: cal.dateComponents([.year, .month], from: newDate))!
        if !cal.isDate(newMonthStart, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = newMonthStart
            Task { await loadMonth() }
        }
    }

    func navigateWeek(by value: Int) { navigateDay(by: value * 7) }

    func shiftDay(for date: Date) -> ShiftDay? {
        let id = ShiftDay.dayId(for: date)
        return shiftDays.first { $0.id == id }
    }

    func events(for date: Date) -> [CalEvent] {
        events.filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
    }

    func legendEntry(for key: String) -> LegendEntry? {
        legend.first { $0.id == key }
    }
}
