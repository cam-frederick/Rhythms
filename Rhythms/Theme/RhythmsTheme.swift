//
//  RhythmsTheme.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

/// Main theme export and utilities for the Rhythms app
/// Refined/Minimal design system implementation

// MARK: - Theme Environment Key

/// Environment key for accessing theme globally
private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = RhythmsTheme()
}

extension EnvironmentValues {
    var theme: RhythmsTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

/// Main theme configuration object
struct RhythmsTheme {
    // Color accessors (convenience)
    let colors = ThemeColors.self
    let typography = ThemeTypography.self
    let spacing = ThemeSpacing.self
    let radius = ThemeRadius.self
    let animation = ThemeAnimation.self
    let border = ThemeBorder.self
}

// MARK: - View Extension for Theme Setup

extension View {
    /// Apply the Rhythms theme to the entire view hierarchy
    func rhythmsTheme() -> some View {
        modifier(RhythmsThemeModifier())
    }
}

/// Main theme modifier that sets up global styling
struct RhythmsThemeModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    init() {
        configureAppearance()
    }

    func body(content: Content) -> some View {
        content
            .tint(ThemeColors.accentGold)
            .environment(\.theme, RhythmsTheme())
    }

    private func configureAppearance() {
        // Configure UIKit appearances for native components
        configureNavigationBarAppearance()
        configureTabBarAppearance()
        configureTableViewAppearance()
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Use theme colors
        appearance.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1) // #0c0c0c
                : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)    // #fafafa
        }

        // Title styling with serif font
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1) // #f0f0f0
                    : UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)    // #1a1a1a
            }
        ]

        appearance.largeTitleTextAttributes = [
            .font: UIFont(name: "NewYork-Bold", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1)
                    : UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
            }
        ]

        // Remove shadow line
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(red: 0.788, green: 0.663, blue: 0.384, alpha: 1) // #c9a962
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()

        // Background color
        appearance.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        }

        // Remove shadow line
        appearance.shadowColor = .clear

        // Configure item appearance
        let itemAppearance = UITabBarItemAppearance()

        // Normal state - muted
        itemAppearance.normal.iconColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1) // #4a4a4a
                : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)    // #999999
        }
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1)
                    : UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
            }
        ]

        // Selected state - gold accent
        let goldColor = UIColor(red: 0.788, green: 0.663, blue: 0.384, alpha: 1) // #c9a962
        itemAppearance.selected.iconColor = goldColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: goldColor
        ]

        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func configureTableViewAppearance() {
        // Table/List background
        UITableView.appearance().backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.047, green: 0.047, blue: 0.047, alpha: 1)
                : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        }

        // Separator color
        UITableView.appearance().separatorColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.06)
        }
    }
}

// MARK: - Preview Helpers

#Preview("Theme Colors - Dark") {
    ThemeColorPreview()
        .preferredColorScheme(.dark)
}

#Preview("Theme Colors - Light") {
    ThemeColorPreview()
        .preferredColorScheme(.light)
}

struct ThemeColorPreview: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Rhythms Theme")
                    .font(ThemeTypography.displayLarge)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                // Background colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("BACKGROUNDS")
                        .sectionLabelStyle()

                    HStack(spacing: 8) {
                        colorSwatch("Primary", ThemeColors.bgPrimary(colorScheme))
                        colorSwatch("Secondary", ThemeColors.bgSecondary(colorScheme))
                        colorSwatch("Card", ThemeColors.bgCard(colorScheme))
                        colorSwatch("Elevated", ThemeColors.bgElevated(colorScheme))
                    }
                }

                // Text colors
                VStack(alignment: .leading, spacing: 8) {
                    Text("TEXT")
                        .sectionLabelStyle()

                    HStack(spacing: 8) {
                        colorSwatch("Primary", ThemeColors.textPrimary(colorScheme))
                        colorSwatch("Secondary", ThemeColors.textSecondary(colorScheme))
                        colorSwatch("Muted", ThemeColors.textMuted(colorScheme))
                    }
                }

                // Accent
                VStack(alignment: .leading, spacing: 8) {
                    Text("ACCENT")
                        .sectionLabelStyle()

                    colorSwatch("Gold", ThemeColors.accentGold)
                        .frame(maxWidth: .infinity)
                }

                // Components
                VStack(alignment: .leading, spacing: 8) {
                    Text("COMPONENTS")
                        .sectionLabelStyle()

                    GoldButton("Gold Button", icon: "star.fill") {}

                    SecondaryButton("Secondary Button", icon: "arrow.right") {}

                    ThemedCard {
                        Text("Themed Card")
                            .font(ThemeTypography.bodyLarge)
                    }
                }
            }
            .padding()
        }
        .background(ThemeColors.bgPrimary(colorScheme))
    }

    func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: ThemeRadius.small)
                .fill(color)
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: ThemeRadius.small)
                        .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: 1)
                )

            Text(name)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
    }
}
