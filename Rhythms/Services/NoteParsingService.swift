//
//  NoteParsingService.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import FoundationModels

// MARK: - Generable Types for Structured Output

@available(iOS 26, *)
@Generable
enum ParsedScheduleType: String, Codable {
    case weekday
    case dayOfMonth
    case specificDate
}

@available(iOS 26, *)
@Generable
enum ParsedWeekday: String, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var toWeekday: Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
}

@available(iOS 26, *)
@Generable
struct ParsedNote {
    @Guide(description: "The schedule type: weekday for weekly recurring, dayOfMonth for monthly recurring, or specificDate for one-time notes")
    let scheduleType: ParsedScheduleType

    @Guide(description: "The day of week if scheduleType is weekday (e.g., monday, tuesday)")
    let weekday: ParsedWeekday?

    @Guide(description: "The day of month (1-31) if scheduleType is dayOfMonth")
    let dayOfMonth: Int?

    @Guide(description: "The specific date in ISO 8601 format (YYYY-MM-DD) if scheduleType is specificDate")
    let specificDate: String?

    @Guide(description: "The content/activity for this scheduled note")
    let content: String
}

@available(iOS 26, *)
@Generable
struct ParsedNotesResponse {
    @Guide(description: "List of individual notes extracted from the user's input")
    let notes: [ParsedNote]
}

// MARK: - NoteParsingService

@available(iOS 26, *)
@MainActor
final class NoteParsingService: ObservableObject {

    // MARK: - Published Properties

    @Published var parsedNotes: [ParsedNotePreview] = []
    @Published var isParsing: Bool = false
    @Published var error: NoteParsingError?
    @Published var isAvailable: Bool = false

    // MARK: - Types

    struct ParsedNotePreview: Identifiable {
        let id = UUID()
        let scheduleDescription: String
        let content: String
        let weekday: Weekday?
        let dayOfMonth: Int?
        let specificDate: Date?

        var isValid: Bool {
            weekday != nil || dayOfMonth != nil || specificDate != nil
        }

        var isRecurring: Bool {
            weekday != nil || dayOfMonth != nil
        }
    }

    enum NoteParsingError: LocalizedError {
        case unavailable
        case parsingFailed(String)
        case noNotesFound

        var errorDescription: String? {
            switch self {
            case .unavailable:
                return "Apple Intelligence is not available on this device"
            case .parsingFailed(let message):
                return "Failed to parse notes: \(message)"
            case .noNotesFound:
                return "No scheduled notes found in your input"
            }
        }
    }

    enum UnavailabilityReason {
        case deviceNotSupported
        case appleIntelligenceDisabled
        case languageNotSupported
        case unknown
    }

    // MARK: - Private Properties

    private var session: LanguageModelSession?

    private var instructions: Instructions {
        let year = Calendar.current.component(.year, from: Date())
        return Instructions("""
        You are a helpful assistant that extracts scheduled notes from natural language input.

        Your task is to parse user input about scheduled activities and extract:
        1. What activity/content they want to schedule
        2. When they want to schedule it (weekday, day of month, or specific date)

        Examples:
        - "Chest on Mondays and legs on Fridays" -> Two notes: "Chest" for monday, "Legs" for friday
        - "Read 20 pages every Tuesday" -> One note: "Read 20 pages" for tuesday
        - "Pay bills on the 1st of each month" -> One note: "Pay bills" with dayOfMonth=1
        - "Doctor appointment on January 15th 2025" -> One note for specificDate 2025-01-15
        - "Dec 28: Read chapters 1-5" -> One note "Read chapters 1-5" for specificDate \(year)-12-28
        - "Jan 3: Meeting notes" -> One note "Meeting notes" for specificDate \(year + 1)-01-03
        - Multi-line input like:
          "Dec 28: Task A
           Dec 29: Task B"
          -> Two separate notes, one for each date

        Rules:
        - If a day of week is mentioned (Monday, Tuesday, etc.), use weekday type
        - If a day number with "of the month" or "every Xth" is mentioned, use dayOfMonth
        - For specific dates with month and day, use specificDate with ISO 8601 format (YYYY-MM-DD)
        - If no year is specified, assume the current year (\(year)) or next year if the date has passed
        - Extract the activity as the content, keeping it concise but complete
        - If multiple schedules are mentioned (including multi-line input), create multiple notes
        - Handle formats like "Dec 28: content" or "12/28: content" as specific dates
        """)
    }

