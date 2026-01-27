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
            VStack(spacing: 24) {
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
            .padding()
        }
        .navigationTitle(rhythm.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Text("Edit")
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
        VStack(spacing: 16) {
            // Emoji and title
            Text(rhythm.emoji)
                .font(.system(size: 64))

            VStack(spacing: 4) {
                Text(rhythm.title)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(rhythm.schedule.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Category badge
            if let category = rhythm.category {
                HStack(spacing: 4) {
                    Text(category.emoji)
                    Text(category.name)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(rhythm.color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Stats Overview

    private var statsOverview: some View {
        HStack(spacing: 16) {
            statCard(
                title: "Current Streak",
                value: "\(rhythm.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                title: "Best Streak",
                value: "\(rhythm.longestStreak)",
                icon: "trophy.fill",
                color: .yellow
            )

            statCard(
                title: "Total",
                value: "\(rhythm.totalCompletions)",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Completion History Section

    private var completionHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Completion History")
                    .font(.headline)

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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var completionChart: some View {
        let data = completionData()

        return Chart(data) { point in
            BarMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Completed", point.completed ? 1 : 0)
            )
            .foregroundStyle(point.completed ? rhythm.color.gradient : Color.gray.opacity(0.3).gradient)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            let recentEntries = rhythm.entries
                .sorted { $0.completedAt > $1.completedAt }
                .prefix(10)

            if recentEntries.isEmpty {
                Text("No completions yet")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(Array(recentEntries)) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Completed \(entry.completedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if let mood = entry.mood {
                            Text(mood.emoji)
                                .font(.title3)
                        }

                        if entry.note != nil {
                            Image(systemName: "note.text")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)

                    if entry.id != recentEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scheduled Notes")
                    .font(.headline)

                Spacer()

                Button {
                    showingNotes = true
                } label: {
                    Text("Manage")
                        .font(.subheadline)
                }
            }

            if rhythm.notes.isEmpty {
                Text("No notes configured")
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ForEach(rhythm.notes.sorted { $0.sortOrder < $1.sortOrder }.prefix(5)) { note in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(note.content)
                                .font(.subheadline)
                                .lineLimit(2)

                            Text(note.scheduleDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if note.isRecurring {
                            Image(systemName: "repeat")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if rhythm.notes.count > 5 {
                    Button {
                        showingNotes = true
                    } label: {
                        Text("View all \(rhythm.notes.count) notes")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
