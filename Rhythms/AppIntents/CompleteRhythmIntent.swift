//
//  CompleteRhythmIntent.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import AppIntents
import SwiftData

/// Intent to mark a rhythm as complete
struct CompleteRhythmIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Rhythm"
    static var description = IntentDescription("Mark a rhythm as completed for today")

    @Parameter(title: "Rhythm")
    var rhythm: RhythmAppEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$rhythm) as complete")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        // Fetch all rhythms and find by ID (workaround for predicate limitations)
        let descriptor = FetchDescriptor<Rhythm>()
        let allRhythms = try context.fetch(descriptor)

        guard let rhythmModel = allRhythms.first(where: { $0.id == rhythm.id }) else {
            throw IntentError.rhythmNotFound
        }

        let today = Date()

        if rhythmModel.isCompleted(on: today) {
            let dialogText = "\(rhythm.emoji) \(rhythm.title) is already completed today!"
            return .result(
                dialog: IntentDialog(stringLiteral: dialogText),
                view: CompletionResultView(
                    emoji: rhythm.emoji,
                    title: rhythm.title,
                    message: "Already completed",
                    streak: rhythmModel.currentStreak
                )
            )
        }

        rhythmModel.markCompleted(for: today)
        try context.save()

        // Reload widgets
        WidgetReloadService.rhythmCompletionChanged()

        let streak = rhythmModel.currentStreak
        let streakMessage = streak > 1 ? " You're on a \(streak)-day streak!" : ""
        let dialogText = "Done! \(rhythm.emoji) \(rhythm.title) completed.\(streakMessage)"

        return .result(
            dialog: IntentDialog(stringLiteral: dialogText),
            view: CompletionResultView(
                emoji: rhythm.emoji,
                title: rhythm.title,
                message: "Completed!",
                streak: streak
            )
        )
    }
}

/// Errors for rhythm intents
enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case rhythmNotFound
    case alreadyCompleted

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .rhythmNotFound:
            return "Rhythm not found"
        case .alreadyCompleted:
            return "Rhythm is already completed"
        }
    }
}

/// View shown in Siri/Shortcuts after completing a rhythm
import SwiftUI

struct CompletionResultView: View {
    let emoji: String
    let title: String
    let message: String
    let streak: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 40))

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.green)

            if streak > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("\(streak) day streak")
                        .fontWeight(.medium)
                }
                .font(.caption)
            }
        }
        .padding()
    }
}
