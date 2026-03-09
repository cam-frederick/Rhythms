//
//  SettingsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.notificationService) private var notificationService
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true
    @AppStorage("globalReminderEnabled") private var globalReminderEnabled = false
    @AppStorage("globalReminderTimeInterval") private var globalReminderTimeInterval: Double = 9 * 3600 // 9:00 AM

    @State private var showingAddCategory = false
    @State private var showingResetConfirmation = false
    @State private var categoryToEdit: Category?
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showPermissionDeniedAlert = false

    private var globalReminderTime: Binding<Date> {
        Binding(
            get: {
                let midnight = Calendar.current.startOfDay(for: Date())
                return midnight.addingTimeInterval(globalReminderTimeInterval)
            },
            set: { newDate in
                let midnight = Calendar.current.startOfDay(for: newDate)
                globalReminderTimeInterval = newDate.timeIntervalSince(midnight)
                if globalReminderEnabled {
                    scheduleGlobalReminder()
                }
            }
        )
    }

    var body: some View {
        List {
            // General Section
            Section("General") {
                Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                    .tint(ThemeColors.accentGold)

                Picker("Week Starts On", selection: $weekStartsOnMonday) {
                    Text("Sunday").tag(false)
                    Text("Monday").tag(true)
                }
            }

            // Notifications Section
            Section {
                Toggle("Daily Check-In Reminder", isOn: $globalReminderEnabled)
                    .tint(ThemeColors.accentGold)
                    .onChange(of: globalReminderEnabled) { _, enabled in
                        if enabled {
                            requestPermissionAndSchedule()
                        } else {
                            cancelGlobalReminder()
                        }
                    }

                if globalReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: globalReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .tint(ThemeColors.accentGold)

                    if notificationStatus == .denied {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.callout)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Notifications Disabled")
                                    .font(ThemeTypography.bodyMedium)
                                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .font(ThemeTypography.bodySmall)
                                .foregroundStyle(ThemeColors.accentGold)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get a daily nudge to check in with your rhythms. Individual rhythms can also have their own reminder times.")
            }

            // Categories Section
            Section {
                ForEach(categories) { category in
                    Button {
                        categoryToEdit = category
                    } label: {
                        HStack {
                            Text(category.emoji)
                                .font(.title2)

                            Text(category.name)
                                .font(ThemeTypography.bodyLarge)
                                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                            Spacer()

                            Text("\(category.rhythms.count)")
                                .font(ThemeTypography.bodyMedium)
                                .foregroundStyle(ThemeColors.textSecondary(colorScheme))

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(ThemeColors.textMuted(colorScheme))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: deleteCategories)
                .onMove(perform: moveCategories)

                Button {
                    showingAddCategory = true
                } label: {
                    Label("Add Category", systemImage: "plus.circle.fill")
                        .foregroundStyle(ThemeColors.accentGold)
                }
            } header: {
                HStack {
                    Text("Categories")
                    Spacer()
                    EditButton()
                        .font(.caption)
                        .textCase(nil)
                }
            }

            // About Section
            Section("About") {
                HStack {
                    Text("Version")
                        .font(ThemeTypography.bodyLarge)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }

                HStack {
                    Text("Build")
                        .font(ThemeTypography.bodyLarge)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
            }

            // Data Section
            Section("Data") {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("Reset All Data", systemImage: "trash")
                        .foregroundStyle(ThemeColors.destructive(colorScheme))
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ThemeColors.bgPrimary(colorScheme))
        .navigationTitle("Settings")
        .onAppear {
            checkNotificationStatus()
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                globalReminderEnabled = false
            }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders.")
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorView(mode: .create)
        }
        .sheet(item: $categoryToEdit) { category in
            CategoryEditorView(mode: .edit(category))
        }
        .confirmationDialog(
            "Reset All Data?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will permanently delete all rhythms, entries, and categories. This cannot be undone.")
        }
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories[index]
            // Unlink rhythms before deleting category
            for rhythm in category.rhythms {
                rhythm.category = nil
            }
            modelContext.delete(category)
        }
        try? modelContext.save()
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        var reorderedCategories = categories
        reorderedCategories.move(fromOffsets: source, toOffset: destination)
        for (index, category) in reorderedCategories.enumerated() {
            category.sortOrder = index
        }
        try? modelContext.save()
    }

    // MARK: - Notification Helpers

    private func checkNotificationStatus() {
        Task {
            notificationStatus = await notificationService.authorizationStatus
        }
    }

    private func requestPermissionAndSchedule() {
        Task {
            do {
                let granted = try await notificationService.requestPermission()
                notificationStatus = await notificationService.authorizationStatus
                if granted {
                    scheduleGlobalReminder()
                } else {
                    await MainActor.run {
                        globalReminderEnabled = false
                        notificationStatus = .denied
                        showPermissionDeniedAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    globalReminderEnabled = false
                }
            }
        }
    }

    private func scheduleGlobalReminder() {
        Task {
            // Build a UNMutableNotificationContent for the daily check-in
            let content = UNMutableNotificationContent()
            content.title = "Daily Rhythm Check-In"
            content.body = "Time to check in with your rhythms and keep your streaks alive! 🔥"
            content.sound = .default
            content.categoryIdentifier = "DAILY_CHECKIN"

            let midnight = Calendar.current.startOfDay(for: Date())
            let reminderDate = midnight.addingTimeInterval(globalReminderTimeInterval)
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            let request = UNNotificationRequest(
                identifier: "global-daily-checkin",
                content: content,
                trigger: trigger
            )

            do {
                let center = UNUserNotificationCenter.current()
                center.removePendingNotificationRequests(withIdentifiers: ["global-daily-checkin"])
                try await center.add(request)
            } catch {
                print("Failed to schedule global reminder: \(error)")
            }
        }
    }

    private func cancelGlobalReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["global-daily-checkin"]
        )
    }

    // MARK: - Data Helpers

    private func resetAllData() {
        // Delete all rhythms (entries and notes cascade)
        let rhythmDescriptor = FetchDescriptor<Rhythm>()
        if let rhythms = try? modelContext.fetch(rhythmDescriptor) {
            for rhythm in rhythms {
                modelContext.delete(rhythm)
            }
        }

        // Delete all categories
        for category in categories {
            modelContext.delete(category)
        }

        // Re-seed default categories
        Category.seedDefaults(in: modelContext)
        try? modelContext.save()
    }
}

