//
//  Date+Extensions.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation

extension Date {
    /// Returns the start of the day for this date
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Returns the end of the day for this date (23:59:59)
    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!.addingTimeInterval(-1)
    }

    /// Returns the start of the week containing this date
    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components)!
    }

    /// Returns the end of the week containing this date
    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek)!.endOfDay
    }

    /// Returns the start of the month containing this date
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }

    /// Returns the end of the month containing this date
    var endOfMonth: Date {
        Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!.endOfDay
    }

    /// Returns the weekday for this date
    var weekday: Weekday {
        Weekday.from(date: self)
    }

    /// Returns the day of the month (1-31)
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Returns the number of days between this date and another date
    func daysBetween(_ other: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startOfDay, to: other.startOfDay)
        return components.day ?? 0
    }

    /// Returns true if this date is the same day as another date
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Returns true if this date is the same week as another date
    func isSameWeek(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .weekOfYear)
    }

    /// Returns true if this date is the same month as another date
    func isSameMonth(as other: Date) -> Bool {
        Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
    }

    /// Returns true if this date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Returns true if this date is yesterday
    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    /// Returns true if this date is in the past (before today)
    var isPast: Bool {
        self.startOfDay < Date().startOfDay
    }

    /// Returns true if this date is in the future (after today)
    var isFuture: Bool {
        self.startOfDay > Date().startOfDay
    }

    /// Returns a date by adding days to this date
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }

    /// Returns a formatted string for display
    var displayString: String {
        if isToday {
            return "Today"
        } else if isYesterday {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(self) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: self)
        }
    }

    /// Returns a short formatted string (e.g., "Dec 27")
    var shortDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

extension Calendar {
    /// Returns an array of dates from start to end (inclusive)
    func dates(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate.startOfDay

        while currentDate <= endDate.startOfDay {
            dates.append(currentDate)
            currentDate = date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }

    /// Returns the dates in the current week
    func datesInWeek(containing date: Date) -> [Date] {
        let startOfWeek = date.startOfWeek
        return (0..<7).map { self.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    /// Returns the dates in the current month
    func datesInMonth(containing date: Date) -> [Date] {
        let startOfMonth = date.startOfMonth
        let range = self.range(of: .day, in: .month, for: date)!
        return range.map { self.date(byAdding: .day, value: $0 - 1, to: startOfMonth)! }
    }
}
