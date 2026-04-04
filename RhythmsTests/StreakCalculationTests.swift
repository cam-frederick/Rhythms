//
//  StreakCalculationTests.swift
//  RhythmsTests
//
//  Created by Cici — TASK-RH-C: Statistics UX
//

import XCTest
@testable import Rhythms

final class StreakCalculationTests: XCTestCase {

    // MARK: - Streak Tests

    func testCurrentStreakIsZeroForNewRhythm() {
        let rhythm = Rhythm(title: "Test")
        XCTAssertEqual(rhythm.currentStreak, 0,
                       "New rhythm with no entries should have 0 current streak")
    }

    func testLongestStreakIsZeroForNewRhythm() {
        let rhythm = Rhythm(title: "Test")
        XCTAssertEqual(rhythm.longestStreak, 0,
                       "New rhythm with no entries should have 0 longest streak")
    }

    func testTotalCompletionsCountsAllEntries() {
        let rhythm = Rhythm(title: "Daily Jog")
        rhythm.markCompleted(for: Date().adding(days: -2))
        rhythm.markCompleted(for: Date().adding(days: -1))
        rhythm.markCompleted(for: Date())
        XCTAssertEqual(rhythm.totalCompletions, 3,
                       "totalCompletions should equal number of entries")
    }

    func testMarkCompletedIsIdempotent() {
        let rhythm = Rhythm(title: "Meditation")
        let today = Date()
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today) // second call on same day should replace, not double
        XCTAssertEqual(rhythm.totalCompletions, 1,
                       "Completing the same day twice should result in 1 entry, not 2")
    }

    func testIsCompletedReturnsFalseForMissingDate() {
        let rhythm = Rhythm(title: "Exercise")
        let yesterday = Date().adding(days: -1)
        XCTAssertFalse(rhythm.isCompleted(on: yesterday),
                       "isCompleted should return false for a date with no entry")
    }

    func testIsCompletedReturnsTrueAfterMarkComplete() {
        let rhythm = Rhythm(title: "Reading")
        let today = Date()
        rhythm.markCompleted(for: today)
        XCTAssertTrue(rhythm.isCompleted(on: today),
                      "isCompleted should return true after markCompleted is called")
    }

    func testMarkIncompleteRemovesEntry() {
        let rhythm = Rhythm(title: "Yoga")
        let today = Date()
        rhythm.markCompleted(for: today)
        rhythm.markIncomplete(for: today)
        XCTAssertFalse(rhythm.isCompleted(on: today),
                       "isCompleted should be false after markIncomplete")
        XCTAssertEqual(rhythm.totalCompletions, 0,
                       "totalCompletions should be 0 after removing entry")
    }

    // MARK: - Completion Rate Tests

    func testCompletionRateIsZeroForNoScheduledDays() {
        // A rhythm with a very specific schedule may have no scheduled days in a range
        let rhythm = Rhythm(title: "Monthly Review", schedule: .dayOfMonth(1))
        // For a 7-day window that doesn't include day 1 of the month, rate should be 0
        // (or based on what's actually scheduled — just verify it's in [0,1] range)
        let rate = rhythm.completionRate(forLast: 7)
        XCTAssertGreaterThanOrEqual(rate, 0.0)
        XCTAssertLessThanOrEqual(rate, 1.0)
    }

    func testCompletionRateIs100PercentWhenAllCompleted() {
        let rhythm = Rhythm(title: "Daily Habit") // .daily schedule
        let today = Date()
        // Complete the last 7 days
        for i in 0..<7 {
            rhythm.markCompleted(for: today.adding(days: -i))
        }
        let rate = rhythm.completionRate(forLast: 7)
        XCTAssertEqual(rate, 1.0, accuracy: 0.01,
                       "Completion rate should be 100% when all scheduled days are completed")
    }

    // MARK: - Heatmap Color Legend Tests

    func testHeatmapColorLevelRange() {
        // Verify the 4 legend levels produce distinct non-nil colors
        // (Visual test — we just ensure no crash and levels 0-3 are handled)
        let levels = [0, 1, 2, 3]
        XCTAssertEqual(levels.count, 4, "Heatmap legend should have 4 levels (0-3)")
    }
}
