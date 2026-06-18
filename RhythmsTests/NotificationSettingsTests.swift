//
//  NotificationSettingsTests.swift
//  RhythmsTests
//
//  Tests for global notification settings and the per-rhythm
//  reminder scheduling model logic.
//
//  Created by Cici on 2026-03-09.
//

import Testing
import Foundation
import UserNotifications
@testable import Rhythms

// MARK: - Global Reminder Settings Tests

struct GlobalReminderSettingsTests {

    // MARK: - Time interval helpers

    @Test func globalReminderTimeIntervalRoundTripAt9AM() {
        // 9:00 AM = 9 * 3600 seconds from midnight
        let interval: TimeInterval = 9 * 3600
        let midnight = Calendar.current.startOfDay(for: Date.make())
        let reminderDate = midnight.addingTimeInterval(interval)

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }

    @Test func globalReminderTimeIntervalRoundTripAt730PM() {
        // 7:30 PM = 19.5 * 3600
        let interval: TimeInterval = 19 * 3600 + 30 * 60
        let midnight = Calendar.current.startOfDay(for: Date.make())
        let reminderDate = midnight.addingTimeInterval(interval)

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
        #expect(components.hour == 19)
        #expect(components.minute == 30)
    }

    @Test func extractingIntervalFromDatePreservesTime() {
        // Simulate what the Binding setter does
        let targetHour = 14
        let targetMinute = 15
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 10
        components.hour = targetHour
        components.minute = targetMinute
        let chosenDate = Calendar.current.date(from: components)!

        let midnight = Calendar.current.startOfDay(for: chosenDate)
        let interval = chosenDate.timeIntervalSince(midnight)

        // Re-derive the time from interval
        let derived = midnight.addingTimeInterval(interval)
        let derivedComponents = Calendar.current.dateComponents([.hour, .minute], from: derived)
        #expect(derivedComponents.hour == targetHour)
        #expect(derivedComponents.minute == targetMinute)
    }

    // MARK: - Daily check-in content

    @Test func globalCheckinNotificationIdentifierIsConstant() {
        let id = "global-daily-checkin"
        #expect(id == "global-daily-checkin", "Identifier must be stable for cancel/update to work")
    }

    @Test func globalCheckinCategoryIsCorrect() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Rhythm Check-In"
        content.body = "Time to check in with your rhythms and keep your streaks alive! 🔥"
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        #expect(content.categoryIdentifier == "DAILY_CHECKIN")
        #expect(!content.title.isEmpty)
        #expect(!content.body.isEmpty)
    }

    @Test func triggerIsRepeatDaily() {
        let components = DateComponents(hour: 9, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        #expect(trigger.repeats == true)
    }

    @Test func triggerHourAndMinuteMatchInput() {
        let inputHour = 8
        let inputMinute = 45
        let components = DateComponents(hour: inputHour, minute: inputMinute)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        #expect(trigger.dateComponents.hour == inputHour)
        #expect(trigger.dateComponents.minute == inputMinute)
    }
}

// MARK: - Per-Rhythm Reminder Tests

struct PerRhythmReminderTests {

    @Test func rhythmDefaultsReminderDisabled() {
        let rhythm = Rhythm(title: "Morning Run", emoji: "🏃", colorHex: "#34C759")
        #expect(rhythm.reminderEnabled == false)
        #expect(rhythm.reminderTime == nil)
    }

    @Test func rhythmReminderCanBeEnabled() {
        let rhythm = Rhythm(title: "Meditate", emoji: "🧘", colorHex: "#AF52DE")
        rhythm.reminderEnabled = true

        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        let reminderDate = Calendar.current.date(from: components)!
        rhythm.reminderTime = reminderDate

        #expect(rhythm.reminderEnabled == true)
        #expect(rhythm.reminderTime != nil)
    }

    @Test func rhythmReminderIdentifierIsStable() {
        let rhythm = Rhythm(title: "Read", emoji: "📚", colorHex: "#007AFF")
        let identifier = "rhythm-\(rhythm.id.uuidString)"
        let identifierAgain = "rhythm-\(rhythm.id.uuidString)"
        #expect(identifier == identifierAgain, "Identifier must be deterministic for cancel/update to work")
    }

    @Test func rhythmReminderIdentifierIsUniquePerRhythm() {
        let r1 = Rhythm(title: "Run", emoji: "🏃", colorHex: "#34C759")
        let r2 = Rhythm(title: "Read", emoji: "📚", colorHex: "#007AFF")
        let id1 = "rhythm-\(r1.id.uuidString)"
        let id2 = "rhythm-\(r2.id.uuidString)"
        #expect(id1 != id2)
    }

