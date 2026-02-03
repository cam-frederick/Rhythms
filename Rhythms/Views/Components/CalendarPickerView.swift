//
//  CalendarPickerView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct CalendarPickerView: View {
    @Environment(\.colorScheme) private var colorScheme
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
            VStack(spacing: ThemeSpacing.lg) {
                // Month navigation
                monthHeader

                // Weekday headers
                weekdayHeader

                // Calendar grid
                calendarGrid

                Spacer()
            }
            .padding(ThemeSpacing.md)
            .background(ThemeColors.bgPrimary(colorScheme))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Today") {
                        selectedDate = Date()
                        displayedMonth = Date()
                        dismiss()
                    }
                    .foregroundStyle(ThemeColors.accentGold)
                }
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            Spacer()

            Text(monthYearString)
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Spacer()

            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
        }
        .padding(.horizontal, ThemeSpacing.md)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: ThemeSpacing.sm) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(ThemeTypography.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: ThemeSpacing.sm) {
            ForEach(days, id: \.self) { day in
                if let date = day {
                    CalendarDayCell(
                        date: date,
                        isSelected: date.isSameDay(as: selectedDate),
                        isToday: date.isToday,
                        progress: progressForDate(date),
                        rhythmCount: rhythmCountForDate(date),
                        colorScheme: colorScheme
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
    let colorScheme: ColorScheme

    private let cellSize: CGFloat = 44

    private var progressColor: Color {
        guard let progress else { return .clear }
        switch progress {
        case 1.0:
            return ThemeColors.accentGold
        case 0.5..<1.0:
            return ThemeColors.accentGold.opacity(0.7)
        case 0.0..<0.5:
            return ThemeColors.accentGold.opacity(0.4)
        default:
            return ThemeColors.textMuted(colorScheme).opacity(0.3)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Progress ring for past dates
                if let progress, progress > 0 {
                    Circle()
                        .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                // Today or selection highlight
                if isSelected {
                    Circle()
                        .fill(ThemeColors.accentGold)
                } else if isToday {
                    Circle()
                        .fill(ThemeColors.accentGold.opacity(0.2))
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
            return colorScheme == .dark ? .black : .white
        } else if date.isFuture {
            return ThemeColors.textPrimary(colorScheme).opacity(0.5)
        } else {
            return ThemeColors.textPrimary(colorScheme)
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
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
            }
        } else {
            Color.clear
                .frame(height: 4)
        }
    }

    private var dotColor: Color {
        if isSelected {
            return ThemeColors.accentGold
        } else if let progress, progress == 1.0 {
            return ThemeColors.accentGold
        } else {
            return ThemeColors.textSecondary(colorScheme).opacity(0.5)
        }
    }
}

#Preview {
    CalendarPickerView(selectedDate: .constant(Date()))
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
