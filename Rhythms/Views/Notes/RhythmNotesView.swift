//
//  RhythmNotesView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

/// View for managing scheduled notes for a rhythm (workout plans, reading pages, etc.)
struct RhythmNotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var rhythm: Rhythm

    @State private var showingAddSheet = false
    @State private var noteToEdit: RhythmNote?

    private var weeklyNotes: [RhythmNote] {
        rhythm.notes
            .filter { $0.dayOfWeek != nil }
            .sorted { ($0.dayOfWeek?.rawValue ?? 0) < ($1.dayOfWeek?.rawValue ?? 0) }
    }

    private var monthlyNotes: [RhythmNote] {
        rhythm.notes
            .filter { $0.dayOfMonth != nil }
            .sorted { ($0.dayOfMonth ?? 0) < ($1.dayOfMonth ?? 0) }
    }

    private var dateSpecificNotes: [RhythmNote] {
        rhythm.notes
            .filter { $0.scheduledDate != nil }
            .sorted { ($0.scheduledDate ?? Date.distantPast) < ($1.scheduledDate ?? Date.distantPast) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Explanation section
                Section {
                    VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
                        Label("Scheduled Notes", systemImage: "note.text")
                            .font(ThemeTypography.titleSmall)
                            .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                        Text("Add notes for specific days to track workout splits, reading goals, or daily focus areas.")
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }
                    .padding(.vertical, ThemeSpacing.xs)
                }

                // Smart Add section (iOS 26+ only)
                if #available(iOS 26, *) {
                    Section {
                        SmartNoteInputView(rhythm: rhythm)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    } header: {
                        Label("Smart Add", systemImage: "sparkles")
                    } footer: {
                        Text("Try: \"Chest on Mondays, back on Wednesdays, legs on Fridays\"")
                    }
                }

                // Weekly recurring notes
                if !weeklyNotes.isEmpty {
                    Section("Weekly Schedule") {
                        ForEach(weeklyNotes, id: \.id) { note in
                            NoteRow(note: note)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    noteToEdit = note
                                }
                        }
                        .onDelete { indexSet in
                            deleteNotes(weeklyNotes, at: indexSet)
                        }
                    }
                }

                // Monthly recurring notes
                if !monthlyNotes.isEmpty {
                    Section("Monthly Schedule") {
                        ForEach(monthlyNotes, id: \.id) { note in
                            NoteRow(note: note)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    noteToEdit = note
                                }
                        }
                        .onDelete { indexSet in
                            deleteNotes(monthlyNotes, at: indexSet)
                        }
                    }
                }

                // Date-specific notes
                if !dateSpecificNotes.isEmpty {
                    Section("Specific Dates") {
                        ForEach(dateSpecificNotes, id: \.id) { note in
                            NoteRow(note: note)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    noteToEdit = note
                                }
                        }
                        .onDelete { indexSet in
                            deleteNotes(dateSpecificNotes, at: indexSet)
                        }
                    }
                }

                // Empty state
                if rhythm.notes.isEmpty {
                    Section {
                        VStack(spacing: ThemeSpacing.md) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 40))
                                .foregroundStyle(ThemeColors.accentGold.opacity(0.7))

                            Text("No notes yet")
                                .font(ThemeTypography.titleSmall)
                                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                            Text("Add notes to plan your \(rhythm.title.lowercased()) schedule")
                                .font(ThemeTypography.bodyMedium)
                                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ThemeSpacing.lg)
                    }
                }

                // Quick add section
                Section {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Note", systemImage: "plus.circle.fill")
                            .foregroundStyle(ThemeColors.accentGold)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeColors.bgPrimary(colorScheme))
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.accentGold)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NoteEditorView(rhythm: rhythm, mode: .create)
            }
            .sheet(item: $noteToEdit) { note in
                NoteEditorView(rhythm: rhythm, mode: .edit(note))
            }
        }
    }

    private func deleteNotes(_ notes: [RhythmNote], at indexSet: IndexSet) {
        for index in indexSet {
            let note = notes[index]
            rhythm.removeNote(note)
            modelContext.delete(note)
        }
        try? modelContext.save()
    }
}

// MARK: - Note Row

struct NoteRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let note: RhythmNote

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            HStack {
                Text(note.scheduleDescription)
                    .font(ThemeTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ThemeColors.accentGold)

                Spacer()

                if note.isRecurring {
                    Image(systemName: "repeat")
                        .font(ThemeTypography.caption)
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))
                }
            }

            Text(note.content)
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                .lineLimit(3)
        }
        .padding(.vertical, ThemeSpacing.xs)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Rhythm.self, configurations: config)

    let rhythm = Rhythm(title: "Workout", emoji: "💪", schedule: .specificDays([.monday, .wednesday, .friday]))
    rhythm.addNote(.forWeekday(.monday, content: "Chest & Triceps - Bench press 4x10, Incline press 3x12"))
    rhythm.addNote(.forWeekday(.wednesday, content: "Back & Biceps - Deadlift 4x8, Rows 3x12"))
    rhythm.addNote(.forWeekday(.friday, content: "Legs - Squats 4x10, Lunges 3x12"))

    return RhythmNotesView(rhythm: rhythm)
        .modelContainer(container)
}
