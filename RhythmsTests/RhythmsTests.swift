//
//  RhythmsTests.swift
//  RhythmsTests
//
//  Created by Cam Frederick on 12/27/25.
//

import Testing
import Foundation
import SwiftUI
@testable import Rhythms

// MARK: - Test Helpers

extension Date {
    /// Creates a date with specific components for testing
    static func make(year: Int = 2025, month: Int = 1, day: Int = 15, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components)!
    }

    /// Returns a Monday date for consistent weekday testing
    static var testMonday: Date {
        // January 13, 2025 is a Monday
        make(year: 2025, month: 1, day: 13)
    }

    /// Returns dates for each day of a test week (Mon-Sun)
    static var testWeek: [Date] {
        (0..<7).map { testMonday.adding(days: $0) }
    }
}

// MARK: - Rhythm Model Tests

struct RhythmTests {

    // MARK: - Initialization

    @Test func initializationSetsDefaultValues() {
        let rhythm = Rhythm(title: "Test Rhythm")

        #expect(rhythm.title == "Test Rhythm")
        #expect(rhythm.emoji == "🎯")
        #expect(rhythm.colorHex == "#007AFF")
        #expect(rhythm.schedule == .daily)
        #expect(rhythm.isArchived == false)
        #expect(rhythm.isPaused == false)
        #expect(rhythm.reminderEnabled == false)
        #expect(rhythm.entries.isEmpty)
        #expect(rhythm.notes.isEmpty)
    }

    @Test func initializationWithCustomValues() {
        let rhythm = Rhythm(
            title: "Workout",
            emoji: "💪",
            colorHex: "#FF0000",
            schedule: .weekdays,
            rhythmDescription: "Daily workout"
        )

        #expect(rhythm.title == "Workout")
        #expect(rhythm.emoji == "💪")
        #expect(rhythm.colorHex == "#FF0000")
        #expect(rhythm.schedule == .weekdays)
        #expect(rhythm.rhythmDescription == "Daily workout")
    }

    // MARK: - State Management

    @Test func isActiveWhenNotArchivedOrPaused() {
        let rhythm = Rhythm(title: "Test")
        #expect(rhythm.isActive == true)

        rhythm.isPaused = true
        #expect(rhythm.isActive == false)

        rhythm.isPaused = false
        rhythm.isArchived = true
        #expect(rhythm.isActive == false)
    }

    @Test func archiveSetsCorrectState() {
        let rhythm = Rhythm(title: "Test")
        rhythm.isPaused = true
        rhythm.pausedUntil = Date()

        rhythm.archive()

        #expect(rhythm.isArchived == true)
        #expect(rhythm.isPaused == false)
        #expect(rhythm.pausedUntil == nil)
    }

    @Test func unarchiveResetsArchivedState() {
        let rhythm = Rhythm(title: "Test")
        rhythm.archive()

        rhythm.unarchive()

        #expect(rhythm.isArchived == false)
    }

    @Test func pauseSetsCorrectState() {
        let rhythm = Rhythm(title: "Test")
        let futureDate = Date().adding(days: 7)

        rhythm.pause(until: futureDate)

        #expect(rhythm.isPaused == true)
        #expect(rhythm.pausedUntil != nil)
    }

    @Test func resumeResetsPausedState() {
        let rhythm = Rhythm(title: "Test")
        rhythm.pause(until: Date().adding(days: 7))

        rhythm.resume()

        #expect(rhythm.isPaused == false)
        #expect(rhythm.pausedUntil == nil)
    }

    // MARK: - Completion Tracking

    @Test func markCompletedCreatesEntry() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        let entry = rhythm.markCompleted(for: date)

