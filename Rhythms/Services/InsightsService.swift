//
//  InsightsService.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData

/// Service for generating AI-powered insights about rhythm performance
@MainActor
final class InsightsService: ObservableObject {
    @Published var weeklyInsight: WeeklyInsight?
    @Published var isGenerating: Bool = false

    private var cachedInsight: WeeklyInsight?
    private var cacheDate: Date?

    // Cache insights for 1 hour to avoid regenerating unnecessarily
    private let cacheValidityDuration: TimeInterval = 3600

    struct WeeklyInsight: Identifiable {
        let id = UUID()
        let generatedAt: Date
        let summaryText: String
        let highlights: [Highlight]
        let suggestions: [String]
        let stats: Stats

        struct Highlight {
            let emoji: String
            let title: String
            let description: String
        }

        struct Stats {
            let totalCompletions: Int
            let completionRate: Double
            let currentStreaks: [(rhythm: String, streak: Int)]
            let bestDay: Weekday?
            let worstDay: Weekday?
        }
    }

    /// Generates weekly insights for the given rhythms
    func generateWeeklyInsight(for rhythms: [Rhythm]) async {
        // Check cache
        if let cached = cachedInsight,
           let cacheDate = cacheDate,
           Date().timeIntervalSince(cacheDate) < cacheValidityDuration {
            weeklyInsight = cached
            return
        }

        isGenerating = true

        // Simulate async work (for future AI integration)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second

        let insight = buildInsight(for: rhythms)

        cachedInsight = insight
        cacheDate = Date()
        weeklyInsight = insight
        isGenerating = false
    }

    /// Clears the cached insight
    func clearCache() {
        cachedInsight = nil
        cacheDate = nil
        weeklyInsight = nil
    }

    // MARK: - Insight Generation

    private func buildInsight(for rhythms: [Rhythm]) -> WeeklyInsight {
        let activeRhythms = rhythms.filter { $0.isActive }
        let stats = calculateStats(for: activeRhythms)
        let highlights = generateHighlights(for: activeRhythms, stats: stats)
        let suggestions = generateSuggestions(for: activeRhythms, stats: stats)
        let summaryText = generateSummaryText(for: activeRhythms, stats: stats)

        return WeeklyInsight(
            generatedAt: Date(),
            summaryText: summaryText,
            highlights: highlights,
            suggestions: suggestions,
            stats: stats
        )
    }

    private func calculateStats(for rhythms: [Rhythm]) -> WeeklyInsight.Stats {
        let startOfWeek = Date().startOfWeek
        let today = Date()

        var totalCompletions = 0
        var totalScheduled = 0
        var completionsByDay: [Weekday: (completed: Int, scheduled: Int)] = [:]

        // Initialize all days
        for day in Weekday.allCases {
            completionsByDay[day] = (0, 0)
        }

        // Calculate completions for this week
        for rhythm in rhythms {
            let scheduledDates = rhythm.scheduledDates(from: startOfWeek, to: today)
            totalScheduled += scheduledDates.count

            for date in scheduledDates {
                let weekday = date.weekday
                var dayStats = completionsByDay[weekday] ?? (0, 0)
                dayStats.scheduled += 1

                if rhythm.isCompleted(on: date) {
                    totalCompletions += 1
                    dayStats.completed += 1
                }

                completionsByDay[weekday] = dayStats
            }
        }

        // Find best and worst days
        var bestDay: Weekday?
        var worstDay: Weekday?
        var bestRate: Double = -1
        var worstRate: Double = 2

        for (day, stats) in completionsByDay {
            guard stats.scheduled > 0 else { continue }
            let rate = Double(stats.completed) / Double(stats.scheduled)

            if rate > bestRate {
                bestRate = rate
                bestDay = day
            }
            if rate < worstRate {
                worstRate = rate
                worstDay = day
            }
        }

        // Get current streaks
        let streaks = rhythms
            .filter { $0.currentStreak > 0 }
            .sorted { $0.currentStreak > $1.currentStreak }
            .prefix(3)
            .map { (rhythm: $0.title, streak: $0.currentStreak) }

        let completionRate = totalScheduled > 0 ? Double(totalCompletions) / Double(totalScheduled) : 0

        return WeeklyInsight.Stats(
            totalCompletions: totalCompletions,
            completionRate: completionRate,
            currentStreaks: Array(streaks),
            bestDay: bestDay,
            worstDay: worstDay
        )
    }

