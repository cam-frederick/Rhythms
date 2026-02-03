//
//  InsightsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @StateObject private var insightsService = InsightsService()

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.lg) {
                if insightsService.isGenerating {
                    LoadingView()
                } else if let insight = insightsService.weeklyInsight {
                    InsightContentView(insight: insight)
                } else {
                    EmptyInsightView()
                }
            }
            .padding(ThemeSpacing.md)
        }
        .background(ThemeColors.bgPrimary(colorScheme))
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(ThemeColors.accentGold)

            Text("Analyzing your rhythms...")
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ThemeSpacing.xxl)
    }
}

// MARK: - Empty State

struct EmptyInsightView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(ThemeColors.accentGold.opacity(0.7))

            Text("No insights yet")
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text("Complete some rhythms this week to see personalized insights")
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
        }
        .padding(ThemeSpacing.xl)
    }
}

// MARK: - Insight Content

struct InsightContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    let insight: InsightsService.WeeklyInsight

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
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
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let generatedAt: Date

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(ThemeColors.accentGold)
                Text("Weekly Summary")
                    .font(ThemeTypography.titleSmall)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                Spacer()
                Text(generatedAt, style: .relative)
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
            }

            Text(text)
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.accentGold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }
}

// MARK: - Stats Overview

struct StatsOverview: View {
    @Environment(\.colorScheme) private var colorScheme
    let stats: InsightsService.WeeklyInsight.Stats

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("THIS WEEK")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            HStack(spacing: ThemeSpacing.md) {
                StatBox(
                    value: "\(stats.totalCompletions)",
                    label: "Completed"
                )

                StatBox(
                    value: "\(Int(stats.completionRate * 100))%",
                    label: "Rate"
                )

                if let topStreak = stats.currentStreaks.first {
                    StatBox(
                        value: "\(topStreak.streak)",
                        label: "Top Streak"
                    )
                }
            }
        }
    }
}

struct StatBox: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: ThemeSpacing.xs) {
            Text(value)
                .font(ThemeTypography.numericMedium)
                .foregroundStyle(ThemeColors.accentGold)

            Text(label)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, ThemeSpacing.sm)
        .background(ThemeColors.bgSecondary(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }
}

// MARK: - Highlights Section

struct HighlightsSection: View {
    @Environment(\.colorScheme) private var colorScheme
    let highlights: [InsightsService.WeeklyInsight.Highlight]

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("HIGHLIGHTS")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            ForEach(highlights, id: \.title) { highlight in
                HStack(spacing: ThemeSpacing.sm) {
                    Text(highlight.emoji)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(ThemeColors.bgSecondary(colorScheme))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(highlight.title)
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                        Text(highlight.description)
                            .font(ThemeTypography.caption)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }

                    Spacer()
                }
                .padding(ThemeSpacing.md)
                .background(ThemeColors.bgCard(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.large)
                        .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
                )
            }
        }
    }
}

// MARK: - Suggestions Section

struct SuggestionsSection: View {
    @Environment(\.colorScheme) private var colorScheme
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(ThemeColors.accentGold)
                Text("SUGGESTIONS")
                    .font(ThemeTypography.sectionLabel)
                    .tracking(ThemeTypography.sectionLabelTracking)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
            }

            ForEach(suggestions, id: \.self) { suggestion in
                HStack(alignment: .top, spacing: ThemeSpacing.sm) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(ThemeColors.accentGold)
                        .font(ThemeTypography.caption)
                        .padding(.top, 2)

                    Text(suggestion)
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.accentGold.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(for: Rhythm.self, inMemory: true)
}
