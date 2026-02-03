//
//  RhythmsTodayWidget.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import WidgetKit
import SwiftUI

/// Medium widget showing today's rhythm list
struct RhythmsTodayWidget: Widget {
    let kind: String = "RhythmsTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayWidgetProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Rhythms")
        .description("View and track your rhythms for today.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Timeline Provider

struct TodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayWidgetEntry {
        TodayWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayWidgetEntry) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            completion(TodayWidgetEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayWidgetEntry>) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            let entry = TodayWidgetEntry(date: Date(), data: data)

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct TodayWidgetEntry: TimelineEntry {
    let date: Date
    let data: TodayWidgetData
}

// MARK: - Widget View

struct TodayWidgetView: View {
    @Environment(\.colorScheme) var colorScheme
    var entry: TodayWidgetEntry

    private let maxVisibleRhythms = 4

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetTheme.spacingSM) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(WidgetTheme.titleSmall)
                        .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                    Text(entry.data.date.formatted(date: .abbreviated, time: .omitted))
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                }

                Spacer()

                // Progress indicator
                HStack(spacing: WidgetTheme.spacingXS) {
                    Image(systemName: entry.data.isAllComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(entry.data.isAllComplete ? WidgetTheme.accentGold : WidgetTheme.textSecondary(colorScheme))
                    Text("\(entry.data.completedCount)/\(entry.data.totalCount)")
                        .font(WidgetTheme.labelMedium)
                        .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                }
            }

            Divider()
                .overlay(WidgetTheme.borderSubtle(colorScheme))

            // Rhythms list
            if entry.data.rhythms.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: WidgetTheme.spacingXS) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(WidgetTheme.accentGold.opacity(0.7))
                        Text("No rhythms today")
                            .font(WidgetTheme.caption)
                            .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                    }
                    Spacer()
                }
                Spacer()
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.data.rhythms.prefix(maxVisibleRhythms)) { rhythm in
                        rhythmRow(rhythm)
                    }

                    // Show overflow count if needed
                    if entry.data.rhythms.count > maxVisibleRhythms {
                        Text("+\(entry.data.rhythms.count - maxVisibleRhythms) more")
                            .font(WidgetTheme.caption)
                            .foregroundStyle(WidgetTheme.textMuted(colorScheme))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func rhythmRow(_ rhythm: RhythmWidgetItem) -> some View {
        HStack(spacing: WidgetTheme.spacingSM) {
            // Completion indicator
            Image(systemName: rhythm.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(rhythm.isCompleted ? Color(hex: rhythm.colorHex) ?? WidgetTheme.accentGold : WidgetTheme.textSecondary(colorScheme))
                .font(.body)

            // Emoji
            Text(rhythm.emoji)
                .font(.callout)

            // Title
            Text(rhythm.title)
                .font(WidgetTheme.bodyMedium)
                .lineLimit(1)
                .strikethrough(rhythm.isCompleted, color: WidgetTheme.textSecondary(colorScheme))
                .foregroundStyle(rhythm.isCompleted ? WidgetTheme.textSecondary(colorScheme) : WidgetTheme.textPrimary(colorScheme))

            Spacer()

            // Streak badge
            if rhythm.streak > 0 && !rhythm.isCompleted {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(WidgetTheme.accentGold)
                    Text("\(rhythm.streak)")
                        .font(.caption2.bold())
                        .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Medium", as: .systemMedium) {
    RhythmsTodayWidget()
} timeline: {
    TodayWidgetEntry(date: .now, data: .placeholder)
}
