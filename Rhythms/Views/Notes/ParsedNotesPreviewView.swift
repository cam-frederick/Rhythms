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
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Found \(previews.count) note\(previews.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Note Previews
            ForEach(previews) { preview in
                PreviewNoteRow(preview: preview)
            }

            // Action Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)

                Button("Add All") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        }
    }
}

// MARK: - Preview Note Row

@available(iOS 26, *)
struct PreviewNoteRow: View {
    let preview: NoteParsingService.ParsedNotePreview

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(preview.scheduleDescription)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                if preview.isRecurring {
                    Image(systemName: "repeat")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(preview.content)
                .font(.subheadline)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
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
        onConfirm: {},
        onCancel: {}
    )
    .padding()
}
