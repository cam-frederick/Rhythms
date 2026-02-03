//
//  StatisticsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @State private var selectedTimeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.lg) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, ThemeSpacing.md)

                // Overall completion rate card
                overallCompletionCard

                // Completion trend chart
                completionTrendChart

                // Best performing days
                bestDaysCard

                // Streak leaderboard
                streakLeaderboard

                // Mood distribution (if any mood data)
                if hasMoodData {
                    moodDistributionChart
                }
            }
            .padding(.vertical, ThemeSpacing.md)
        }
        .background(ThemeColors.bgPrimary(colorScheme))
        .navigationTitle("Statistics")
    }

    // MARK: - Overall Completion Card

    private var overallCompletionCard: some View {
        let rate = calculateOverallCompletionRate()

        return VStack(spacing: ThemeSpacing.sm) {
            Text("OVERALL COMPLETION")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            ZStack {
                Circle()
                    .stroke(ThemeColors.bgSecondary(colorScheme), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(ThemeColors.accentGold, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(ThemeAnimation.smoothEase, value: rate)

                VStack(spacing: ThemeSpacing.xs) {
                    Text("\(Int(rate * 100))%")
                        .font(ThemeTypography.numericLarge)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                    Text("Last \(selectedTimeRange.days) days")
                        .font(ThemeTypography.caption)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
            }
            .frame(width: 150, height: 150)
        }
        .padding(ThemeSpacing.md)
        .frame(maxWidth: .infinity)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .padding(.horizontal, ThemeSpacing.md)
    }

    // MARK: - Completion Trend Chart

    private var completionTrendChart: some View {
        let data = completionTrendData()

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("COMPLETION TREND")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                .padding(.horizontal, ThemeSpacing.md)

            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Completed", point.completedCount)
                )
                .foregroundStyle(ThemeColors.accentGold.gradient)
                .cornerRadius(ThemeRadius.small)

                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Missed", point.missedCount)
                )
                .foregroundStyle(ThemeColors.bgSecondary(colorScheme).gradient)
                .cornerRadius(ThemeRadius.small)
            }
            .frame(height: 200)
            .padding(.horizontal, ThemeSpacing.md)
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisLabelFormat)
                }
            }
        }
        .padding(.vertical, ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .padding(.horizontal, ThemeSpacing.md)
    }

    // MARK: - Best Days Card

    private var bestDaysCard: some View {
        let dayStats = calculateDayOfWeekStats()

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("BEST PERFORMING DAYS")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                .padding(.horizontal, ThemeSpacing.md)

            Chart(dayStats) { stat in
                BarMark(
                    x: .value("Day", stat.dayName),
                    y: .value("Rate", stat.completionRate)
                )
                .foregroundStyle(ThemeColors.accentGold.gradient)
                .cornerRadius(ThemeRadius.small)
            }
            .frame(height: 150)
            .padding(.horizontal, ThemeSpacing.md)
            .chartYAxis {
                AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(100))
            }
        }
        .padding(.vertical, ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .padding(.horizontal, ThemeSpacing.md)
    }

    // MARK: - Streak Leaderboard

    private var streakLeaderboard: some View {
        let topRhythms = rhythms
            .sorted { $0.currentStreak > $1.currentStreak }
            .prefix(5)

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("STREAK LEADERBOARD")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                .padding(.horizontal, ThemeSpacing.md)

            if topRhythms.isEmpty {
                Text("No streaks yet")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .padding(ThemeSpacing.md)
            } else {
                ForEach(Array(topRhythms.enumerated()), id: \.element.id) { index, rhythm in
                    HStack(spacing: ThemeSpacing.sm) {
                        Text("\(index + 1)")
                            .font(ThemeTypography.labelLarge)
                            .foregroundStyle(ThemeColors.textMuted(colorScheme))
                            .frame(width: 24)

                        Text(rhythm.emoji)
                            .font(.title2)

                        Text(rhythm.title)
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                        Spacer()

                        HStack(spacing: ThemeSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(ThemeColors.accentGold)
                            Text("\(rhythm.currentStreak)")
                                .font(ThemeTypography.labelLarge)
                                .foregroundStyle(ThemeColors.accentGold)
                        }
                    }
                    .padding(.horizontal, ThemeSpacing.md)

                    if index < topRhythms.count - 1 {
                        Rectangle()
                            .fill(ThemeColors.borderSubtle(colorScheme))
                            .frame(height: ThemeBorder.thin)
                            .padding(.horizontal, ThemeSpacing.md)
                    }
                }
            }
        }
        .padding(.vertical, ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .padding(.horizontal, ThemeSpacing.md)
    }

    // MARK: - Mood Distribution Chart

    private var hasMoodData: Bool {
        rhythms.flatMap { $0.entries }.contains { $0.mood != nil }
    }

    private var moodDistributionChart: some View {
        let moodCounts = calculateMoodDistribution()

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("MOOD DISTRIBUTION")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                .padding(.horizontal, ThemeSpacing.md)

            Chart(moodCounts) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.mood.color)
                .cornerRadius(ThemeRadius.small)
            }
            .frame(height: 200)
            .padding(.horizontal, ThemeSpacing.md)

            // Legend
            HStack(spacing: ThemeSpacing.md) {
                ForEach(moodCounts) { item in
                    HStack(spacing: ThemeSpacing.xs) {
                        Circle()
                            .fill(item.mood.color)
                            .frame(width: 10, height: 10)
                        Text(item.mood.emoji)
                        Text("\(item.count)")
                            .font(ThemeTypography.caption)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }
                }
            }
            .padding(.horizontal, ThemeSpacing.md)
        }
        .padding(.vertical, ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .padding(.horizontal, ThemeSpacing.md)
    }

    // MARK: - Helper Methods

    private func calculateOverallCompletionRate() -> Double {
        guard !rhythms.isEmpty else { return 0 }

        let rates = rhythms.map { $0.completionRate(forLast: selectedTimeRange.days) }
        return rates.reduce(0, +) / Double(rates.count)
    }

    private func completionTrendData() -> [DailyCompletion] {
        let endDate = Date()
        let startDate = endDate.adding(days: -selectedTimeRange.days + 1)
        var data: [DailyCompletion] = []

        for date in Calendar.current.dates(from: startDate, to: endDate) {
            let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
            let completedCount = scheduledRhythms.filter { $0.isCompleted(on: date) }.count
            let missedCount = scheduledRhythms.count - completedCount

            data.append(DailyCompletion(
                date: date,
                completedCount: completedCount,
                missedCount: missedCount
            ))
        }

        return data
    }

    private func calculateDayOfWeekStats() -> [DayOfWeekStat] {
        let calendar = Calendar.current
        var dayStats: [Int: (completed: Int, total: Int)] = [:]

        // Initialize all days
        for day in 1...7 {
            dayStats[day] = (0, 0)
        }

        let endDate = Date()
        let startDate = endDate.adding(days: -selectedTimeRange.days + 1)

        for date in calendar.dates(from: startDate, to: endDate) {
            let weekday = calendar.component(.weekday, from: date)
            let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
            let completedCount = scheduledRhythms.filter { $0.isCompleted(on: date) }.count

            var current = dayStats[weekday] ?? (0, 0)
            current.completed += completedCount
            current.total += scheduledRhythms.count
            dayStats[weekday] = current
        }

        return dayStats.map { weekday, stats in
            let rate = stats.total > 0 ? Double(stats.completed) / Double(stats.total) : 0
            let dayName = calendar.shortWeekdaySymbols[weekday - 1]
            return DayOfWeekStat(weekday: weekday, dayName: dayName, completionRate: rate)
        }
        .sorted { $0.weekday < $1.weekday }
    }

    private func calculateMoodDistribution() -> [MoodCount] {
        let allEntries = rhythms.flatMap { $0.entries }
        var moodCounts: [Mood: Int] = [:]

        for entry in allEntries {
            if let mood = entry.mood {
                moodCounts[mood, default: 0] += 1
            }
        }

        return moodCounts.map { MoodCount(mood: $0.key, count: $0.value) }
            .sorted { $0.mood.rawValue < $1.mood.rawValue }
    }

    private func completionColor(for rate: Double) -> Color {
        switch rate {
        case 0.8...: return .green
        case 0.6..<0.8: return .yellow
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }

    private var xAxisStride: Calendar.Component {
        switch selectedTimeRange {
        case .week: return .day
        case .month: return .weekOfYear
        case .year: return .month
        }
    }

    private var xAxisLabelFormat: Date.FormatStyle {
        switch selectedTimeRange {
        case .week:
            return .dateTime.weekday(.abbreviated)
        case .month:
            return .dateTime.day()
        case .year:
            return .dateTime.month(.abbreviated)
        }
    }
}

// MARK: - Supporting Types

struct DailyCompletion: Identifiable {
    let id = UUID()
    let date: Date
    let completedCount: Int
    let missedCount: Int
}

struct DayOfWeekStat: Identifiable {
    let id = UUID()
    let weekday: Int
    let dayName: String
    let completionRate: Double
}

struct MoodCount: Identifiable {
    let id = UUID()
    let mood: Mood
    let count: Int
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
    .modelContainer(for: [Rhythm.self, RhythmEntry.self, RhythmNote.self, Category.self])
}