        #expect(rhythm.entries.count == 1)
        #expect(entry.scheduledDate.isSameDay(as: date))
        #expect(rhythm.isCompleted(on: date) == true)
    }

    @Test func markCompletedWithNoteAndMood() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        let entry = rhythm.markCompleted(for: date, note: "Great session", mood: .great)

        #expect(entry.note == "Great session")
        #expect(entry.mood == .great)
    }

    @Test func markCompletedReplacesExistingEntry() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, note: "First")
        #expect(rhythm.entries.count == 1)

        rhythm.markCompleted(for: date, note: "Second")
        #expect(rhythm.entries.count == 1)
        #expect(rhythm.entry(for: date)?.note == "Second")
    }

    @Test func markIncompleteRemovesEntry() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date)
        #expect(rhythm.isCompleted(on: date) == true)

        rhythm.markIncomplete(for: date)
        #expect(rhythm.isCompleted(on: date) == false)
        #expect(rhythm.entries.isEmpty)
    }

    @Test func toggleCompletionWorks() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        let completed = rhythm.toggleCompletion(for: date)
        #expect(completed == true)
        #expect(rhythm.isCompleted(on: date) == true)

        let incomplete = rhythm.toggleCompletion(for: date)
        #expect(incomplete == false)
        #expect(rhythm.isCompleted(on: date) == false)
    }

    @Test func totalCompletionsCountsEntries() {
        let rhythm = Rhythm(title: "Test")

        rhythm.markCompleted(for: Date.make(day: 1))
        rhythm.markCompleted(for: Date.make(day: 2))
        rhythm.markCompleted(for: Date.make(day: 3))

        #expect(rhythm.totalCompletions == 3)
    }

    // MARK: - Note Management
    // Note: SwiftData relationship tests require model context;
    // detailed note tests are in RhythmNoteTests

    @Test func rhythmInitializesWithEmptyNotes() {
        let rhythm = Rhythm(title: "Workout")
        #expect(rhythm.notes.isEmpty)
    }

    // MARK: - Scheduling

    @Test func dailyRhythmScheduledEveryDay() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates

        for day in 1...7 {
            let date = Date.make(day: day)
            #expect(rhythm.isScheduledFor(date: date) == true)
        }
    }

    @Test func weekdaysRhythmScheduledMondayToFriday() {
        let rhythm = Rhythm(title: "Test", schedule: .weekdays)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates
        let week = Date.testWeek

        // Monday through Friday (indices 0-4) should be scheduled
        for i in 0..<5 {
            #expect(rhythm.isScheduledFor(date: week[i]) == true, "Weekday \(i) should be scheduled")
        }

        // Saturday and Sunday (indices 5-6) should not be scheduled
        #expect(rhythm.isScheduledFor(date: week[5]) == false, "Saturday should not be scheduled")
        #expect(rhythm.isScheduledFor(date: week[6]) == false, "Sunday should not be scheduled")
    }

    @Test func weekendsRhythmScheduledSaturdayAndSunday() {
        let rhythm = Rhythm(title: "Test", schedule: .weekends)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates
        let week = Date.testWeek

        // Monday through Friday should not be scheduled
        for i in 0..<5 {
            #expect(rhythm.isScheduledFor(date: week[i]) == false)
        }

        // Saturday and Sunday should be scheduled
        #expect(rhythm.isScheduledFor(date: week[5]) == true)
        #expect(rhythm.isScheduledFor(date: week[6]) == true)
    }

    @Test func specificDaysRhythmScheduledOnSelectedDays() {
        let rhythm = Rhythm(title: "Test", schedule: .specificDays([.monday, .wednesday, .friday]))
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates
        let week = Date.testWeek

        #expect(rhythm.isScheduledFor(date: week[0]) == true, "Monday")
        #expect(rhythm.isScheduledFor(date: week[1]) == false, "Tuesday")
        #expect(rhythm.isScheduledFor(date: week[2]) == true, "Wednesday")
        #expect(rhythm.isScheduledFor(date: week[3]) == false, "Thursday")
        #expect(rhythm.isScheduledFor(date: week[4]) == true, "Friday")
        #expect(rhythm.isScheduledFor(date: week[5]) == false, "Saturday")
        #expect(rhythm.isScheduledFor(date: week[6]) == false, "Sunday")
    }

    @Test func pausedRhythmNotScheduled() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        rhythm.pause()

        #expect(rhythm.isScheduledFor(date: Date()) == false)
    }

    @Test func archivedRhythmNotScheduled() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        rhythm.archive()

        #expect(rhythm.isScheduledFor(date: Date()) == false)
    }

    @Test func rhythmNotScheduledBeforeCreationDate() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        // Set creation date to a known date
        let creationDate = Date.make(year: 2025, month: 6, day: 15)
        rhythm.createdAt = creationDate

        // Should be scheduled on creation date
        #expect(rhythm.isScheduledFor(date: creationDate) == true)

        // Should be scheduled after creation date
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: 1)) == true)
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: 7)) == true)

        // Should NOT be scheduled before creation date
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: -1)) == false)
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: -7)) == false)
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: -30)) == false)
    }

    @Test func rhythmWithIntervalNotScheduledBeforeCreationDate() {
        let creationDate = Date.make(year: 2025, month: 6, day: 15)
        let rhythm = Rhythm(title: "Test", schedule: .interval(days: 3))
        rhythm.createdAt = creationDate

        // Should be scheduled on creation date (interval day 0)
        #expect(rhythm.isScheduledFor(date: creationDate) == true)

        // Should NOT be scheduled before creation date
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: -3)) == false)
        #expect(rhythm.isScheduledFor(date: creationDate.adding(days: -6)) == false)
    }

    // MARK: - Streak Calculation

    @Test func currentStreakCountsConsecutiveCompletions() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30) // Set creation date before test dates

        // Complete the last 5 days
        for i in 0..<5 {
            rhythm.markCompleted(for: today.adding(days: -i))
        }

        #expect(rhythm.currentStreak == 5)
    }

    @Test func currentStreakBreaksOnMissedDay() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30) // Set creation date before test dates

        // Complete today and yesterday
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today.adding(days: -1))
        // Skip day -2
        rhythm.markCompleted(for: today.adding(days: -3))

        #expect(rhythm.currentStreak == 2)
    }

    @Test func longestStreakTracksMaximum() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let start = Date.make(day: 1)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates

        // First streak: 3 days
        rhythm.markCompleted(for: start)
        rhythm.markCompleted(for: start.adding(days: 1))
        rhythm.markCompleted(for: start.adding(days: 2))
        // Gap at day 3
        // Second streak: 5 days
        for i in 4..<9 {
            rhythm.markCompleted(for: start.adding(days: i))
        }

        #expect(rhythm.longestStreak == 5)
    }

    @Test func streakSkipsUnscheduledDays() {
        let rhythm = Rhythm(title: "Test", schedule: .weekdays)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1) // Set creation date before test dates

        // Use a historical week where we control all dates
        // January 6, 2025 was a Monday
        let monday = Date.make(year: 2025, month: 1, day: 6)

        // Complete Mon, Tue, Wed, Thu, Fri
        rhythm.markCompleted(for: monday)
        rhythm.markCompleted(for: monday.adding(days: 1))
        rhythm.markCompleted(for: monday.adding(days: 2))
        rhythm.markCompleted(for: monday.adding(days: 3))
        rhythm.markCompleted(for: monday.adding(days: 4))

        // Verify the longestStreak is 5 (all weekdays)
        #expect(rhythm.longestStreak == 5)
    }

    // MARK: - Completion Rate

    @Test func completionRateCalculatesCorrectly() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30) // Set creation date before test dates

        // Complete 3 out of last 5 days
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today.adding(days: -1))
        rhythm.markCompleted(for: today.adding(days: -3))

        let rate = rhythm.completionRate(forLast: 5)
        #expect(rate == 0.6) // 3/5
    }

    @Test func averageMoodCalculatesCorrectly() {
        let rhythm = Rhythm(title: "Test")

        rhythm.markCompleted(for: Date.make(day: 1), mood: .great)    // 5
        rhythm.markCompleted(for: Date.make(day: 2), mood: .good)     // 4
        rhythm.markCompleted(for: Date.make(day: 3), mood: .okay)     // 3

        #expect(rhythm.averageMood == 4.0) // (5+4+3)/3
    }

    @Test func averageMoodReturnsNilWithNoMoodData() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date())

        #expect(rhythm.averageMood == nil)
    }

    // MARK: - Sorting

    @Test func sortingByTitle() {
        let rhythms = [
            Rhythm(title: "Zebra"),
            Rhythm(title: "Apple"),
            Rhythm(title: "Mango")
        ]

        let sorted = Rhythm.sorted(rhythms, by: .title)

        #expect(sorted[0].title == "Apple")
        #expect(sorted[1].title == "Mango")
        #expect(sorted[2].title == "Zebra")
    }

    @Test func sortingDescending() {
        let rhythms = [
            Rhythm(title: "Apple"),
            Rhythm(title: "Zebra")
        ]

        let sorted = Rhythm.sorted(rhythms, by: .title, ascending: false)

        #expect(sorted[0].title == "Zebra")
        #expect(sorted[1].title == "Apple")
    }
}

