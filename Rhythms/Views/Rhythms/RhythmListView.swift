//
//  RhythmListView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct RhythmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Rhythm.createdAt, order: .reverse) private var allRhythms: [Rhythm]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var searchText = ""
    @State private var selectedFilter: RhythmFilter = .active
    @State private var showingAddSheet = false

    enum RhythmFilter: String, CaseIterable {
        case active = "Active"
        case paused = "Paused"
        case archived = "Archived"
        case all = "All"
    }

    private var filteredRhythms: [Rhythm] {
        var rhythms = allRhythms

        // Apply filter
        switch selectedFilter {
        case .active:
            rhythms = rhythms.filter { $0.isActive }
        case .paused:
            rhythms = rhythms.filter { $0.isPaused }
        case .archived:
            rhythms = rhythms.filter { $0.isArchived }
        case .all:
            break
        }

        // Apply search
        if !searchText.isEmpty {
            rhythms = rhythms.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                ($0.rhythmDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return rhythms
    }

    // Group rhythms by category
    private var groupedRhythms: [(category: Category?, rhythms: [Rhythm])] {
        let categorized = Dictionary(grouping: filteredRhythms) { $0.category }

        var result: [(category: Category?, rhythms: [Rhythm])] = []

        // First add rhythms with categories (sorted by category sortOrder)
        for category in categories {
            if let rhythms = categorized[category], !rhythms.isEmpty {
                result.append((category: category, rhythms: rhythms))
            }
        }

        // Then add uncategorized rhythms
        if let uncategorized = categorized[nil], !uncategorized.isEmpty {
            result.append((category: nil, rhythms: uncategorized))
        }

        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if allRhythms.isEmpty {
                    EmptyRhythmListView(onAddTap: { showingAddSheet = true })
                } else {
                    List {
                        // Filter picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(RhythmFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                        .padding(.vertical, ThemeSpacing.sm)

                        // Grouped rhythms
                        ForEach(groupedRhythms, id: \.category?.id) { group in
                            Section {
                                ForEach(group.rhythms, id: \.id) { rhythm in
                                    NavigationLink(value: rhythm) {
                                        RhythmRowView(rhythm: rhythm)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        if rhythm.isArchived {
                                            Button {
                                                rhythm.unarchive()
                                            } label: {
                                                Label("Unarchive", systemImage: "arrow.uturn.backward")
                                            }
                                            .tint(ThemeColors.accentGold)
                                        } else {
                                            Button(role: .destructive) {
                                                rhythm.archive()
                                            } label: {
                                                Label("Archive", systemImage: "archivebox")
                                            }
                                        }
                                    }
                                    .swipeActions(edge: .leading) {
                                        if rhythm.isPaused {
                                            Button {
                                                rhythm.resume()
                                            } label: {
                                                Label("Resume", systemImage: "play.fill")
                                            }
                                            .tint(ThemeColors.success(colorScheme))
                                        } else if !rhythm.isArchived {
                                            Button {
                                                rhythm.pause()
                                            } label: {
                                                Label("Pause", systemImage: "pause.fill")
                                            }
                                            .tint(ThemeColors.warning(colorScheme))
                                        }
                                    }
                                }
                            } header: {
                                if let category = group.category {
                                    Label {
                                        Text(category.name)
                                            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                                    } icon: {
                                        Text(category.emoji)
                                    }
                                } else {
                                    Text("Uncategorized")
                                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(ThemeColors.bgPrimary(colorScheme))
                    .searchable(text: $searchText, prompt: "Search rhythms")
                    .navigationDestination(for: Rhythm.self) { rhythm in
                        RhythmDetailView(rhythm: rhythm)
                    }
                }
            }
            .background(ThemeColors.bgPrimary(colorScheme))
            .navigationTitle("Rhythms")
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
        }
    }
}

// MARK: - Rhythm Row View

struct RhythmRowView: View {
    @Environment(\.colorScheme) private var colorScheme

    let rhythm: Rhythm

    var body: some View {
        HStack(spacing: ThemeSpacing.sm) {
            // Emoji icon
            Text(rhythm.emoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(rhythm.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))

            // Info
            VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
                HStack {
                    Text(rhythm.title)
                        .font(ThemeTypography.titleSmall)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                    if rhythm.isPaused {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(ThemeColors.warning(colorScheme))
                            .font(.caption)
                    }

                    if rhythm.isArchived {
                        Image(systemName: "archivebox.fill")
                            .foregroundStyle(ThemeColors.textMuted(colorScheme))
                            .font(.caption)
                    }
                }

                Text(rhythm.schedule.displayName)
                    .font(ThemeTypography.bodySmall)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
            }

            Spacer()

            // Streak
            if rhythm.currentStreak > 0 {
                HStack(spacing: ThemeSpacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(ThemeColors.accentGold)
                    Text("\(rhythm.currentStreak)")
                        .font(ThemeTypography.labelMedium)
                        .foregroundStyle(ThemeColors.accentGold)
                }
            }
        }
        .padding(.vertical, ThemeSpacing.xs)
        .opacity(rhythm.isArchived ? 0.6 : 1)
    }
}

// MARK: - Empty State

struct EmptyRhythmListView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(ThemeColors.accentGold.opacity(0.7))

            Text("No rhythms yet")
                .font(ThemeTypography.displaySmall)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text("Create your first rhythm to start building better habits")
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, ThemeSpacing.xl)

            GoldButton("Create Rhythm", icon: "plus.circle.fill", action: onAddTap)
                .padding(.top, ThemeSpacing.sm)
                .frame(maxWidth: 200)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ThemeColors.bgPrimary(colorScheme))
    }
}

#Preview {
    RhythmListView()
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
