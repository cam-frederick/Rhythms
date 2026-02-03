//
//  ThemeModifiers.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

// MARK: - Section Label Style

/// Modifier for section labels (11pt uppercase with 2pt tracking)
struct SectionLabelStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(ThemeTypography.sectionLabel)
            .tracking(ThemeTypography.sectionLabelTracking)
            .foregroundStyle(ThemeColors.textMuted(colorScheme))
    }
}

extension View {
    /// Apply section label styling (uppercase, tracked)
    func sectionLabelStyle() -> some View {
        modifier(SectionLabelStyle())
    }
}

// MARK: - Card Style

/// Modifier for themed card containers
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let hasShadow: Bool
    let padding: CGFloat

    init(hasShadow: Bool = false, padding: CGFloat = ThemeSpacing.md) {
        self.hasShadow = hasShadow
        self.padding = padding
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ThemeColors.bgCard(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.large)
                    .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
            )
            .shadow(
                color: hasShadow ? Color.black.opacity(colorScheme == .dark ? 0.3 : 0.05) : .clear,
                radius: hasShadow ? 8 : 0,
                y: hasShadow ? 2 : 0
            )
    }
}

extension View {
    /// Apply themed card styling
    func cardStyle(hasShadow: Bool = false, padding: CGFloat = ThemeSpacing.md) -> some View {
        modifier(CardStyle(hasShadow: hasShadow, padding: padding))
    }
}

// MARK: - Primary Background

/// Modifier for primary background
struct PrimaryBackgroundStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(ThemeColors.bgPrimary(colorScheme))
    }
}

extension View {
    /// Apply primary background color
    func primaryBackground() -> some View {
        modifier(PrimaryBackgroundStyle())
    }
}

// MARK: - Subtle Border

/// Modifier for adding subtle border to any view
struct SubtleBorderStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
            )
    }
}

extension View {
    /// Add subtle border with specified corner radius
    func subtleBorder(cornerRadius: CGFloat = ThemeRadius.medium) -> some View {
        modifier(SubtleBorderStyle(cornerRadius: cornerRadius))
    }
}

// MARK: - Gold Tint

/// Modifier for applying gold accent tint
struct GoldTintStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .tint(ThemeColors.accentGold)
    }
}

extension View {
    /// Apply gold accent tint
    func goldTint() -> some View {
        modifier(GoldTintStyle())
    }
}

// MARK: - Themed Text Styles

extension View {
    /// Apply primary text color
    func textPrimary() -> some View {
        modifier(TextPrimaryStyle())
    }

    /// Apply secondary text color
    func textSecondary() -> some View {
        modifier(TextSecondaryStyle())
    }

    /// Apply muted text color
    func textMuted() -> some View {
        modifier(TextMutedStyle())
    }
}

struct TextPrimaryStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(ThemeColors.textPrimary(colorScheme))
    }
}

struct TextSecondaryStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(ThemeColors.textSecondary(colorScheme))
    }
}

struct TextMutedStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(ThemeColors.textMuted(colorScheme))
    }
}

// MARK: - Smooth Animation

extension View {
    /// Apply smooth 0.4s animation
    func smoothAnimation<V: Equatable>(value: V) -> some View {
        animation(ThemeAnimation.smoothEase, value: value)
    }
}

// MARK: - Display Title Style

/// Modifier for serif display titles
struct DisplayTitleStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    enum Size {
        case large, medium, small
    }

    let size: Size

    var font: Font {
        switch size {
        case .large: return ThemeTypography.displayLarge
        case .medium: return ThemeTypography.displayMedium
        case .small: return ThemeTypography.displaySmall
        }
    }

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundStyle(ThemeColors.textPrimary(colorScheme))
    }
}

extension View {
    /// Apply display title styling (serif)
    func displayTitle(_ size: DisplayTitleStyle.Size = .medium) -> some View {
        modifier(DisplayTitleStyle(size: size))
    }
}
