//
//  WidgetTheme.swift
//  RhythmsWidgets
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

/// Theme constants for Rhythms widgets - matches the main app's Refined/Minimal design system
enum WidgetTheme {
    // MARK: - Colors

    /// Gold accent color - the signature color of Rhythms
    static let accentGold = Color(red: 201/255, green: 169/255, blue: 98/255)

    /// Background colors adaptive to color scheme
    static func bgPrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 12/255, green: 12/255, blue: 12/255) : Color(red: 250/255, green: 250/255, blue: 250/255)
    }

    static func bgSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 20/255, green: 20/255, blue: 20/255) : Color(red: 240/255, green: 240/255, blue: 240/255)
    }

    static func bgCard(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 26/255, green: 26/255, blue: 26/255) : Color.white
    }

    /// Text colors
    static func textPrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 240/255, green: 240/255, blue: 240/255) : Color(red: 26/255, green: 26/255, blue: 26/255)
    }

    static func textSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 128/255, green: 128/255, blue: 128/255) : Color(red: 102/255, green: 102/255, blue: 102/255)
    }

    static func textMuted(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(red: 74/255, green: 74/255, blue: 74/255) : Color(red: 153/255, green: 153/255, blue: 153/255)
    }

    /// Border colors
    static func borderSubtle(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.06)
    }

    // MARK: - Typography

    /// Display title font (serif)
    static let displayLarge = Font.system(size: 28, weight: .semibold, design: .serif)
    static let titleMedium = Font.system(size: 18, weight: .semibold, design: .serif)
    static let titleSmall = Font.system(size: 16, weight: .semibold, design: .serif)

    /// Body fonts (system)
    static let bodyMedium = Font.system(size: 14, weight: .regular)
    static let bodySmall = Font.system(size: 12, weight: .regular)

    /// Caption and label fonts
    static let caption = Font.system(size: 11, weight: .regular)
    static let labelMedium = Font.system(size: 13, weight: .medium)

    /// Section label style
    static let sectionLabel = Font.system(size: 11, weight: .semibold)

    /// Numeric fonts (for stats)
    static let numericLarge = Font.system(size: 24, weight: .bold, design: .rounded)
    static let numericMedium = Font.system(size: 18, weight: .bold, design: .rounded)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24

    // MARK: - Radius

    static let radiusSmall: CGFloat = 4
    static let radiusMedium: CGFloat = 8
    static let radiusLarge: CGFloat = 16
}