    // MARK: - Initialization

    init() {
        checkAvailability()
    }

    // MARK: - Public Methods

    func checkAvailability() {
        let availability = SystemLanguageModel.default.availability
        isAvailable = availability == .available

        if isAvailable {
            session = LanguageModelSession(instructions: instructions)
        }
    }

    func getUnavailabilityReason() -> UnavailabilityReason {
        let availability = SystemLanguageModel.default.availability

        switch availability {
        case .available:
            return .unknown
        case .unavailable(let reason):
            // Map the actual API reasons to our UnavailabilityReason
            let reasonDescription = String(describing: reason)
            if reasonDescription.contains("device") || reasonDescription.contains("Device") {
                return .deviceNotSupported
            } else if reasonDescription.contains("Intelligence") || reasonDescription.contains("enabled") {
                return .appleIntelligenceDisabled
            } else if reasonDescription.contains("language") || reasonDescription.contains("Language") {
                return .languageNotSupported
            }
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    func parseNotes(from input: String) async {
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            parsedNotes = []
            return
        }

        guard isAvailable, let session = session else {
            error = .unavailable
            return
        }

        isParsing = true
        error = nil

        do {
            let response = try await session.respond(
                to: "Parse the following input into scheduled notes: \(trimmedInput)",
                generating: ParsedNotesResponse.self
            )

            parsedNotes = response.content.notes.compactMap { convertToPreview($0) }

            if parsedNotes.isEmpty {
                error = .noNotesFound
            }
        } catch {
            self.error = .parsingFailed(error.localizedDescription)
            parsedNotes = []
        }

        isParsing = false
    }

    func createRhythmNotes(for rhythm: Rhythm) -> [RhythmNote] {
        return parsedNotes.compactMap { preview -> RhythmNote? in
            guard preview.isValid else { return nil }

            if let weekday = preview.weekday {
                return .forWeekday(weekday, content: preview.content)
            } else if let day = preview.dayOfMonth {
                return .forDayOfMonth(day, content: preview.content)
            } else if let date = preview.specificDate {
                return .forDate(date, content: preview.content)
            }

            return nil
        }
    }

    func clearParsedNotes() {
        parsedNotes = []
        error = nil
    }

    // MARK: - Private Methods

    private func convertToPreview(_ parsed: ParsedNote) -> ParsedNotePreview? {
        switch parsed.scheduleType {
        case .weekday:
            guard let parsedWeekday = parsed.weekday else { return nil }
            let weekday = parsedWeekday.toWeekday
            return ParsedNotePreview(
                scheduleDescription: "Every \(weekday.fullName)",
                content: parsed.content,
                weekday: weekday,
                dayOfMonth: nil,
                specificDate: nil
            )

        case .dayOfMonth:
            guard let day = parsed.dayOfMonth, day >= 1, day <= 31 else { return nil }
            let suffix = ordinalSuffix(for: day)
            return ParsedNotePreview(
                scheduleDescription: "Every \(day)\(suffix) of month",
                content: parsed.content,
                weekday: nil,
                dayOfMonth: day,
                specificDate: nil
            )

        case .specificDate:
            guard let dateString = parsed.specificDate,
                  let date = parseDate(dateString) else { return nil }
            return ParsedNotePreview(
                scheduleDescription: date.shortDisplayString,
                content: parsed.content,
                weekday: nil,
                dayOfMonth: nil,
                specificDate: date
            )
        }
    }

    private func parseDate(_ string: String) -> Date? {
        // Try ISO 8601 format first
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        if let date = isoFormatter.date(from: string) {
            return date
        }

        // Try common date formats
        let formats = [
            "yyyy-MM-dd",
            "MM/dd/yyyy",
            "M/d/yyyy",
            "MM-dd-yyyy",
            "MMMM d, yyyy",
            "MMMM d yyyy",
            "MMM d, yyyy",
            "MMM d yyyy",
            "d MMMM yyyy",
            "d MMM yyyy"
        ]

        for format in formats {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    private func ordinalSuffix(for day: Int) -> String {
        switch day {
        case 1, 21, 31: return "st"
        case 2, 22: return "nd"
        case 3, 23: return "rd"
        default: return "th"
        }
    }
}
