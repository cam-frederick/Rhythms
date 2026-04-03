//
//  TodayView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.hapticService) private var hapticService
    @Environment(\.colorScheme) private var colorScheme

    @Query(
        filter: #Predicate<Rhythm> { !$0.isArchived && !$0.isPaused },
        sort: \Rhythm.createdAt
    ) private var allRhythms: [Rhythm]

    @State private var selectedDate: Date = Date()
    @State private var showingAddSheet = false
    @State private var rhythmToCheckIn: Rhythm?
    @State private var showingMilestone = false
    @State private var milestoneStreak: Int = 0
    @State private var showingAllDoneCelebration = false
    @State private var lastCelebrationDate: Date?

    // Filtered rhythms for the selected date
    private var todaysRhythms: [Rhythm] {
        allRhythms.filter { $0.isScheduledFor(date: selectedDate) }
    }

    private var incompleteRhythms: [Rhythm] {
        todaysRhythms.filter { !$0.isCompleted(on: selectedDate) }
    }

    private var completedRhythms: [Rhythm] {
        todaysRhythms.filter { $0.isCompleted(on: selectedDate) }
    }

    private var completedCount: Int {
        completedRhythms.count
    }

    private var totalCount: Int {
        todaysRhythms.count
    }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector (outside ScrollView)
                DateSelectorView(selectedDate: $selectedDate)
                    .padding(.top, ThemeSpacing.sm)

                // Progress ring (outside ScrollView)
                DailyProgressRing(
                    progress: progress,
                    completedCount: completedCount,
                    totalCount: totalCount
                )
                .frame(height: 180)
                .padding(.horizontal, ThemeSpacing.md)
                .padding(.vertical, ThemeSpacing.md)

                // Rhythm sections (in ScrollView)
                ScrollView {
                    VStack(spacing: ThemeSpacing.lg) {
                        // Incomplete rhythms
                        if !incompleteRhythms.isEmpty {
                            RhythmSection(
                                title: "To Do",
                                rhythms: incompleteRhythms,
                                selectedDate: selectedDate,
                                onToggle: toggleCompletion
                            )
                        }

                        // Completed rhythms
                        if !completedRhythms.isEmpty {
                            RhythmSection(
                                title: "Completed",
                                rhythms: completedRhythms,
                                selectedDate: selectedDate,
                                onToggle: toggleCompletion,
                                isCompleted: true
                            )
                        }

                        // Empty state
                        if todaysRhythms.isEmpty {
                            EmptyTodayView(
                                selectedDate: selectedDate,
                                onAddTap: { showingAddSheet = true }
                            )
                        }
                    }
                    .padding(.horizontal, ThemeSpacing.md)
                    .padding(.bottom, ThemeSpacing.md)
                }
            }
            .background(ThemeColors.bgPrimary(colorScheme))
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height

                        // Only trigger if horizontal swipe is dominant
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            withAnimation(ThemeAnimation.standardEase) {
                                if horizontalAmount < 0 {
                                    // Swipe left -> next day
                                    selectedDate = selectedDate.adding(days: 1)
                                } else {
                                    // Swipe right -> previous day
                                    selectedDate = selectedDate.adding(days: -1)
                                }
                            }
                            hapticService.playLight()
                        }
                    }
            )
            .navigationTitle(selectedDate.isToday ? "Today" : selectedDate.displayString)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ThemeColors.accentGold)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                RhythmEditorView(mode: .create)
            }
            .sheet(item: $rhythmToCheckIn) { rhythm in
                QuickCheckInSheet(
                    rhythm: rhythm,
                    date: selectedDate
                ) { note, mood in
                    completeRhythm(rhythm, note: note, mood: mood)
                }
            }
            .overlay {
                if showingMilestone {
                    StreakMilestoneOverlay(streak: milestoneStreak, isShowing: $showingMilestone)
                }
                if showingAllDoneCelebration {
                    AllDoneCelebrationOverlay(isShowing: $showingAllDoneCelebration)
                        .transition(.opacity)
                }
            }
        }
    }

    private func toggleCompletion(for rhythm: Rhythm) {
        let wasCompleted = rhythm.isCompleted(on: selectedDate)

        if wasCompleted {
            // Uncompleting - just toggle directly
            rhythm.toggleCompletion(for: selectedDate)
            try? modelContext.save()
            hapticService.playLight()
            WidgetReloadService.rhythmCompletionChanged()
        } else {
            // Completing - show check-in sheet for mood/notes
            rhythmToCheckIn = rhythm
        }
    }

    private func completeRhythm(_ rhythm: Rhythm, note: String?, mood: Mood?) {
        rhythm.markCompleted(for: selectedDate, note: note, mood: mood)
        try? modelContext.save()

        hapticService.playSuccess()
        WidgetReloadService.rhythmCompletionChanged()

        // Check if all rhythms are now done
        let allComplete = totalCount > 0 && completedCount + 1 >= totalCount
        if allComplete {
            let alreadyCelebratedToday = lastCelebrationDate.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
            if !alreadyCelebratedToday {
                lastCelebrationDate = selectedDate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation { showingAllDoneCelebration = true }
                }
            }
        }

        // Check for streak milestones
        let streak = rhythm.currentStreak
        if streak.isStreakMilestone {
            hapticService.playMilestone()
            milestoneStreak = streak
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingMilestone = true
            }
        }
    }
}

