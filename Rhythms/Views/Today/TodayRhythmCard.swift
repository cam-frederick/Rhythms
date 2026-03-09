//
//  TodayRhythmCard.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct TodayRhythmCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let rhythm: Rhythm
    let selectedDate: Date
    let onToggle: () -> Void

    @State private var checkmarkScale: CGFloat = 1.0
    @State private var celebrationOpacity: Double = 0

    private var isCompleted: Bool {
        rhythm.isCompleted(on: selectedDate)
    }

    private var todaysNote: RhythmNote? {
        rhythm.noteForDate(selectedDate)
    }

    var body: some View {
        Button(action: {
            onToggle()
            if !isCompleted {
                // Trigger spring pop when completing (will appear completed after toggle)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    checkmarkScale = 1.4
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.1)) {
                    checkmarkScale = 1.0
                }
                // Brief celebration sparkle
                withAnimation(.easeOut(duration: 0.15)) {
                    celebrationOpacity = 1
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                    celebrationOpacity = 0
                }
            }
        }) {
            HStack(spacing: ThemeSpacing.md) {
                // Completion checkbox
                ZStack {
                    Circle()
                        .stroke(isCompleted ? rhythm.color : ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.standard)
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(rhythm.color)
                            .frame(width: 28, height: 28)
                            .scaleEffect(checkmarkScale)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .scaleEffect(checkmarkScale)
                    }

                    // Sparkle overlay on completion
                    Image(systemName: "sparkles")
                        .font(.system(size: 22))
                        .foregroundStyle(rhythm.color)
                        .opacity(celebrationOpacity)
                        .scaleEffect(celebrationOpacity == 1 ? 1.2 : 0.8)
                }

                // Rhythm info
                VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                    HStack(spacing: ThemeSpacing.sm) {
                        Text(rhythm.emoji)
                            .font(.title3)

                        Text(rhythm.title)
                            .font(ThemeTypography.titleSmall)
                            .foregroundStyle(isCompleted ? ThemeColors.textMuted(colorScheme) : ThemeColors.textPrimary(colorScheme))
                            .strikethrough(isCompleted, color: ThemeColors.textMuted(colorScheme))
                    }

                    // Show today's note if available
                    if let note = todaysNote {
                        Text(note.content)
                            .font(ThemeTypography.bodySmall)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                            .lineLimit(2)
                    }

                    // Streak badge
                    if rhythm.currentStreak > 0 {
                        HStack(spacing: ThemeSpacing.xs) {
                            Image(systemName: "flame.fill")
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.accentGold)

                            Text("\(rhythm.currentStreak) day streak")
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
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
            .padding(ThemeSpacing.md)
            .background(ThemeColors.bgCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.large)
                    .stroke(
                        isCompleted ? rhythm.color.opacity(0.3) : ThemeColors.borderSubtle(colorScheme),
                        lineWidth: ThemeBorder.thin
                    )
            )
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(isCompleted ? 0 : 0.04),
                radius: isCompleted ? 0 : 6,
                y: isCompleted ? 0 : 2
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
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
