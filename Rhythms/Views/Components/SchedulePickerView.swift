//
//  SchedulePickerView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct SchedulePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var schedule: RhythmSchedule

    @State private var selectedType: ScheduleType = .daily
    @State private var selectedDays: Set<Weekday> = []
    @State private var intervalDays: Int = 2
    @State private var timesPerWeek: Int = 3
    @State private var timesPerMonth: Int = 4
    @State private var dayOfMonth: Int = 1

    enum ScheduleType: String, CaseIterable, Identifiable {
        case daily = "Every day"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case specificDays = "Specific days"
        case interval = "Every X days"
        case timesPerWeek = "X times per week"
        case timesPerMonth = "X times per month"
        case dayOfMonth = "Day of month"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .daily: return "sun.max.fill"
            case .weekdays: return "briefcase.fill"
            case .weekends: return "moon.stars.fill"
            case .specificDays: return "calendar"
            case .interval: return "repeat"
            case .timesPerWeek: return "7.circle"
            case .timesPerMonth: return "calendar.badge.clock"
            case .dayOfMonth: return "1.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                typeSelectionSection
                configurationSection
                previewSection
            }
            .scrollContentBackground(.hidden)
            .background(ThemeColors.bgPrimary(colorScheme))
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(ThemeColors.accentGold)
                }
            }
            .onAppear {
                loadCurrentSchedule()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var typeSelectionSection: some View {
        Section("Schedule Type") {
            ForEach(ScheduleType.allCases) { type in
                ScheduleTypeRow(
                    type: type,
                    isSelected: selectedType == type,
                    colorScheme: colorScheme,
                    onTap: {
                        selectedType = type
                        updateScheduleForType(type)
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var configurationSection: some View {
        if selectedType == .specificDays {
            Section("Select Days") {
                WeekdaySelector(selectedDays: $selectedDays)
            }
            .onChange(of: selectedDays) { _, newValue in
                if !newValue.isEmpty {
                    schedule = .specificDays(newValue)
                }
            }
        }

        if selectedType == .interval {
            Section("Interval") {
                Stepper("Every \(intervalDays) days", value: $intervalDays, in: 2...30)
            }
            .onChange(of: intervalDays) { _, newValue in
                schedule = .interval(days: newValue)
            }
        }

        if selectedType == .timesPerWeek {
            Section("Frequency") {
                Stepper("\(timesPerWeek) times per week", value: $timesPerWeek, in: 1...7)
                Text("Complete on any \(timesPerWeek) days of your choice each week")
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
            .onChange(of: timesPerWeek) { _, newValue in
                schedule = .timesPerWeek(count: newValue)
            }
        }

        if selectedType == .timesPerMonth {
            Section("Frequency") {
                Stepper("\(timesPerMonth) times per month", value: $timesPerMonth, in: 1...31)
                Text("Complete on any \(timesPerMonth) days of your choice each month")
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
            .onChange(of: timesPerMonth) { _, newValue in
                schedule = .timesPerMonth(count: newValue)
            }
        }

        if selectedType == .dayOfMonth {
            Section("Day of Month") {
                Picker("Day", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text(dayLabel(for: day)).tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)

                Text("Great for monthly bills, rent, or subscriptions")
                    .font(ThemeTypography.caption)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
            .onChange(of: dayOfMonth) { _, newValue in
                schedule = .dayOfMonth(day: newValue)
            }
        }
    }

    private func dayLabel(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    private var previewSection: some View {
        Section("Preview") {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(ThemeColors.textMuted(colorScheme))
                Text(schedule.displayName)
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
        }
    }

    private func loadCurrentSchedule() {
        switch schedule {
        case .daily:
            selectedType = .daily
        case .weekdays:
            selectedType = .weekdays
        case .weekends:
            selectedType = .weekends
        case .specificDays(let days):
            selectedType = .specificDays
            selectedDays = days
        case .interval(let days):
            selectedType = .interval
            intervalDays = days
        case .timesPerWeek(let count):
            selectedType = .timesPerWeek
            timesPerWeek = count
        case .timesPerMonth(let count):
            selectedType = .timesPerMonth
            timesPerMonth = count
        case .dayOfMonth(let day):
            selectedType = .dayOfMonth
            dayOfMonth = day
        }
    }

    private func updateScheduleForType(_ type: ScheduleType) {
        switch type {
        case .daily:
            schedule = .daily
        case .weekdays:
            schedule = .weekdays
        case .weekends:
            schedule = .weekends
        case .specificDays:
            if selectedDays.isEmpty {
                selectedDays = [.monday, .wednesday, .friday]
            }
            schedule = .specificDays(selectedDays)
        case .interval:
            schedule = .interval(days: intervalDays)
        case .timesPerWeek:
            schedule = .timesPerWeek(count: timesPerWeek)
        case .timesPerMonth:
            schedule = .timesPerMonth(count: timesPerMonth)
        case .dayOfMonth:
            schedule = .dayOfMonth(day: dayOfMonth)
        }
    }
}

// MARK: - Schedule Type Row

struct ScheduleTypeRow: View {
    let type: SchedulePickerView.ScheduleType
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .frame(width: 24)

                Text(type.rawValue)
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(ThemeColors.accentGold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Weekday Selector

struct WeekdaySelector: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            ForEach(Weekday.allCases) { day in
                WeekdayButton(day: day, isSelected: selectedDays.contains(day), colorScheme: colorScheme) {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }
            }
        }
        .padding(.vertical, ThemeSpacing.sm)
    }
}

struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(day.singleLetter)
                .font(ThemeTypography.labelLarge)
                .frame(width: 36, height: 36)
                .foregroundStyle(isSelected ? (colorScheme == .dark ? .black : .white) : ThemeColors.textPrimary(colorScheme))
                .background(isSelected ? ThemeColors.accentGold : ThemeColors.bgSecondary(colorScheme))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SchedulePickerView(schedule: .constant(.daily))
}
