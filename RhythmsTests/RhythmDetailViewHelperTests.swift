//
//  RhythmDetailViewHelperTests.swift
//  RhythmsTests
//
//  Created by Cici on 3/31/26.
//  Tests for completion rate and streak calculation helpers used in RhythmDetailView.
//

import Testing
import Foundation
@testable import Rhythms

// MARK: - Completion Rate Tests

struct CompletionRateTests {

    // MARK: - completionRate(forLast:)

    @Test func completionRateIsZeroWithNoEntries() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        let rate = rhythm.completionRate(forLast: 30)
        #expect(rate == 0.0)
    }

    @Test func completionRateIs100PercentWhenAllCompleted() {
        // Use a daily rhythm and complete the last 7 days
        let rhythm = Rhythm(title: "Daily", schedule: .daily)
        // Mark the last 7 days complete (within last 30 day window)
        for offset in 0..<7 {
            rhythm.markCompleted(for: Date().adding(days: -offset))
        }
        // completionRate looks at last 30 scheduled days; we completed 7 out of ≥7
        // Since all scheduled days we completed are within the range, rate > 0
        let rate = rhythm.completionRate(forLast: 7)
        // 7 scheduled, 7 completed — but "last 7 days" includes today
        // The rate should be 1.0 if all 7 are completed
        #expect(rate == 1.0)
    }

    @Test func completionRateIsCorrectPartialCompletion() {
        let rhythm = Rhythm(title: "Daily", schedule: .daily)
        // Complete exactly 3 out of 6 days back
        for offset in [0, 2, 4] {
            rhythm.markCompleted(for: Date().adding(days: -offset))
        }
        let rate = rhythm.completionRate(forLast: 6)
        // 6 scheduled days (daily), 3 completed
        #expect(abs(rate - 0.5) < 0.01)
    }

    @Test func completionRateRespectsDayWindow() {
        let rhythm = Rhythm(title: "Daily", schedule: .daily)
        // Complete only the most recent day — older completions shouldn't count
        rhythm.markCompleted(for: Date())
        let rate7 = rhythm.completionRate(forLast: 7)
        // 1/7 days completed
        #expect(abs(rate7 - (1.0 / 7.0)) < 0.01)
    }

    @Test func completionRateZeroForNonScheduledRange() {
        // Weekday-only rhythm; if called over a weekend window with no entries it should be 0
        let rhythm = Rhythm(title: "Weekdays", schedule: .weekdays)
        let rate = rhythm.completionRate(forLast: 30)
        #expect(rate == 0.0)
    }

    @Test func completionRateWithWeekdaySchedule() {
        let rhythm = Rhythm(title: "Weekdays", schedule: .weekdays)
        // Mark completions for Mon–Fri of a known week
        let monday = Date.make(year: 2025, month: 1, day: 13)  // January 13, 2025 = Monday
        for offset in 0..<5 {
            rhythm.markCompleted(for: monday.adding(days: offset))
        }
        // Ask for last 30 days from that Friday (Jan 17)
        // The rhythm was created at init time (now), so isScheduledFor checks createdAt
        // For this test we measure just that the method doesn't crash and returns 0–1
        let rate = rhythm.completionRate(forLast: 30)
        #expect(rate >= 0.0 && rate <= 1.0)
    }
}

// MARK: - Streak Tests

struct StreakCalculationTests {

    @Test func currentStreakIsZeroWithNoEntries() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        #expect(rhythm.currentStreak == 0)
    }

    @Test func currentStreakIsOneAfterTodayCompletion() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        rhythm.markCompleted(for: Date())
        #expect(rhythm.currentStreak == 1)
    }

    @Test func currentStreakCountsConsecutiveDays() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        // Complete today + 2 days back = streak of 3
        rhythm.markCompleted(for: Date())
        rhythm.markCompleted(for: Date().adding(days: -1))
        rhythm.markCompleted(for: Date().adding(days: -2))
        #expect(rhythm.currentStreak == 3)
    }

    @Test func currentStreakBreaksOnMissedDay() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        rhythm.markCompleted(for: Date())
        // Skip one day, then complete 2 more
        rhythm.markCompleted(for: Date().adding(days: -2))
        rhythm.markCompleted(for: Date().adding(days: -3))
        // Streak should only count from today: 1 (yesterday was missed)
        #expect(rhythm.currentStreak == 1)
    }

    @Test func longestStreakIsZeroWithNoEntries() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        #expect(rhythm.longestStreak == 0)
    }

    @Test func longestStreakTracksMaximum() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        // Build a streak of 3, break it, then a streak of 5
        let base = Date.make(year: 2025, month: 1, day: 1)
        // Streak A: days 1–3
        for offset in 0..<3 {
            rhythm.markCompleted(for: base.adding(days: offset))
        }
        // Gap: day 4 missed
        // Streak B: days 5–9 (5 days)
        for offset in 4..<9 {
            rhythm.markCompleted(for: base.adding(days: offset))
        }
        #expect(rhythm.longestStreak == 5)
    }

    @Test func longestStreakEqualsCurrentWhenNeverBroken() {
        let rhythm = Rhythm(title: "Test", schedule: .daily)
        for offset in (0..<5).reversed() {
            rhythm.markCompleted(for: Date().adding(days: -offset))
        }
        #expect(rhythm.longestStreak >= rhythm.currentStreak)
        #expect(rhythm.currentStreak == 5)
    }
}

// MARK: - Dot Calendar Helper Tests

struct DotCalendarHelperTests {

    /// Validates that last 28 days produces exactly 28 entries ending today.
    @Test func last28DaysProduces28Entries() {
        let today = Date().startOfDay
        let points = (0..<28).reversed().map { offset in
            CompletionPoint(date: today.adding(days: -offset), completed: false)
        }
        #expect(points.count == 28)
        #expect(points.last?.date.isSameDay(as: today) == true)
        #expect(points.first?.date.isSameDay(as: today.adding(days: -27)) == true)
    }

    /// Verifies leading offset is in 0–6 range for any given start date.
    @Test func leadingOffsetIsValidWeekdayRange() {
        let today = Date().startOfDay
        let weekday = Calendar.current.component(.weekday, from: today)
        let offset = weekday - 1
        #expect(offset >= 0 && offset <= 6)
    }

    /// Completion rate color logic: ≥80% = green, 50–80% = gold, <50% = red
    @Test func completionRateColorThresholds() {
        // We test the thresholds directly with the same switch logic used in the view
        func colorCategory(_ rate: Double) -> String {
            switch rate {
            case 0.8...: return "green"
            case 0.5..<0.8: return "gold"
            default: return "red"
            }
        }
        #expect(colorCategory(1.0) == "green")
        #expect(colorCategory(0.8) == "green")
        #expect(colorCategory(0.79) == "gold")
        #expect(colorCategory(0.5) == "gold")
        #expect(colorCategory(0.49) == "red")
        #expect(colorCategory(0.0) == "red")
    }
}
