//
//  Rhythm.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a recurring activity, habit, or routine that a user wants to track
@Model
final class Rhythm {
    // MARK: - Identity

    var id: UUID
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Basic Info

    var title: String
    var rhythmDescription: String?
    var emoji: String
    var colorHex: String

    // MARK: - Schedule

    // Store schedule as encoded data since SwiftData can't handle enums with associated values
    private var scheduleData: Data?

    var schedule: RhythmSchedule {
        get {
            guard let data = scheduleData,
                  let decoded = try? JSONDecoder().decode(RhythmSchedule.self, from: data) else {
                return .daily
            }
            return decoded
        }
        set {
            scheduleData = try? JSONEncoder().encode(newValue)
        }
    }

    var reminderTime: Date?
    var reminderEnabled: Bool

    // MARK: - State

    var isArchived: Bool
    var isPaused: Bool
    var pausedUntil: Date?

    // MARK: - Display Order

    /// User-defined sort order within the Today view (lower = higher in list)
    var sortOrder: Int

    // MARK: - Tags

    var tags: [String]

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade, inverse: \RhythmEntry.rhythm)
    var entries: [RhythmEntry]

    @Relationship(deleteRule: .cascade, inverse: \RhythmNote.rhythm)
    var notes: [RhythmNote]

    var category: Category?

    // MARK: - Initialization

    init(
        title: String,
        emoji: String = "🎯",
        colorHex: String = "#007AFF",
        schedule: RhythmSchedule = .daily,
        rhythmDescription: String? = nil,
        category: Category? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.title = title
        self.emoji = emoji
        self.colorHex = colorHex
        self.scheduleData = try? JSONEncoder().encode(schedule)
        self.rhythmDescription = rhythmDescription
        self.reminderEnabled = false
        self.isArchived = false
        self.isPaused = false
        self.sortOrder = Int.max  // new rhythms go to end by default
        self.tags = []
        self.entries = []
        self.notes = []
        self.category = category
    }

    // MARK: - Computed Properties

    /// Returns the SwiftUI Color from the hex string
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }

    /// Returns true if the rhythm is currently active (not archived or paused)
    var isActive: Bool {
        !isArchived && !isPaused
    }

    /// Returns true if the rhythm is paused but the pause period has expired
    var shouldResume: Bool {
        guard isPaused, let pausedUntil = pausedUntil else { return false }
        return Date() >= pausedUntil
    }

    // MARK: - Schedule Methods

    /// Returns true if this rhythm is scheduled for the given date
    func isScheduledFor(date: Date) -> Bool {
        guard isActive else { return false }

        // Don't show rhythm on dates before it was created
        guard date.startOfDay >= createdAt.startOfDay else { return false }

        switch schedule {
        case .interval:
            return schedule.isIntervalDue(date: date, startDate: createdAt)
        default:
            return schedule.isScheduledFor(date: date)
        }
    }

    /// Returns the dates when this rhythm was scheduled in the given range
    func scheduledDates(from startDate: Date, to endDate: Date) -> [Date] {
        Calendar.current.dates(from: startDate, to: endDate)
            .filter { isScheduledFor(date: $0) }
    }

    // MARK: - Completion Methods

    /// Returns true if this rhythm was completed on the given date
    func isCompleted(on date: Date) -> Bool {
        entries.contains { $0.scheduledDate.isSameDay(as: date) }
    }

    /// Returns the entry for the given date, if any
    func entry(for date: Date) -> RhythmEntry? {
        entries.first { $0.scheduledDate.isSameDay(as: date) }
    }

    /// Marks this rhythm as completed for the given date
    @discardableResult
    func markCompleted(for date: Date, note: String? = nil, mood: Mood? = nil) -> RhythmEntry {
        // Remove any existing entry for this date
        entries.removeAll { $0.scheduledDate.isSameDay(as: date) }

        // Create and add new entry
        let entry = RhythmEntry(
            scheduledDate: date,
            rhythm: self,
            note: note,
            mood: mood
        )
        entries.append(entry)
        updatedAt = Date()

        return entry
    }

    /// Removes the completion for the given date
    func markIncomplete(for date: Date) {
        entries.removeAll { $0.scheduledDate.isSameDay(as: date) }
        updatedAt = Date()
    }

    /// Toggles completion for the given date
    @discardableResult
    func toggleCompletion(for date: Date) -> Bool {
        if isCompleted(on: date) {
            markIncomplete(for: date)
            return false
        } else {
            markCompleted(for: date)
            return true
        }
    }

    // MARK: - Note Methods

    /// Returns the note that applies to the given date
    func noteForDate(_ date: Date) -> RhythmNote? {
        // First check for a specific date note
        if let specificNote = notes.first(where: { $0.scheduledDate?.isSameDay(as: date) == true }) {
            return specificNote
        }

        // Then check for recurring notes
        return notes
            .filter { $0.isRecurring }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first { $0.appliesTo(date: date) }
    }

    /// Returns all notes for the given date (may include multiple matching recurring notes)
    func allNotesForDate(_ date: Date) -> [RhythmNote] {
        notes.filter { $0.appliesTo(date: date) }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Adds a note to this rhythm
    func addNote(_ note: RhythmNote) {
        note.rhythm = self
        note.sortOrder = notes.count
        notes.append(note)
        updatedAt = Date()
    }

    /// Removes a note from this rhythm
    func removeNote(_ note: RhythmNote) {
        notes.removeAll { $0.id == note.id }
        updatedAt = Date()
    }

    // MARK: - Streak Calculation

    /// Returns the current streak count
    var currentStreak: Int {
        calculateStreak(from: Date())
    }

    /// Returns the longest streak ever achieved
    var longestStreak: Int {
        guard !entries.isEmpty else { return 0 }

        let sortedDates = entries.map { $0.scheduledDate }.sorted()
        guard let firstDate = sortedDates.first, let lastDate = sortedDates.last else { return 0 }

        var maxStreak = 0
        var currentStreakCount = 0
        var previousDate: Date?

        for date in Calendar.current.dates(from: firstDate, to: lastDate) {
            guard isScheduledFor(date: date) else { continue }

            if isCompleted(on: date) {
                currentStreakCount += 1
                maxStreak = max(maxStreak, currentStreakCount)
            } else {
                currentStreakCount = 0
            }
            previousDate = date
        }

        return maxStreak
    }

    /// Calculates the streak counting backwards from the given date
    private func calculateStreak(from date: Date) -> Int {
        var streak = 0
        var currentDate = date.startOfDay

        // If today isn't completed yet, start from yesterday
        if !isCompleted(on: currentDate) {
            currentDate = currentDate.adding(days: -1)
        }

        while true {
            guard isScheduledFor(date: currentDate) else {
                // Skip days when the rhythm isn't scheduled
                currentDate = currentDate.adding(days: -1)

                // Safety: don't go back more than a year
                if currentDate < Date().adding(days: -365) {
                    break
                }
                continue
            }

            if isCompleted(on: currentDate) {
                streak += 1
                currentDate = currentDate.adding(days: -1)
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Statistics

    /// Returns the completion rate for the last N days
    func completionRate(forLast days: Int) -> Double {
        let endDate = Date()
        let startDate = endDate.adding(days: -days + 1)

        let scheduledDays = scheduledDates(from: startDate, to: endDate)
        guard !scheduledDays.isEmpty else { return 0 }

        let completedDays = scheduledDays.filter { isCompleted(on: $0) }
        return Double(completedDays.count) / Double(scheduledDays.count)
    }

    /// Returns the completion rate for this week
    var completionRateThisWeek: Double {
        let startOfWeek = Date().startOfWeek
        let today = Date()

        let scheduledDays = scheduledDates(from: startOfWeek, to: today)
        guard !scheduledDays.isEmpty else { return 0 }

        let completedDays = scheduledDays.filter { isCompleted(on: $0) }
        return Double(completedDays.count) / Double(scheduledDays.count)
    }

    /// Returns the total number of completions
    var totalCompletions: Int {
        entries.count
    }

    /// Returns the average mood across all entries with mood data
    var averageMood: Double? {
        let entriesWithMood = entries.compactMap { $0.mood?.rawValue }
        guard !entriesWithMood.isEmpty else { return nil }
        return Double(entriesWithMood.reduce(0, +)) / Double(entriesWithMood.count)
    }

    // MARK: - State Management

    /// Archives this rhythm
    func archive() {
        isArchived = true
        isPaused = false
        pausedUntil = nil
        updatedAt = Date()
    }

    /// Unarchives this rhythm
    func unarchive() {
        isArchived = false
        updatedAt = Date()
    }

    /// Pauses this rhythm until the given date
    func pause(until date: Date? = nil) {
        isPaused = true
        pausedUntil = date
        updatedAt = Date()
    }

    /// Resumes this rhythm
    func resume() {
        isPaused = false
        pausedUntil = nil
        updatedAt = Date()
    }
}

// MARK: - Sorting & Filtering

extension Rhythm {
    /// Sorts rhythms by various criteria
    enum SortOrder {
        case title
        case createdAt
        case updatedAt
        case streak
        case completionRate
    }

    /// Returns rhythms sorted by the given order
    static func sorted(_ rhythms: [Rhythm], by order: SortOrder, ascending: Bool = true) -> [Rhythm] {
        let sorted: [Rhythm]

        switch order {
        case .title:
            sorted = rhythms.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .createdAt:
            sorted = rhythms.sorted { $0.createdAt < $1.createdAt }
        case .updatedAt:
            sorted = rhythms.sorted { $0.updatedAt < $1.updatedAt }
        case .streak:
            sorted = rhythms.sorted { $0.currentStreak < $1.currentStreak }
        case .completionRate:
            sorted = rhythms.sorted { $0.completionRateThisWeek < $1.completionRateThisWeek }
        }

        return ascending ? sorted : sorted.reversed()
    }
}
