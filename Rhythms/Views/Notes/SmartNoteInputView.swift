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
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var parsingService = NoteParsingService()

    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
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
                    colorScheme: colorScheme,
                    onConfirm: saveNotes,
                    onCancel: {
                        parsingService.clearParsedNotes()
                    }
                )
            }
        }
        .padding(ThemeSpacing.md)
    }

    // MARK: - Input Field

    private var inputField: some View {
        HStack(alignment: .top, spacing: ThemeSpacing.sm) {
            Image(systemName: "sparkles")
                .foregroundStyle(ThemeColors.accentGold)
                .font(.title3)
                .padding(.top, ThemeSpacing.sm)

            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("Describe your schedule...")
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        .padding(.top, ThemeSpacing.sm)
                        .padding(.leading, ThemeSpacing.xs)
                }

                TextEditor(text: $inputText)
                    .font(ThemeTypography.bodyMedium)
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
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
                .buttonStyle(.plain)
                .padding(.top, ThemeSpacing.sm)
            }
        }
        .padding(ThemeSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .fill(ThemeColors.bgSecondary(colorScheme))
        }
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Parse Button

    private var parseButton: some View {
        Button {
            parseInput()
        } label: {
            HStack(spacing: ThemeSpacing.sm) {
                if parsingService.isParsing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(colorScheme == .dark ? .black : .white)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(parsingService.isParsing ? "Parsing..." : "Parse Notes")
                    .font(ThemeTypography.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.sm)
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .background(ThemeColors.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
        }
        .buttonStyle(.plain)
        .disabled(parsingService.isParsing)
    }

    // MARK: - Unavailable View

    private var unavailableView: some View {
        HStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ThemeColors.accentGold)

            Text(unavailabilityMessage)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .padding(.horizontal, ThemeSpacing.md)
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
        HStack(spacing: ThemeSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(ThemeColors.destructive(colorScheme))

            Text(error.localizedDescription)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .padding(.horizontal, ThemeSpacing.md)
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
