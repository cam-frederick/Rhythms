//
//  ThemeColors.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

/// Refined/Minimal design system color palette with light/dark mode support
struct ThemeColors {

    // MARK: - Background Colors

    /// Primary background - main app background
    /// Dark: #0c0c0c, Light: #fafafa
    static func bgPrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#0c0c0c")!
            : Color(hex: "#fafafa")!
    }

    /// Secondary background - subtle contrast areas
    /// Dark: #141414, Light: #f0f0f0
    static func bgSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#141414")!
            : Color(hex: "#f0f0f0")!
    }

    /// Card background - elevated content containers
    /// Dark: #1a1a1a, Light: #ffffff
    static func bgCard(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#1a1a1a")!
            : Color(hex: "#ffffff")!
    }

    /// Elevated background - modals, sheets, popovers
    /// Dark: #222222, Light: #ffffff
    static func bgElevated(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#222222")!
            : Color(hex: "#ffffff")!
    }

    // MARK: - Text Colors

    /// Primary text - headings, important content
    /// Dark: #f0f0f0, Light: #1a1a1a
    static func textPrimary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#f0f0f0")!
            : Color(hex: "#1a1a1a")!
    }

    /// Secondary text - supporting content
    /// Dark: #808080, Light: #666666
    static func textSecondary(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#808080")!
            : Color(hex: "#666666")!
    }

    /// Muted text - placeholders, disabled states
    /// Dark: #4a4a4a, Light: #999999
    static func textMuted(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#4a4a4a")!
            : Color(hex: "#999999")!
    }

    // MARK: - Accent Colors

    /// Gold accent - primary accent color throughout the app
    /// Same in both modes: #c9a962
    static let accentGold = Color(hex: "#c9a962")!

    /// Gold gradient for special elements
    static var accentGoldGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#d4b96e")!, Color(hex: "#c9a962")!, Color(hex: "#b89b55")!],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Border Colors

    /// Subtle border - ultra-thin dividers and card outlines
    /// Dark: white 6%, Light: black 6%
    static func borderSubtle(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.black.opacity(0.06)
    }

    /// Border for focused/active states
    static func borderActive(_ colorScheme: ColorScheme) -> Color {
        accentGold.opacity(colorScheme == .dark ? 0.5 : 0.4)
    }

    // MARK: - Semantic Colors

    /// Success state - completions
    static func success(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#4ade80")!
            : Color(hex: "#22c55e")!
    }

    /// Warning state - paused, attention needed
    static func warning(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#facc15")!
            : Color(hex: "#eab308")!
    }

    /// Destructive state - delete, archive
    static func destructive(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(hex: "#f87171")!
            : Color(hex: "#ef4444")!
    }

    // MARK: - Overlay Colors

    /// Dimmed overlay for modals
    static func overlayDim(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.6)
            : Color.black.opacity(0.4)
    }
}
