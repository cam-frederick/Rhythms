//
//  TodayRhythmCard.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct TodayRhythmCard: View {
    let rhythm: Rhythm
    let selectedDate: Date
    let onToggle: () -> Void

    private var isCompleted: Bool {
        rhythm.isCompleted(on: selectedDate)
    }

    private var todaysNote: RhythmNote? {
        rhythm.noteForDate(selectedDate)
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // Completion checkbox
                ZStack {
                    Circle()
                        .stroke(isCompleted ? rhythm.color : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(rhythm.color)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                // Rhythm info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(rhythm.emoji)
                            .font(.title3)

                        Text(rhythm.title)
                            .font(.headline)
                            .foregroundStyle(isCompleted ? .secondary : .primary)
                            .strikethrough(isCompleted)
                    }

                    // Show today's note if available
                    if let note = todaysNote {
                        Text(note.content)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    // Streak badge
                    if rhythm.currentStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)

                            Text("\(rhythm.currentStreak) day streak")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Category indicator
                if let category = rhythm.category {
                    Text(category.emoji)
                        .font(.title3)
                        .opacity(0.6)
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color.secondary.opacity(0.1) : Color(.systemBackground))
                    .shadow(color: .black.opacity(isCompleted ? 0 : 0.05), radius: 4, y: 2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isCompleted ? rhythm.color.opacity(0.3) : Color.clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isCompleted)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Incomplete rhythm
        TodayRhythmCard(
            rhythm: {
                let r = Rhythm(title: "Morning Workout", emoji: "💪", colorHex: "#34C759")
                return r
            }(),
            selectedDate: Date(),
            onToggle: {}
        )

        // Completed rhythm
        TodayRhythmCard(
            rhythm: {
                let r = Rhythm(title: "Read 30 minutes", emoji: "📚", colorHex: "#007AFF")
                r.markCompleted(for: Date())
                return r
            }(),
            selectedDate: Date(),
            onToggle: {}
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
