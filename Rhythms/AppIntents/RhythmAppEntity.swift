//
//  RhythmAppEntity.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import AppIntents
import SwiftData

/// App Entity representing a Rhythm for use with App Intents
struct RhythmAppEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Rhythm")
    }

    static var defaultQuery = RhythmAppEntityQuery()

    var id: UUID
    var title: String
    var emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(emoji) \(title)",
            subtitle: nil
        )
    }

    init(id: UUID, title: String, emoji: String) {
        self.id = id
        self.title = title
        self.emoji = emoji
    }

    init(from rhythm: Rhythm) {
        self.id = rhythm.id
        self.title = rhythm.title
        self.emoji = rhythm.emoji
    }
}

/// Query to find rhythms for App Intents
struct RhythmAppEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [RhythmAppEntity] {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        var results: [RhythmAppEntity] = []
        for id in identifiers {
            let descriptor = FetchDescriptor<Rhythm>(
                predicate: #Predicate { $0.id == id }
            )
            if let rhythm = try context.fetch(descriptor).first {
                results.append(RhythmAppEntity(from: rhythm))
            }
        }
        return results
    }

    func suggestedEntities() async throws -> [RhythmAppEntity] {
        // Return today's incomplete rhythms as suggestions
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Rhythm>(
            predicate: #Predicate { !$0.isArchived && !$0.isPaused }
        )
        let rhythms = try context.fetch(descriptor)
        let today = Date()

        return rhythms
            .filter { $0.isScheduledFor(date: today) && !$0.isCompleted(on: today) }
            .map { RhythmAppEntity(from: $0) }
    }
}

extension RhythmAppEntityQuery: EntityStringQuery {
    func entities(matching string: String) async throws -> [RhythmAppEntity] {
        let container = try SharedModelContainer.makeContainer()
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Rhythm>(
            predicate: #Predicate { !$0.isArchived }
        )
        let rhythms = try context.fetch(descriptor)

        return rhythms
            .filter { $0.title.localizedCaseInsensitiveContains(string) }
            .map { RhythmAppEntity(from: $0) }
    }
}
