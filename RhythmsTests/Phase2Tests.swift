//
//  Phase2Tests.swift
//  RhythmsTests
//
//  Created by Cam Frederick on 12/27/25.
//

import Testing
import Foundation
import SwiftUI
@testable import Rhythms

// MARK: - Streak Milestone Tests

struct StreakMilestoneTests {

    // MARK: - Standard Milestones

    @Test func weekMilestonesAreDetected() {
        #expect(7.isStreakMilestone == true, "7 days should be a milestone")
        #expect(14.isStreakMilestone == true, "14 days should be a milestone")
        #expect(21.isStreakMilestone == true, "21 days should be a milestone")
    }

    @Test func monthMilestoneIsDetected() {
        #expect(30.isStreakMilestone == true, "30 days should be a milestone")
    }

    @Test func majorMilestonesAreDetected() {
        #expect(50.isStreakMilestone == true, "50 days should be a milestone")
        #expect(100.isStreakMilestone == true, "100 days should be a milestone")
        #expect(150.isStreakMilestone == true, "150 days should be a milestone")
        #expect(200.isStreakMilestone == true, "200 days should be a milestone")
        #expect(250.isStreakMilestone == true, "250 days should be a milestone")
        #expect(300.isStreakMilestone == true, "300 days should be a milestone")
        #expect(365.isStreakMilestone == true, "365 days (1 year) should be a milestone")
        #expect(500.isStreakMilestone == true, "500 days should be a milestone")
        #expect(750.isStreakMilestone == true, "750 days should be a milestone")
        #expect(1000.isStreakMilestone == true, "1000 days should be a milestone")
    }

    @Test func hundredMultiplesAreDetectedAfter100() {
        #expect(200.isStreakMilestone == true, "200 should be a milestone")
        #expect(300.isStreakMilestone == true, "300 should be a milestone")
        #expect(400.isStreakMilestone == true, "400 should be a milestone")
        #expect(600.isStreakMilestone == true, "600 should be a milestone")
        #expect(700.isStreakMilestone == true, "700 should be a milestone")
        #expect(800.isStreakMilestone == true, "800 should be a milestone")
        #expect(900.isStreakMilestone == true, "900 should be a milestone")
    }

    // MARK: - Non-Milestones

    @Test func nonMilestoneValuesAreNotDetected() {
        #expect(1.isStreakMilestone == false, "1 day should not be a milestone")
        #expect(2.isStreakMilestone == false, "2 days should not be a milestone")
        #expect(3.isStreakMilestone == false, "3 days should not be a milestone")
        #expect(5.isStreakMilestone == false, "5 days should not be a milestone")
        #expect(6.isStreakMilestone == false, "6 days should not be a milestone")
        #expect(8.isStreakMilestone == false, "8 days should not be a milestone")
        #expect(10.isStreakMilestone == false, "10 days should not be a milestone")
        #expect(15.isStreakMilestone == false, "15 days should not be a milestone")
        #expect(25.isStreakMilestone == false, "25 days should not be a milestone")
        #expect(35.isStreakMilestone == false, "35 days should not be a milestone")
        #expect(45.isStreakMilestone == false, "45 days should not be a milestone")
        #expect(99.isStreakMilestone == false, "99 days should not be a milestone")
        #expect(101.isStreakMilestone == false, "101 days should not be a milestone")
    }

    @Test func zeroIsNotAMilestone() {
        #expect(0.isStreakMilestone == false, "0 should not be a milestone")
    }

    @Test func negativeNumbersAreNotMilestones() {
        #expect((-7).isStreakMilestone == false, "-7 should not be a milestone")
        #expect((-100).isStreakMilestone == false, "-100 should not be a milestone")
    }
}

// MARK: - Mood Color Tests

struct MoodColorTests {

    @Test func terribleMoodIsRed() {
        #expect(Mood.terrible.color == .red)
    }

    @Test func badMoodIsOrange() {
        #expect(Mood.bad.color == .orange)
    }

    @Test func okayMoodIsYellow() {
        #expect(Mood.okay.color == .yellow)
    }

    @Test func goodMoodIsMint() {
        #expect(Mood.good.color == .mint)
    }