// MARK: - RhythmSchedule Tests

struct RhythmScheduleTests {

    // MARK: - Display Names

    @Test func displayNameForDaily() {
        #expect(RhythmSchedule.daily.displayName == "Every day")
    }

    @Test func displayNameForWeekdays() {
        #expect(RhythmSchedule.weekdays.displayName == "Weekdays")
    }

    @Test func displayNameForWeekends() {
        #expect(RhythmSchedule.weekends.displayName == "Weekends")
    }

    @Test func displayNameForSpecificDays() {
        let schedule = RhythmSchedule.specificDays([.monday, .wednesday, .friday])
        #expect(schedule.displayName == "Mon, Wed, Fri")
    }

    @Test func displayNameForSingleDay() {
        let schedule = RhythmSchedule.specificDays([.monday])
        #expect(schedule.displayName == "Mondays")
    }

    @Test func displayNameForInterval() {
        #expect(RhythmSchedule.interval(days: 1).displayName == "Every day")
        #expect(RhythmSchedule.interval(days: 2).displayName == "Every other day")
        #expect(RhythmSchedule.interval(days: 3).displayName == "Every 3 days")
    }

    @Test func displayNameForTimesPerWeek() {
        #expect(RhythmSchedule.timesPerWeek(count: 1).displayName == "Once a week")
        #expect(RhythmSchedule.timesPerWeek(count: 3).displayName == "3x per week")
    }

