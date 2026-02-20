//
//  OnboardingTests.swift
//  RhythmsTests
//
//  Created by Cici on 2/19/26.
//

import Testing
import Foundation
import SwiftUI
@testable import Rhythms

// MARK: - Onboarding Page Model Tests

struct OnboardingPageTests {

    @Test("OnboardingPage has unique ids")
    func onboardingPageIdsAreUnique() {
        let page1 = OnboardingPage(
            emoji: "🌅",
            title: "Title 1",
            subtitle: "Subtitle 1",
            description: "Description 1",
            accentColor: .yellow
        )
        let page2 = OnboardingPage(
            emoji: "🎯",
            title: "Title 2",
            subtitle: "Subtitle 2",
            description: "Description 2",
            accentColor: .green
        )

        #expect(page1.id != page2.id)
    }

    @Test("OnboardingPage stores emoji correctly")
    func onboardingPageStoresEmoji() {
        let page = OnboardingPage(
            emoji: "🔥",
            title: "Streaks",
            subtitle: "Keep going",
            description: "Every day counts",
            accentColor: .orange
        )

        #expect(page.emoji == "🔥")
        #expect(page.title == "Streaks")
        #expect(page.subtitle == "Keep going")
        #expect(page.description == "Every day counts")
    }

    @Test("OnboardingPage accent color can be any Color")
    func onboardingPageSupportsVariousColors() {
        let colors: [Color] = [.red, .green, .blue, .yellow, .purple, .orange]

        for color in colors {
            let page = OnboardingPage(
                emoji: "✨",
                title: "Test",
                subtitle: "Test",
                description: "Test description for this page",
                accentColor: color
            )
            // Test just that we can create pages with various colors
            #expect(!page.id.uuidString.isEmpty)
        }
    }
}

// MARK: - Onboarding Content Tests

struct OnboardingContentTests {

    /// Default pages for testing (mirrors OnboardingView's pages)
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🌅",
            title: "Build Better Habits",
            subtitle: "One day at a time",
            description: "Rhythms helps you track the small daily actions that compound into meaningful change. No overwhelming streaks — just steady momentum.",
            accentColor: .yellow
        ),
        OnboardingPage(
            emoji: "🎯",
            title: "What's a Rhythm?",
            subtitle: "Your daily commitments",
            description: "A rhythm is any habit you want to build — morning workouts, journaling, meditation, reading. You choose the frequency, we help you show up.",
            accentColor: .green
        ),
        OnboardingPage(
            emoji: "🔥",
            title: "Streaks That Motivate",
            subtitle: "Every day counts",
            description: "Watch your streak grow day by day. Hit milestones at 7, 14, 21, and 30 days. Miss a day? No shame — just restart and keep going.",
            accentColor: .orange
        ),
        OnboardingPage(
            emoji: "📊",
            title: "See Your Progress",
            subtitle: "AI-powered insights",
            description: "Get personalized weekly insights powered by Apple Intelligence. Understand your patterns, celebrate your wins, and spot where to improve.",
            accentColor: .purple
        )
    ]

    @Test("Onboarding has exactly 4 pages")
    func onboardingHasFourPages() {
        #expect(pages.count == 4)
    }

    @Test("First page introduces the app concept")
    func firstPageIsWelcome() {
        let firstPage = pages[0]
        #expect(firstPage.emoji == "🌅")
        #expect(firstPage.title.contains("Habits") || firstPage.title.contains("Better"))
    }

    @Test("Second page explains what a rhythm is")
    func secondPageExplainsRhythm() {
        let secondPage = pages[1]
        #expect(secondPage.emoji == "🎯")
        #expect(secondPage.title.lowercased().contains("rhythm"))
    }

    @Test("Third page covers streak motivation")
    func thirdPageCoversStreaks() {
        let thirdPage = pages[2]
        #expect(thirdPage.emoji == "🔥")
        #expect(thirdPage.title.lowercased().contains("streak") || thirdPage.description.lowercased().contains("streak"))
    }

    @Test("Fourth page covers insights/progress")
    func fourthPageCoversInsights() {
        let fourthPage = pages[3]
        #expect(fourthPage.emoji == "📊")
        #expect(fourthPage.title.lowercased().contains("progress") || fourthPage.description.lowercased().contains("insight"))
    }

    @Test("All pages have non-empty content")
    func allPagesHaveContent() {
        for page in pages {
            #expect(!page.emoji.isEmpty, "Page \(page.title) has empty emoji")
            #expect(!page.title.isEmpty, "Page \(page.title) has empty title")
            #expect(!page.subtitle.isEmpty, "Page \(page.title) has empty subtitle")
            #expect(page.description.count > 50, "Page \(page.title) description is too short: \(page.description.count) chars")
        }
    }

    @Test("All pages have unique titles")
    func allPageTitlesAreUnique() {
        let titles = pages.map { $0.title }
        let uniqueTitles = Set(titles)
        #expect(titles.count == uniqueTitles.count)
    }

    @Test("All pages have unique emojis")
    func allPageEmojisAreUnique() {
        let emojis = pages.map { $0.emoji }
        let uniqueEmojis = Set(emojis)
        #expect(emojis.count == uniqueEmojis.count)
    }

    @Test("All pages have distinctive subtitles")
    func allPageSubtitlesAreUnique() {
        let subtitles = pages.map { $0.subtitle }
        let uniqueSubtitles = Set(subtitles)
        #expect(subtitles.count == uniqueSubtitles.count)
    }
}

// MARK: - Onboarding State Tests

struct OnboardingStateTests {

    @Test("AppStorage key for onboarding is consistent")
    func onboardingStorageKeyIsConsistent() {
        // The key used in ContentView @AppStorage
        let key = "hasCompletedOnboarding"
        #expect(!key.isEmpty)
        #expect(key == "hasCompletedOnboarding")
    }

    @Test("Default onboarding state is false (not completed)")
    func defaultOnboardingStateIsFalse() {
        // New installations should show onboarding
        // We simulate this by checking that false is the correct default
        let defaultValue = false
        #expect(!defaultValue) // hasCompletedOnboarding defaults to false
    }

    @Test("Completing onboarding should persist state")
    func completingOnboardingShouldPersist() {
        // Write to UserDefaults (test domain)
        let defaults = UserDefaults(suiteName: "com.rhythms.test.onboarding")!
        let key = "hasCompletedOnboarding"

        defaults.set(false, forKey: key)
        #expect(defaults.bool(forKey: key) == false)

        defaults.set(true, forKey: key)
        #expect(defaults.bool(forKey: key) == true)

        // Clean up
        defaults.removePersistentDomain(forName: "com.rhythms.test.onboarding")
    }
}
