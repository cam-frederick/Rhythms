//
//  GetNextRhythmIntent.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import AppIntents
import SwiftData
import SwiftUI

/// Intent to get the next incomplete rhythm for today
struct GetNextRhythmIntent: AppIntent {
    static var title: LocalizedStringResource = "What's Next?"
    static var description = IntentDescription("Get your next incomplete rhythm for today")

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Rhythm>(
            predicate: #Predicate { !$0.isArchived && !$0.isPaused }
        )
        let rhythms = try context.fetch(descriptor)
        let today = Date()

        let incompleteRhythms = rhythms
            .filter { $0.isScheduledFor(date: today) && !$0.isCompleted(on: today) }

        if incompleteRhythms.isEmpty {
            let totalCompleted = rhythms.filter { $0.isScheduledFor(date: today) && $0.isCompleted(on: today) }.count

            let dialogText = totalCompleted > 0
                ? "You've completed all \(totalCompleted) rhythms for today!"
                : "No rhythms scheduled for today."

            return .result(
                dialog: IntentDialog(stringLiteral: dialogText),
                view: AllDoneView(completedCount: totalCompleted)
            )
        }

        let nextRhythm = incompleteRhythms.first!
        let remainingCount = incompleteRhythms.count
        let note = nextRhythm.noteForDate(today)?.content

        let dialogText = "Up next: \(nextRhythm.emoji) \(nextRhythm.title). \(remainingCount) rhythm\(remainingCount == 1 ? "" : "s") remaining today."

        return .result(
            dialog: IntentDialog(stringLiteral: dialogText),
            view: NextRhythmView(
                emoji: nextRhythm.emoji,
                title: nextRhythm.title,
                note: note,
                streak: nextRhythm.currentStreak,
                remainingCount: remainingCount
            )
        )
    }
}

struct AllDoneView: View {
    let completedCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: completedCount > 0 ? "checkmark.circle.fill" : "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundStyle(completedCount > 0 ? .green : .secondary)

            Text(completedCount > 0 ? "All Done!" : "Free Day")
                .font(.headline)

            if completedCount > 0 {
                Text("\(completedCount) rhythms completed today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct NextRhythmView: View {
    let emoji: String
    let title: String
    let note: String?
    let streak: Int
    let remainingCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 40))

            Text(title)
                .font(.headline)

            if let note = note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                if streak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                        Text("\(streak)")
                    }
                    .font(.caption)
                }

                Text("\(remainingCount) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
