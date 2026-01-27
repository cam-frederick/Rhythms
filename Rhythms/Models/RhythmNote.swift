//
//  RhythmNote.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData

/// Represents a scheduled note for a rhythm, such as workout plans or reading pages.
/// Notes can be date-specific, day-of-week recurring, or day-of-month recurring.
@Model
final class RhythmNote {
    // MARK: - Properties

    var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date

    // Scheduling - only one of these should be set for recurring notes
    var scheduledDate: Date?      // For date-specific notes
    var dayOfWeek: Weekday?       // For weekly recurring notes (e.g., "Leg day" on Mondays)
    var dayOfMonth: Int?          // For monthly recurring notes (1-31)

    var isRecurring: Bool
    var sortOrder: Int

    // Relationship
    var rhythm: Rhythm?

    // MARK: - Initialization

    init(
        content: String,
        scheduledDate: Date? = nil,
        dayOfWeek: Weekday? = nil,
        dayOfMonth: Int? = nil,
        isRecurring: Bool = false,
        sortOrder: Int = 0,
        rhythm: Rhythm? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
        self.scheduledDate = scheduledDate?.startOfDay
        self.dayOfWeek = dayOfWeek
        self.dayOfMonth = dayOfMonth
        self.isRecurring = isRecurring
        self.sortOrder = sortOrder
        self.rhythm = rhythm
    }

    // MARK: - Factory Methods

    /// Creates a note for a specific date
    static func forDate(_ date: Date, content: String, rhythm: Rhythm? = nil) -> RhythmNote {
        RhythmNote(
            content: content,
            scheduledDate: date,
            isRecurring: false,
            rhythm: rhythm
        )
    }

    /// Creates a recurring note for a specific day of the week
    static func forWeekday(_ weekday: Weekday, content: String, rhythm: Rhythm? = nil) -> RhythmNote {
        RhythmNote(
            content: content,
            dayOfWeek: weekday,
            isRecurring: true,
            rhythm: rhythm
        )
    }

    /// Creates a recurring note for a specific day of the month
    static func forDayOfMonth(_ day: Int, content: String, rhythm: Rhythm? = nil) -> RhythmNote {
        RhythmNote(
            content: content,
            dayOfMonth: min(max(day, 1), 31),
            isRecurring: true,
            rhythm: rhythm
        )
    }

    // MARK: - Matching

    /// Returns true if this note applies to the given date
    func appliesTo(date: Date) -> Bool {
        // Check specific date match
        if let scheduledDate = scheduledDate {
            return date.isSameDay(as: scheduledDate)
        }

        // Check day of week match
        if let dayOfWeek = dayOfWeek {
            return date.weekday == dayOfWeek
        }

        // Check day of month match
        if let dayOfMonth = dayOfMonth {
            return date.dayOfMonth == dayOfMonth
        }

        return false
    }

    // MARK: - Display

    /// Returns a human-readable description of when this note applies
    var scheduleDescription: String {
        if let date = scheduledDate {
            return date.shortDisplayString
        }

        if let weekday = dayOfWeek {
            return "Every \(weekday.fullName)"
        }

        if let day = dayOfMonth {
            let suffix: String
            switch day {
            case 1, 21, 31: suffix = "st"
            case 2, 22: suffix = "nd"
            case 3, 23: suffix = "rd"
            default: suffix = "th"
            }
            return "Every \(day)\(suffix) of month"
        }

        return "Anytime"
    }
}
