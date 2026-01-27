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
                    .padding(.top, 8)

                // Progress ring (outside ScrollView)
                DailyProgressRing(
                    progress: progress,
                    completedCount: completedCount,
                    totalCount: totalCount
                )
                .frame(height: 180)
                .padding(.horizontal)
                .padding(.vertical, 16)

                // Rhythm sections (in ScrollView)
                ScrollView {
                    VStack(spacing: 20) {
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
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height

                        // Only trigger if horizontal swipe is dominant
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            withAnimation(.easeInOut(duration: 0.2)) {
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
    @Binding var selectedDate: Date
    @State private var showingCalendar = false

    var body: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation {
                    selectedDate = selectedDate.adding(days: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            Button {
                showingCalendar = true
            } label: {
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Text(selectedDate.displayString)
                            .font(.headline)

                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if !selectedDate.isToday {
                        Text(selectedDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(minWidth: 120)

            Button {
                withAnimation {
                    selectedDate = selectedDate.adding(days: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingCalendar) {
            CalendarPickerView(selectedDate: $selectedDate)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Rhythm Section

struct RhythmSection: View {
    let title: String
    let rhythms: [Rhythm]
    let selectedDate: Date
    let onToggle: (Rhythm) -> Void
    var isCompleted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isCompleted ? .secondary : .primary)

            VStack(spacing: 8) {
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
    let selectedDate: Date
    let onAddTap: () -> Void

    private var isPastDate: Bool {
        selectedDate.isPast
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isPastDate ? "calendar" : "leaf.fill")
                .font(.system(size: 50))
                .foregroundStyle(isPastDate ? Color.secondary : Color.green.opacity(0.6))

            Text("No rhythms scheduled")
                .font(.title3)
                .fontWeight(.medium)

            Text(isPastDate
                 ? "No rhythms were scheduled for this day"
                 : "Add a rhythm to start tracking your daily routines")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !isPastDate {
                Button(action: onAddTap) {
                    Label("Add Rhythm", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
