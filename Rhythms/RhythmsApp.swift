//
//  RhythmsApp.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct RhythmsApp: App {
    let modelContainer: ModelContainer
    let appEnvironment: AppEnvironment

    init() {
        // Initialize services
        appEnvironment = AppEnvironment()

        do {
            // Use shared container for App Group support (widgets)
            modelContainer = try SharedModelContainer.makeContainer()

            // Seed default categories on first launch
            seedDefaultCategoriesIfNeeded()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .withAppEnvironment(appEnvironment)
                .rhythmsTheme()
                .task {
                    await appEnvironment.notificationService.registerNotificationCategories()
                }
        }
    }

    private func seedDefaultCategoriesIfNeeded() {
        let context = modelContainer.mainContext

        // Check if categories already exist
        let descriptor = FetchDescriptor<Category>()

        do {
            let existingCount = try context.fetchCount(descriptor)
            guard existingCount == 0 else {
                print("[Rhythms] Found \(existingCount) existing categories, skipping seed")
                return
            }
        } catch {
            print("[Rhythms] Error checking categories: \(error)")
            // If we can't check, don't seed to avoid duplicates
            return
        }

        print("[Rhythms] Seeding default categories...")

        // Create default categories
        for category in Category.createDefaults() {
            context.insert(category)
        }

        do {
            try context.save()
            print("[Rhythms] Successfully seeded default categories")
        } catch {
            print("[Rhythms] Error saving default categories: \(error)")
        }
    }
}