// MARK: - Category Editor

struct CategoryEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    enum Mode {
        case create
        case edit(Category)

        var title: String {
            switch self {
            case .create: return "New Category"
            case .edit: return "Edit Category"
            }
        }
    }

    @State private var name: String = ""
    @State private var emoji: String = ""
    @State private var colorHex: String = "#007AFF"
    @State private var showingEmojiPicker = false

    private let categoryEmojis = ["💪", "🧘", "📊", "📚", "👥", "💰", "🎨", "🏠", "❤️", "🎯", "⭐", "🔥"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !emoji.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Button {
                            showingEmojiPicker = true
                        } label: {
                            Text(emoji.isEmpty ? "📁" : emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        TextField("Category name", text: $name)
                            .font(.title3)
                    }
                }

                Section("Quick Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(categoryEmojis, id: \.self) { categoryEmoji in
                            Button {
                                emoji = categoryEmoji
                            } label: {
                                Text(categoryEmoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(emoji == categoryEmoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                loadExistingData()
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }

    private func loadExistingData() {
        if case .edit(let category) = mode {
            name = category.name
            emoji = category.emoji
            colorHex = category.colorHex
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !emoji.isEmpty else { return }

        switch mode {
        case .create:
            let category = Category(name: trimmedName, emoji: emoji, colorHex: colorHex)
            modelContext.insert(category)

        case .edit(let category):
            category.name = trimmedName
            category.emoji = emoji
            category.colorHex = colorHex
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
