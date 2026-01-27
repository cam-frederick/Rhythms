//
//  CalendarPickerView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Rhythm> { !$0.isArchived && !$0.isPaused },
        sort: \Rhythm.createdAt
    ) private var rhythms: [Rhythm]

    @State private var displayedMonth: Date = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Month navigation
                monthHeader

                // Weekday headers
                weekdayHeader

                // Calendar grid
                calendarGrid

                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Today") {
                        selectedDate = Date()
                        displayedMonth = Date()
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(monthYearString)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let date = day {
                    CalendarDayCell(
                        date: date,
                        isSelected: date.isSameDay(as: selectedDate),
                        isToday: date.isToday,
                        progress: progressForDate(date),
                        rhythmCount: rhythmCountForDate(date)
                    )
                    .onTapGesture {
                        selectedDate = date
                        dismiss()
                    }
                } else {
                    Color.clear
                        .frame(height: 50)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        let startOfMonth = displayedMonth.startOfMonth
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)!.count

        // Get the weekday of the first day (0 = Sunday in Calendar)
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)

        // Create array with leading empty slots
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        // Add all days of the month
        for day in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                days.append(date)
            }
        }

        return days
    }

    private func progressForDate(_ date: Date) -> Double? {
        // Only show progress for past dates
        guard date.isPast || date.isToday else { return nil }

        let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
        guard !scheduledRhythms.isEmpty else { return nil }

        let completedCount = scheduledRhythms.filter { $0.isCompleted(on: date) }.count
        return Double(completedCount) / Double(scheduledRhythms.count)
    }

    private func rhythmCountForDate(_ date: Date) -> Int {
        rhythms.filter { $0.isScheduledFor(date: date) }.count
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let progress: Double?
    let rhythmCount: Int

    private let cellSize: CGFloat = 44

    private var progressColor: Color {
        guard let progress else { return .clear }
        switch progress {
        case 1.0:
            return .green
        case 0.5..<1.0:
            return .blue
        case 0.0..<0.5:
            return .orange
        default:
            return .gray.opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Progress ring for past dates
                if let progress, progress > 0 {
                    Circle()
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                // Today or selection highlight
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                } else if isToday {
                    Circle()
                        .fill(Color.accentColor.opacity(0.2))
                }

                // Day number
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday || isSelected ? .bold : .regular))
                    .foregroundStyle(dayTextColor)
            }
            .frame(width: cellSize, height: cellSize)

            // Rhythm count dots
            rhythmDots
        }
        .frame(height: 58)
    }

    private var dayTextColor: Color {
        if isSelected {
            return .white
        } else if date.isFuture {
            return .primary.opacity(0.5)
        } else {
            return .primary
        }
    }

    @ViewBuilder
    private var rhythmDots: some View {
        if rhythmCount > 0 {
            HStack(spacing: 2) {
                ForEach(0..<min(rhythmCount, 4), id: \.self) { _ in
                    Circle()
                        .fill(dotColor)
                        .frame(width: 4, height: 4)
                }
                if rhythmCount > 4 {
                    Text("+")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Color.clear
                .frame(height: 4)
        }
    }

    private var dotColor: Color {
        if isSelected {
            return .accentColor
        } else if let progress, progress == 1.0 {
            return .green
        } else {
            return .secondary.opacity(0.5)
        }
    }
}

#Preview {
    CalendarPickerView(selectedDate: .constant(Date()))
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
