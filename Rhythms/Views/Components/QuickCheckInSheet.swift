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

    @State private var note: String = ""
    @State private var selectedMood: Mood?
    @FocusState private var isNoteFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Rhythm header
                    rhythmHeader

                    // Mood selector
                    moodSelector

                    // Note input
                    noteInput

                    // Complete button
                    completeButton
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Skip") {
                        hapticService.playLight()
                        onComplete(nil, nil)
                        dismiss()
                    }
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
        VStack(spacing: 8) {
            Text(rhythm.emoji)
                .font(.system(size: 48))

            Text(rhythm.title)
                .font(.title3)
                .fontWeight(.semibold)

            Text(date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Mood Selector

    private var moodSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How are you feeling?")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(Mood.allCases) { mood in
                    moodButton(mood)
                }
            }
        }
    }

    private func moodButton(_ mood: Mood) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedMood == mood {
                    selectedMood = nil
                } else {
                    selectedMood = mood
                    hapticService.playSelection()
                }
            }
        } label: {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 32))

                Text(mood.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedMood == mood ? mood.color.opacity(0.2) : Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Note Input

    private var noteInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a note (optional)")
                .font(.headline)

            TextField("How did it go?", text: $note, axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(rhythm.color)
            .clipShape(RoundedRectangle(cornerRadius: 14))
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