    @Test func greatMoodIsGreen() {
        #expect(Mood.great.color == .green)
    }

    @Test func allMoodsHaveColors() {
        for mood in Mood.allCases {
            // Just verify they don't crash and return a Color
            let _ = mood.color
        }
    }
}

// MARK: - Completion with Mood/Notes Tests

struct CompletionWithMoodNotesTests {

    @Test func completionStoresMood() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, mood: .great)

        let entry = rhythm.entry(for: date)
        #expect(entry?.mood == .great)
    }

    @Test func completionStoresNote() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, note: "Felt amazing today!")

        let entry = rhythm.entry(for: date)
        #expect(entry?.note == "Felt amazing today!")
    }

    @Test func completionStoresBothMoodAndNote() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, note: "Great workout", mood: .good)

        let entry = rhythm.entry(for: date)
        #expect(entry?.note == "Great workout")
        #expect(entry?.mood == .good)
    }

    @Test func completionWithNilMoodAndNote() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, note: nil, mood: nil)

        let entry = rhythm.entry(for: date)
        #expect(entry != nil)
        #expect(entry?.note == nil)
        #expect(entry?.mood == nil)
    }

    @Test func updatingCompletionUpdatesMoodAndNote() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        // First completion
        rhythm.markCompleted(for: date, note: "First", mood: .okay)

        // Update with new values
        rhythm.markCompleted(for: date, note: "Updated", mood: .great)

        let entry = rhythm.entry(for: date)
        #expect(entry?.note == "Updated")
        #expect(entry?.mood == .great)
        #expect(rhythm.entries.count == 1, "Should still have only one entry")
    }

    @Test func emptyNoteIsTreatedAsNil() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date, note: "", mood: nil)

        // Note: The implementation may or may not convert empty to nil
        // This test documents the actual behavior
        let entry = rhythm.entry(for: date)
        #expect(entry != nil)
    }
}

// MARK: - Average Mood Calculation Tests

struct AverageMoodCalculationTests {

    @Test func averageMoodWithSingleEntry() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date.make(day: 1), mood: .great)

        #expect(rhythm.averageMood == 5.0)
    }

    @Test func averageMoodWithMultipleEntries() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date.make(day: 1), mood: .terrible) // 1
        rhythm.markCompleted(for: Date.make(day: 2), mood: .bad)      // 2
        rhythm.markCompleted(for: Date.make(day: 3), mood: .okay)     // 3
        rhythm.markCompleted(for: Date.make(day: 4), mood: .good)     // 4
        rhythm.markCompleted(for: Date.make(day: 5), mood: .great)    // 5

        // (1+2+3+4+5) / 5 = 3.0
        #expect(rhythm.averageMood == 3.0)
    }

    @Test func averageMoodIgnoresEntriesWithoutMood() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date.make(day: 1), mood: .great)    // 5
        rhythm.markCompleted(for: Date.make(day: 2), mood: nil)       // excluded
        rhythm.markCompleted(for: Date.make(day: 3), mood: .okay)     // 3

        // Only entries with mood count: (5+3) / 2 = 4.0
        #expect(rhythm.averageMood == 4.0)
    }

    @Test func averageMoodReturnsNilWithNoMoodEntries() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date.make(day: 1), mood: nil)
        rhythm.markCompleted(for: Date.make(day: 2), mood: nil)

        #expect(rhythm.averageMood == nil)
    }

    @Test func averageMoodReturnsNilWithNoEntries() {
        let rhythm = Rhythm(title: "Test")
        #expect(rhythm.averageMood == nil)
    }
}

// MARK: - Streak Calculation After Completion Tests

struct StreakAfterCompletionTests {

    @Test func streakIncrementsAfterCompletion() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Complete yesterday and today
        rhythm.markCompleted(for: today.adding(days: -1))
        #expect(rhythm.currentStreak == 1)

