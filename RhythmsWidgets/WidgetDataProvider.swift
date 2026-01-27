//
//  WidgetDataProvider.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData
import WidgetKit

/// Provides rhythm data for widgets
@MainActor
final class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private var modelContainer: ModelContainer?
    private var initError: Error?

    private init() {
        do {
            print("[Widget] Initializing WidgetDataProvider...")
            modelContainer = try SharedModelContainer.makeWidgetContainer()
            print("[Widget] Model container created successfully")
        } catch {
            print("[Widget] Failed to create model container: \(error)")
            initError = error
        }
    }

    /// Fetches today's rhythm data for widgets
    func fetchTodayData() -> TodayWidgetData {
        guard let container = modelContainer else {
            print("[Widget] No model container available, error: \(String(describing: initError))")
            return TodayWidgetData.empty
        }

        let context = container.mainContext
        let today = Date()

        do {
            // Fetch all active (non-archived) rhythms
            let descriptor = FetchDescriptor<Rhythm>(
                predicate: #Predicate { !$0.isArchived }
            )
            let allRhythms = try context.fetch(descriptor)
            print("[Widget] Fetched \(allRhythms.count) total rhythms")

            // Filter to today's scheduled rhythms
            let todayRhythms = allRhythms.filter { $0.isScheduledFor(date: today) }
            print("[Widget] \(todayRhythms.count) rhythms scheduled for today")

            // Split into completed and incomplete
            let completedRhythms = todayRhythms.filter { $0.isCompleted(on: today) }

            // Map to widget-friendly data
            let rhythmItems = todayRhythms.map { rhythm in
                RhythmWidgetItem(
                    id: rhythm.id,
                    title: rhythm.title,
                    emoji: rhythm.emoji,
                    colorHex: rhythm.colorHex,
                    isCompleted: rhythm.isCompleted(on: today),
                    streak: rhythm.currentStreak,
                    note: rhythm.noteForDate(today)?.content
                )
            }
            .sorted { !$0.isCompleted && $1.isCompleted }  // Incomplete first

            return TodayWidgetData(
                date: today,
                totalCount: todayRhythms.count,
                completedCount: completedRhythms.count,
                rhythms: rhythmItems,
                nextRhythm: rhythmItems.first { !$0.isCompleted }
            )
        } catch {
            print("[Widget] Failed to fetch rhythms: \(error)")
            return TodayWidgetData.empty
        }
    }
}

// MARK: - Widget Data Models

/// Data structure for today's widget content
struct TodayWidgetData {
    let date: Date
    let totalCount: Int
    let completedCount: Int
    let rhythms: [RhythmWidgetItem]
    let nextRhythm: RhythmWidgetItem?

    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var remainingCount: Int {
        totalCount - completedCount
    }

    var isAllComplete: Bool {
        totalCount > 0 && completedCount == totalCount
    }

    /// Empty state - no rhythms scheduled
    static var empty: TodayWidgetData {
        TodayWidgetData(
            date: Date(),
            totalCount: 0,
            completedCount: 0,
            rhythms: [],
            nextRhythm: nil
        )
    }

    /// Placeholder for widget gallery preview only
    static var placeholder: TodayWidgetData {
        TodayWidgetData(
            date: Date(),
            totalCount: 5,
            completedCount: 3,
            rhythms: [
                RhythmWidgetItem(id: UUID(), title: "Morning Workout", emoji: "💪", colorHex: "#34C759", isCompleted: true, streak: 7, note: nil),
                RhythmWidgetItem(id: UUID(), title: "Read 20 Pages", emoji: "📚", colorHex: "#007AFF", isCompleted: true, streak: 14, note: nil),
                RhythmWidgetItem(id: UUID(), title: "Meditate", emoji: "🧘", colorHex: "#AF52DE", isCompleted: true, streak: 3, note: nil),
                RhythmWidgetItem(id: UUID(), title: "Journal", emoji: "📝", colorHex: "#FF9500", isCompleted: false, streak: 0, note: nil),
                RhythmWidgetItem(id: UUID(), title: "Evening Walk", emoji: "🚶", colorHex: "#5AC8FA", isCompleted: false, streak: 5, note: nil),
            ],
            nextRhythm: RhythmWidgetItem(id: UUID(), title: "Journal", emoji: "📝", colorHex: "#FF9500", isCompleted: false, streak: 0, note: nil)
        )
    }
}

/// Widget-friendly rhythm item
struct RhythmWidgetItem: Identifiable {
    let id: UUID
    let title: String
    let emoji: String
    let colorHex: String
    let isCompleted: Bool
    let streak: Int
    let note: String?
}
