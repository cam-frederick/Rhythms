//
//  DailyProgressRing.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct DailyProgressRing: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int

    @State private var animatedProgress: Double = 0

    private var displayProgress: Double {
        min(max(progress, 0), 1)
    }

    private var ringColor: Color {
        switch displayProgress {
        case 1.0:
            return .green
        case 0.5..<1.0:
            return .blue
        case 0.0..<0.5:
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: 16
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: 16,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: animatedProgress)

            // Center content
            VStack(spacing: 8) {
                if totalCount > 0 {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))

                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)

                    Text("No rhythms today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear {
            animatedProgress = displayProgress
        }
        .onChange(of: progress) { _, newValue in
            animatedProgress = min(max(newValue, 0), 1)
        }
    }

    private var statusText: String {
        if displayProgress == 1.0 {
            return "All done! 🎉"
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
    let progress: Double
    let size: CGFloat

    private var displayProgress: Double {
        min(max(progress, 0), 1)
    }

    private var ringColor: Color {
        switch displayProgress {
        case 1.0:
            return .green
        case 0.5..<1.0:
            return .blue
        case 0.0..<0.5:
            return .orange
        default:
            return .gray
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: size / 8
                )

            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(
                        lineWidth: size / 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            if displayProgress == 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: size / 3, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Text("\(Int(displayProgress * 100))%")
                    .font(.system(size: size / 4, weight: .semibold, design: .rounded))
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
