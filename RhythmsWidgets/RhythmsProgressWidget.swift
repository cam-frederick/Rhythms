//
//  RhythmsProgressWidget.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import WidgetKit
import SwiftUI

/// Small widget showing today's progress ring
struct RhythmsProgressWidget: Widget {
    let kind: String = "RhythmsProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ProgressWidgetProvider()) { entry in
            ProgressWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Progress")
        .description("See your daily rhythm completion at a glance.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct ProgressWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ProgressWidgetEntry {
        ProgressWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ProgressWidgetEntry) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            completion(ProgressWidgetEntry(date: Date(), data: data))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProgressWidgetEntry>) -> Void) {
        Task { @MainActor in
            let data = WidgetDataProvider.shared.fetchTodayData()
            let entry = ProgressWidgetEntry(date: Date(), data: data)

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
}

struct ProgressWidgetEntry: TimelineEntry {
    let date: Date
    let data: TodayWidgetData
}

// MARK: - Widget View

struct ProgressWidgetView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    var entry: ProgressWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            smallView
        }
    }

    // MARK: - Small Widget View

    private var smallView: some View {
        VStack(spacing: WidgetTheme.spacingSM) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(WidgetTheme.borderSubtle(colorScheme), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.data.completionRate)
                    .stroke(
                        WidgetTheme.accentGold,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: entry.data.completionRate)

                VStack(spacing: 2) {
                    if entry.data.isAllComplete {
                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                            .foregroundStyle(WidgetTheme.accentGold)
                    } else {
                        Text("\(entry.data.completedCount)")
                            .font(WidgetTheme.numericLarge)
                            .foregroundStyle(WidgetTheme.textPrimary(colorScheme))
                        Text("of \(entry.data.totalCount)")
                            .font(WidgetTheme.caption)
                            .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                    }
                }
            }
            .frame(width: 80, height: 80)

            // Status text
            Group {
                if entry.data.totalCount == 0 {
                    Text("No rhythms today")
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                } else if entry.data.isAllComplete {
                    Text("All done!")
                        .font(WidgetTheme.labelMedium)
                        .foregroundStyle(WidgetTheme.accentGold)
                } else {
                    Text("\(entry.data.remainingCount) remaining")
                        .font(WidgetTheme.caption)
                        .foregroundStyle(WidgetTheme.textSecondary(colorScheme))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Accessory Circular View (Watch/Lock Screen)

    private var accessoryCircularView: some View {
        Gauge(value: entry.data.completionRate) {
            Text("\(entry.data.completedCount)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }

    // MARK: - Accessory Rectangular View (Watch/Lock Screen)

    private var accessoryRectangularView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rhythms")
                    .font(.headline)
                Text("\(entry.data.completedCount)/\(entry.data.totalCount) done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: entry.data.completionRate)
                    .stroke(WidgetTheme.accentGold, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 30, height: 30)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    RhythmsProgressWidget()
} timeline: {
    ProgressWidgetEntry(date: .now, data: .placeholder)
    ProgressWidgetEntry(date: .now, data: TodayWidgetData(
        date: Date(),
        totalCount: 5,
        completedCount: 5,
        rhythms: [],
        nextRhythm: nil
    ))
}

#Preview("Circular", as: .accessoryCircular) {
    RhythmsProgressWidget()
} timeline: {
    ProgressWidgetEntry(date: .now, data: .placeholder)
}