    @Test func displayNameForTimesPerMonth() {
        #expect(RhythmSchedule.timesPerMonth(count: 1).displayName == "Once a month")
        #expect(RhythmSchedule.timesPerMonth(count: 4).displayName == "4x per month")
    }

    // MARK: - Scheduling Logic

    @Test func dailyScheduleAlwaysReturnsTrue() {
        let schedule = RhythmSchedule.daily

        for day in 1...31 {
            let date = Date.make(day: day)
            #expect(schedule.isScheduledFor(date: date) == true)
        }
    }

    @Test func weekdaysScheduleExcludesWeekends() {
        let schedule = RhythmSchedule.weekdays
        let week = Date.testWeek

        #expect(schedule.isScheduledFor(date: week[0]) == true)  // Monday
        #expect(schedule.isScheduledFor(date: week[4]) == true)  // Friday
        #expect(schedule.isScheduledFor(date: week[5]) == false) // Saturday
        #expect(schedule.isScheduledFor(date: week[6]) == false) // Sunday
    }

    @Test func weekendsScheduleOnlyWeekends() {
        let schedule = RhythmSchedule.weekends
        let week = Date.testWeek

        #expect(schedule.isScheduledFor(date: week[0]) == false) // Monday
        #expect(schedule.isScheduledFor(date: week[5]) == true)  // Saturday
        #expect(schedule.isScheduledFor(date: week[6]) == true)  // Sunday
    }

    @Test func specificDaysScheduleMatchesSelectedDays() {
        let schedule = RhythmSchedule.specificDays([.tuesday, .thursday])
        let week = Date.testWeek

        #expect(schedule.isScheduledFor(date: week[0]) == false) // Monday
        #expect(schedule.isScheduledFor(date: week[1]) == true)  // Tuesday
        #expect(schedule.isScheduledFor(date: week[2]) == false) // Wednesday
        #expect(schedule.isScheduledFor(date: week[3]) == true)  // Thursday
    }

    @Test func intervalScheduleCalculatesCorrectly() {
        let schedule = RhythmSchedule.interval(days: 3)
        let startDate = Date.make(day: 1)

        #expect(schedule.isIntervalDue(date: startDate, startDate: startDate) == true)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 1), startDate: startDate) == false)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 2), startDate: startDate) == false)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 3), startDate: startDate) == true)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 6), startDate: startDate) == true)
    }