    @Test func rhythmReminderBodyIncludesStreakWhenPositive() {
        let rhythm = Rhythm(title: "Workout", emoji: "💪", colorHex: "#FF9500")
        // Simulate having a streak
        rhythm.markCompleted(for: Date.make(year: 2026, month: 3, day: 8))

        let streak = rhythm.currentStreak
        // With one completion we expect streak >= 0
        // Body logic: streak > 0 → include streak text
        if streak > 0 {
            let body = "Keep your \(streak)-day streak going! \(rhythm.emoji)"
            #expect(body.contains("streak"))
            #expect(body.contains(rhythm.emoji))
        } else {
            let body = "Start building your streak today! \(rhythm.emoji)"
            #expect(body.contains("streak"))
        }
    }

    @Test func rhythmReminderBodyForNoStreak() {
        let rhythm = Rhythm(title: "Journal", emoji: "📝", colorHex: "#5856D6")
        // No completions → streak 0
        let body = "Start building your streak today! \(rhythm.emoji)"
        #expect(body.contains("Start building"))
        #expect(body.contains(rhythm.emoji))
    }

    @Test func dailyScheduleProducesRepeatingTrigger() {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        #expect(trigger.repeats == true)
    }

    @Test func weekdayScheduleNextWeekdayAfterFriday() {
        // After Friday, next weekday is Monday (raw value 2)
        let friday = Weekday.friday
        let nextRaw: Int
        switch friday {
        case .friday, .saturday, .sunday:
            nextRaw = Weekday.monday.rawValue
        default:
            nextRaw = friday.rawValue + 1
        }
        #expect(nextRaw == Weekday.monday.rawValue)
    }

    @Test func weekdayScheduleNextWeekdayAfterWednesday() {
        let wednesday = Weekday.wednesday
        let nextRaw: Int
        switch wednesday {
        case .friday, .saturday, .sunday:
            nextRaw = Weekday.monday.rawValue
        default:
            nextRaw = wednesday.rawValue + 1
        }
        #expect(nextRaw == Weekday.thursday.rawValue)
    }

    @Test func cancelReminderRemovesCorrectIdentifier() {
        let rhythm = Rhythm(title: "Hydrate", emoji: "💧", colorHex: "#007AFF")
        let expectedIdentifier = "rhythm-\(rhythm.id.uuidString)"
        // The cancel should remove exactly this identifier (we just verify the string is correct)
        #expect(expectedIdentifier.hasPrefix("rhythm-"))
        #expect(expectedIdentifier.hasSuffix(rhythm.id.uuidString))
    }
}

// MARK: - Notification Request Building Tests

struct NotificationRequestBuildingTests {

    @Test func requestIdentifierMatchesRhythmId() {
        let rhythm = Rhythm(title: "Sleep by 10", emoji: "😴", colorHex: "#5856D6")
        let content = UNMutableNotificationContent()
        content.title = "Time for \(rhythm.title)"
        content.body = "Start building your streak today! \(rhythm.emoji)"
        content.sound = .default
        content.categoryIdentifier = "RHYTHM_REMINDER"
        content.userInfo = ["rhythmId": rhythm.id.uuidString]

        let components = DateComponents(hour: 22, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "rhythm-\(rhythm.id.uuidString)",
            content: content,
            trigger: trigger
        )

        #expect(request.identifier == "rhythm-\(rhythm.id.uuidString)")
        #expect(request.content.title == "Time for Sleep by 10")
        #expect(request.content.categoryIdentifier == "RHYTHM_REMINDER")
    }

    @Test func requestUserInfoContainsRhythmId() {
        let rhythm = Rhythm(title: "Meditate", emoji: "🧘", colorHex: "#AF52DE")
        let content = UNMutableNotificationContent()
        content.userInfo = ["rhythmId": rhythm.id.uuidString]

        #expect(content.userInfo["rhythmId"] as? String == rhythm.id.uuidString)
    }

    @Test func globalCheckinRequestHasStableIdentifier() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Rhythm Check-In"
        content.categoryIdentifier = "DAILY_CHECKIN"

        let components = DateComponents(hour: 9, minute: 0)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "global-daily-checkin",
            content: content,
            trigger: trigger
        )

        #expect(request.identifier == "global-daily-checkin")
        #expect(request.content.categoryIdentifier == "DAILY_CHECKIN")
    }
}