    private func generateHighlights(for rhythms: [Rhythm], stats: WeeklyInsight.Stats) -> [WeeklyInsight.Highlight] {
        var highlights: [WeeklyInsight.Highlight] = []

        // Streak highlights
        if let topStreak = stats.currentStreaks.first, topStreak.streak >= 7 {
            highlights.append(WeeklyInsight.Highlight(
                emoji: "🔥",
                title: "Hot Streak!",
                description: "\(topStreak.rhythm) is on a \(topStreak.streak)-day streak"
            ))
        }

        // Completion rate highlight
        if stats.completionRate >= 0.8 {
            highlights.append(WeeklyInsight.Highlight(
                emoji: "⭐",
                title: "Excellent Week",
                description: "You completed \(Int(stats.completionRate * 100))% of your rhythms"
            ))
        } else if stats.completionRate >= 0.5 {
            highlights.append(WeeklyInsight.Highlight(
                emoji: "💪",
                title: "Solid Progress",
                description: "You're hitting about half your rhythms consistently"
            ))
        }

        // Best day highlight
        if let bestDay = stats.bestDay {
            highlights.append(WeeklyInsight.Highlight(
                emoji: "📅",
                title: "Best Day: \(bestDay.fullName)",
                description: "You tend to be most consistent on \(bestDay.fullName)s"
            ))
        }

        // Perfect rhythms
        let perfectRhythms = rhythms.filter { $0.completionRateThisWeek == 1.0 && $0.totalCompletions > 0 }
        if !perfectRhythms.isEmpty {
            let names = perfectRhythms.prefix(2).map { $0.title }.joined(separator: " & ")
            highlights.append(WeeklyInsight.Highlight(
                emoji: "✨",
                title: "Perfect Record",
                description: "\(names) at 100% this week"
            ))
        }

        return Array(highlights.prefix(3))
    }

    private func generateSuggestions(for rhythms: [Rhythm], stats: WeeklyInsight.Stats) -> [String] {
        var suggestions: [String] = []

        // Suggest focusing on worst day
        if let worstDay = stats.worstDay, stats.completionRate < 0.7 {
            suggestions.append("Try setting reminders for \(worstDay.fullName)s to improve consistency")
        }

        // Suggest for rhythms with broken streaks
        let brokenStreaks = rhythms.filter { rhythm in
            rhythm.currentStreak == 0 && rhythm.longestStreak > 3
        }
        if let rhythm = brokenStreaks.first {
            suggestions.append("Restart your \(rhythm.title) streak - you previously hit \(rhythm.longestStreak) days!")
        }

        // Suggest for low completion rhythms
        let lowCompletion = rhythms.filter { $0.completionRateThisWeek < 0.3 && $0.completionRateThisWeek > 0 }
        if let rhythm = lowCompletion.first {
            suggestions.append("Consider adjusting \(rhythm.title)'s schedule if it's too ambitious")
        }

        // General encouragement
        if suggestions.isEmpty && stats.completionRate > 0.7 {
            suggestions.append("Keep up the great work! Your consistency is building strong habits")
        }

        return Array(suggestions.prefix(3))
    }

    private func generateSummaryText(for rhythms: [Rhythm], stats: WeeklyInsight.Stats) -> String {
        let completionPercent = Int(stats.completionRate * 100)

        if rhythms.isEmpty {
            return "Create some rhythms to start tracking your habits and see insights here!"
        }

        if stats.totalCompletions == 0 {
            return "This week is just getting started. Complete some rhythms to build your momentum!"
        }

        var summary = "This week you completed \(stats.totalCompletions) rhythms"

        if completionPercent >= 80 {
            summary += " - outstanding consistency at \(completionPercent)%! "
        } else if completionPercent >= 50 {
            summary += " with a \(completionPercent)% completion rate. "
        } else {
            summary += ". There's room to grow - you're at \(completionPercent)%. "
        }

        if let topStreak = stats.currentStreaks.first {
            summary += "Your longest active streak is \(topStreak.streak) days on \(topStreak.rhythm)."
        }

        return summary
    }
}
