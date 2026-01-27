//
//  RhythmEntry.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData

/// Represents a single completion of a rhythm on a specific date
@Model
final class RhythmEntry {
    // MARK: - Properties

    var id: UUID
    var completedAt: Date
    var scheduledDate: Date

    // Optional metadata
    var note: String?
    var mood: Mood?
    var duration: TimeInterval?

    // Relationship
    var rhythm: Rhythm?

    // MARK: - Initialization

    init(
        scheduledDate: Date,
        rhythm: Rhythm? = nil,
        note: String? = nil,
        mood: Mood? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = UUID()
        self.completedAt = Date()
        self.scheduledDate = scheduledDate.startOfDay
        self.rhythm = rhythm
        self.note = note
        self.mood = mood
        self.duration = duration
    }

    // MARK: - Computed Properties

    /// Returns true if this entry was completed on the scheduled date
    var wasCompletedOnTime: Bool {
        completedAt.isSameDay(as: scheduledDate)
    }

    /// Returns the time between when the entry was scheduled and completed
    var completionDelay: TimeInterval {
        completedAt.timeIntervalSince(scheduledDate)
    }
}
