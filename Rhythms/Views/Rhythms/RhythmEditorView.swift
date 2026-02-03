//
//  RhythmEditorView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct RhythmEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticService) private var hapticService
    @Environment(\.notificationService) private var notificationService
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \Category.sortOrder) private var categories: [Category]

    let mode: Mode

    enum Mode {
        case create
        case edit(Rhythm)

        var title: String {
            switch self {
            case .create: return "New Rhythm"
            case .edit: return "Edit Rhythm"
            }
        }
    }

    // Form state
    @State private var title: String = ""
    @State private var emoji: String = "🎯"
    @State private var colorHex: String = "#007AFF"
    @State private var schedule: RhythmSchedule = .daily
    @State private var selectedCategory: Category?
    @State private var rhythmDescription: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    @State private var showingEmojiPicker = false
    @State private var showingSchedulePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingNotesSheet = false
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(mode: Mode) {
        self.mode = mode
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    // Emoji and Title
                    HStack(spacing: 16) {
                        Button {
                            showingEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(Color(hex: colorHex)?.opacity(0.15) ?? Color.gray.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        TextField("Rhythm name", text: $title)
                            .font(.title3)
                    }

                    // Description
                    TextField("Description (optional)", text: $rhythmDescription, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Schedule Section
                Section("Schedule") {
                    Button {
                        showingSchedulePicker = true
                    } label: {
                        HStack {
                            Label("Frequency", systemImage: "calendar")
                            Spacer()
                            Text(schedule.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Category Section
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories, id: \.id) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Text(category.emoji)
                            }
                            .tag(category as Category?)
                        }
                    }
                }

                // Appearance Section
                Section("Appearance") {
                    ColorPickerRow(selectedHex: $colorHex)
                }

                // Reminder Section
                Section("Reminder") {
                    Toggle("Enable reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, enabled in
                            if enabled {
                                requestNotificationPermission()
                            }
                        }

                    if reminderEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )

                        if notificationStatus == .denied {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                Text("Notifications disabled. Enable in Settings.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Notes Section (edit mode only)
                if case .edit(let rhythm) = mode {
                    Section("Scheduled Notes") {
                        Button {
                            showingNotesSheet = true
                        } label: {
                            HStack {
                                Label("Manage Notes", systemImage: "note.text")
                                Spacer()
                                if rhythm.notes.isEmpty {
                                    Text("None")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("\(rhythm.notes.count)")
                                        .foregroundStyle(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)

                        Text("Add workout splits, reading pages, or daily focus areas")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Delete Button (edit mode only)
                if case .edit(let rhythm) = mode {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Delete Rhythm", systemImage: "trash")
                                Spacer()
                            }
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
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
            .sheet(isPresented: $showingSchedulePicker) {
                SchedulePickerView(schedule: $schedule)
            }
            .sheet(isPresented: $showingNotesSheet) {
                if case .edit(let rhythm) = mode {
                    RhythmNotesView(rhythm: rhythm)
                }
            }
            .confirmationDialog(
                "Delete Rhythm?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    delete()
                }
            } message: {
                Text("This will permanently delete this rhythm and all its history.")
            }
            .onAppear {
                loadExistingData()
                checkNotificationStatus()
            }
        }
    }

    private func checkNotificationStatus() {
        Task {
            notificationStatus = await notificationService.authorizationStatus
        }
    }

    private func requestNotificationPermission() {
        Task {
            do {
                _ = try await notificationService.requestPermission()
                notificationStatus = await notificationService.authorizationStatus
            } catch {
                print("Failed to request notification permission: \(error)")
            }
        }
    }

    private func loadExistingData() {
        if case .edit(let rhythm) = mode {
            title = rhythm.title
            emoji = rhythm.emoji
            colorHex = rhythm.colorHex
            schedule = rhythm.schedule
            selectedCategory = rhythm.category
            rhythmDescription = rhythm.rhythmDescription ?? ""
            reminderEnabled = rhythm.reminderEnabled
            if let time = rhythm.reminderTime {
                reminderTime = time
            }
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        switch mode {
        case .create:
            let rhythm = Rhythm(
                title: trimmedTitle,
                emoji: emoji,
                colorHex: colorHex,
                schedule: schedule,
                rhythmDescription: rhythmDescription.isEmpty ? nil : rhythmDescription,
                category: selectedCategory
            )
            rhythm.reminderEnabled = reminderEnabled
            rhythm.reminderTime = reminderEnabled ? reminderTime : nil

            modelContext.insert(rhythm)
            try? modelContext.save()
            hapticService.playSuccess()
            WidgetReloadService.rhythmDataChanged()

            // Schedule notification if enabled
            if reminderEnabled {
                scheduleNotification(for: rhythm)
            }

        case .edit(let rhythm):
            rhythm.title = trimmedTitle
            rhythm.emoji = emoji
            rhythm.colorHex = colorHex
            rhythm.schedule = schedule
            rhythm.rhythmDescription = rhythmDescription.isEmpty ? nil : rhythmDescription
            rhythm.category = selectedCategory
            rhythm.reminderEnabled = reminderEnabled
            rhythm.reminderTime = reminderEnabled ? reminderTime : nil
            rhythm.updatedAt = Date()
            try? modelContext.save()

            hapticService.playLight()
            WidgetReloadService.rhythmDataChanged()

            // Update notification
            if reminderEnabled {
                scheduleNotification(for: rhythm)
            } else {
                cancelNotification(for: rhythm)
            }
        }

        dismiss()
    }

    private func scheduleNotification(for rhythm: Rhythm) {
        Task {
            do {
                try await notificationService.scheduleReminder(for: rhythm)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotification(for rhythm: Rhythm) {
        Task {
            await notificationService.cancelReminder(for: rhythm)
        }
    }

    private func delete() {
        if case .edit(let rhythm) = mode {
            modelContext.delete(rhythm)
            try? modelContext.save()
            hapticService.playWarning()
            WidgetReloadService.rhythmDataChanged()
            dismiss()
        }
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    @Binding var selectedHex: String

    private let colors: [String] = [
        "#007AFF", "#34C759", "#FF9500", "#FF2D55",
        "#AF52DE", "#5856D6", "#FF3B30", "#30D158"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(colors, id: \.self) { hex in
                    Button {
                        selectedHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex) ?? .gray)
                            .frame(width: 32, height: 32)
                            .overlay {
                                if hex == selectedHex {
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                        .padding(2)
                                    Circle()
                                        .stroke(Color(hex: hex) ?? .gray, lineWidth: 2)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Emoji Picker View

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    @State private var searchText = ""
    @State private var customEmoji = ""
    @FocusState private var isCustomEmojiFieldFocused: Bool

    private let emojiData: [(name: String, emojis: [(emoji: String, keywords: String)])] = [
        ("Suggested", [
            ("💪", "muscle strength workout gym fitness"),
            ("🏃", "run running exercise cardio jog"),
            ("🧘", "yoga meditation mindfulness zen"),
            ("📚", "book books read reading study learn"),
            ("💊", "pill medicine health vitamin"),
            ("💰", "money savings finance budget"),
            ("🎯", "target goal focus aim"),
            ("✅", "check done complete task"),
            ("📝", "note write writing memo"),
            ("⏰", "alarm clock time wake morning")
        ]),
        ("Smileys", [
            ("😀", "grin happy smile"),
            ("😃", "smile happy joy"),
            ("😄", "laugh happy grin"),
            ("😁", "beam grin happy"),
            ("😊", "blush smile happy shy"),
            ("🥰", "love hearts smile"),
            ("😎", "cool sunglasses"),
            ("🤔", "think thinking hmm"),
            ("😴", "sleep sleeping tired zzz"),
            ("🤩", "star eyes excited wow"),
            ("😤", "frustrated angry huff"),
            ("🥳", "party celebrate birthday"),
            ("😇", "angel innocent halo"),
            ("🧐", "monocle inspect curious"),
            ("🤓", "nerd glasses smart")
        ]),
        ("Activities", [
            ("💪", "muscle strength workout gym"),
            ("🏃", "run running exercise cardio"),
            ("🧘", "yoga meditation mindfulness"),
            ("🏋️", "weightlifting gym workout"),
            ("🚴", "bike cycling bicycle"),
            ("⚽", "soccer football sport"),
            ("🎾", "tennis sport racket"),
            ("🏊", "swim swimming pool"),
            ("🧗", "climb climbing rock"),
            ("⛷️", "ski skiing snow winter"),
            ("🏀", "basketball sport ball"),
            ("🎮", "game gaming video controller"),
            ("🎲", "dice game board"),
            ("🎳", "bowling sport"),
            ("🏸", "badminton sport"),
            ("🥊", "boxing fight sport"),
            ("🧩", "puzzle piece game")
        ]),
        ("Health", [
            ("💊", "pill medicine vitamin"),
            ("🧠", "brain mind think smart"),
            ("❤️", "heart love health"),
            ("😴", "sleep rest tired"),
            ("🥗", "salad healthy food diet"),
            ("💧", "water hydrate drink"),
            ("🍎", "apple fruit healthy"),
            ("🥦", "broccoli vegetable healthy"),
            ("🧪", "science lab test"),
            ("🩺", "doctor medical health"),
            ("🏥", "hospital medical health"),
            ("💉", "shot vaccine needle"),
            ("🩹", "bandage heal injury"),
            ("🧘‍♀️", "yoga woman meditation"),
            ("🧘‍♂️", "yoga man meditation"),
            ("🦷", "tooth dental teeth"),
            ("👁️", "eye vision see"),
            ("🫀", "heart organ health"),
            ("🫁", "lungs breathing health")
        ]),
        ("Work", [
            ("📊", "chart graph data analytics"),
            ("💼", "briefcase work business job"),
            ("📝", "memo note write"),
            ("✅", "check done complete"),
            ("📚", "books study read learn"),
            ("💡", "idea lightbulb think"),
            ("🎯", "target goal aim focus"),
            ("⏰", "clock time alarm"),
            ("📅", "calendar date schedule"),
            ("🗂️", "folder files organize"),
            ("💻", "laptop computer work"),
            ("📧", "email mail message"),
            ("📞", "phone call telephone"),
            ("🖥️", "desktop computer monitor"),
            ("⌨️", "keyboard type"),
            ("📎", "paperclip attach"),
            ("✏️", "pencil write edit"),
            ("📌", "pin pushpin"),
            ("🗓️", "calendar schedule plan")
        ]),
        ("Creative", [
            ("🎨", "art paint palette creative"),
            ("🎵", "music note song"),
            ("📷", "camera photo picture"),
            ("✏️", "pencil draw write"),
            ("🎬", "movie film video"),
            ("🎸", "guitar music instrument"),
            ("🎹", "piano keyboard music"),
            ("🖌️", "paintbrush art draw"),
            ("🎭", "theater drama masks"),
            ("✍️", "write writing hand"),
            ("📸", "camera flash photo"),
            ("🎤", "microphone sing karaoke"),
            ("🎧", "headphones music listen"),
            ("📺", "tv television watch"),
            ("🎻", "violin music instrument"),
            ("🥁", "drum music beat"),
            ("🎺", "trumpet music instrument"),
            ("🪕", "banjo music instrument")
        ]),
        ("Social", [
            ("👥", "people group friends"),
            ("💬", "chat talk message"),
            ("📱", "phone mobile smartphone"),
            ("💌", "letter love mail"),
            ("🤝", "handshake deal agree"),
            ("👋", "wave hello hi bye"),
            ("🎉", "party celebrate tada"),
            ("☕", "coffee cafe drink"),
            ("🍽️", "dinner food meal"),
            ("🎊", "celebration party confetti"),
            ("👨‍👩‍👧", "family parents child"),
            ("💑", "couple love relationship"),
            ("👫", "couple holding hands"),
            ("🗣️", "speak talk head"),
            ("👂", "ear listen hear"),
            ("🍻", "cheers beer drinks"),
            ("🥂", "toast champagne celebrate")
        ]),
        ("Finance", [
            ("💰", "money bag rich savings"),
            ("💳", "credit card payment"),
            ("📈", "chart up growth"),
            ("🏦", "bank money finance"),
            ("💵", "dollar money cash"),
            ("🪙", "coin money gold"),
            ("🧾", "receipt bill payment"),
            ("💸", "money wings spend"),
            ("🤑", "money face rich"),
            ("📉", "chart down loss"),
            ("💹", "chart stocks market"),
            ("🏧", "atm cash money"),
            ("💎", "gem diamond valuable")
        ]),
        ("Home", [
            ("🏠", "home house"),
            ("🧹", "broom clean sweep"),
            ("🛏️", "bed sleep bedroom"),
            ("🌱", "plant seedling grow"),
            ("🪴", "plant pot houseplant"),
            ("🧺", "basket laundry"),
            ("🧼", "soap clean wash"),
            ("🔧", "wrench tool fix"),
            ("🛠️", "tools hammer fix"),
            ("🚿", "shower bath clean"),
            ("🍳", "cooking egg pan"),
            ("🧽", "sponge clean dishes"),
            ("🛋️", "couch sofa living room"),
            ("🚪", "door entrance"),
            ("🪑", "chair seat furniture"),
            ("🛁", "bathtub bath relax"),
            ("🧴", "lotion bottle"),
            ("🪥", "toothbrush teeth dental")
        ]),
        ("Nature", [
            ("🌸", "flower cherry blossom"),
            ("🌈", "rainbow colors"),
            ("⭐", "star night sky"),
            ("🌟", "glowing star shine"),
            ("✨", "sparkles magic"),
            ("💫", "dizzy star"),
            ("🦋", "butterfly insect"),
            ("🌻", "sunflower flower"),
            ("🌺", "hibiscus flower"),
            ("🍀", "clover luck four leaf"),
            ("🌲", "tree evergreen pine"),
            ("🌊", "wave ocean water"),
            ("☀️", "sun sunny weather"),
            ("🌙", "moon night crescent"),
            ("⛅", "cloud sun weather"),
            ("🔥", "fire hot flame"),
            ("❄️", "snow cold winter"),
            ("🌴", "palm tree tropical")
        ]),
        ("Food", [
            ("🍎", "apple fruit red"),
            ("🥗", "salad healthy green"),
            ("🥦", "broccoli vegetable"),
            ("🍕", "pizza food italian"),
            ("🍔", "burger hamburger food"),
            ("🥤", "drink soda cup"),
            ("☕", "coffee hot drink"),
            ("🍵", "tea green matcha"),
            ("🥛", "milk glass dairy"),
            ("🍳", "egg breakfast cooking"),
            ("🥑", "avocado healthy food"),
            ("🍌", "banana fruit yellow"),
            ("🍇", "grapes fruit purple"),
            ("🍓", "strawberry fruit red"),
            ("🥕", "carrot vegetable orange"),
            ("🌮", "taco mexican food"),
            ("🍜", "noodles ramen soup"),
            ("🍣", "sushi japanese food")
        ]),
        ("Travel", [
            ("✈️", "airplane plane travel fly"),
            ("🚗", "car drive automobile"),
            ("🚌", "bus transit public"),
            ("🚂", "train locomotive"),
            ("🚢", "ship boat cruise"),
            ("🏖️", "beach vacation sand"),
            ("🏔️", "mountain hiking nature"),
            ("🗺️", "map world travel"),
            ("🧳", "luggage suitcase travel"),
            ("🏕️", "camping tent outdoor"),
            ("🎢", "rollercoaster amusement"),
            ("🗼", "tower landmark"),
            ("🏰", "castle palace"),
            ("⛩️", "shrine temple japan")
        ]),
        ("Objects", [
            ("📱", "phone mobile smartphone"),
            ("💻", "laptop computer"),
            ("⌚", "watch time wrist"),
            ("📖", "book open read"),
            ("🔑", "key lock security"),
            ("💡", "lightbulb idea"),
            ("🔋", "battery power charge"),
            ("📦", "box package delivery"),
            ("🎁", "gift present birthday"),
            ("🏆", "trophy winner award"),
            ("🥇", "medal gold first"),
            ("🎖️", "medal military award"),
            ("📿", "prayer beads"),
            ("🧿", "evil eye protection"),
            ("🔔", "bell notification alert"),
            ("⚙️", "gear settings cog")
        ]),
        ("Symbols", [
            ("❤️", "heart love red"),
            ("🧡", "heart orange"),
            ("💛", "heart yellow"),
            ("💚", "heart green"),
            ("💙", "heart blue"),
            ("💜", "heart purple"),
            ("🖤", "heart black"),
            ("🤍", "heart white"),
            ("💯", "hundred perfect score"),
            ("✔️", "check mark done"),
            ("❌", "x cross wrong"),
            ("❗", "exclamation important"),
            ("❓", "question mark"),
            ("💤", "zzz sleep tired"),
            ("♻️", "recycle environment"),
            ("⚡", "lightning bolt energy"),
            ("🔴", "red circle"),
            ("🟢", "green circle"),
            ("🔵", "blue circle")
        ])
    ]

    private var filteredEmojis: [(emoji: String, keywords: String)] {
        if searchText.isEmpty {
            return []
        }
        let search = searchText.lowercased()
        var results: [(emoji: String, keywords: String)] = []
        for category in emojiData {
            for item in category.emojis {
                if item.keywords.lowercased().contains(search) || item.emoji == search {
                    if !results.contains(where: { $0.emoji == item.emoji }) {
                        results.append(item)
                    }
                }
            }
        }
        return results
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Custom emoji input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Custom Emoji")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        HStack(spacing: 12) {
                            TextField("Enter any emoji", text: $customEmoji)
                                .font(.system(size: 28))
                                .frame(height: 50)
                                .multilineTextAlignment(.center)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .focused($isCustomEmojiFieldFocused)
                                .onChange(of: customEmoji) { _, newValue in
                                    // Limit to first grapheme cluster (one emoji, including compound emojis)
                                    if newValue.count > 1 {
                                        customEmoji = String(newValue.prefix(1))
                                    }
                                }

                            Button {
                                if !customEmoji.isEmpty {
                                    selectedEmoji = customEmoji
                                    dismiss()
                                }
                            } label: {
                                Text("Use")
                                    .fontWeight(.semibold)
                                    .frame(width: 60, height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(customEmoji.isEmpty)
                        }
                        .padding(.horizontal)

                        Text("Tap the field and use the emoji keyboard")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Search results
                    if !searchText.isEmpty {
                        if filteredEmojis.isEmpty {
                            ContentUnavailableView.search(text: searchText)
                        } else {
                            emojiGrid(emojis: filteredEmojis.map { $0.emoji }, title: "Search Results")
                        }
                    } else {
                        // Show all categories
                        ForEach(emojiData, id: \.name) { category in
                            emojiGrid(emojis: category.emojis.map { $0.emoji }, title: category.name)
                        }
                    }
                }
                .padding(.vertical)
            }
            .searchable(text: $searchText, prompt: "Search emojis...")
            .navigationTitle("Choose Emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func emojiGrid(emojis: [String], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(emojis, id: \.self) { emoji in
                    Button {
                        selectedEmoji = emoji
                        dismiss()
                    } label: {
                        Text(emoji)
                            .font(.system(size: 28))
                            .frame(width: 44, height: 44)
                            .background(
                                emoji == selectedEmoji ?
                                Color.accentColor.opacity(0.2) :
                                Color.secondary.opacity(0.1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    RhythmEditorView(mode: .create)
        .modelContainer(for: [Rhythm.self, Category.self], inMemory: true)
}
