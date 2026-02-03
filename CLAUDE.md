# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Rhythms is a native iOS habit-tracking app built with SwiftUI and SwiftData. It allows users to track recurring activities with flexible scheduling, streak management, mood tracking, AI-powered insights, home screen widgets, and Siri shortcuts.

- **Language**: Swift 5.0
- **Framework**: SwiftUI + SwiftData
- **iOS Deployment Target**: 18.5
- **Dependencies**: None (all native Apple frameworks)

## Build & Run (XcodeBuildMCP)

This project uses **XcodeBuildMCP** for all building, running, and testing. Use the MCP tools instead of raw `xcodebuild` commands.

### Common Operations

**Build for Simulator:**
```
Use: mcp__XcodeBuildMCP__xcodebuild_build
- scheme: "Rhythms"
- destination: iOS Simulator (iPhone 17, iOS 26.2)
```

**Build and Run on Device:**
```
Use: mcp__XcodeBuildMCP__xcodebuild_build_and_run
- scheme: "Rhythms"
- destination: Physical device
```

**Run Tests:**
```
Use: mcp__XcodeBuildMCP__xcodebuild_test
- scheme: "Rhythms"
- destination: iOS Simulator
```

**List Available Simulators/Devices:**
```
Use: mcp__XcodeBuildMCP__list_simulators
Use: mcp__XcodeBuildMCP__list_devices
```

**Discover Project Info:**
```
Use: mcp__XcodeBuildMCP__discover_projects
Use: mcp__XcodeBuildMCP__get_project_info
```

### Why XcodeBuildMCP?

- **Better Integration**: Native MCP tools provide structured output and better error handling
- **Incremental Builds**: Supports faster incremental builds
- **Device Management**: Simplified device/simulator selection and management
- **Session Persistence**: Maintains build session state across tool calls

## Architecture

### Models (SwiftData)

All data models use SwiftData for persistence:

- **Rhythm** (`Models/Rhythm.swift`) - Core habit entity with embedded schedule, relationships to entries/notes
- **RhythmEntry** (`Models/RhythmEntry.swift`) - Individual completion records with optional mood/note
- **RhythmNote** (`Models/RhythmNote.swift`) - Recurring or date-specific notes attached to rhythms
- **Category** (`Models/Category.swift`) - Organizational grouping with color support
- **RhythmSchedule** (`Models/RhythmSchedule.swift`) - Enum with 8 schedule types (daily, weekdays, weekends, specific days, interval, flexible weekly/monthly, day of month)

**Important**: `RhythmSchedule` is stored as JSON in SwiftData because SwiftData cannot handle enums with associated values directly. The `Rhythm` model has a `scheduleData` property for storage and a computed `schedule` property for access.

### Services

- **AppEnvironment** (`App/AppEnvironment.swift`) - Service locator providing singleton access to services
- **SharedModelContainer** (`App/SharedModelContainer.swift`) - Shared SwiftData container for app and widgets using App Groups
- **HapticService** (`Services/HapticService.swift`) - Haptic feedback management
- **NotificationService** (`Services/NotificationService.swift`) - Local push notification scheduling (actor-based for thread safety)
- **InsightsService** (`Services/InsightsService.swift`) - Weekly analytics generation with stats, highlights, and suggestions
- **WidgetReloadService** (`Services/WidgetReloadService.swift`) - Triggers widget timeline reloads on data changes

### Views Structure

Tab-based navigation with 4 main tabs:
- **Today** (`Views/Today/`) - Daily progress view with completion rings, quick check-in sheet
- **Rhythms** (`Views/Rhythms/`) - List and editor views for managing habits
- **Insights** (`Views/Insights/` + `Views/Statistics/`) - Analytics, calendar heat map, and AI insights
- **Settings** (`Views/Settings/`) - App configuration

### Widgets (Phase 3)

Widget extension files in `RhythmsWidgets/`:
- **RhythmsProgressWidget** - Small widget with today's progress ring (also supports accessory circular/rectangular)
- **RhythmsTodayWidget** - Medium widget showing today's rhythm list
- **RhythmsDetailWidget** - Large widget with detailed progress and rhythm status
- **WidgetDataProvider** - Shared data provider fetching rhythms via App Groups

### App Intents / Siri Shortcuts

App Intents in `AppIntents/`:
- **CompleteRhythmIntent** - Mark a rhythm as complete via Siri ("Complete workout in Rhythms")
- **GetTodayStatusIntent** - Get today's progress ("How am I doing with Rhythms")
- **GetNextRhythmIntent** - Get next incomplete rhythm ("What's next in Rhythms")
- **RhythmAppEntity** - Entity representing rhythms for Siri
- **RhythmShortcuts** - Suggested shortcuts for the Shortcuts app

### Key Algorithms

- **Streak Calculation**: Counts backwards from today, skips unscheduled days, has 1-year safety limit
- **Schedule Matching**: `isScheduledForDate(_:)` method handles all 8 schedule types
- **Completion Rate**: Ratio of completed days to scheduled days for any time window
- **Streak Milestones**: Celebrations at 7, 14, 21, 30, 50, 100, 365 day streaks

## Testing

Uses Apple's native Testing framework with async/await support:

- `RhythmsTests/RhythmsTests.swift` - Comprehensive model tests
- `RhythmsTests/InsightsServiceTests.swift` - Analytics service tests
- `RhythmsTests/Phase2Tests.swift` - Streak milestones, mood colors, completion tests

Test utilities:
- `Date.make(year:month:day:)` - Create specific test dates
- `Date.testWeek` - Array of 7 consecutive dates for testing

## Setup Notes

### Widget Extension Setup (Required in Xcode)

To enable widgets, you need to:
1. Add the Widget Extension target in Xcode (File > New > Target > Widget Extension)
2. Add App Group capability to both main app and widget (use `group.com.camfrederick.Rhythms`)
3. Add the files from `RhythmsWidgets/` to the widget target
4. Ensure `SharedModelContainer.swift` and model files are shared with the widget target

### App Groups

The app uses App Groups (`group.com.camfrederick.Rhythms`) for sharing data between the main app and widgets. The shared SwiftData store is accessed via `SharedModelContainer`.
