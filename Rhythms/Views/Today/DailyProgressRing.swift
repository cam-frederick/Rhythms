//
//  DailyProgressRing.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct DailyProgressRing: View {
    @Environment(\.colorScheme) private var colorScheme

    let progress: Double
    let completedCount: Int
    let totalCount: Int

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
                    lineWidth: 16
                )

            // Progress ring - gold accent
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ThemeColors.accentGold,
                    style: StrokeStyle(
                        lineWidth: 16,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: ThemeSpacing.sm) {
                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount)")
                        .font(ThemeTypography.numericLarge)
                        .foregroundStyle(ThemeColors.textPrimary(colorScheme))

                    Text(statusText)
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                } else {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(ThemeColors.textMuted(colorScheme))

                    Text("No rhythms today")
                        .font(ThemeTypography.bodyMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                }
            }
        }
        .padding(ThemeSpacing.md)
        .onAppear {
            withAnimation(ThemeAnimation.refinedSpring) {
                animatedProgress = displayProgress
            }
        }
        .onChange(of: progress) { _, newValue in
            // Use a spring animation so the ring has a satisfying bounce when
            // the user checks off a rhythm and the percentage jumps up.
            withAnimation(ThemeAnimation.refinedSpring) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }

    private var statusText: String {
        if displayProgress == 1.0 {
            return "All done!"
        } else if displayProgress >= 0.5 {
            return "Keep going!"
        } else if completedCount > 0 {
            return "Good start!"
        } else {
            return "Let's begin"
        }
    }
}

// MARK: - Mini Progress Ring (for list views)

struct MiniProgressRing: View {
    @Environment(\.colorScheme) private var colorScheme

    let progress: Double
    let size: CGFloat

    private var displayProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    ThemeColors.bgSecondary(colorScheme),
                    lineWidth: size / 8
                )

            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    ThemeColors.accentGold,
                    style: StrokeStyle(
                        lineWidth: size / 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            if displayProgress == 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size / 3, weight: .bold))
                    .foregroundStyle(ThemeColors.accentGold)
            } else {
                Text("\(Int(displayProgress * 100))%")
                    .font(.system(size: size / 4, weight: .semibold, design: .rounded))
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 40) {
        DailyProgressRing(progress: 0.75, completedCount: 3, totalCount: 4)
            .frame(height: 180)

        DailyProgressRing(progress: 1.0, completedCount: 5, totalCount: 5)
            .frame(height: 180)

        DailyProgressRing(progress: 0, completedCount: 0, totalCount: 0)
            .frame(height: 180)

        HStack(spacing: 20) {
            MiniProgressRing(progress: 0.25, size: 40)
            MiniProgressRing(progress: 0.5, size: 40)
            MiniProgressRing(progress: 0.75, size: 40)
            MiniProgressRing(progress: 1.0, size: 40)
        }
    }
    .padding()
}
