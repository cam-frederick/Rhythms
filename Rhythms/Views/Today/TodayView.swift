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

                        // All done state — all rhythms completed
                        if !todaysRhythms.isEmpty && incompleteRhythms.isEmpty {
                            AllDoneView()
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Empty state — no rhythms at all
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

    @State private var appeared = false

    private var isPastDate: Bool {
        selectedDate.isPast
    }

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            Image(systemName: isPastDate ? "calendar" : "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(isPastDate ? ThemeColors.textMuted(colorScheme) : ThemeColors.accentGold.opacity(0.75))
                .scaleEffect(appeared ? 1 : 0.7)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.65), value: appeared)

            VStack(spacing: ThemeSpacing.sm) {
                Text(isPastDate ? "Rest day" : "Nothing scheduled")
                    .font(ThemeTypography.titleMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: appeared)

                Text(isPastDate
                     ? "No rhythms were scheduled for this day."
                     : "Add a rhythm to start building better daily habits.")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.18), value: appeared)
            }

            if !isPastDate {
                GoldButton("Add Rhythm", icon: "plus.circle.fill", action: onAddTap)
                    .padding(.top, ThemeSpacing.xs)
                    .frame(maxWidth: 200)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(response: 0.45, dampingFraction: 0.75).delay(0.25), value: appeared)
            }
        }
        .padding(ThemeSpacing.xl)
        .onAppear { appeared = true }
        .onChange(of: selectedDate) { _, _ in
            appeared = false
            withAnimation { appeared = true }
        }
    }
}

// MARK: - All Done View

struct AllDoneView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var appeared = false

    var body: some View {
        VStack(spacing: ThemeSpacing.lg) {
            // Trophy
            ZStack {
                Circle()
                    .fill(ThemeColors.accentGold.opacity(0.12))
                    .frame(width: 90, height: 90)

                Text("🏆")
                    .font(.system(size: 48))
            }
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: appeared)

            VStack(spacing: ThemeSpacing.sm) {
                Text("You're all done!")
                    .font(ThemeTypography.titleMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.12), value: appeared)

                Text("Every rhythm completed.\nYou showed up today — that's what matters. 🔥")
                    .font(ThemeTypography.bodyMedium)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.2), value: appeared)
            }
        }
        .padding(ThemeSpacing.xl)
        .onAppear { appeared = true }
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
