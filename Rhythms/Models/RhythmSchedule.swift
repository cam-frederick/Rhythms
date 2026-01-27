//
//  RhythmSchedule.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftUI

// MARK: - Weekday

enum Weekday: Int, Codable, CaseIterable, Comparable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    var singleLetter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        let weekdayNumber = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNumber) ?? .sunday
    }
}

// MARK: - Mood

enum Mood: Int, Codable, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case okay = 3
    case good = 4
    case great = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }

    var label: String {
        switch self {
        case .terrible: return "Terrible"
        case .bad: return "Bad"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var color: Color {
        switch self {
        case .terrible: return .red
        case .bad: return .orange
        case .okay: return .yellow
        case .good: return .mint
        case .great: return .green
        }
    }
}

// MARK: - RhythmSchedule

enum RhythmSchedule: Codable, Hashable {
    case daily
    case weekdays
    case weekends
    case specificDays(Set<Weekday>)
    case interval(days: Int)
    case timesPerWeek(count: Int)
    case timesPerMonth(count: Int)
    case dayOfMonth(day: Int)

    var displayName: String {
        switch self {
        case .daily:
            return "Every day"
        case .weekdays:
            return "Weekdays"
        case .weekends:
            return "Weekends"
        case .specificDays(let days):
            let sortedDays = days.sorted()
            if sortedDays.count == 7 {
                return "Every day"
            } else if sortedDays.count == 1 {
                return sortedDays.first!.fullName + "s"
            } else {
                return sortedDays.map(\.shortName).joined(separator: ", ")
            }
        case .interval(let days):
            if days == 1 {
                return "Every day"
            } else if days == 2 {
                return "Every other day"
            } else {
                return "Every \(days) days"
            }
        case .timesPerWeek(let count):
            if count == 1 {
                return "Once a week"
            } else {
                return "\(count)x per week"
            }
        case .timesPerMonth(let count):
            if count == 1 {
                return "Once a month"
            } else {
                return "\(count)x per month"
            }
        case .dayOfMonth(let day):
            return "\(day)\(ordinalSuffix(for: day)) of each month"
        }
    }

    private func ordinalSuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }

    /// Determines if this rhythm is scheduled for a given date.
    /// For flexible schedules (timesPerWeek/Month), this always returns true
    /// since the user can complete it on any day within the period.
    func isScheduledFor(date: Date, calendar: Calendar = .current) -> Bool {
        let weekday = Weekday.from(date: date, calendar: calendar)

        switch self {
        case .daily:
            return true

        case .weekdays:
            return weekday != .saturday && weekday != .sunday

        case .weekends:
            return weekday == .saturday || weekday == .sunday

        case .specificDays(let days):
            return days.contains(weekday)

        case .interval:
            // For interval schedules, we need to track from a start date
            // This will be handled by the Rhythm model which knows its creation date
            return true

        case .timesPerWeek, .timesPerMonth:
            // Flexible schedules - rhythm can be done any day
            return true

        case .dayOfMonth(let day):
            let currentDay = calendar.component(.day, from: date)
            // Handle months with fewer days (e.g., if day is 31 but month only has 30 days)
            let lastDayOfMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 31
            if day > lastDayOfMonth {
                // If the scheduled day doesn't exist this month, use the last day
                return currentDay == lastDayOfMonth
            }
            return currentDay == day
        }
    }

    /// For interval schedules, determines if the rhythm is due on a given date
    /// based on the start date
    func isIntervalDue(date: Date, startDate: Date, calendar: Calendar = .current) -> Bool {
        guard case .interval(let days) = self else { return true }

        let startOfDate = calendar.startOfDay(for: date)
        let startOfStart = calendar.startOfDay(for: startDate)

        guard let daysDifference = calendar.dateComponents([.day], from: startOfStart, to: startOfDate).day else {
            return false
        }

        return daysDifference >= 0 && daysDifference % days == 0
    }
}