    @Test func intervalScheduleEveryOtherDay() {
        let schedule = RhythmSchedule.interval(days: 2)
        let startDate = Date.make(day: 1)

        #expect(schedule.isIntervalDue(date: startDate, startDate: startDate) == true)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 1), startDate: startDate) == false)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 2), startDate: startDate) == true)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 3), startDate: startDate) == false)
        #expect(schedule.isIntervalDue(date: startDate.adding(days: 4), startDate: startDate) == true)
    }

    // MARK: - Codable

    @Test func scheduleEncodesAndDecodes() throws {
        let schedules: [RhythmSchedule] = [
            .daily,
            .weekdays,
            .weekends,
            .specificDays([.monday, .friday]),
            .interval(days: 5),
            .timesPerWeek(count: 3),
            .timesPerMonth(count: 2)
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for original in schedules {
            let data = try encoder.encode(original)
            let decoded = try decoder.decode(RhythmSchedule.self, from: data)
            #expect(decoded == original)
        }
    }
}

// MARK: - Weekday Tests

struct WeekdayTests {

    @Test func weekdayFromDate() {
        let monday = Date.testMonday
        #expect(Weekday.from(date: monday) == .monday)
        #expect(Weekday.from(date: monday.adding(days: 1)) == .tuesday)
        #expect(Weekday.from(date: monday.adding(days: 5)) == .saturday)
        #expect(Weekday.from(date: monday.adding(days: 6)) == .sunday)
    }

    @Test func weekdayNames() {
        #expect(Weekday.monday.shortName == "Mon")
        #expect(Weekday.monday.fullName == "Monday")
        #expect(Weekday.monday.singleLetter == "M")

        #expect(Weekday.sunday.shortName == "Sun")
        #expect(Weekday.sunday.fullName == "Sunday")
        #expect(Weekday.sunday.singleLetter == "S")
    }

    @Test func weekdayComparable() {
        #expect(Weekday.sunday < Weekday.monday)
        #expect(Weekday.monday < Weekday.saturday)
    }

    @Test func weekdayAllCases() {
        #expect(Weekday.allCases.count == 7)
        #expect(Weekday.allCases.first == .sunday)
        #expect(Weekday.allCases.last == .saturday)
    }
}

// MARK: - Mood Tests

struct MoodTests {

    @Test func moodRawValues() {
        #expect(Mood.terrible.rawValue == 1)
        #expect(Mood.bad.rawValue == 2)
        #expect(Mood.okay.rawValue == 3)
        #expect(Mood.good.rawValue == 4)
        #expect(Mood.great.rawValue == 5)
    }

    @Test func moodEmojis() {
        #expect(Mood.terrible.emoji == "😫")
        #expect(Mood.great.emoji == "😄")
    }

    @Test func moodLabels() {
        #expect(Mood.terrible.label == "Terrible")
        #expect(Mood.great.label == "Great")
    }

    @Test func moodAllCases() {
        #expect(Mood.allCases.count == 5)
    }
}

// MARK: - RhythmNote Tests

struct RhythmNoteTests {

    // MARK: - Factory Methods

    @Test func forDateCreatesNonRecurringNote() {
        let date = Date.make(day: 15)
        let note = RhythmNote.forDate(date, content: "Special day")

        #expect(note.content == "Special day")
        #expect(note.scheduledDate != nil)
        #expect(note.isRecurring == false)
        #expect(note.dayOfWeek == nil)
        #expect(note.dayOfMonth == nil)
    }

    @Test func forWeekdayCreatesRecurringNote() {
        let note = RhythmNote.forWeekday(.wednesday, content: "Hump day")

        #expect(note.content == "Hump day")
        #expect(note.dayOfWeek == .wednesday)
        #expect(note.isRecurring == true)
        #expect(note.scheduledDate == nil)
        #expect(note.dayOfMonth == nil)
    }

    @Test func forDayOfMonthCreatesRecurringNote() {
        let note = RhythmNote.forDayOfMonth(15, content: "Mid-month check")

        #expect(note.content == "Mid-month check")
        #expect(note.dayOfMonth == 15)
        #expect(note.isRecurring == true)
        #expect(note.scheduledDate == nil)
        #expect(note.dayOfWeek == nil)
    }

