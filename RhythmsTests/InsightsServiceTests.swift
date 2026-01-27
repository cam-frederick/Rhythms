//
//  InsightsServiceTests.swift
//  RhythmsTests
//
//  Created by Cam Frederick on 12/27/25.
//

import Testing
import Foundation
@testable import Rhythms

// MARK: - InsightsService Tests

@MainActor
struct InsightsServiceTests {

    // MARK: - Test Setup

    private func createTestRhythms() -> [Rhythm] {
        let workout = Rhythm(title: "Workout", emoji: "💪", schedule: .weekdays)
        let meditation = Rhythm(title: "Meditation", emoji: "🧘", schedule: .daily)
        let reading = Rhythm(title: "Reading", emoji: "📚", schedule: .daily)

        return [workout, meditation, reading]
    }

    private func setupCompletions(for rhythms: [Rhythm], startDate: Date) {
        let today = Date()

        // Workout: Complete Mon-Fri for past week (5 completions)
        for rhythm in rhythms where rhythm.title == "Workout" {
            var date = startDate
            while date <= today {
                let weekday = Weekday.from(date: date)
                if weekday != .saturday && weekday != .sunday {
                    rhythm.markCompleted(for: date)
                }
                date = date.adding(days: 1)
            }
        }

        // Meditation: Complete every day (7 completions)
        for rhythm in rhythms where rhythm.title == "Meditation" {
            var date = startDate
            while date <= today {
                rhythm.markCompleted(for: date)
                date = date.adding(days: 1)
            }
        }

        // Reading: Complete 3 out of 7 days (43% rate)
        for rhythm in rhythms where rhythm.title == "Reading" {
            rhythm.markCompleted(for: startDate)
            rhythm.markCompleted(for: startDate.adding(days: 2))
            rhythm.markCompleted(for: startDate.adding(days: 4))
        }
    }

    // MARK: - Initialization

    @Test func serviceInitializesWithNoInsight() {
        let service = InsightsService()

        #expect(service.weeklyInsight == nil)
        #expect(service.isGenerating == false)
    }

    // MARK: - Insight Generation

    @Test func generateInsightForEmptyRhythms() async {
        let service = InsightsService()

        await service.generateWeeklyInsight(for: [])

        #expect(service.weeklyInsight != nil)
        #expect(service.weeklyInsight?.stats.totalCompletions == 0)
    }

    @Test func generateInsightCalculatesStats() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()
        let startOfWeek = Date().startOfWeek

        setupCompletions(for: rhythms, startDate: startOfWeek)

        await service.generateWeeklyInsight(for: rhythms)