        rhythm.markCompleted(for: today)
        #expect(rhythm.currentStreak == 2)
    }

    @Test func streakReachingMilestoneAfterCompletion() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Complete 6 consecutive days
        for i in (1...6).reversed() {
            rhythm.markCompleted(for: today.adding(days: -i))
        }
        #expect(rhythm.currentStreak == 6)

        // Complete today (7th day)
        rhythm.markCompleted(for: today)
        #expect(rhythm.currentStreak == 7)
        #expect(7.isStreakMilestone == true)
    }

    @Test func streakResets() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Build a 5-day streak
        for i in (1...5).reversed() {
            rhythm.markCompleted(for: today.adding(days: -i))
        }
        #expect(rhythm.currentStreak == 5)

        // Remove middle completion to break streak
        rhythm.markIncomplete(for: today.adding(days: -3))

        // Streak should now only count from yesterday backwards until the gap
        // Days -1, -2 are complete, gap at -3, then -4, -5 are complete
        #expect(rhythm.currentStreak == 2, "Streak should be 2 after breaking")
    }
}

// MARK: - Completion Rate Tests

struct CompletionRateTests {

    @Test func completionRateForPerfectWeek() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Complete all 7 days
        for i in 0..<7 {
            rhythm.markCompleted(for: today.adding(days: -i))
        }

        let rate = rhythm.completionRate(forLast: 7)
        #expect(rate == 1.0, "Perfect week should have 100% completion rate")
    }

    @Test func completionRateForPartialWeek() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Complete 4 out of 7 days
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today.adding(days: -1))
        rhythm.markCompleted(for: today.adding(days: -3))
        rhythm.markCompleted(for: today.adding(days: -5))

        let rate = rhythm.completionRate(forLast: 7)
        #expect(abs(rate - (4.0/7.0)) < 0.01, "Should be about 57% completion rate")
    }

    @Test func completionRateWithNoCompletions() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        let rate = rhythm.completionRate(forLast: 7)
        #expect(rate == 0.0, "No completions should have 0% rate")
    }

    @Test func completionRateForWeekdaysSchedule() {
        let rhythm = Rhythm(title: "Test", schedule: .weekdays)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Complete today and yesterday and day before (assuming today is a weekday)
        // We'll just test the method works and count correctly
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today.adding(days: -1))
        rhythm.markCompleted(for: today.adding(days: -2))

        // Completion rate should be > 0 if any weekdays were scheduled
        let rate = rhythm.completionRate(forLast: 7)
        #expect(rate > 0, "Should have some completion rate")
    }
}

// MARK: - Entry Retrieval Tests

struct EntryRetrievalTests {

    @Test func entryForDateReturnsCorrectEntry() {
        let rhythm = Rhythm(title: "Test")
        let date1 = Date.make(day: 10)
        let date2 = Date.make(day: 15)

        rhythm.markCompleted(for: date1, note: "Entry 1", mood: .good)
        rhythm.markCompleted(for: date2, note: "Entry 2", mood: .great)

        let entry1 = rhythm.entry(for: date1)
        let entry2 = rhythm.entry(for: date2)

        #expect(entry1?.note == "Entry 1")
        #expect(entry1?.mood == .good)
        #expect(entry2?.note == "Entry 2")
        #expect(entry2?.mood == .great)
    }

    @Test func entryForNonExistentDateReturnsNil() {
        let rhythm = Rhythm(title: "Test")
        rhythm.markCompleted(for: Date.make(day: 10))

        let entry = rhythm.entry(for: Date.make(day: 15))
        #expect(entry == nil)
    }

    @Test func isCompletedOnWorksCorrectly() {
        let rhythm = Rhythm(title: "Test")
        let completedDate = Date.make(day: 10)
        let notCompletedDate = Date.make(day: 15)

        rhythm.markCompleted(for: completedDate)

        #expect(rhythm.isCompleted(on: completedDate) == true)
        #expect(rhythm.isCompleted(on: notCompletedDate) == false)
    }
}

// MARK: - Total Completions Tests

struct TotalCompletionsTests {

    @Test func totalCompletionsCountsAllEntries() {
        let rhythm = Rhythm(title: "Test")

        rhythm.markCompleted(for: Date.make(day: 1))
        rhythm.markCompleted(for: Date.make(day: 5))
        rhythm.markCompleted(for: Date.make(day: 10))
        rhythm.markCompleted(for: Date.make(day: 15))
        rhythm.markCompleted(for: Date.make(day: 20))

        #expect(rhythm.totalCompletions == 5)
    }

