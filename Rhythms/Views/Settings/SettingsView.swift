//
//  SettingsView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("weekStartsOnMonday") private var weekStartsOnMonday = true

    @State private var showingAddCategory = false
    @State private var showingResetConfirmation = false
    @State private var categoryToEdit: Category?

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
