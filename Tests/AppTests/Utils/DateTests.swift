import Foundation
import Testing

@testable import App

@Suite struct DateTests {
  @Test func advancedToNextMiddleOfTheWeek() {
    let wednesday = Date.isoDate("2025-10-01")!

    let nextSaturday = wednesday.advancedToNext(weekday: 7)
    let nextSunday = wednesday.advancedToNext(weekday: 1)
    let nextWednesday = wednesday.advancedToNext(weekday: 4)

    #expect(nextSaturday == .isoDate("2025-10-04"))
    #expect(nextSunday == .isoDate("2025-10-05"))
    #expect(nextWednesday == .isoDate("2025-10-08"))
  }

  @Test func advancedToNextStartOfTheWeek() {
    let sunday = Date.isoDate("2025-10-05")!

    let nextWednesday = sunday.advancedToNext(weekday: 4)
    let nextSaturday = sunday.advancedToNext(weekday: 7)
    let nextSunday = sunday.advancedToNext(weekday: 1)

    #expect(nextWednesday == .isoDate("2025-10-08"))
    #expect(nextSaturday == .isoDate("2025-10-11"))
    #expect(nextSunday == .isoDate("2025-10-12"))
  }

  @Test func advancedToNextEndOfTheWeek() {
    let saturday = Date.isoDate("2025-10-04")!

    let nextSunday = saturday.advancedToNext(weekday: 1)
    let nextWednesday = saturday.advancedToNext(weekday: 4)
    let nextSaturday = saturday.advancedToNext(weekday: 7)

    #expect(nextSunday == .isoDate("2025-10-05"))
    #expect(nextWednesday == .isoDate("2025-10-08"))
    #expect(nextSaturday == .isoDate("2025-10-11"))
  }

  @Test func withTime() {
    func testWithTime(dateOf: String, timeOf: String, expected: String) {
      let date = Date.iso(dateOf)!
      let time = Date.iso(timeOf)!
      let expected = Date.iso(expected)!
      #expect(date.withTime(of: time) == expected)
    }

    testWithTime(
      dateOf: "2025-10-04T12:30:15Z",
      timeOf: "2026-11-05T09:15:45Z",
      expected: "2025-10-04T09:15:45Z",
    )
    testWithTime(
      dateOf: "2025-10-04T00:00:00Z",
      timeOf: "2025-10-04T09:15:45Z",
      expected: "2025-10-04T09:15:45Z",
    )
    testWithTime(
      dateOf: "2025-10-04T12:30:15Z",
      timeOf: "2025-10-04T00:00:00Z",
      expected: "2025-10-04T00:00:0Z",
    )
  }
}