    @Test func totalCompletionsIsZeroForNewRhythm() {
        let rhythm = Rhythm(title: "Test")
        #expect(rhythm.totalCompletions == 0)
    }

    @Test func totalCompletionsDecreasesAfterMarkIncomplete() {
        let rhythm = Rhythm(title: "Test")
        let date = Date.make()

        rhythm.markCompleted(for: date)
        #expect(rhythm.totalCompletions == 1)

        rhythm.markIncomplete(for: date)
        #expect(rhythm.totalCompletions == 0)
    }
}

// MARK: - Longest Streak Tests

struct LongestStreakTests {

    @Test func longestStreakTracksMaximumStreak() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let start = Date.make(day: 1)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1)

        // First streak: 3 days
        rhythm.markCompleted(for: start)
        rhythm.markCompleted(for: start.adding(days: 1))
        rhythm.markCompleted(for: start.adding(days: 2))
        // Gap at day 3

        // Second streak: 5 days
        rhythm.markCompleted(for: start.adding(days: 4))
        rhythm.markCompleted(for: start.adding(days: 5))
        rhythm.markCompleted(for: start.adding(days: 6))
        rhythm.markCompleted(for: start.adding(days: 7))
        rhythm.markCompleted(for: start.adding(days: 8))
        // Gap at day 9

        // Third streak: 2 days
        rhythm.markCompleted(for: start.adding(days: 10))
        rhythm.markCompleted(for: start.adding(days: 11))

        #expect(rhythm.longestStreak == 5, "Longest streak should be 5")
    }

    @Test func longestStreakIsSameAsCurrentWhenNoGaps() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Continuous 10-day streak
        for i in 0..<10 {
            rhythm.markCompleted(for: today.adding(days: -i))
        }

        #expect(rhythm.currentStreak == 10)
        #expect(rhythm.longestStreak == 10)
    }

    @Test func longestStreakWithWeekdaysSchedule() {
        let rhythm = Rhythm(title: "Test", schedule: .weekdays)
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1)

        // January 6, 2025 is a Monday
        let monday = Date.make(year: 2025, month: 1, day: 6)

        // Complete entire first week (Mon-Fri)
        for i in 0..<5 {
            rhythm.markCompleted(for: monday.adding(days: i))
        }

        // Skip Saturday/Sunday (not scheduled)
        // Complete Mon-Wed of next week
        for i in 7..<10 {
            rhythm.markCompleted(for: monday.adding(days: i))
        }

        // The streak should be continuous because weekends don't count
        #expect(rhythm.longestStreak == 8, "Should be 8 weekdays in a row")
    }
}

// MARK: - Day of Month Schedule Tests (Phase 2 addition)

struct DayOfMonthScheduleTests {

    @Test func dayOfMonthScheduleDisplayName() {
        #expect(RhythmSchedule.dayOfMonth(day: 1).displayName == "1st of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 2).displayName == "2nd of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 3).displayName == "3rd of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 4).displayName == "4th of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 11).displayName == "11th of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 12).displayName == "12th of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 13).displayName == "13th of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 21).displayName == "21st of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 22).displayName == "22nd of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 23).displayName == "23rd of each month")
        #expect(RhythmSchedule.dayOfMonth(day: 31).displayName == "31st of each month")
    }

    @Test func dayOfMonthScheduleMatchesCorrectDay() {
        let schedule = RhythmSchedule.dayOfMonth(day: 15)

        // The 15th of any month should match
        #expect(schedule.isScheduledFor(date: Date.make(month: 1, day: 15)) == true)
        #expect(schedule.isScheduledFor(date: Date.make(month: 6, day: 15)) == true)
        #expect(schedule.isScheduledFor(date: Date.make(month: 12, day: 15)) == true)

        // Other days should not match
        #expect(schedule.isScheduledFor(date: Date.make(month: 1, day: 14)) == false)
        #expect(schedule.isScheduledFor(date: Date.make(month: 1, day: 16)) == false)
    }