    @Test func forDayOfMonthClampsToBounds() {
        let tooLow = RhythmNote.forDayOfMonth(0, content: "Test")
        let tooHigh = RhythmNote.forDayOfMonth(50, content: "Test")

        #expect(tooLow.dayOfMonth == 1)
        #expect(tooHigh.dayOfMonth == 31)
    }

    // MARK: - Matching

    @Test func appliesToMatchesSpecificDate() {
        let targetDate = Date.make(day: 20)
        let note = RhythmNote.forDate(targetDate, content: "Test")

        #expect(note.appliesTo(date: targetDate) == true)
        #expect(note.appliesTo(date: Date.make(day: 21)) == false)
    }

    @Test func appliesToMatchesWeekday() {
        let note = RhythmNote.forWeekday(.monday, content: "Monday note")
        let monday = Date.testMonday

        #expect(note.appliesTo(date: monday) == true)
        #expect(note.appliesTo(date: monday.adding(days: 1)) == false) // Tuesday
        #expect(note.appliesTo(date: monday.adding(days: 7)) == true)  // Next Monday
    }

    @Test func appliesToMatchesDayOfMonth() {
        let note = RhythmNote.forDayOfMonth(15, content: "15th note")

        #expect(note.appliesTo(date: Date.make(month: 1, day: 15)) == true)
        #expect(note.appliesTo(date: Date.make(month: 2, day: 15)) == true)
        #expect(note.appliesTo(date: Date.make(month: 1, day: 14)) == false)
    }

    // MARK: - Schedule Description

    @Test func scheduleDescriptionForWeekday() {
        let note = RhythmNote.forWeekday(.friday, content: "TGIF")
        #expect(note.scheduleDescription == "Every Friday")
    }

    @Test func scheduleDescriptionForDayOfMonth() {
        #expect(RhythmNote.forDayOfMonth(1, content: "").scheduleDescription == "Every 1st of month")
        #expect(RhythmNote.forDayOfMonth(2, content: "").scheduleDescription == "Every 2nd of month")
        #expect(RhythmNote.forDayOfMonth(3, content: "").scheduleDescription == "Every 3rd of month")
        #expect(RhythmNote.forDayOfMonth(4, content: "").scheduleDescription == "Every 4th of month")
        #expect(RhythmNote.forDayOfMonth(21, content: "").scheduleDescription == "Every 21st of month")
        #expect(RhythmNote.forDayOfMonth(22, content: "").scheduleDescription == "Every 22nd of month")
        #expect(RhythmNote.forDayOfMonth(23, content: "").scheduleDescription == "Every 23rd of month")
    }

    @Test func scheduleDescriptionForNoSchedule() {
        let note = RhythmNote(content: "Floating note")
        #expect(note.scheduleDescription == "Anytime")
    }
}

// MARK: - Category Tests

struct CategoryTests {

    @Test func initializationSetsDefaultValues() {
        let category = Category(name: "Health", emoji: "💪", colorHex: "#34C759")

        #expect(category.name == "Health")
        #expect(category.emoji == "💪")
        #expect(category.colorHex == "#34C759")
        #expect(category.sortOrder == 0)
        #expect(category.isSystemCategory == false)
        #expect(category.rhythms.isEmpty)
    }

    @Test func defaultCategoriesProvided() {
        let defaults = Category.defaultCategories

        #expect(defaults.count == 8)
        #expect(defaults.contains { $0.name == "Health" })
        #expect(defaults.contains { $0.name == "Productivity" })
    }

    @Test func createDefaultsReturnsCategories() {
        let categories = Category.createDefaults()

        #expect(categories.count == 8)
        #expect(categories.allSatisfy { $0.isSystemCategory })

        // Check sort orders are set correctly
        for (index, category) in categories.enumerated() {
            #expect(category.sortOrder == index)
        }
    }

    @Test func displayDescriptionFormatsCorrectly() {
        let category = Category(name: "Health", emoji: "💪", colorHex: "#34C759")

        #expect(category.displayDescription == "💪 Health (0 rhythms)")
    }
}

// MARK: - Date Extension Tests

struct DateExtensionTests {

