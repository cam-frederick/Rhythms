//
//  CalendarHeatMapView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct CalendarHeatMapView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            // Month navigation
            monthHeader

            // Weekday headers
            weekdayHeaders

            // Calendar grid
            calendarGrid

            // Legend
            legend

            // Selected date details
            if let date = selectedDate {
                selectedDateDetails(for: date)
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(ThemeTypography.labelLarge)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            Spacer()

            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Spacer()

            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(ThemeTypography.labelLarge)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day.prefix(1))
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(days, id: \.self) { date in
                if let date = date {
                    dayCell(for: date)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private func dayCell(for date: Date) -> some View {
        let completionRate = completionRate(for: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate?.isSameDay(as: date) == true
        let isFuture = date > Date()

        return Button {
            withAnimation(ThemeAnimation.standardEase) {
                selectedDate = selectedDate?.isSameDay(as: date) == true ? nil : date
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: ThemeRadius.small)
                    .fill(isFuture ? Color.clear : heatColor(for: completionRate))

                Text("\(calendar.component(.day, from: date))")
                    .font(ThemeTypography.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isFuture ? ThemeColors.textMuted(colorScheme).opacity(0.3) : ThemeColors.textPrimary(colorScheme))
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .stroke(ThemeColors.accentGold, lineWidth: ThemeBorder.thick)
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .stroke(ThemeColors.textPrimary(colorScheme), lineWidth: ThemeBorder.thick)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: ThemeSpacing.xs) {
            Text("Less")
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            ForEach([0.0, 0.1, 0.3, 0.6, 0.8, 1.0], id: \.self) { value in
                RoundedRectangle(cornerRadius: ThemeRadius.small)
                    .fill(heatColor(for: value))
                    .frame(width: 14, height: 14)
            }

            Text("More")
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
        }
    }

    // MARK: - Selected Date Details

    private func selectedDateDetails(for date: Date) -> some View {
        let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
        let completedRhythms = scheduledRhythms.filter { $0.isCompleted(on: date) }

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Rectangle()
                .fill(ThemeColors.borderSubtle(colorScheme))
                .frame(height: ThemeBorder.thin)

            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(ThemeTypography.titleSmall)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                Spacer()

                Text("\(completedRhythms.count)/\(scheduledRhythms.count) completed")
                    .font(ThemeTypography.bodySmall)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            if scheduledRhythms.isEmpty {
                Text("No rhythms scheduled")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            } else {
                ForEach(scheduledRhythms) { rhythm in
                    HStack(spacing: ThemeSpacing.sm) {
                        Image(systemName: rhythm.isCompleted(on: date) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(rhythm.isCompleted(on: date) ? ThemeColors.accentGold : ThemeColors.textMuted(colorScheme))

                        Text(rhythm.emoji)

                        Text(rhythm.title)
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                        Spacer()

                        if let entry = rhythm.entry(for: date), let mood = entry.mood {
                            Text(mood.emoji)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        let adjustedLeadingDays = leadingEmptyDays < 0 ? leadingEmptyDays + 7 : leadingEmptyDays

        var days: [Date?] = Array(repeating: nil, count: adjustedLeadingDays)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }

        // Pad to complete the last week
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func completionRate(for date: Date) -> Double {
        let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
        guard !scheduledRhythms.isEmpty else { return 0 }

        let completedCount = scheduledRhythms.filter { $0.isCompleted(on: date) }.count
        return Double(completedCount) / Double(scheduledRhythms.count)
    }

    private func heatColor(for rate: Double) -> Color {
        switch rate {
        case 0:
            return ThemeColors.bgSecondary(colorScheme)
        case 0..<0.25:
            return ThemeColors.accentGold.opacity(0.2)
        case 0.25..<0.5:
            return ThemeColors.accentGold.opacity(0.35)
        case 0.5..<0.75:
            return ThemeColors.accentGold.opacity(0.5)
        case 0.75..<1.0:
            return ThemeColors.accentGold.opacity(0.7)
        default:
            return ThemeColors.accentGold.opacity(0.9)
        }
    }
}

#Preview {
    ScrollView {
        CalendarHeatMapView()
            .padding()
    }
    .modelContainer(for: [Rhythm.self, RhythmEntry.self, RhythmNote.self, Category.self])
}
