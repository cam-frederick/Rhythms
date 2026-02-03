//
//  ParsedNotesPreviewView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

/// Displays a preview of parsed notes before saving them
@available(iOS 26, *)
struct ParsedNotesPreviewView: View {
    let previews: [NoteParsingService.ParsedNotePreview]
    let colorScheme: ColorScheme
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(ThemeColors.accentGold)
                Text("Found \(previews.count) note\(previews.count == 1 ? "" : "s")")
                    .font(ThemeTypography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
            }

            // Note Previews
            ForEach(previews) { preview in
                PreviewNoteRow(preview: preview, colorScheme: colorScheme)
            }

            // Action Buttons
            HStack(spacing: ThemeSpacing.sm) {
                Button("Cancel") {
                    onCancel()
                }
                .font(ThemeTypography.labelMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.sm)
                .background(ThemeColors.bgSecondary(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))

                Button("Add All") {
                    onConfirm()
                }
                .font(ThemeTypography.labelMedium)
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.sm)
                .background(ThemeColors.accentGold)
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(ThemeSpacing.md)
        .background {
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .fill(ThemeColors.accentGold.opacity(0.1))
        }
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }
}

// MARK: - Preview Note Row

@available(iOS 26, *)
struct PreviewNoteRow: View {
    let preview: NoteParsingService.ParsedNotePreview
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            HStack {
                Text(preview.scheduleDescription)
                    .font(ThemeTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ThemeColors.accentGold)

                Spacer()

                if preview.isRecurring {
                    Image(systemName: "repeat")
                        .font(ThemeTypography.caption)
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                }
            }

            Text(preview.content)
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))
        }
        .padding(.vertical, ThemeSpacing.sm)
        .padding(.horizontal, ThemeSpacing.sm)
        .background {
            RoundedRectangle(cornerRadius: ThemeRadius.medium)
                .fill(ThemeColors.bgCard(colorScheme))
        }
    }
}

@available(iOS 26, *)
#Preview {
    ParsedNotesPreviewView(
        previews: [
            NoteParsingService.ParsedNotePreview(
                scheduleDescription: "Every Monday",
                content: "Chest & Triceps",
                weekday: .monday,
                dayOfMonth: nil,
                specificDate: nil
            ),
            NoteParsingService.ParsedNotePreview(
                scheduleDescription: "Every Wednesday",
                content: "Back & Biceps",
                weekday: .wednesday,
                dayOfMonth: nil,
                specificDate: nil
            ),
            NoteParsingService.ParsedNotePreview(
                scheduleDescription: "Every Friday",
                content: "Legs & Shoulders",
                weekday: .friday,
                dayOfMonth: nil,
                specificDate: nil
            )
        ],
        colorScheme: .dark,
        onConfirm: {},
        onCancel: {}
    )
    .padding()
}
