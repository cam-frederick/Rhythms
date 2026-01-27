//
//  NotificationService.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import UserNotifications
import SwiftUI

/// Service for managing local notifications for rhythm reminders
actor NotificationService {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Permission

    /// Current authorization status
    var authorizationStatus: UNAuthorizationStatus {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus
        }
    }

    /// Whether notifications are authorized
    var isAuthorized: Bool {
        get async {
            let status = await authorizationStatus
            return status == .authorized || status == .provisional
        }
    }

    /// Requests notification permission from the user
    @discardableResult
    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    // MARK: - Rhythm Reminders

    /// Schedules a reminder notification for a rhythm
    func scheduleReminder(for rhythm: Rhythm) async throws {
        guard rhythm.reminderEnabled, let reminderTime = rhythm.reminderTime else { return }

        // Cancel any existing reminder for this rhythm
        cancelReminder(for: rhythm)

        let content = UNMutableNotificationContent()
        content.title = "Time for \(rhythm.title)"
        content.body = createReminderBody(for: rhythm)
        content.sound = .default
        content.categoryIdentifier = "RHYTHM_REMINDER"
        content.userInfo = ["rhythmId": rhythm.id.uuidString]

        // Create trigger based on schedule
        let trigger = createTrigger(for: rhythm, at: reminderTime)

        let request = UNNotificationRequest(
            identifier: "rhythm-\(rhythm.id.uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Cancels the reminder for a rhythm
    func cancelReminder(for rhythm: Rhythm) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["rhythm-\(rhythm.id.uuidString)"]
        )
    }

    /// Cancels all pending notifications
    func cancelAllReminders() {
        center.removeAllPendingNotificationRequests()
    }

    /// Returns all pending notification requests
    func pendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    // MARK: - Private Helpers

    private func createReminderBody(for rhythm: Rhythm) -> String {
        let streak = rhythm.currentStreak
        if streak > 0 {
            return "Keep your \(streak)-day streak going! \(rhythm.emoji)"
        } else {
            return "Start building your streak today! \(rhythm.emoji)"
        }
    }

    private func createTrigger(for rhythm: Rhythm, at reminderTime: Date) -> UNNotificationTrigger {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)

        switch rhythm.schedule {
        case .daily:
            // Every day at the specified time
            return UNCalendarNotificationTrigger(
                dateMatching: timeComponents,
                repeats: true
            )

        case .weekdays:
            // For weekdays, we need to schedule individual triggers
            // This returns a single trigger for tomorrow if it's a weekday
            var components = timeComponents
            components.weekday = nextWeekday(after: Date())
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

        case .weekends:
            var components = timeComponents
            let today = Weekday.from(date: Date())
            components.weekday = (today == .saturday) ? 7 : 1  // Saturday or Sunday
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

        case .specificDays(let days):
            // Schedule for the next matching day
            var components = timeComponents
            let today = Weekday.from(date: Date())
            let sortedDays = days.sorted()
            let nextDay = sortedDays.first { $0.rawValue > today.rawValue } ?? sortedDays.first!
            components.weekday = nextDay.rawValue
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )

        case .interval(let days):
            // Schedule for N days from now
            let nextDate = Date().adding(days: days)
            var components = calendar.dateComponents([.year, .month, .day], from: nextDate)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false  // Need to reschedule after each completion
            )

        case .timesPerWeek, .timesPerMonth:
            // For flexible schedules, just remind daily at the specified time
            return UNCalendarNotificationTrigger(
                dateMatching: timeComponents,
                repeats: true
            )

        case .dayOfMonth(let day):
            // Schedule for specific day of each month
            var components = timeComponents
            components.day = day
            return UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: true
            )
        }
    }

    private func nextWeekday(after date: Date) -> Int {
        let weekday = Weekday.from(date: date)
        switch weekday {
        case .friday: return Weekday.monday.rawValue
        case .saturday: return Weekday.monday.rawValue
        case .sunday: return Weekday.monday.rawValue
        default: return weekday.rawValue + 1
        }
    }
}

// MARK: - Notification Categories

extension NotificationService {
    /// Registers notification categories and actions
    func registerNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_RHYTHM",
            title: "Mark Complete",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_RHYTHM",
            title: "Skip Today",
            options: []
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "RHYTHM_REMINDER",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([reminderCategory])
    }
}
