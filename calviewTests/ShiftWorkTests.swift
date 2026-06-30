import Testing
import Foundation
@testable import calview

/// Covers the pure Shift Work logic: the day/night time-window math (including a
/// night shift that crosses midnight), the Category-id ↔ ShiftType mapping, and
/// backward-compatible decoding of Events written before `location` existed.
struct ShiftWorkTests {

    private let cal = Calendar.current

    // A fixed anchor day to build windows on (2026-06-30, components only).
    private func anchorDate() -> Date {
        cal.date(from: DateComponents(year: 2026, month: 6, day: 30))!
    }

    @Test func dayShiftWindowIsSameDay() throws {
        let day = anchorDate()
        let w = try #require(ShiftWork.window(
            for: .day, on: day,
            dayStart: ShiftWork.defaultDayStart, dayEnd: ShiftWork.defaultDayEnd,
            nightStart: ShiftWork.defaultNightStart, nightEnd: ShiftWork.defaultNightEnd))
        #expect(cal.component(.hour, from: w.start) == 7)
        #expect(cal.component(.hour, from: w.end) == 19)
        // Same calendar day, 12-hour duration.
        #expect(cal.isDate(w.start, inSameDayAs: w.end))
        #expect(w.end.timeIntervalSince(w.start) == 12 * 3600)
    }

    @Test func nightShiftWindowCrossesMidnight() throws {
        let day = anchorDate()
        let w = try #require(ShiftWork.window(
            for: .night, on: day,
            dayStart: ShiftWork.defaultDayStart, dayEnd: ShiftWork.defaultDayEnd,
            nightStart: ShiftWork.defaultNightStart, nightEnd: ShiftWork.defaultNightEnd))
        #expect(cal.component(.hour, from: w.start) == 19)
        #expect(cal.component(.hour, from: w.end) == 7)
        // End rolls over to the next day, and stays after start.
        #expect(w.end > w.start)
        #expect(!cal.isDate(w.start, inSameDayAs: w.end))
        #expect(w.end.timeIntervalSince(w.start) == 12 * 3600)
    }

    @Test func noneShiftHasNoWindow() {
        let w = ShiftWork.window(
            for: .none, on: anchorDate(),
            dayStart: ShiftWork.defaultDayStart, dayEnd: ShiftWork.defaultDayEnd,
            nightStart: ShiftWork.defaultNightStart, nightEnd: ShiftWork.defaultNightEnd)
        #expect(w == nil)
    }

    @Test func shiftTypeMapsToReservedCategoryAndBack() {
        #expect(ShiftType.day.categoryId == ShiftWork.dayCategoryId)
        #expect(ShiftType.night.categoryId == ShiftWork.nightCategoryId)
        #expect(ShiftType.none.categoryId == nil)

        #expect(ShiftType.from(categoryId: ShiftWork.dayCategoryId) == .day)
        #expect(ShiftType.from(categoryId: ShiftWork.nightCategoryId) == .night)
        #expect(ShiftType.from(categoryId: "doctor") == .none)
    }

    @Test func eventDecodesWhenLocationKeyMissing() throws {
        // Simulates a document written before `location` existed: the key is absent.
        let json = """
        {
          "id": "e1",
          "title": "Old Event",
          "startDate": "2026-06-30T07:00:00Z",
          "endDate": "2026-06-30T08:00:00Z",
          "colorKey": "doctor",
          "createdBy": "user-1",
          "updatedAt": "2026-06-30T07:00:00Z",
          "isDeleted": false
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let event = try decoder.decode(CalEvent.self, from: json)
        #expect(event.location == "")
        #expect(event.title == "Old Event")
    }

    @Test func eventRoundTripsLocation() throws {
        let event = CalEvent(id: "e1", title: "Shift", startDate: Date(), endDate: Date(),
                             colorKey: ShiftWork.nightCategoryId, location: "Riverside Hospital")
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CalEvent.self, from: try encoder.encode(event))
        #expect(decoded.location == "Riverside Hospital")
    }
}
