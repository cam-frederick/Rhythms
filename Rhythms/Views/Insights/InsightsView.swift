//
//  InsightsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @StateObject private var insightsService = InsightsService()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if insightsService.isGenerating {
                    LoadingView()
                } else if let insight = insightsService.weeklyInsight {
                    InsightContentView(insight: insight)
                } else {
                    EmptyInsightView()
                }
            }
            .padding()
        }
        .navigationTitle("Insights")
        .task {
            await insightsService.generateWeeklyInsight(for: rhythms)
        }
        .refreshable {
            insightsService.clearCache()
            await insightsService.generateWeeklyInsight(for: rhythms)
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing your rhythms...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Empty State

struct EmptyInsightView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.purple.opacity(0.6))

            Text("No insights yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Complete some rhythms this week to see personalized insights")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Insight Content

struct InsightContentView: View {
    let insight: InsightsService.WeeklyInsight

    var body: some View {
        VStack(spacing: 20) {
            // Summary Card
            SummaryCard(text: insight.summaryText, generatedAt: insight.generatedAt)

            // Stats Overview
            StatsOverview(stats: insight.stats)

            // Highlights
            if !insight.highlights.isEmpty {
                HighlightsSection(highlights: insight.highlights)
            }

            // Suggestions
            if !insight.suggestions.isEmpty {
                SuggestionsSection(suggestions: insight.suggestions)
            }
        }
    }
}

// MARK: - Summary Card

struct SummaryCard: View {
    let text: String
    let generatedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Weekly Summary")
                    .font(.headline)
                Spacer()
                Text(generatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.1))
        }
    }
}

// MARK: - Stats Overview

struct StatsOverview: View {
    let stats: InsightsService.WeeklyInsight.Stats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 16) {
                StatBox(
                    value: "\(stats.totalCompletions)",
                    label: "Completed",
                    color: .green
                )

                StatBox(
                    value: "\(Int(stats.completionRate * 100))%",
                    label: "Rate",
                    color: .blue
                )

                if let topStreak = stats.currentStreaks.first {
                    StatBox(
                        value: "\(topStreak.streak)",
                        label: "Top Streak",
                        color: .orange
                    )
                }
            }
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        }
    }
}

// MARK: - Highlights Section

struct HighlightsSection: View {
    let highlights: [InsightsService.WeeklyInsight.Highlight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Highlights")
                .font(.headline)

            ForEach(highlights, id: \.title) { highlight in
                HStack(spacing: 12) {
                    Text(highlight.emoji)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(highlight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(highlight.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
            }
        }
    }
}

// MARK: - Suggestions Section

struct SuggestionsSection: View {
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Suggestions")
                    .font(.headline)
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                        .padding(.top, 2)

                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        }
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(for: Rhythm.self, inMemory: true)
}
