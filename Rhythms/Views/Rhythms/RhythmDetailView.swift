//
//  RhythmDetailView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData
import Charts

struct RhythmDetailView: View {
    @Bindable var rhythm: Rhythm
    @Environment(\.modelContext) private var modelContext
    @Environment(\.hapticService) private var hapticService
    @Environment(\.colorScheme) private var colorScheme

    @State private var showingEditor = false
    @State private var showingNotes = false
    @State private var selectedHistoryRange: HistoryRange = .week

    enum HistoryRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"

        var days: Int? {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return nil
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ThemeSpacing.lg) {
                // Header card
                headerCard

                // Stats overview
                statsOverview

                // Completion history chart
                completionHistorySection

                // Recent completions list
                recentCompletionsSection

                // Notes section
                notesSection
            }
            .padding(ThemeSpacing.md)
        }
        .background(ThemeColors.bgPrimary(colorScheme))
        .navigationTitle(rhythm.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Text("Edit")
                        .foregroundStyle(ThemeColors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                RhythmEditorView(mode: .edit(rhythm))
            }
        }
        .sheet(isPresented: $showingNotes) {
            NavigationStack {
                RhythmNotesView(rhythm: rhythm)
            }
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: ThemeSpacing.md) {
            // Emoji and title
            Text(rhythm.emoji)
                .font(.system(size: 64))

            VStack(spacing: ThemeSpacing.xs) {
                Text(rhythm.title)
                    .font(ThemeTypography.displaySmall)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                Text(rhythm.schedule.displayName)
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            // Category badge
            if let category = rhythm.category {
                HStack(spacing: ThemeSpacing.xs) {
                    Text(category.emoji)
                    Text(category.name)
                }
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .padding(.horizontal, ThemeSpacing.sm)
                .padding(.vertical, ThemeSpacing.xs)
                .background(ThemeColors.bgSecondary(colorScheme))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ThemeSpacing.md)
        .background(rhythm.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        HStack(spacing: ThemeSpacing.md) {
            statCard(
                title: "Current Streak",
                value: "\(rhythm.currentStreak)",
                icon: "flame.fill"
            )

            statCard(
                title: "Best Streak",
                value: "\(rhythm.longestStreak)",
                icon: "trophy.fill"
            )

            statCard(
                title: "Total",
                value: "\(rhythm.totalCompletions)",
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: ThemeSpacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ThemeColors.accentGold)

            Text(value)
                .font(ThemeTypography.numericMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text(title)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Completion History Section

    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack {
                Text("COMPLETION HISTORY")
                    .font(ThemeTypography.sectionLabel)
                    .tracking(ThemeTypography.sectionLabelTracking)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))

                Spacer()

                Picker("Range", selection: $selectedHistoryRange) {
                    ForEach(HistoryRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            completionChart
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    private var completionChart: some View {
        let data = completionData()

        return Chart(data) { point in
            BarMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Completed", point.completed ? 1 : 0)
            )
            .foregroundStyle(point.completed ? ThemeColors.accentGold.gradient : ThemeColors.bgSecondary(colorScheme).gradient)
            .cornerRadius(ThemeRadius.small)
        }
        .frame(height: 120)
        .chartYAxis(.hidden)
        .chartXAxis {
            if selectedHistoryRange == .week {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            } else {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
        }
    }

    // MARK: - Recent Completions Section

    private var recentCompletionsSection: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("RECENT ACTIVITY")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            let recentEntries = rhythm.entries
                .sorted { $0.completedAt > $1.completedAt }
                .prefix(10)

            if recentEntries.isEmpty {
                Text("No completions yet")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .padding(ThemeSpacing.md)
            } else {
                ForEach(Array(recentEntries)) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                                .font(ThemeTypography.bodyMedium)
                                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                            Text("Completed \(entry.completedAt.formatted(.relative(presentation: .named)))")
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                        }

                        Spacer()

                        if let mood = entry.mood {
                            Text(mood.emoji)
                                .font(.title3)
                        }

                        if entry.note != nil {
                            Image(systemName: "note.text")
                                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        }
                    }
                    .padding(.vertical, ThemeSpacing.sm)

                    if entry.id != recentEntries.last?.id {
                        Rectangle()
                            .fill(ThemeColors.borderSubtle(colorScheme))
                            .frame(height: ThemeBorder.thin)
                    }
                }
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            HStack {
                Text("SCHEDULED NOTES")
                    .font(ThemeTypography.sectionLabel)
                    .tracking(ThemeTypography.sectionLabelTracking)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))

                Spacer()

                Button {
                    showingNotes = true
                } label: {
                    Text("Manage")
                        .font(ThemeTypography.labelMedium)
                        .foregroundStyle(ThemeColors.accentGold)
                }
            }

            if rhythm.notes.isEmpty {
                Text("No notes configured")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .padding(ThemeSpacing.md)
            } else {
                ForEach(rhythm.notes.sorted { $0.sortOrder < $1.sortOrder }.prefix(5)) { note in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.content)
                                .font(ThemeTypography.bodyMedium)
                                .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                                .lineLimit(2)

                            Text(note.scheduleDescription)
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                        }

                        Spacer()

                        if note.isRecurring {
                            Image(systemName: "repeat")
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        }
                    }
                    .padding(.vertical, ThemeSpacing.xs)
                }

                if rhythm.notes.count > 5 {
                    Button {
                        showingNotes = true
                    } label: {
                        Text("View all \(rhythm.notes.count) notes")
                            .font(ThemeTypography.caption)
                            .foregroundStyle(ThemeColors.accentGold)
                    }
                }
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Helper Methods

    private func completionData() -> [CompletionPoint] {
        let endDate = Date()
        let days = selectedHistoryRange.days ?? 365
        let startDate = endDate.adding(days: -days + 1)

        return Calendar.current.dates(from: startDate, to: endDate)
            .filter { rhythm.isScheduledFor(date: $0) }
            .map { date in
                CompletionPoint(
                    date: date,
                    completed: rhythm.isCompleted(on: date)
                )
            }
    }
}

struct CompletionPoint: Identifiable {
    let id = UUID()
    let date: Date
    let completed: Bool
}

#Preview {
    NavigationStack {
        RhythmDetailView(rhythm: {
            let r = Rhythm(title: "Morning Workout", emoji: "💪", colorHex: "#34C759", schedule: .weekdays)
            r.markCompleted(for: Date())
            r.markCompleted(for: Date().adding(days: -1))
            r.markCompleted(for: Date().adding(days: -2))
            return r
        }())
    }
    .modelContainer(for: [Rhythm.self, RhythmEntry.self, RhythmNote.self, Category.self])
}
