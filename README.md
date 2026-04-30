# Rhythms

> *Native iOS habit tracking with flexible scheduling and home screen widgets*

[![Platform](https://img.shields.io/badge/platform-iOS%2018.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green.svg)](https://developer.apple.com/xcode/swiftui/)

Rhythms is a beautifully designed habit-tracking app for iPhone and iPad, built entirely with native Apple frameworks. Track recurring activities with 8 flexible schedule types, visualize your progress with home screen widgets, and build lasting habits with streak tracking and AI-powered insights.

## ✨ Features

### Flexible Scheduling (8 Types)
- **Daily** — Every single day
- **Weekdays** — Monday through Friday
- **Weekends** — Saturday and Sunday
- **Specific Days** — Select custom days of the week (e.g., Mon/Wed/Fri)
- **Interval** — Every N days (e.g., every 3 days)
- **Flexible Weekly** — N times per week (e.g., 3x per week, any days)
- **Flexible Monthly** — N times per month (e.g., 4x per month, any days)
- **Day of Month** — Specific date each month (e.g., 15th of every month)

### Today View
- **Progress Ring** — Visual completion indicator for today's rhythms
- **Quick Check-in** — Tap to complete rhythms with optional mood and notes
- **Date Navigation** — Swipe to view past/future days
- **Haptic Feedback** — Tactile response for milestone celebrations
- **Empty States** — Helpful UI when no rhythms are due today

### Rhythms Management
- **Create Rhythms** — Title, emoji, color, description, schedule
- **Category Organization** — Group rhythms by category
- **Archive/Pause** — Temporarily disable rhythms without deleting
- **Pause Until Date** — Resume rhythms on a specific date
- **Tags** — Add custom tags for filtering
- **Reminder Notifications** — Schedule push notifications for rhythms

### Streak Tracking
- **Current Streak** — Days in a row of completion
- **Best Streak** — All-time longest streak
- **Milestone Celebrations** — Haptic feedback at 7, 14, 21, 30, 50, 100, 365 days
- **Streak Recovery** — 1-year safety limit for calculation
- **Smart Counting** — Skips unscheduled days automatically

### Statistics & Insights
- **Calendar Heat Map** — Visual history of completions
- **Completion Rate** — Percentage of scheduled days completed
- **Weekly Analytics** — Auto-generated insights with highlights and suggestions
- **AI-Powered Insights** — Personalized recommendations based on your data
- **Trend Analysis** — Track progress over time

### Home Screen Widgets
- **Small Widget** — Today's progress ring (also accessory circular/rectangular)
- **Medium Widget** — Today's rhythm list with completion status
- **Large Widget** — Detailed progress and rhythm breakdown
- **Live Activities** — Real-time updates (future feature)

### Siri Shortcuts
- **"Complete [rhythm] in Rhythms"** — Mark a rhythm as complete
- **"How am I doing with Rhythms"** — Get today's progress summary
- **"What's next in Rhythms"** — Find the next incomplete rhythm
- **Shortcuts App Integration** — Create custom automation workflows

### Mood Tracking
- **Check-in Mood** — Record how you felt during each completion
- **Color-coded Moods** — Visual indicators (red = tough, yellow = okay, green = great)
- **Mood History** — See emotional patterns over time
- **Optional Notes** — Add context to each check-in

## 🏗️ Architecture

### SwiftData Persistence
- **@Model** — Modern Swift data persistence
- **Relationships** — Rhythms → Entries → Notes
- **App Groups** — Shared container for app + widgets
- **Real-time Sync** — Automatic UI updates on data changes

### Service Layer
```
┌──────────────────────────────────────┐
│ Views (SwiftUI)                      │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ AppEnvironment (Service Locator)     │
└────────────┬─────────────────────────┘
             │
             ▼
┌──────────────────────────────────────┐
│ Services                             │
│ • HapticService                      │
│ • NotificationService (actor-based)  │
│ • InsightsService (AI analytics)     │
│ • WidgetReloadService                │
│ • NoteParsingService                 │
└──────────────────────────────────────┘
```

### File Structure
```
Rhythms/
├── RhythmsApp.swift          # App entry point
│
├── App/
│   ├── AppEnvironment.swift   # Service locator
│   └── SharedModelContainer.swift # SwiftData for widgets
│
├── Models/ (5 files)
│   ├── Rhythm.swift           # @Model - Main habit entity
│   ├── RhythmEntry.swift      # @Model - Completion records
│   ├── RhythmNote.swift       # @Model - Attached notes
│   ├── RhythmSchedule.swift   # Enum - 8 schedule types
│   └── Category.swift         # @Model - Organizational groups
│
├── Views/
│   ├── Today/                 # Daily progress view
│   ├── Rhythms/               # List and editor
│   ├── Insights/              # Analytics + calendar
│   ├── Statistics/            # Trend graphs
│   ├── Notes/                 # Note creation and management
│   ├── Components/            # Shared UI components
│   ├── Settings/              # App configuration
│   └── Onboarding/            # First-launch tutorial
│
├── Services/ (5 files)
│   ├── HapticService.swift
│   ├── NotificationService.swift
│   ├── InsightsService.swift
│   ├── WidgetReloadService.swift
│   └── NoteParsingService.swift
│
├── Theme/ (6 files)
│   ├── RhythmsTheme.swift
│   ├── ThemeColors.swift
│   ├── ThemeTypography.swift
│   ├── ThemeSpacing.swift
│   ├── ThemeModifiers.swift
│   └── ThemeComponents.swift
│
└── Extensions/
    └── Date+Extensions.swift

RhythmsWidgets/               # Widget extension
├── RhythmsProgressWidget.swift  # Small widget
├── RhythmsTodayWidget.swift     # Medium widget
├── RhythmsDetailWidget.swift    # Large widget
└── WidgetDataProvider.swift     # Shared data access

AppIntents/                   # Siri Shortcuts
├── CompleteRhythmIntent.swift
├── GetTodayStatusIntent.swift
├── GetNextRhythmIntent.swift
├── RhythmAppEntity.swift
└── RhythmShortcuts.swift

prototypes/                   # 4 design theme prototypes
├── geometric-modern.html
├── organic-flowing.html
├── playful-toy.html
└── refined-minimal.html

RhythmsTests/                 # Unit tests
RhythmsUITests/               # UI automation tests
```

## 🎨 Design Themes (Prototypes)

Located in `prototypes/`, 4 unique visual themes have been designed:

1. **Geometric Modern** — Clean lines, bold shapes, modern aesthetic
2. **Organic Flowing** — Soft curves, natural colors, peaceful vibe
3. **Playful Toy** — Fun, energetic, youthful design
4. **Refined Minimal** — Elegant, sophisticated, minimalist

**Status:** Theme selection pending. Current implementation uses a flexible theming system that can adopt any of these styles.

## 🛠️ Tech Stack

**Core:**
- SwiftUI (100% native, no UIKit)
- SwiftData (local persistence)
- WidgetKit (home screen widgets)
- App Intents (Siri shortcuts)
- Swift 5.0+
- iOS 18.5+ deployment target

**Features:**
- @Observable (modern state management)
- Swift Charts (trend visualization)
- LocalNotifications (reminders)
- UserNotifications (push notifications)
- App Groups (widget data sharing)
- Haptic Engine (tactile feedback)

**Testing:**
- Apple Testing framework (async/await support)
- SwiftData in-memory testing
- Mock date utilities for schedule testing

**Dependencies:**
- **None** — All native Apple frameworks

## 🚀 Getting Started

### Prerequisites
- Xcode 16.0+
- macOS Sequoia or later
- iPhone or iPad running iOS 18.5+

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/cam-frederick/Rhythms.git
   cd Rhythms
   ```

2. **Open in Xcode**
   ```bash
   open Rhythms.xcodeproj
   ```

3. **Configure App Groups** (required for widgets)
   - Select the Rhythms target
   - Go to "Signing & Capabilities"
   - Add "App Groups" capability
   - Create group: `group.com.camfrederick.Rhythms`
   - Repeat for RhythmsWidgets target

4. **Run the app**
   - Select an iOS simulator or device
   - Press `Cmd+R` to build and run

### Widget Extension Setup

If widgets aren't working:
1. File → New → Target → Widget Extension
2. Name it "RhythmsWidgets"
3. Add App Group capability (same group as main app)
4. Add shared files to widget target:
   - `SharedModelContainer.swift`
   - All model files (`Rhythm.swift`, etc.)
   - Widget files from `RhythmsWidgets/`

### Testing

```bash
# Run all tests in Xcode: Cmd+U
# Or via command line:
xcodebuild test -project Rhythms.xcodeproj -scheme Rhythms
```

**Test Coverage:**
- Model tests (Rhythm, RhythmEntry, schedules)
- InsightsService tests (analytics generation)
- Streak milestone tests
- Mood color tests
- Completion rate calculations

## 🎯 How It Works

### Creating a Rhythm

1. **Tap "+"** in Rhythms tab
2. **Enter Details** — Title, emoji, color, description
3. **Choose Schedule** — Select from 8 schedule types
4. **Set Reminder** (optional) — Pick a notification time
5. **Add to Category** (optional) — Organize by type
6. **Save** — Rhythm appears in Today view on scheduled days

### Completing a Rhythm

**From Today View:**
1. Tap the rhythm card
2. Quick check-in sheet appears
3. Select mood (optional)
4. Add note (optional)
5. Tap "Complete" — Progress ring updates, haptic feedback

**From Siri:**
- "Hey Siri, complete workout in Rhythms"

**From Widget:**
- Tap rhythm in widget → opens to Today view

### Streak Calculation

```swift
// Smart streak counting:
1. Start from today, count backwards
2. Skip days the rhythm wasn't scheduled
3. Stop at first missed scheduled day
4. Safety limit: 1 year maximum

Example: Weekday rhythm (Mon-Fri)
✅ Friday (today)
✅ Thursday
✅ Wednesday
[Weekend - skipped]
✅ Last Friday
❌ Last Thursday → Streak stops (4 days)
```

### Milestone Celebrations

Haptic feedback triggers at:
- **7 days** — One week!
- **14 days** — Two weeks!
- **21 days** — Three weeks! (habit formation)
- **30 days** — One month!
- **50 days** — Incredible consistency!
- **100 days** — Triple digits!
- **365 days** — ONE YEAR! 🎉

## 📊 Status

**Version:** 1.0 (in development)  
**Status:** 🔵 **Deprioritized** — Solid foundation, theme selection pending

### Implementation Status
- ✅ **Models** — 5 SwiftData models, 8 schedule types
- ✅ **Today View** — Progress ring, date navigation, quick check-in
- ✅ **Rhythms Management** — List, editor, categories, tags
- ✅ **Streak Tracking** — Current/best streak, milestone celebrations
- ✅ **Widgets** — 3 widget sizes with App Groups integration
- ✅ **Siri Shortcuts** — 3 intents with App Entity
- ✅ **Haptic Feedback** — Contextual vibrations
- ✅ **Theme System** — Flexible, supports 4 prototype designs
- ⚠️ **Theme Selection** — Needs final design decision
- ⚠️ **UI/UX Polish** — 90% complete, final pass needed

### What's Ready
- **Architecture** — Clean, testable, extensible
- **Data Layer** — SwiftData with relationships
- **Service Layer** — Singletons for haptics, notifications, insights
- **Widget Support** — Full integration with App Groups
- **Siri Integration** — 3 working App Intents
- **Testing** — Comprehensive unit tests

### What's Needed
1. **Theme Selection** — Choose from 4 prototypes
2. **UI/UX Polish** — Final design pass
3. **App Icon** — Professional icon design
4. **Screenshots** — App Store assets

## 🎨 Theme Prototypes Preview

Open any prototype HTML file in a browser to preview:
```bash
open prototypes/geometric-modern.html
open prototypes/organic-flowing.html
open prototypes/playful-toy.html
open prototypes/refined-minimal.html
```

## 🚢 Future Enhancements

- [ ] Analytics dashboard for admin
- [ ] iCloud sync for cross-device
- [ ] Apple Watch companion app
- [ ] Live Activities for active sessions
- [ ] Shared rhythms (family/team habits)
- [ ] Import/export data
- [ ] Custom color themes
- [ ] Advanced filtering and search

## 🤝 Contributing

This is a private repository. For access or questions, contact the repository owner.

## 📝 License

Private — All rights reserved.

---

**Built for humans who want to build better habits, one rhythm at a time.**
