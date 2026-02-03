//
//  RhythmsDetailWidget.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import WidgetKit
import SwiftUI

/// Large widget showing detailed today view with progress and rhythms
struct RhythmsDetailWidget: Widget {
    let kind: String = "RhythmsDetailWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DetailWidgetProvider()) { entry in
            DetailWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Rhythms Overview")
        .description("A complete view of today's rhythms with progress tracking.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Timeline Provider

struct DetailWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DetailWidgetEntry {
        DetailWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (DetailWidgetEntry) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            completion(DetailWidgetEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DetailWidgetEntry>) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            let entry = DetailWidgetEntry(date: Date(), data: data)

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct DetailWidgetEntry: TimelineEntry {
    let date: Date
    let data: TodayWidgetData
}

// MARK: - Widget View

struct DetailWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: DetailWidgetEntry

    var body: some View {
        VStack(spacing: WidgetTheme.spacingSM) {
            // Header with date and progress
            headerSection

            Divider()
                .overlay(WidgetTheme.borderSubtle(colorScheme))

            // Main content
            if entry.data.rhythms.isEmpty {
                emptyStateView
            } else {
                rhythmsListSection
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            // Date and status
            VStack(alignment: .leading, spacing: WidgetTheme.spacingXS) {
                Text(entry.data.date.formatted(date: .complete, time: .omitted))
                    .font(WidgetTheme.titleSmall)
                    .foregroundStyle(WidgetTheme.textPrimary(colorScheme))

                if entry.data.isAllComplete {
                    Label("All rhythms complete!", systemImage: "star.fill")
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.accentGold)
                } else if entry.data.remainingCount > 0 {
                    Text("\(entry.data.remainingCount) rhythm\(entry.data.remainingCount == 1 ? "" : "s") remaining")
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                }
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(WidgetTheme.borderSubtle(colorScheme), lineWidth: 6)

                Circle()
                    .trim(from: 0, to: entry.data.completionRate)
                    .stroke(
                        WidgetTheme.accentGold,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.data.completionRate * 100))")
                        .font(WidgetTheme.numericMedium)
                        .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                    Text("%")
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                }
            }
            .frame(width: 60, height: 60)
        }
    }

    // MARK: - Rhythms List Section

    private var rhythmsListSection: some View {
        VStack(spacing: WidgetTheme.spacingSM) {
            // Incomplete rhythms (highlighted)
            let incompleteRhythms = entry.data.rhythms.filter { !$0.isCompleted }
            let completedRhythms = entry.data.rhythms.filter { $0.isCompleted }

            if !incompleteRhythms.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TO DO")
                        .font(WidgetTheme.sectionLabel)
                        .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                        .tracking(2)

                    ForEach(incompleteRhythms.prefix(4)) { rhythm in
                        incompleteRhythmRow(rhythm)
                    }

                    if incompleteRhythms.count > 4 {
                        Text("+\(incompleteRhythms.count - 4) more")
                            .font(WidgetTheme.caption)
                            .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                    }
                }
            }

            if !completedRhythms.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("COMPLETED")
                        .font(WidgetTheme.sectionLabel)
                        .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                        .tracking(2)

                    ForEach(completedRhythms.prefix(3)) { rhythm in
                        completedRhythmRow(rhythm)
                    }

                    if completedRhythms.count > 3 {
                        Text("+\(completedRhythms.count - 3) more")
                            .font(WidgetTheme.caption)
                            .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func incompleteRhythmRow(_ rhythm: RhythmWidgetItem) -> some View {
        HStack(spacing: 10) {
            // Emoji with background
            Text(rhythm.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(Color(hex: rhythm.colorHex)?.opacity(0.15) ?? WidgetTheme.bgSecondary(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.radiusMedium))

            VStack(alignment: .leading, spacing: 2) {
                Text(rhythm.title)
                    .font(WidgetTheme.labelMedium)
                    .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                    .lineLimit(1)

                if let note = rhythm.note {
                    Text(note)
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Streak at risk indicator
            if rhythm.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(WidgetTheme.accentGold)
                    Text("\(rhythm.streak)")
                        .fontWeight(.semibold)
                        .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                }
                .font(WidgetTheme.caption)
            }
        }
        .padding(.vertical, WidgetTheme.spacingXS)
        .padding(.horizontal, WidgetTheme.spacingSM)
        .background(Color(hex: rhythm.colorHex)?.opacity(0.08) ?? WidgetTheme.bgSecondary(colorScheme).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: WidgetTheme.radiusMedium))
    }

    private func completedRhythmRow(_ rhythm: RhythmWidgetItem) -> some View {
        HStack(spacing: WidgetTheme.spacingSM) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: rhythm.colorHex) ?? WidgetTheme.accentGold)
                .font(.body)

            Text(rhythm.emoji)

            Text(rhythm.title)
                .font(WidgetTheme.caption)
                .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                .lineLimit(1)

            Spacer()

            if rhythm.streak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(WidgetTheme.accentGold)
                    Text("\(rhythm.streak)")
                        .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                }
                .font(.caption2)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: WidgetTheme.spacingSM) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(WidgetTheme.accentGold.opacity(0.5))

            Text("No rhythms scheduled")
                .font(WidgetTheme.bodyMedium)
                .foregroundStyle(WidgetTheme.textSecondary(colorScheme))

            Text("Enjoy your free day!")
                .font(WidgetTheme.caption)
                .foregroundStyle(WidgetTheme.textMuted(colorScheme))

            Spacer()
        }
    }
}

// MARK: - Previews

#Preview("Large", as: .systemLarge) {
    RhythmsDetailWidget()
} timeline: {
    DetailWidgetEntry(date: .now, data: .placeholder)
    DetailWidgetEntry(date: .now, data: TodayWidgetData(
        date: Date(),
        totalCount: 0,
        completedCount: 0,
        rhythms: [],
        nextRhythm: nil
    ))
}
