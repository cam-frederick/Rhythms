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
    var entry: TodayWidgetEntry

    private let maxVisibleRhythms = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.headline)
                    Text(entry.data.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Progress indicator
                HStack(spacing: 4) {
                    Image(systemName: entry.data.isAllComplete ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(entry.data.isAllComplete ? .green : .secondary)
                    Text("\(entry.data.completedCount)/\(entry.data.totalCount)")
                        .font(.subheadline.bold())
                }
            }

            Divider()

            // Rhythms list
            if entry.data.rhythms.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("No rhythms today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
    }

    private func rhythmRow(_ rhythm: RhythmWidgetItem) -> some View {
        HStack(spacing: 8) {
            // Completion indicator
            Image(systemName: rhythm.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(rhythm.isCompleted ? Color(hex: rhythm.colorHex) ?? .green : .secondary)
                .font(.body)

            // Emoji
            Text(rhythm.emoji)
                .font(.callout)

            // Title
            Text(rhythm.title)
                .font(.subheadline)
                .lineLimit(1)
                .strikethrough(rhythm.isCompleted, color: .secondary)
                .foregroundStyle(rhythm.isCompleted ? .secondary : .primary)

            Spacer()

            // Streak badge
            if rhythm.streak > 0 && !rhythm.isCompleted {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(rhythm.streak)")
                        .font(.caption2.bold())
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
