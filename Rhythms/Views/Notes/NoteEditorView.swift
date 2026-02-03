//
//  NoteEditorView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let rhythm: Rhythm
    let mode: Mode

    enum Mode {
        case create
        case edit(RhythmNote)

        var title: String {
            switch self {
            case .create: return "Add Note"
            case .edit: return "Edit Note"
            }
        }
    }

    enum NoteType: String, CaseIterable, Identifiable {
        case weekday = "Day of Week"
        case dayOfMonth = "Day of Month"
        case specificDate = "Specific Date"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .weekday: return "calendar.day.timeline.left"
            case .dayOfMonth: return "calendar"
            case .specificDate: return "calendar.badge.clock"
            }
        }

        var description: String {
            switch self {
            case .weekday: return "Repeats every week on this day"
            case .dayOfMonth: return "Repeats monthly on this date"
            case .specificDate: return "One-time note for a specific date"
            }
        }
    }

    @State private var content: String = ""
    @State private var noteType: NoteType = .weekday
    @State private var selectedWeekday: Weekday = .monday
    @State private var selectedDayOfMonth: Int = 1
    @State private var selectedDate: Date = Date()
    @State private var showingDeleteConfirmation = false

    private var isValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // Note content
                Section("Note Content") {
                    TextField("What's the plan?", text: $content, axis: .vertical)
                        .font(ThemeTypography.bodyMedium)
                        .lineLimit(3...8)
                }

                // Schedule type
                Section("When") {
                    Picker("Schedule Type", selection: $noteType) {
                        ForEach(NoteType.allCases) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)

                    // Type-specific picker
                    switch noteType {
                    case .weekday:
                        Picker("Day", selection: $selectedWeekday) {
                            ForEach(Weekday.allCases) { day in
                                Text(day.fullName).tag(day)
                            }
                        }

                    case .dayOfMonth:
                        Picker("Day of Month", selection: $selectedDayOfMonth) {
                            ForEach(1...31, id: \.self) { day in
                                Text(ordinalString(for: day)).tag(day)
                            }
                        }

                    case .specificDate:
                        DatePicker(
                            "Date",
                            selection: $selectedDate,
                            displayedComponents: .date
                        )
                        .tint(ThemeColors.accentGold)
                    }
                }

                // Info section
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        Text(noteType.description)
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }
                }

                // Delete button (edit mode only)
                if case .edit = mode {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Note", systemImage: "trash")
                                    .foregroundStyle(ThemeColors.destructive(colorScheme))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(ThemeColors.bgPrimary(colorScheme))
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? ThemeColors.accentGold : ThemeColors.textMuted(colorScheme))
                }
            }
            .confirmationDialog(
                "Delete Note?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    delete()
                }
            }
            .onAppear {
                loadExistingData()
            }
        }
    }

    private func loadExistingData() {
        if case .edit(let note) = mode {
            content = note.content

            if let weekday = note.dayOfWeek {
                noteType = .weekday
                selectedWeekday = weekday
            } else if let day = note.dayOfMonth {
                noteType = .dayOfMonth
                selectedDayOfMonth = day
            } else if let date = note.scheduledDate {
                noteType = .specificDate
                selectedDate = date
            }
        }
    }

    private func save() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        switch mode {
        case .create:
            let note: RhythmNote
            switch noteType {
            case .weekday:
                note = .forWeekday(selectedWeekday, content: trimmedContent)
            case .dayOfMonth:
                note = .forDayOfMonth(selectedDayOfMonth, content: trimmedContent)
            case .specificDate:
                note = .forDate(selectedDate, content: trimmedContent)
            }
            rhythm.addNote(note)
            modelContext.insert(note)

        case .edit(let note):
            note.content = trimmedContent
            note.updatedAt = Date()

            // Update schedule
            note.dayOfWeek = nil
            note.dayOfMonth = nil
            note.scheduledDate = nil
            note.isRecurring = false

            switch noteType {
            case .weekday:
                note.dayOfWeek = selectedWeekday
                note.isRecurring = true
            case .dayOfMonth:
                note.dayOfMonth = selectedDayOfMonth
                note.isRecurring = true
            case .specificDate:
                note.scheduledDate = selectedDate
                note.isRecurring = false
            }
        }

        try? modelContext.save()
        dismiss()
    }

    private func delete() {
        if case .edit(let note) = mode {
            rhythm.removeNote(note)
            modelContext.delete(note)
            try? modelContext.save()
            dismiss()
        }
    }

    private func ordinalString(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Rhythm.self, configurations: config)
    let rhythm = Rhythm(title: "Workout", emoji: "💪")

    return NoteEditorView(rhythm: rhythm, mode: .create)
        .modelContainer(container)
}
