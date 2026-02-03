//
//  QuickCheckInSheet.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct QuickCheckInSheet: View {
    let rhythm: Rhythm
    let date: Date
    let onComplete: (String?, Mood?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticService) private var hapticService
    @Environment(\.colorScheme) private var colorScheme

    @State private var note: String = ""
    @State private var selectedMood: Mood?
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: ThemeSpacing.lg) {
                    // Rhythm header
                    rhythmHeader

                    // Mood selector
                    moodSelector

                    // Note input
                    noteInput

                    // Complete button
                    completeButton
                }
                .padding(ThemeSpacing.md)
            }
            .background(ThemeColors.bgPrimary(colorScheme))
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        hapticService.playLight()
                        onComplete(nil, nil)
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
                }

                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        isNoteFocused = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Rhythm Header

    private var rhythmHeader: some View {
        VStack(spacing: ThemeSpacing.sm) {
            Text(rhythm.emoji)
                .font(.system(size: 48))

            Text(rhythm.title)
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("How are you feeling?")
                .font(ThemeTypography.titleSmall)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            HStack(spacing: ThemeSpacing.sm) {
                ForEach(Mood.allCases) { mood in
                    moodButton(mood)
                }
            }
        }
    }

    private func moodButton(_ mood: Mood) -> some View {
        Button {
            withAnimation(ThemeAnimation.standardEase) {
                if selectedMood == mood {
                    selectedMood = nil
                } else {
                    selectedMood = mood
                    hapticService.playSelection()
                }
            }
        } label: {
            VStack(spacing: ThemeSpacing.xs) {
                Text(mood.emoji)
                    .font(.system(size: 32))

                Text(mood.label)
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.sm)
            .background(selectedMood == mood ? mood.color.opacity(0.2) : ThemeColors.bgSecondary(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.large)
                    .stroke(selectedMood == mood ? mood.color : ThemeColors.borderSubtle(colorScheme), lineWidth: selectedMood == mood ? ThemeBorder.thick : ThemeBorder.thin)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Input

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text("Add a note (optional)")
                .font(ThemeTypography.titleSmall)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            TextField("How did it go?", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .font(ThemeTypography.bodyMedium)
                .padding(ThemeSpacing.md)
                .background(ThemeColors.bgSecondary(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.large)
                        .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
                )
                .focused($isNoteFocused)
                .lineLimit(3...6)
        }
    }

    // MARK: - Complete Button

    private var completeButton: some View {
        Button {
            hapticService.playSuccess()
            onComplete(note.isEmpty ? nil : note, selectedMood)
            dismiss()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete")
            }
            .font(ThemeTypography.labelLarge)
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(ThemeSpacing.md)
            .background(ThemeColors.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            QuickCheckInSheet(
                rhythm: Rhythm(title: "Morning Workout", emoji: "💪", colorHex: "#34C759"),
                date: Date()
            ) { note, mood in
                print("Note: \(note ?? "none"), Mood: \(mood?.label ?? "none")")
            }
        }
}
