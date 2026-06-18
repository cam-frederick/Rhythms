//
//  TodayRhythmCard.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//  Updated by Cici on 3/30/26 – note indicator + quick-add note from card.
//

import SwiftUI

struct TodayRhythmCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let rhythm: Rhythm
    let selectedDate: Date
    let onToggle: () -> Void

    @State private var checkmarkScale: CGFloat = 1.0
    @State private var celebrationOpacity: Double = 0
    @State private var showingNoteEditor: Bool = false

    private var isCompleted: Bool {
        rhythm.isCompleted(on: selectedDate)
    }

    private var isMissed: Bool {
        selectedDate.isPast && !selectedDate.isToday && !isCompleted
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
                            .opacity(isMissed ? 0.5 : 1.0)

                        Text(rhythm.title)
                            .font(ThemeTypography.titleSmall)
                            .foregroundStyle(
                                isCompleted ? ThemeColors.textMuted(colorScheme) :
                                isMissed ? ThemeColors.textMuted(colorScheme) :
                                ThemeColors.textPrimary(colorScheme)
                            )
                            .strikethrough(isCompleted, color: ThemeColors.textMuted(colorScheme))

                        // Missed badge — small pill shown when past-day rhythm was skipped
                        if isMissed {
                            Text("Missed")
                                .font(ThemeTypography.caption)
                                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(ThemeColors.bgSecondary(colorScheme))
                                )
                        }
                    }

                    // Show today's note if available
                    if let note = todaysNote {
                        Text(note.content)
                            .font(ThemeTypography.bodySmall)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                            .lineLimit(2)
                    }

                    // Streak badge — only show for current/future day rhythms to avoid confusion
                    if rhythm.currentStreak > 0 && !isMissed {
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

                // Trailing: note indicator + category
                VStack(alignment: .trailing, spacing: ThemeSpacing.xs) {
                    // Note button — shows pencil.badge if no note, note.text if note exists
                    Button {
                        showingNoteEditor = true
                    } label: {
                        Image(systemName: todaysNote != nil ? "note.text" : "square.and.pencil")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                todaysNote != nil
                                ? rhythm.color
                                : ThemeColors.textMuted(colorScheme).opacity(0.5)
                            )
                            .frame(width: 28, height: 28)
                            .background(
                                todaysNote != nil
                                ? rhythm.color.opacity(0.12)
                                : Color.clear
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(todaysNote != nil ? "View or edit note" : "Add note")

                    // Category indicator
                    if let category = rhythm.category {
                        Text(category.emoji)
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                }
            }
            .padding(ThemeSpacing.md)
            .background(ThemeColors.bgCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.large)
                    .stroke(
                        isCompleted ? rhythm.color.opacity(0.3) :
                        isMissed ? ThemeColors.borderSubtle(colorScheme).opacity(0.5) :
                        ThemeColors.borderSubtle(colorScheme),
                        lineWidth: ThemeBorder.thin
                    )
            )
            .opacity(isMissed ? 0.7 : 1.0)
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(isCompleted || isMissed ? 0 : 0.04),
                radius: isCompleted || isMissed ? 0 : 6,
                y: isCompleted || isMissed ? 0 : 2
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
        .sheet(isPresented: $showingNoteEditor) {
            NavigationStack {
                NoteEditorView(
                    rhythm: rhythm,
                    mode: todaysNote != nil ? .edit(todaysNote!) : .create
                )
            }
        }
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
