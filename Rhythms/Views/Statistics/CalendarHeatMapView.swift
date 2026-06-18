//
//  CalendarHeatMapView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//  Updated by Cici on 3/30/26 – heat gradient polish, accessibility, entrance animations.
//

import SwiftUI
import SwiftData

struct CalendarHeatMapView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date?
    @State private var appeared: Bool = false

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
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgCard(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.xlarge))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.xlarge)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(ThemeTypography.labelLarge)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .frame(width: 32, height: 32)
                    .background(ThemeColors.bgSecondary(colorScheme))
                    .clipShape(Circle())
            }

            Spacer()

            VStack(spacing: 2) {
                Text(selectedMonth.formatted(.dateTime.month(.wide)))
                    .font(ThemeTypography.titleMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                Text(selectedMonth.formatted(.dateTime.year()))
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            Spacer()

            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    selectedDate = nil
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(ThemeTypography.labelLarge)
                    .foregroundStyle(isCurrentMonth ? ThemeColors.textMuted(colorScheme) : ThemeColors.textSecondary(colorScheme))
                    .frame(width: 32, height: 32)
                    .background(ThemeColors.bgSecondary(colorScheme))
                    .clipShape(Circle())
            }
            .disabled(isCurrentMonth)
        }
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(orderedWeekdaySymbols, id: \.self) { day in
                Text(day.prefix(1))
                    .font(ThemeTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Weekday symbols ordered starting from the locale's first weekday
    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday - 1  // 0-indexed
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday])
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                if let date = date {
                    dayCell(for: date, index: index)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }

    private func dayCell(for date: Date, index: Int) -> some View {
        let completionRate = completionRate(for: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate?.isSameDay(as: date) == true
        let isFuture = date > Date()
        let hasActivity = completionRate > 0 && !isFuture
        let scheduledCount = rhythms.filter { $0.isScheduledFor(date: date) }.count

        return Button {
            withAnimation(ThemeAnimation.standardEase) {
                selectedDate = selectedDate?.isSameDay(as: date) == true ? nil : date
            }
        } label: {
            ZStack {
                // Background fill
                RoundedRectangle(cornerRadius: ThemeRadius.small)
                    .fill(isFuture ? Color.clear : heatColor(for: completionRate))

                // Day number
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 11, weight: isToday ? .bold : .regular, design: .rounded))
                    .foregroundStyle(labelColor(for: completionRate, isFuture: isFuture, isToday: isToday))
                    .accessibilityLabel(accessibilityLabel(for: date, rate: completionRate, isFuture: isFuture, scheduledCount: scheduledCount))
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .stroke(ThemeColors.accentGold, lineWidth: 2)
                }
                if isSelected && !isToday {
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .stroke(ThemeColors.textPrimary(colorScheme).opacity(0.7), lineWidth: 1.5)
                }
            }
            // Staggered entrance animation
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.5)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.65)
                    .delay(Double(index) * 0.01),
                value: appeared
            )
        }
        .buttonStyle(.plain)
        .disabled(isFuture || scheduledCount == 0)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: ThemeSpacing.sm) {
            Text("No rhythms")
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            Spacer()

            HStack(spacing: 3) {
                ForEach([0.0, 0.2, 0.4, 0.65, 0.85, 1.0], id: \.self) { value in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(for: value))
                        .frame(width: 16, height: 16)
                }
            }

            Text("All done")
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))
        }
        .padding(.horizontal, ThemeSpacing.xs)
    }

    // MARK: - Selected Date Details

    private func selectedDateDetails(for date: Date) -> some View {
        let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
        let completedRhythms = scheduledRhythms.filter { $0.isCompleted(on: date) }
        let rate = scheduledRhythms.isEmpty ? 0.0 : Double(completedRhythms.count) / Double(scheduledRhythms.count)

        return VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Rectangle()
                .fill(ThemeColors.borderSubtle(colorScheme))
                .frame(height: ThemeBorder.thin)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(ThemeTypography.titleSmall)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                    if !scheduledRhythms.isEmpty {
                        // Pill showing completion rate
                        Text("\(completedRhythms.count)/\(scheduledRhythms.count) completed")
                            .font(ThemeTypography.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(rate == 1.0 ? ThemeColors.accentGold : ThemeColors.textSecondary(colorScheme))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                (rate == 1.0 ? ThemeColors.accentGold : ThemeColors.textSecondary(colorScheme))
                                    .opacity(0.12)
                            )
                            .clipShape(Capsule())
                    }
                }

                Spacer()

                if rate == 1.0 {
                    Image(systemName: "star.fill")
                        .foregroundStyle(ThemeColors.accentGold)
                        .font(.title3)
                }
            }

            if scheduledRhythms.isEmpty {
                Text("No rhythms scheduled")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
                    .padding(.vertical, ThemeSpacing.xs)
            } else {
                ForEach(scheduledRhythms) { rhythm in
                    HStack(spacing: ThemeSpacing.sm) {
                        let completed = rhythm.isCompleted(on: date)
                        Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(completed ? ThemeColors.accentGold : ThemeColors.textMuted(colorScheme))
                            .font(.system(size: 16))

                        Text(rhythm.emoji)
                            .font(.system(size: 14))

                        Text(rhythm.title)
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(
                                completed
                                ? ThemeColors.textPrimary(colorScheme)
                                : ThemeColors.textSecondary(colorScheme)
                            )
                            .strikethrough(completed, color: ThemeColors.textMuted(colorScheme).opacity(0.5))

                        Spacer()

                        if let entry = rhythm.entry(for: date), let mood = entry.mood {
                            Text(mood.emoji)
                                .font(.system(size: 14))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func daysInMonth() -> [Date?] {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!

        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let adjustedFirstWeekday = ((firstWeekday - calendar.firstWeekday) + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: adjustedFirstWeekday)

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

    /// Smooth perceptual heat gradient: grey → warm amber → rich gold
    private func heatColor(for rate: Double) -> Color {
        switch rate {
        case 0:
            return ThemeColors.bgSecondary(colorScheme)
        case 0..<0.2:
            return ThemeColors.accentGold.opacity(0.15)
        case 0.2..<0.4:
            return ThemeColors.accentGold.opacity(0.30)
        case 0.4..<0.6:
            return ThemeColors.accentGold.opacity(0.50)
        case 0.6..<0.8:
            return ThemeColors.accentGold.opacity(0.70)
        case 0.8..<1.0:
            return ThemeColors.accentGold.opacity(0.85)
        default:
            // 100% — full gold with slight glow treatment
            return ThemeColors.accentGold
        }
    }

    /// Readable text color against the heat background
    private func labelColor(for rate: Double, isFuture: Bool, isToday: Bool) -> Color {
        if isFuture {
            return ThemeColors.textMuted(colorScheme).opacity(0.3)
        }
        // At high completion rates the background is gold — use dark text for contrast
        if rate >= 0.8 {
            return Color.black.opacity(0.75)
        }
        return ThemeColors.textPrimary(colorScheme)
    }

    /// VoiceOver label for each day cell
    private func accessibilityLabel(for date: Date, rate: Double, isFuture: Bool, scheduledCount: Int) -> String {
        let dayString = date.formatted(date: .abbreviated, time: .omitted)
        if isFuture { return "\(dayString), future date" }
        if scheduledCount == 0 { return "\(dayString), no rhythms scheduled" }
        let pct = Int(rate * 100)
        return "\(dayString), \(pct)% complete"
    }
}

#Preview {
    ScrollView {
        CalendarHeatMapView()
            .padding()
    }
    .modelContainer(for: [Rhythm.self, RhythmEntry.self, RhythmNote.self, Category.self])
}
