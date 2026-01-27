//
//  SmartNoteInputView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

/// A text input component that uses AI to parse natural language into scheduled notes
@available(iOS 26, *)
struct SmartNoteInputView: View {
    @Bindable var rhythm: Rhythm
    @Environment(\.modelContext) private var modelContext
    @StateObject private var parsingService = NoteParsingService()

    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Smart Input Field
            inputField

            // Availability Warning or Parse Button
            if !parsingService.isAvailable {
                unavailableView
            } else if !inputText.isEmpty && parsingService.parsedNotes.isEmpty && !parsingService.isParsing {
                parseButton
            }

            // Error Display
            if let error = parsingService.error {
                errorView(error)
            }

            // Parsed Notes Preview
            if !parsingService.parsedNotes.isEmpty {
                ParsedNotesPreviewView(
                    previews: parsingService.parsedNotes,
                    onConfirm: saveNotes,
                    onCancel: {
                        parsingService.clearParsedNotes()
                    }
                )
            }
        }
        .padding()
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundStyle(.purple)
                .font(.title3)
                .padding(.top, 8)

            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Describe your schedule...")
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }

                TextEditor(text: $inputText)
                    .frame(minHeight: 36, maxHeight: 100)
                    .scrollContentBackground(.hidden)
                    .focused($isInputFocused)
                    .onChange(of: inputText) { _, _ in
                        // Clear parsed notes when input changes
                        if !parsingService.parsedNotes.isEmpty {
                            parsingService.clearParsedNotes()
                        }
                    }
            }

            if !inputText.isEmpty {
                Button {
                    inputText = ""
                    parsingService.clearParsedNotes()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        }
    }

    // MARK: - Parse Button

    private var parseButton: some View {
        Button {
            parseInput()
        } label: {
            HStack(spacing: 8) {
                if parsingService.isParsing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(parsingService.isParsing ? "Parsing..." : "Parse Notes")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .disabled(parsingService.isParsing)
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            Text(unavailabilityMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var unavailabilityMessage: String {
        switch parsingService.getUnavailabilityReason() {
        case .deviceNotSupported:
            return "Smart parsing requires an Apple Intelligence-compatible device"
        case .appleIntelligenceDisabled:
            return "Enable Apple Intelligence in Settings to use smart parsing"
        case .languageNotSupported:
            return "Smart parsing is not available in your current language"
        case .unknown:
            return "Smart parsing is currently unavailable"
        }
    }

    // MARK: - Error View

    private func errorView(_ error: NoteParsingService.NoteParsingError) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func parseInput() {
        isInputFocused = false
        Task {
            await parsingService.parseNotes(from: inputText)
        }
    }

    private func saveNotes() {
        let notes = parsingService.createRhythmNotes(for: rhythm)
        for note in notes {
            rhythm.addNote(note)
            modelContext.insert(note)
        }
        try? modelContext.save()

        // Reset state
        inputText = ""
        parsingService.clearParsedNotes()
    }
}

@available(iOS 26, *)
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Rhythm.self, configurations: config)
    let rhythm = Rhythm(title: "Workout", emoji: "💪")

    return SmartNoteInputView(rhythm: rhythm)
        .modelContainer(container)
        .padding()
}
