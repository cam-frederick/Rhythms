//
//  CalendarHeatMapView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct CalendarHeatMapView: View {
    @Query(filter: #Predicate<Rhythm> { !$0.isArchived }) private var rhythms: [Rhythm]
    @State private var selectedMonth: Date = Date()
    @State private var selectedDate: Date?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: 16) {
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
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
            }

            Spacer()

            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline)
            }
            .disabled(calendar.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
    }

    // MARK: - Weekday Headers

    private var weekdayHeaders: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                Text(day.prefix(1))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
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
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = selectedDate?.isSameDay(as: date) == true ? nil : date
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFuture ? Color.clear : heatColor(for: completionRate))

                Text("\(calendar.component(.day, from: date))")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isFuture ? Color.secondary.opacity(0.3) : Color.primary)
            }
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.accentColor, lineWidth: 2)
                }
                if isSelected {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isFuture)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 6) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)

            ForEach([0.0, 0.1, 0.3, 0.6, 0.8, 1.0], id: \.self) { value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(heatColor(for: value))
                    .frame(width: 14, height: 14)
            }

            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Selected Date Details

    private func selectedDateDetails(for date: Date) -> some View {
        let scheduledRhythms = rhythms.filter { $0.isScheduledFor(date: date) }
        let completedRhythms = scheduledRhythms.filter { $0.isCompleted(on: date) }

        return VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)

                Spacer()

                Text("\(completedRhythms.count)/\(scheduledRhythms.count) completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if scheduledRhythms.isEmpty {
                Text("No rhythms scheduled")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(scheduledRhythms) { rhythm in
                    HStack(spacing: 8) {
                        Image(systemName: rhythm.isCompleted(on: date) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(rhythm.isCompleted(on: date) ? .green : .secondary)

                        Text(rhythm.emoji)

                        Text(rhythm.title)
                            .font(.subheadline)

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
            return Color(.systemGray5)
        case 0..<0.25:
            return Color.red.opacity(0.4)
        case 0.25..<0.5:
            return Color.orange.opacity(0.5)
        case 0.5..<0.75:
            return Color.yellow.opacity(0.6)
        case 0.75..<1.0:
            return Color.mint.opacity(0.6)
        default:
            return Color.green.opacity(0.7)
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
