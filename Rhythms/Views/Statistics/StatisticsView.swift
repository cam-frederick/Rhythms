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
            VStack(spacing: 24) {
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

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
            .padding(.vertical)
        }
        .navigationTitle("Statistics")
    }

    // MARK: - Overall Completion Card

    private var overallCompletionCard: some View {
        let rate = calculateOverallCompletionRate()

        return VStack(spacing: 12) {
            Text("Overall Completion")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: rate)
                    .stroke(completionColor(for: rate), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: rate)

                VStack(spacing: 4) {
                    Text("\(Int(rate * 100))%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text("Last \(selectedTimeRange.days) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Completion Trend Chart

    private var completionTrendChart: some View {
        let data = completionTrendData()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Completion Trend")
                .font(.headline)
                .padding(.horizontal)

            Chart(data) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Completed", point.completedCount)
                )
                .foregroundStyle(Color.green.gradient)

                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Missed", point.missedCount)
                )
                .foregroundStyle(Color.red.opacity(0.3).gradient)
            }
            .frame(height: 200)
            .padding(.horizontal)
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisLabelFormat)
                }
            }
        }
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Best Days Card

    private var bestDaysCard: some View {
        let dayStats = calculateDayOfWeekStats()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Best Performing Days")
                .font(.headline)
                .padding(.horizontal)

            Chart(dayStats) { stat in
                BarMark(
                    x: .value("Day", stat.dayName),
                    y: .value("Rate", stat.completionRate)
                )
                .foregroundStyle(completionColor(for: stat.completionRate).gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .padding(.horizontal)
            .chartYAxis {
                AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(100))
            }
        }
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Streak Leaderboard

    private var streakLeaderboard: some View {
        let topRhythms = rhythms
            .sorted { $0.currentStreak > $1.currentStreak }
            .prefix(5)

        return VStack(alignment: .leading, spacing: 12) {
            Text("Streak Leaderboard")
                .font(.headline)
                .padding(.horizontal)

            if topRhythms.isEmpty {
                Text("No streaks yet")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(topRhythms.enumerated()), id: \.element.id) { index, rhythm in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text(rhythm.emoji)
                            .font(.title2)

                        Text(rhythm.title)
                            .font(.subheadline)

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("\(rhythm.currentStreak)")
                                .font(.headline)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal)

                    if index < topRhythms.count - 1 {
                        Divider()
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Mood Distribution Chart

    private var hasMoodData: Bool {
        rhythms.flatMap { $0.entries }.contains { $0.mood != nil }
    }

    private var moodDistributionChart: some View {
        let moodCounts = calculateMoodDistribution()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Mood Distribution")
                .font(.headline)
                .padding(.horizontal)

            Chart(moodCounts) { item in
                SectorMark(
                    angle: .value("Count", item.count),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(item.mood.color)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .padding(.horizontal)

            // Legend
            HStack(spacing: 16) {
                ForEach(moodCounts) { item in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(item.mood.color)
                            .frame(width: 10, height: 10)
                        Text(item.mood.emoji)
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
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