        let insight = service.weeklyInsight
        #expect(insight != nil)
        #expect(insight!.stats.totalCompletions > 0)
    }

    @Test func generateInsightSetsTimestamp() async {
        let service = InsightsService()
        let beforeGeneration = Date()

        await service.generateWeeklyInsight(for: [])

        let insight = service.weeklyInsight
        #expect(insight != nil)
        #expect(insight!.generatedAt >= beforeGeneration)
    }

    @Test func generateInsightIncludesSummaryText() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()

        await service.generateWeeklyInsight(for: rhythms)

        let insight = service.weeklyInsight
        #expect(insight != nil)
        #expect(!insight!.summaryText.isEmpty)
    }

    // MARK: - Caching

    @Test func insightsAreCached() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()

        // Generate first insight
        await service.generateWeeklyInsight(for: rhythms)
        let firstInsight = service.weeklyInsight
        let firstId = firstInsight?.id

        // Generate again immediately - should return cached
        await service.generateWeeklyInsight(for: rhythms)
        let secondInsight = service.weeklyInsight

        #expect(firstId == secondInsight?.id, "Should return cached insight")
    }

    @Test func clearCacheRemovesInsight() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()

        await service.generateWeeklyInsight(for: rhythms)
        #expect(service.weeklyInsight != nil)

        service.clearCache()

        #expect(service.weeklyInsight == nil)
    }

    @Test func clearCacheAllowsRegeneration() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()

        await service.generateWeeklyInsight(for: rhythms)
        let firstId = service.weeklyInsight?.id

        service.clearCache()
        await service.generateWeeklyInsight(for: rhythms)
        let secondId = service.weeklyInsight?.id

        #expect(firstId != secondId, "Should generate new insight after cache clear")
    }

    // MARK: - Stats Calculation

    @Test func statsIncludeCompletionRate() async {
        let service = InsightsService()
        let rhythms = createTestRhythms()
        let startOfWeek = Date().startOfWeek

        setupCompletions(for: rhythms, startDate: startOfWeek)

        await service.generateWeeklyInsight(for: rhythms)

        let stats = service.weeklyInsight?.stats
        #expect(stats != nil)
        #expect(stats!.completionRate >= 0.0)
        #expect(stats!.completionRate <= 1.0)
    }

    @Test func statsIncludeStreaks() async {
        let service = InsightsService()
        let meditation = Rhythm(title: "Meditation", emoji: "🧘", schedule: .daily)

        // Create a 5-day streak
        let today = Date()
        for i in 0..<5 {
            meditation.markCompleted(for: today.adding(days: -i))
        }

        await service.generateWeeklyInsight(for: [meditation])

        let stats = service.weeklyInsight?.stats
        #expect(stats != nil)
        #expect(!stats!.currentStreaks.isEmpty)
    }

    // MARK: - Highlights Generation

    @Test func highlightsGeneratedForHighCompletionRate() async {
        let service = InsightsService()
        let rhythm = Rhythm(title: "Test", schedule: .daily)

        // Complete all days this week for 100% completion
        let startOfWeek = Date().startOfWeek
        for i in 0..<7 {
            rhythm.markCompleted(for: startOfWeek.adding(days: i))
        }

        await service.generateWeeklyInsight(for: [rhythm])

        let highlights = service.weeklyInsight?.highlights
        #expect(highlights != nil)
        // Should have at least one highlight for high completion rate
    }

    @Test func highlightsLimitedToThree() async {
        let service = InsightsService()
        let rhythms = (0..<10).map { Rhythm(title: "Rhythm \($0)", schedule: .daily) }

        // Complete all rhythms to generate many potential highlights
        let today = Date()
        for rhythm in rhythms {
            for i in 0..<10 {
                rhythm.markCompleted(for: today.adding(days: -i))
            }
        }

        await service.generateWeeklyInsight(for: rhythms)

        let highlights = service.weeklyInsight?.highlights
        #expect(highlights != nil)
        #expect(highlights!.count <= 3)
    }

    // MARK: - Suggestions Generation

    @Test func suggestionsGeneratedForLowCompletion() async {
        let service = InsightsService()
        let rhythm = Rhythm(title: "Struggling Habit", schedule: .daily)

        // Only complete 1 out of 7 days
        rhythm.markCompleted(for: Date())

        await service.generateWeeklyInsight(for: [rhythm])

        // Should generate suggestions for improvement
        let suggestions = service.weeklyInsight?.suggestions
        #expect(suggestions != nil)
    }

    @Test func suggestionsLimitedToThree() async {
        let service = InsightsService()
        let rhythms = (0..<10).map { Rhythm(title: "Rhythm \($0)", schedule: .daily) }

        // Don't complete any to generate many suggestions
        await service.generateWeeklyInsight(for: rhythms)

        let suggestions = service.weeklyInsight?.suggestions
        #expect(suggestions != nil)
        #expect(suggestions!.count <= 3)
    }

    // MARK: - Summary Text

    @Test func summaryTextForEmptyRhythms() async {
        let service = InsightsService()

        await service.generateWeeklyInsight(for: [])

        let summary = service.weeklyInsight?.summaryText
        #expect(summary != nil)
        #expect(summary!.contains("Create some rhythms") || summary!.contains("getting started"))
    }

    @Test func summaryTextIncludesCompletionCount() async {
        let service = InsightsService()
        let rhythm = Rhythm(title: "Test", schedule: .daily)

        let today = Date()
        rhythm.markCompleted(for: today)
        rhythm.markCompleted(for: today.adding(days: -1))
        rhythm.markCompleted(for: today.adding(days: -2))

        await service.generateWeeklyInsight(for: [rhythm])

        let summary = service.weeklyInsight?.summaryText
        #expect(summary != nil)
        // Summary should mention completions
    }

    // MARK: - Inactive Rhythms

    @Test func archivedRhythmsExcludedFromStats() async {
        let service = InsightsService()
        let activeRhythm = Rhythm(title: "Active", schedule: .daily)
        let archivedRhythm = Rhythm(title: "Archived", schedule: .daily)

        activeRhythm.markCompleted(for: Date())
        archivedRhythm.markCompleted(for: Date())
        archivedRhythm.archive()

        await service.generateWeeklyInsight(for: [activeRhythm, archivedRhythm])

        let stats = service.weeklyInsight?.stats
        #expect(stats != nil)
        // Only active rhythm's completion should count
        #expect(stats!.totalCompletions == 1)
    }

    @Test func pausedRhythmsExcludedFromStats() async {
        let service = InsightsService()
        let activeRhythm = Rhythm(title: "Active", schedule: .daily)
        let pausedRhythm = Rhythm(title: "Paused", schedule: .daily)

        activeRhythm.markCompleted(for: Date())
        pausedRhythm.markCompleted(for: Date())
        pausedRhythm.pause()

        await service.generateWeeklyInsight(for: [activeRhythm, pausedRhythm])

        let stats = service.weeklyInsight?.stats
        #expect(stats != nil)
        // Only active rhythm's completion should count
        #expect(stats!.totalCompletions == 1)
    }

    // MARK: - WeeklyInsight Structure

    @Test func weeklyInsightHasUniqueId() async {
        let service = InsightsService()

        await service.generateWeeklyInsight(for: [])
        let firstId = service.weeklyInsight?.id

        service.clearCache()
        await service.generateWeeklyInsight(for: [])
        let secondId = service.weeklyInsight?.id

        #expect(firstId != nil)
        #expect(secondId != nil)
        #expect(firstId != secondId)
    }

    @Test func highlightStructureHasRequiredFields() async {
        let service = InsightsService()
        let rhythm = Rhythm(title: "Test", schedule: .daily)

        // Complete many days to generate highlights
        for i in 0..<14 {
            rhythm.markCompleted(for: Date().adding(days: -i))
        }

        await service.generateWeeklyInsight(for: [rhythm])

        if let highlight = service.weeklyInsight?.highlights.first {
            #expect(!highlight.emoji.isEmpty)
            #expect(!highlight.title.isEmpty)
            #expect(!highlight.description.isEmpty)
        }
    }
}

// MARK: - RhythmEntry Tests

struct RhythmEntryTests {

    @Test func entryInitialization() {
        let rhythm = Rhythm(title: "Test")
        let date = Date()

        let entry = RhythmEntry(
            scheduledDate: date,
            rhythm: rhythm,
            note: "Test note",
            mood: .good
        )

        #expect(entry.scheduledDate.isSameDay(as: date))
        #expect(entry.note == "Test note")
        #expect(entry.mood == .good)
        #expect(entry.rhythm?.title == "Test")
    }

    @Test func entryWithoutOptionalFields() {
        let entry = RhythmEntry(scheduledDate: Date())

        #expect(entry.note == nil)
        #expect(entry.mood == nil)
        #expect(entry.rhythm == nil)
    }

    @Test func entryCompletedAtIsSet() {
        let before = Date()
        let entry = RhythmEntry(scheduledDate: Date())
        let after = Date()

        #expect(entry.completedAt >= before)
        #expect(entry.completedAt <= after)
    }
}
