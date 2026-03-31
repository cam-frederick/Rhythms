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

    // Animation states
    @State private var headerAppeared = false
    @State private var statsAppeared = false
    @State private var calendarAppeared = false
    @State private var notesAppeared = false
    @State private var historyAppeared = false

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
                    .offset(y: headerAppeared ? 0 : 20)
                    .opacity(headerAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: headerAppeared)

                // Streak badges — visual chip design
                streakBadgesSection
                    .offset(y: statsAppeared ? 0 : 20)
                    .opacity(statsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: statsAppeared)

                // Completion rate + stats row
                statsRow
                    .offset(y: statsAppeared ? 0 : 20)
                    .opacity(statsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: statsAppeared)

                // Mini 28-day dot calendar
                dotCalendarSection
                    .offset(y: calendarAppeared ? 0 : 20)
                    .opacity(calendarAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.28), value: calendarAppeared)

                // Notes timeline (entry notes)
                entryNotesTimeline
                    .offset(y: notesAppeared ? 0 : 20)
                    .opacity(notesAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: notesAppeared)

                // Completion history chart
                completionHistorySection
                    .offset(y: historyAppeared ? 0 : 20)
                    .opacity(historyAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.42), value: historyAppeared)

                // Recent completions list
                recentCompletionsSection
                    .offset(y: historyAppeared ? 0 : 20)
                    .opacity(historyAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.48), value: historyAppeared)

                // Scheduled notes section
                notesSection
                    .offset(y: historyAppeared ? 0 : 20)
                    .opacity(historyAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.52), value: historyAppeared)
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
        .onAppear {
            headerAppeared = true
            statsAppeared = true
            calendarAppeared = true
            notesAppeared = true
            historyAppeared = true
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: ThemeSpacing.md) {
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

    // MARK: - Streak Badges Section

    private var streakBadgesSection: some View {
        HStack(spacing: ThemeSpacing.md) {
            streakBadge(
                label: "Current Streak",
                value: rhythm.currentStreak,
                icon: "flame.fill",
                accentColor: rhythm.currentStreak > 0 ? .orange : ThemeColors.textMuted(colorScheme)
            )
            streakBadge(
                label: "Best Streak",
                value: rhythm.longestStreak,
                icon: "trophy.fill",
                accentColor: ThemeColors.accentGold
            )
        }
    }

    private func streakBadge(label: String, value: Int, icon: String, accentColor: Color) -> some View {
        VStack(spacing: ThemeSpacing.sm) {
            // Chip / badge
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                Text("\(value)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                Text(value == 1 ? "day" : "days")
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .padding(.top, 4)
            }
            .padding(.horizontal, ThemeSpacing.sm)
            .padding(.vertical, ThemeSpacing.xs)
            .background(accentColor.opacity(0.12))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(accentColor.opacity(0.3), lineWidth: 1))

            Text(label)
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

    // MARK: - Stats Row (completion rate + total)

    private var statsRow: some View {
        HStack(spacing: ThemeSpacing.md) {
            // 30-day completion rate chip
            VStack(spacing: ThemeSpacing.sm) {
                let rate = rhythm.completionRate(forLast: 30)
                let pct = Int(rate * 100)
                ZStack {
                    Circle()
                        .stroke(ThemeColors.bgSecondary(colorScheme), lineWidth: 6)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: CGFloat(rate))
                        .stroke(completionRateColor(rate), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: rate)
                    Text("\(pct)%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                }
                Text("Last 30 Days")
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

            // Total completions
            statCard(
                title: "Total",
                value: "\(rhythm.totalCompletions)",
                icon: "checkmark.circle.fill"
            )
        }
    }

    private func completionRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.8...: return .green
        case 0.5..<0.8: return ThemeColors.accentGold
        default: return .red
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

    // MARK: - 28-Day Dot Calendar

    private var dotCalendarSection: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("LAST 28 DAYS")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            dotCalendarGrid
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    private var dotCalendarGrid: some View {
        let days = last28Days()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return VStack(spacing: ThemeSpacing.xs) {
            // Weekday header
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }

            // Dot grid — pad leading blanks to align weekday
            LazyVGrid(columns: columns, spacing: 6) {
                // Leading offset dots (transparent) so first day lands on correct weekday
                ForEach(0..<leadingOffset(for: days), id: \.self) { _ in
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 28, height: 28)
                }

                ForEach(days) { point in
                    dotCell(for: point)
                }
            }

            // Legend
            HStack(spacing: ThemeSpacing.md) {
                legendDot(color: rhythm.color, label: "Completed")
                legendDot(color: ThemeColors.bgSecondary(colorScheme).opacity(0.8), label: "Missed")
                legendDot(color: Color.clear, label: "Not scheduled", bordered: true)
                Spacer()
            }
            .padding(.top, ThemeSpacing.xs)
        }
    }

    private func dotCell(for point: CompletionPoint) -> some View {
        let isScheduled = rhythm.isScheduledFor(date: point.date)
        let isCompleted = point.completed

        return ZStack {
            if isScheduled {
                Circle()
                    .fill(isCompleted ? rhythm.color : ThemeColors.bgSecondary(colorScheme))
                    .frame(width: 28, height: 28)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: 1)
                    .frame(width: 28, height: 28)
            }
        }
    }

    private func legendDot(color: Color, label: String, bordered: Bool = false) -> some View {
        HStack(spacing: 4) {
            ZStack {
                Circle().fill(color).frame(width: 10, height: 10)
                if bordered {
                    Circle().stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: 1).frame(width: 10, height: 10)
                }
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
        }
    }

    private func last28Days() -> [CompletionPoint] {
        let today = Date().startOfDay
        return (0..<28).reversed().map { offset in
            let date = today.adding(days: -offset)
            return CompletionPoint(date: date, completed: rhythm.isCompleted(on: date))
        }
    }

    private func leadingOffset(for days: [CompletionPoint]) -> Int {
        guard let first = days.first else { return 0 }
        let weekday = Calendar.current.component(.weekday, from: first.date)
        // weekday 1=Sun, so offset = weekday - 1
        return weekday - 1
    }

    // MARK: - Entry Notes Timeline

    private var entryNotesTimeline: some View {
        let notedEntries = rhythm.entries
            .filter { $0.note != nil && !($0.note!.isEmpty) }
            .sorted { $0.completedAt > $1.completedAt }
            .prefix(3)

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("RECENT NOTES")
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            if notedEntries.isEmpty {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                    Text("No notes recorded yet")
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
                .padding(ThemeSpacing.md)
            } else {
                ForEach(Array(notedEntries)) { entry in
                    entryNoteCard(entry: entry)
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

    private func entryNoteCard(entry: RhythmEntry) -> some View {
        HStack(alignment: .top, spacing: ThemeSpacing.sm) {
            // Timeline dot + line
            VStack(spacing: 0) {
                Circle()
                    .fill(rhythm.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
                Rectangle()
                    .fill(ThemeColors.borderSubtle(colorScheme))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 16)

            VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                HStack {
                    Text(entry.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                        .font(ThemeTypography.caption)
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                    Spacer()
                    if let mood = entry.mood {
                        Text(mood.emoji)
                            .font(.caption)
                    }
                }
                Text(entry.note ?? "")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(ThemeSpacing.sm)
            .background(ThemeColors.bgSecondary(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
        }
        .padding(.vertical, 2)
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

    // MARK: - Notes Section (Scheduled)

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

// MARK: - Supporting Types

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