// MARK: - Date Selector

struct DateSelectorView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selectedDate: Date
    @State private var showingCalendar = false

    var body: some View {
        HStack(spacing: ThemeSpacing.md) {
            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedDate = selectedDate.adding(days: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            Button {
                showingCalendar = true
            } label: {
                VStack(spacing: ThemeSpacing.xs) {
                    HStack(spacing: ThemeSpacing.sm) {
                        Text(selectedDate.displayString)
                            .font(ThemeTypography.titleMedium)
                            .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                        Image(systemName: "calendar")
                            .font(ThemeTypography.bodyMedium)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }

                    if !selectedDate.isToday {
                        Text(selectedDate, style: .date)
                            .font(ThemeTypography.caption)
                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(minWidth: 120)

            Button {
                withAnimation(ThemeAnimation.standardEase) {
                    selectedDate = selectedDate.adding(days: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }
        }
        .padding(.vertical, ThemeSpacing.sm)
        .sheet(isPresented: $showingCalendar) {
            CalendarPickerView(selectedDate: $selectedDate)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Rhythm Section

struct RhythmSection: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let rhythms: [Rhythm]
    let selectedDate: Date
    let onToggle: (Rhythm) -> Void
    var isCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.sm) {
            Text(title.uppercased())
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(isCompleted ? ThemeColors.textMuted(colorScheme) : ThemeColors.textSecondary(colorScheme))

            VStack(spacing: ThemeSpacing.sm) {
                ForEach(rhythms, id: \.id) { rhythm in
                    TodayRhythmCard(
                        rhythm: rhythm,
                        selectedDate: selectedDate,
                        onToggle: { onToggle(rhythm) }
                    )
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyTodayView: View {
    @Environment(\.colorScheme) private var colorScheme

    let selectedDate: Date
    let onAddTap: () -> Void

    private var isPastDate: Bool {
        selectedDate.isPast
    }

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Image(systemName: isPastDate ? "calendar" : "leaf.fill")
                .font(.system(size: 50))
                .foregroundStyle(isPastDate ? ThemeColors.textMuted(colorScheme) : ThemeColors.accentGold.opacity(0.7))

            Text("No rhythms scheduled")
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text(isPastDate
                 ? "No rhythms were scheduled for this day"
                 : "Add a rhythm to start tracking your daily routines")
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)

            if !isPastDate {
                GoldButton("Add Rhythm", icon: "plus.circle.fill", action: onAddTap)
                    .padding(.top, ThemeSpacing.sm)
                    .frame(maxWidth: 200)
            }
        }
        .padding(ThemeSpacing.xl)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
