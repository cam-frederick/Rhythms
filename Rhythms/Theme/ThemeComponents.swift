//
//  ThemeComponents.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

// MARK: - Themed Card Container

/// A reusable card container with subtle border and optional shadow
struct ThemedCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let content: Content
    var hasShadow: Bool = false

    init(hasShadow: Bool = false, @ViewBuilder content: () -> Content) {
        self.hasShadow = hasShadow
        self.content = content()
    }

    var body: some View {
        content
            .padding(ThemeSpacing.md)
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

// MARK: - Section Header

/// Styled section header with uppercase label
struct ThemeSectionHeader: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var showDivider: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: ThemeSpacing.xs) {
            Text(title.uppercased())
                .font(ThemeTypography.sectionLabel)
                .tracking(ThemeTypography.sectionLabelTracking)
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            if showDivider {
                Rectangle()
                    .fill(ThemeColors.borderSubtle(colorScheme))
                    .frame(height: ThemeBorder.thin)
            }
        }
    }
}

// MARK: - Gold Accent Button

/// Primary action button with gold accent
struct GoldButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ThemeSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(ThemeTypography.labelLarge)
            .foregroundStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.md)
            .background(ThemeColors.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
        }
    }
}

// MARK: - Secondary Button

/// Secondary action button with subtle styling
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ThemeSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(ThemeTypography.labelLarge)
            .foregroundStyle(ThemeColors.textPrimary(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, ThemeSpacing.md)
            .background(ThemeColors.bgSecondary(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: ThemeRadius.medium)
                    .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
            )
        }
    }
}

// MARK: - Progress Ring (Gold Themed)

/// Circular progress ring with gold accent
struct GoldProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 16
    var showPercentage: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0

    private var displayProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    ThemeColors.bgSecondary(colorScheme),
                    lineWidth: lineWidth
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ThemeColors.accentGold,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Percentage text
            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(ThemeTypography.numericMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
            }
        }
        .onAppear {
            withAnimation(ThemeAnimation.smoothEase) {
                animatedProgress = displayProgress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(ThemeAnimation.smoothEase) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}

// MARK: - Stat Card

/// Small stat display card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String?

    @Environment(\.colorScheme) private var colorScheme

    init(value: String, label: String, icon: String? = nil) {
        self.value = value
        self.label = label
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: ThemeSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(ThemeColors.accentGold)
            }

            Text(value)
                .font(ThemeTypography.numericMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text(label)
                .font(ThemeTypography.caption)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(ThemeSpacing.md)
        .background(ThemeColors.bgSecondary(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: ThemeRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: ThemeRadius.large)
                .stroke(ThemeColors.borderSubtle(colorScheme), lineWidth: ThemeBorder.thin)
        )
    }
}

// MARK: - Empty State View

/// Styled empty state placeholder
struct ThemedEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: ThemeSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundStyle(ThemeColors.textMuted(colorScheme))

            Text(title)
                .font(ThemeTypography.titleMedium)
                .foregroundStyle(ThemeColors.textPrimary(colorScheme))

            Text(message)
                .font(ThemeTypography.bodyMedium)
                .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                GoldButton(actionTitle, icon: "plus.circle.fill", action: action)
                    .padding(.top, ThemeSpacing.sm)
                    .frame(maxWidth: 200)
            }
        }
        .padding(ThemeSpacing.xl)
    }
}
