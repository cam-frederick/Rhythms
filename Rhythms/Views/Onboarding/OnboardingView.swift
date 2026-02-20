//
//  OnboardingView.swift
//  Rhythms
//
//  Created by Cici on 2/19/26.
//

import SwiftUI
import UserNotifications

// MARK: - Onboarding Page Model

struct OnboardingPage: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let description: String
    let accentColor: Color
}

// MARK: - Main Onboarding View

struct OnboardingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool

    @State private var currentPage = 0
    @State private var hasRequestedNotifications = false
    @State private var pageOffset: CGFloat = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🌅",
            title: "Build Better Habits",
            subtitle: "One day at a time",
            description: "Rhythms helps you track the small daily actions that compound into meaningful change. No overwhelming streaks — just steady momentum.",
            accentColor: Color(hex: "#c9a962")!
        ),
        OnboardingPage(
            emoji: "🎯",
            title: "What's a Rhythm?",
            subtitle: "Your daily commitments",
            description: "A rhythm is any habit you want to build — morning workouts, journaling, meditation, reading. You choose the frequency, we help you show up.",
            accentColor: Color(hex: "#34c759")!
        ),
        OnboardingPage(
            emoji: "🔥",
            title: "Streaks That Motivate",
            subtitle: "Every day counts",
            description: "Watch your streak grow day by day. Hit milestones at 7, 14, 21, and 30 days. Miss a day? No shame — just restart and keep going.",
            accentColor: Color(hex: "#ff9500")!
        ),
        OnboardingPage(
            emoji: "📊",
            title: "See Your Progress",
            subtitle: "AI-powered insights",
            description: "Get personalized weekly insights powered by Apple Intelligence. Understand your patterns, celebrate your wins, and spot where to improve.",
            accentColor: Color(hex: "#af52de")!
        )
    ]

    var body: some View {
        ZStack {
            // Background
            ThemeColors.bgPrimary(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(ThemeTypography.labelMedium)
                        .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        Spacer()
                            .frame(height: 44)
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Bottom controls
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage
                                      ? ThemeColors.accentGold
                                      : ThemeColors.textMuted(colorScheme).opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // CTA Button
                    if currentPage == pages.count - 1 {
                        // Notification permission + Get Started
                        VStack(spacing: 12) {
                            if !hasRequestedNotifications {
                                Button {
                                    requestNotifications()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bell.badge.fill")
                                        Text("Enable Reminders")
                                    }
                                    .font(ThemeTypography.labelLarge)
                                    .foregroundStyle(ThemeColors.accentGold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(ThemeColors.accentGold.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    isPresented = false
                                }
                            } label: {
                                Text("Get Started")
                                    .font(ThemeTypography.labelLarge)
                                    .foregroundStyle(
                                        colorScheme == .dark ? Color(hex: "#0c0c0c")! : Color.white
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(ThemeColors.accentGoldGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .font(ThemeTypography.labelLarge)
                            .foregroundStyle(
                                colorScheme == .dark ? Color(hex: "#0c0c0c")! : Color.white
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ThemeColors.accentGoldGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                hasRequestedNotifications = true
            }
        }
    }
}

// MARK: - Single Onboarding Page

struct OnboardingPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    let page: OnboardingPage

    @State private var emojiScale: CGFloat = 0.5
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Emoji hero
            ZStack {
                // Glow ring
                Circle()
                    .fill(page.accentColor.opacity(0.12))
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(page.accentColor.opacity(0.06))
                    .frame(width: 200, height: 200)

                Text(page.emoji)
                    .font(.system(size: 80))
                    .scaleEffect(emojiScale)
            }
            .padding(.bottom, 48)

            // Text content
            VStack(spacing: 16) {
                Text(page.subtitle.uppercased())
                    .font(ThemeTypography.sectionLabel)
                    .tracking(ThemeTypography.sectionLabelTracking)
                    .foregroundStyle(page.accentColor)

                Text(page.title)
                    .font(ThemeTypography.displayMedium)
                    .foregroundStyle(ThemeColors.textPrimary(colorScheme))
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(ThemeTypography.bodyLarge)
                    .foregroundStyle(ThemeColors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            .opacity(contentOpacity)
            .offset(y: contentOffset)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                emojiScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