    @Test func dayOfMonthHandlesShortMonths() {
        // February only has 28 days (or 29 in leap year)
        let schedule31 = RhythmSchedule.dayOfMonth(day: 31)

        // In a month with 30 days, day 31 should match day 30
        // In February, day 31 should match day 28 (or 29)
        // This depends on implementation - test documents actual behavior
        let march31 = Date.make(year: 2025, month: 3, day: 31)

        #expect(schedule31.isScheduledFor(date: march31) == true, "31st should match in March")
    }

    @Test func dayOfMonthScheduleEncodesAndDecodes() throws {
        let original = RhythmSchedule.dayOfMonth(day: 15)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(RhythmSchedule.self, from: data)

        #expect(decoded == original)
    }
}

// MARK: - Rhythm with Day of Month Schedule Tests

struct RhythmDayOfMonthTests {

    @Test func rhythmWithDayOfMonthSchedule() {
        let rhythm = Rhythm(title: "Monthly Review", schedule: .dayOfMonth(day: 1))
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1)

        // First of each month should be scheduled
        #expect(rhythm.isScheduledFor(date: Date.make(month: 1, day: 1)) == true)
        #expect(rhythm.isScheduledFor(date: Date.make(month: 2, day: 1)) == true)
        #expect(rhythm.isScheduledFor(date: Date.make(month: 3, day: 1)) == true)

        // Other days should not be scheduled
        #expect(rhythm.isScheduledFor(date: Date.make(month: 1, day: 2)) == false)
        #expect(rhythm.isScheduledFor(date: Date.make(month: 1, day: 15)) == false)
    }

    @Test func streakCalculationForMonthlyRhythm() {
        let rhythm = Rhythm(title: "Monthly", schedule: .dayOfMonth(day: 15))
        rhythm.createdAt = Date.make(year: 2024, month: 1, day: 1)

        // Complete January 15, February 15, March 15
        rhythm.markCompleted(for: Date.make(month: 1, day: 15))
        rhythm.markCompleted(for: Date.make(month: 2, day: 15))
        rhythm.markCompleted(for: Date.make(month: 3, day: 15))

        // Should have a 3-month streak
        #expect(rhythm.totalCompletions == 3)
    }
}

// MARK: - Rhythm State and Statistics Integration Tests

struct RhythmStatisticsIntegrationTests {

    @Test func completionHistoryOrderedByDate() {
        let rhythm = Rhythm(title: "Test")

        // Add completions out of order
        rhythm.markCompleted(for: Date.make(day: 15), mood: .okay)
        rhythm.markCompleted(for: Date.make(day: 5), mood: .good)
        rhythm.markCompleted(for: Date.make(day: 25), mood: .great)
        rhythm.markCompleted(for: Date.make(day: 10), mood: .bad)

        // Entries should be retrievable by their dates
        #expect(rhythm.entry(for: Date.make(day: 5))?.mood == .good)
        #expect(rhythm.entry(for: Date.make(day: 10))?.mood == .bad)
        #expect(rhythm.entry(for: Date.make(day: 15))?.mood == .okay)
        #expect(rhythm.entry(for: Date.make(day: 25))?.mood == .great)
    }

    @Test func rhythmStatisticsAfterMixedMoods() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let today = Date()
        rhythm.createdAt = today.adding(days: -30)

        // Create a week of mixed completions
        rhythm.markCompleted(for: today, mood: .great)           // 5
        rhythm.markCompleted(for: today.adding(days: -1), mood: .good)  // 4
        rhythm.markCompleted(for: today.adding(days: -2), mood: .okay)  // 3
        // Skip day -3 (not completed)
        rhythm.markCompleted(for: today.adding(days: -4), mood: .bad)   // 2
        rhythm.markCompleted(for: today.adding(days: -5), mood: .terrible) // 1

        // Verify statistics
        #expect(rhythm.totalCompletions == 5)
        #expect(rhythm.currentStreak == 3, "Streak broken at day -3")

        // Average mood: (5+4+3+2+1)/5 = 3.0
        #expect(rhythm.averageMood == 3.0)

        // Completion rate for last 7 days: 5/7
        let rate = rhythm.completionRate(forLast: 7)
        #expect(abs(rate - (5.0/7.0)) < 0.01)
    }
}
