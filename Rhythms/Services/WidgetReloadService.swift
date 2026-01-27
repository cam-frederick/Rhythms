//
//  WidgetReloadService.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import WidgetKit

/// Service to manage widget timeline reloading
enum WidgetReloadService {
    /// Widget bundle identifiers
    private static let progressWidgetKind = "RhythmsProgressWidget"
    private static let todayWidgetKind = "RhythmsTodayWidget"
    private static let detailWidgetKind = "RhythmsDetailWidget"

    /// Reloads all widget timelines
    /// Call this after any data changes that affect today's rhythms
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Reloads only the progress widget
    static func reloadProgressWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: progressWidgetKind)
    }

    /// Reloads only the today list widget
    static func reloadTodayWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: todayWidgetKind)
    }

    /// Reloads only the detail widget
    static func reloadDetailWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: detailWidgetKind)
    }

    /// Call this after completing or uncompleting a rhythm
    static func rhythmCompletionChanged() {
        reloadAllWidgets()
    }

    /// Call this after creating, editing, or deleting a rhythm
    static func rhythmDataChanged() {
        reloadAllWidgets()
    }
}
