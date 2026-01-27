//
//  Category.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData
import SwiftUI

/// Represents a category or "bucket" for organizing rhythms
@Model
final class Category {
    // MARK: - Properties

    var id: UUID
    var name: String
    var emoji: String
    var colorHex: String
    var sortOrder: Int
    var isSystemCategory: Bool
    var createdAt: Date

    // Relationship
    @Relationship(deleteRule: .nullify, inverse: \Rhythm.category)
    var rhythms: [Rhythm]

    // MARK: - Initialization

    init(
        name: String,
        emoji: String,
        colorHex: String,
        sortOrder: Int = 0,
        isSystemCategory: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.isSystemCategory = isSystemCategory
        self.createdAt = Date()
        self.rhythms = []
    }

    // MARK: - Computed Properties

    /// Returns the SwiftUI Color from the hex string
    var color: Color {
        Color(hex: colorHex) ?? .accentColor
    }

    /// Returns the number of active (non-archived) rhythms in this category
    var activeRhythmCount: Int {
        rhythms.filter { !$0.isArchived }.count
    }

    /// Returns a display string like "Health (5 rhythms)"
    var displayDescription: String {
        let count = activeRhythmCount
        let rhythmWord = count == 1 ? "rhythm" : "rhythms"
        return "\(emoji) \(name) (\(count) \(rhythmWord))"
    }
}

// MARK: - Default Categories

extension Category {
    /// Default system categories to seed on first launch
    static let defaultCategories: [(name: String, emoji: String, colorHex: String)] = [
        ("Health", "💪", "#34C759"),
        ("Mindfulness", "🧘", "#AF52DE"),
        ("Productivity", "📊", "#007AFF"),
        ("Learning", "📚", "#FF9500"),
        ("Social", "👥", "#FF2D55"),
        ("Finance", "💰", "#30D158"),
        ("Creative", "🎨", "#FF3B30"),
        ("Home", "🏠", "#5856D6")
    ]

    /// Creates all default system categories
    static func createDefaults() -> [Category] {
        defaultCategories.enumerated().map { index, data in
            Category(
                name: data.name,
                emoji: data.emoji,
                colorHex: data.colorHex,
                sortOrder: index,
                isSystemCategory: true
            )
        }
    }

    /// Seeds default categories into the given model context
    static func seedDefaults(in context: ModelContext) {
        for category in createDefaults() {
            context.insert(category)
        }
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count

        switch length {
        case 6:
            self.init(
                red: Double((rgb & 0xFF0000) >> 16) / 255.0,
                green: Double((rgb & 0x00FF00) >> 8) / 255.0,
                blue: Double(rgb & 0x0000FF) / 255.0
            )
        case 8:
            self.init(
                red: Double((rgb & 0xFF000000) >> 24) / 255.0,
                green: Double((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: Double((rgb & 0x0000FF00) >> 8) / 255.0,
                opacity: Double(rgb & 0x000000FF) / 255.0
            )
        default:
            return nil
        }
    }

    /// Returns a hex string representation of this color
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }

        let r = components[0]
        let g = components.count > 1 ? components[1] : r
        let b = components.count > 2 ? components[2] : r

        return String(format: "#%02X%02X%02X",
                      Int(r * 255),
                      Int(g * 255),
                      Int(b * 255))
    }
}