    // MARK: - Start/End of Day

    @Test func startOfDayRemovesTime() {
        let date = Date.make(hour: 15)
        let start = date.startOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test func endOfDayIsLastMoment() {
        let date = Date.make()
        let end = date.endOfDay

        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
    }

    // MARK: - Week Boundaries

    @Test func startOfWeekReturnsCorrectDate() {
        let wednesday = Date.testMonday.adding(days: 2)
        let startOfWeek = wednesday.startOfWeek

        // Start of week should be Sunday or Monday depending on calendar
        let weekday = Weekday.from(date: startOfWeek)
        #expect(weekday == .sunday || weekday == .monday)
    }

    // MARK: - Month Boundaries

    @Test func startOfMonthReturnsFirstDay() {
        let midMonth = Date.make(day: 15)
        let start = midMonth.startOfMonth

        let day = Calendar.current.component(.day, from: start)
        #expect(day == 1)
    }

    // MARK: - Weekday Property

    @Test func weekdayPropertyReturnsCorrectDay() {
        let monday = Date.testMonday
        #expect(monday.weekday == .monday)
        #expect(monday.adding(days: 5).weekday == .saturday)
    }

    // MARK: - Day of Month

    @Test func dayOfMonthReturnsCorrectDay() {
        let date = Date.make(day: 25)
        #expect(date.dayOfMonth == 25)
    }

    // MARK: - Date Comparisons

    @Test func isSameDayComparesCorrectly() {
        let date1 = Date.make(hour: 9)
        let date2 = Date.make(hour: 17)
        let differentDay = Date.make(day: 16)

        #expect(date1.isSameDay(as: date2) == true)
        #expect(date1.isSameDay(as: differentDay) == false)
    }

    @Test func isSameWeekComparesCorrectly() {
        let monday = Date.testMonday
        let friday = monday.adding(days: 4)
        let nextMonday = monday.adding(days: 7)

        #expect(monday.isSameWeek(as: friday) == true)
        #expect(monday.isSameWeek(as: nextMonday) == false)
    }

    @Test func isSameMonthComparesCorrectly() {
        let jan15 = Date.make(month: 1, day: 15)
        let jan25 = Date.make(month: 1, day: 25)
        let feb15 = Date.make(month: 2, day: 15)

        #expect(jan15.isSameMonth(as: jan25) == true)
        #expect(jan15.isSameMonth(as: feb15) == false)
    }

    // MARK: - Days Between

    @Test func daysBetweenCalculatesCorrectly() {
        let date1 = Date.make(day: 10)
        let date2 = Date.make(day: 15)

        #expect(date1.daysBetween(date2) == 5)
        #expect(date2.daysBetween(date1) == -5)
    }

    // MARK: - Adding Days

    @Test func addingDaysWorks() {
        let date = Date.make(day: 10)

        #expect(date.adding(days: 5).dayOfMonth == 15)
        #expect(date.adding(days: -5).dayOfMonth == 5)
    }

    // MARK: - Calendar Dates

    @Test func calendarDatesFromRangeReturnsAllDays() {
        let start = Date.make(day: 1)
        let end = Date.make(day: 5)

        let dates = Calendar.current.dates(from: start, to: end)

        #expect(dates.count == 5)
        #expect(dates[0].dayOfMonth == 1)
        #expect(dates[4].dayOfMonth == 5)
    }

    @Test func datesInWeekReturnsSevenDays() {
        let date = Date.make()
        let dates = Calendar.current.datesInWeek(containing: date)

        #expect(dates.count == 7)
    }
}

// MARK: - Color Hex Extension Tests

struct ColorHexTests {

    @Test func colorFromValidHex() {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)
    }

    @Test func colorFromHexWithoutHash() {
        let color = Color(hex: "00FF00")
        #expect(color != nil)
    }

    @Test func colorFromInvalidHexReturnsNil() {
        let color = Color(hex: "invalid")
        #expect(color == nil)
    }

    @Test func colorFrom8CharHex() {
        let color = Color(hex: "#FF000080") // Red with 50% alpha
        #expect(color != nil)
    }
}
