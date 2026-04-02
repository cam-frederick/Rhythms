//
//  InsightsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//  Updated by Cici on 4/2/26 – skeleton loading, polished insight card, empty state (TASK-RH-3)
//

import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @StateObject private var insightsService = InsightsService()
    @State private var contentVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.lg) {
                if insightsService.isGenerating {
                    InsightSkeletonView()
                        .transition(.opacity)
                } else if let insight = insightsService.weeklyInsight {
                    InsightContentView(insight: insight)
                        .opacity(contentVisible ? 1 : 0)
                        .offset(y: contentVisible ? 0 : 16)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: contentVisible)
                } else {
                    EmptyInsightView {
                        Task { await insightsService.generateWeeklyInsight(for: rhythms) }
                    }
                    .opacity(contentVisible ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: contentVisible)
                }
            }
            .padding(ThemeSpacing.md)
        }
        .background(ThemeColors.bgPrimary(colorScheme))
        .navigationTitle("Insights")
        .task {
            await insightsService.generateWeeklyInsight(for: rhythms)
            withAnimation { contentVisible = true }
        }
        .refreshable {
            contentVisible = false
            insightsService.clearCache()
            await insightsService.generateWeeklyInsight(for: rhythms)
            withAnimation { contentVisible = true }
        }
    }
}

// MARK: - Skeleton Loading

struct InsightSkeletonView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            // Summary card skeleton
            VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                // Header row
                HStack {
                    SkeletonBar(width: 120, height: 14)
                    Spacer()
                    SkeletonBar(width: 70, height: 12)
                }
                // Text lines
                SkeletonBar(width: .infinity, height: 13)
                SkeletonBar(width: .infinity, height: 13)
                SkeletonBar(width: 220, height: 13)
            }
            .padding(ThemeSpacing.md)
            .background(ThemeColors.bgCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))

            // Stats row skeleton
            HStack(spacing: ThemeSpacing.md) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 6) {
                        SkeletonBar(width: 44, height: 22)
                        SkeletonBar(width: 60, height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ThemeSpacing.sm)
                    .background(ThemeColors.bgSecondary(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
                }
            }

            // Highlights skeleton
            VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                SkeletonBar(width: 90, height: 11)
                ForEach(0..<2, id: \.self) { _ in
                    HStack(spacing: ThemeSpacing.sm) {
                        SkeletonBar(width: 40, height: 40, cornerRadius: 20)
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonBar(width: 140, height: 13)
                            SkeletonBar(width: 200, height: 11)
                        }
                        Spacer()
                    }
                    .padding(ThemeSpacing.md)
                    .background(ThemeColors.bgCard(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }
}

/// A single shimmering skeleton bar.
struct SkeletonBar: View {
    @Environment(\.colorScheme) private var colorScheme
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat = 6
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(ThemeColors.bgSecondary(colorScheme))
            LinearGradient(
                colors: [
                    Color.white.opacity(0),
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.4),
                    Color.white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: shimmerOffset)
            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: shimmerOffset)
        }
        .frame(width: width == .infinity ? nil : width, height: height)
        .frame(maxWidth: width == .infinity ? .infinity : nil)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onAppear { shimmerOffset = 300 }
    }
}

// MARK: - Empty State

struct EmptyInsightView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onGenerate: () -> Void
    @State private var sparkleScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            ZStack {
                Circle()
                    .fill(ThemeColors.accentGold.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(ThemeColors.accentGold)
                    .scaleEffect(sparkleScale)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: sparkleScale)
            }

            VStack(spacing: ThemeSpacing.sm) {
                Text("No Insights Yet")
                    .font(ThemeTypography.titleMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                Text("Complete some rhythms this week and we'll generate personalized insights about your habits and patterns.")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button(action: onGenerate) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Generate Insights")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, ThemeSpacing.lg)
                .padding(.vertical, ThemeSpacing.sm)
                .background(ThemeColors.accentGold)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
            }
        }
        .padding(ThemeSpacing.xl)
        .onAppear { sparkleScale = 1.12 }
    }
}

// MARK: - Insight Content

struct InsightContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    let insight: InsightsService.WeeklyInsight

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            // Summary Card (polished with AI badge + gradient)
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
        VStack(alignment: .leading, spacing: ThemeSpacing.md) {
            // Header with AI badge
            HStack(alignment: .center, spacing: ThemeSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ThemeColors.accentGold)

                Text("Weekly Summary")
                    .font(ThemeTypography.titleSmall)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                Spacer()

                // AI badge
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 9))
                    Text("AI")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(ThemeColors.accentGold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ThemeColors.accentGold.opacity(0.15))
                .clipShape(Capsule())
            }

            Divider()
                .background(ThemeColors.borderSubtle(colorScheme))

            // Summary text
            Text(text)
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .lineSpacing(4)

            // Footer
            HStack {
                Spacer()
                Text("Generated \(generatedAt.formatted(.relative(presentation: .named)))")
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
            }
        }
        .padding(ThemeSpacing.md)
        .background(
            ZStack {
                ThemeColors.bgCard(colorScheme)
                LinearGradient(
                    colors: [
                        ThemeColors.accentGold.opacity(0.06),
                        ThemeColors.accentGold.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.accentGold.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: ThemeColors.accentGold.opacity(0.08), radius: 8, x: 0, y: 4)
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

            ForEach(Array(highlights.enumerated()), id: \.element.title) { index, highlight in
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
