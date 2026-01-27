//
//  GetTodayStatusIntent.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import AppIntents
import SwiftData
import SwiftUI

/// Intent to get today's rhythm status
struct GetTodayStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Today's Status"
    static var description = IntentDescription("See your rhythm progress for today")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Rhythm>(
            predicate: #Predicate { !$0.isArchived && !$0.isPaused }
        )
        let rhythms = try context.fetch(descriptor)
        let today = Date()

        let todayRhythms = rhythms.filter { $0.isScheduledFor(date: today) }
        let completedCount = todayRhythms.filter { $0.isCompleted(on: today) }.count
        let totalCount = todayRhythms.count

        let dialogText: String
        if totalCount == 0 {
            dialogText = "You have no rhythms scheduled for today. Enjoy your free day!"
        } else if completedCount == totalCount {
            dialogText = "Amazing! You've completed all \(totalCount) rhythms today!"
        } else {
            let remaining = totalCount - completedCount
            dialogText = "You've completed \(completedCount) of \(totalCount) rhythms. \(remaining) left to go!"
        }

        return .result(
            dialog: IntentDialog(stringLiteral: dialogText),
            view: TodayStatusView(
                completedCount: completedCount,
                totalCount: totalCount,
                rhythms: todayRhythms.map { rhythm in
                    TodayStatusRhythm(
                        emoji: rhythm.emoji,
                        title: rhythm.title,
                        isCompleted: rhythm.isCompleted(on: today)
                    )
                }
            )
        )
    }
}

struct TodayStatusRhythm: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let isCompleted: Bool
}

struct TodayStatusView: View {
    let completedCount: Int
    let totalCount: Int
    let rhythms: [TodayStatusRhythm]

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        completedCount == totalCount ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(completedCount)")
                        .font(.title.bold())
                    Text("of \(totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            // Rhythm list (show first 5)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(rhythms.prefix(5)) { rhythm in
                    HStack(spacing: 8) {
                        Image(systemName: rhythm.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(rhythm.isCompleted ? .green : .secondary)

                        Text(rhythm.emoji)
                        Text(rhythm.title)
                            .lineLimit(1)
                            .foregroundStyle(rhythm.isCompleted ? .secondary : .primary)
                    }
                    .font(.caption)
                }

                if rhythms.count > 5 {
                    Text("+\(rhythms.count - 5) more")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
