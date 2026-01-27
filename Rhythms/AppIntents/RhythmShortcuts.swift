//
//  RhythmShortcuts.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import AppIntents

/// Provides suggested shortcuts for the Shortcuts app
struct RhythmShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodayStatusIntent(),
            phrases: [
                "How am I doing with \(.applicationName)",
                "Show my \(.applicationName) progress",
                "What's my \(.applicationName) status",
                "Check my \(.applicationName)"
            ],
            shortTitle: "Today's Progress",
            systemImageName: "chart.pie.fill"
        )

        AppShortcut(
            intent: GetNextRhythmIntent(),
            phrases: [
                "What's next in \(.applicationName)",
                "What's my next \(.applicationName) task",
                "Show next \(.applicationName)"
            ],
            shortTitle: "What's Next?",
            systemImageName: "arrow.right.circle.fill"
        )

        AppShortcut(
            intent: CompleteRhythmIntent(),
            phrases: [
                "Complete \(\.$rhythm) in \(.applicationName)",
                "Mark \(\.$rhythm) done in \(.applicationName)",
                "I finished \(\.$rhythm) in \(.applicationName)"
            ],
            shortTitle: "Complete Rhythm",
            systemImageName: "checkmark.circle.fill"
        )
    }
}
