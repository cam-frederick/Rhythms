//
//  SharedModelContainer.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import Foundation
import SwiftData

/// Shared configuration for SwiftData container used by both the main app and widgets.
/// Uses App Groups to share data between the main app and widget extension.
enum SharedModelContainer {
    /// The App Group identifier - must match the one configured in Xcode
    /// Format: group.{bundle-id}
    static let appGroupIdentifier = "group.com.camfrederick.Rhythms"

    /// Schema containing all SwiftData models
    static var schema: Schema {
        Schema([
            Rhythm.self,
            RhythmEntry.self,
            RhythmNote.self,
            Category.self
        ])
    }

    /// Returns the URL for the shared container directory
    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// Legacy store URL (original location before App Groups)
    static var legacyStoreURL: URL {
        URL.applicationSupportDirectory
            .appending(path: "Rhythms")
            .appending(path: "Rhythms.store")
    }

    /// App Groups store URL
    static var appGroupStoreURL: URL? {
        guard let containerURL = sharedContainerURL else { return nil }
        return containerURL
            .appending(path: "Library")
            .appending(path: "Application Support")
            .appending(path: "Rhythms.store")
    }

    /// Returns the URL for the SwiftData store, handling migration from legacy location
    /// NOTE: Widgets can ONLY access App Groups container, so we must use that when available
    static var sharedStoreURL: URL {
        let legacyURL = legacyStoreURL
        let legacyExists = FileManager.default.fileExists(atPath: legacyURL.path)

        // Debug logging
        print("[Rhythms] Legacy URL: \(legacyURL.path)")
        print("[Rhythms] Legacy exists: \(legacyExists)")

        // If App Groups is configured, we MUST use it for widget compatibility
        if let appGroupURL = appGroupStoreURL {
            let appGroupExists = FileManager.default.fileExists(atPath: appGroupURL.path)
            print("[Rhythms] App Group URL: \(appGroupURL.path)")
            print("[Rhythms] App Group exists: \(appGroupExists)")

            // Migrate legacy data if it exists and App Group doesn't have data yet
            if legacyExists && !appGroupExists {
                print("[Rhythms] Migrating data from legacy to App Group...")
                migrateToAppGroup(from: legacyURL, to: appGroupURL)
            }
            // Also migrate if legacy has more data (user's real data vs empty schema)
            else if legacyExists && appGroupExists && shouldMigrateLegacyData(legacyURL: legacyURL, appGroupURL: appGroupURL) {
                print("[Rhythms] Legacy has more data - force migrating...")
                migrateToAppGroup(from: legacyURL, to: appGroupURL, force: true)
            }

            print("[Rhythms] Using App Group store location")
            return appGroupURL
        }

        // Fallback to legacy location only if App Groups not configured
        print("[Rhythms] App Groups not configured, using legacy location")
        return legacyURL
    }

    /// Checks if legacy store has more data than App Groups store
    private static func shouldMigrateLegacyData(legacyURL: URL, appGroupURL: URL) -> Bool {
        let fileManager = FileManager.default

        // Get legacy file size
        let legacySize = (try? fileManager.attributesOfItem(atPath: legacyURL.path)[.size] as? Int) ?? 0

        // Get App Groups file size
        let appGroupSize = (try? fileManager.attributesOfItem(atPath: appGroupURL.path)[.size] as? Int) ?? 0

        print("[Rhythms] Legacy size: \(legacySize) bytes, App Group size: \(appGroupSize) bytes")

        // Migrate if legacy is significantly larger (has real data vs just schema)
        return legacySize > appGroupSize + 1000
    }

    /// Migrates data from legacy location to App Group container
    private static func migrateToAppGroup(from source: URL, to destination: URL, force: Bool = false) {
        let fileManager = FileManager.default

        do {
            // Ensure destination directory exists
            try fileManager.createDirectory(
                at: destination.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            // Remove existing destination files if force migrating
            if force {
                let destDir = destination.deletingLastPathComponent()
                let storeName = destination.lastPathComponent
                if let contents = try? fileManager.contentsOfDirectory(atPath: destDir.path) {
                    for file in contents where file.hasPrefix(storeName) {
                        let destFile = destDir.appending(path: file)
                        try? fileManager.removeItem(at: destFile)
                    }
                }
                print("[Rhythms] Removed existing App Group data for migration")
            }

            // Copy all store files (main file and associated -wal, -shm files)
            let sourceDir = source.deletingLastPathComponent()
            let destDir = destination.deletingLastPathComponent()
            let storeName = source.lastPathComponent

            let contents = try fileManager.contentsOfDirectory(atPath: sourceDir.path)

            for file in contents where file.hasPrefix(storeName) {
                let sourceFile = sourceDir.appending(path: file)
                let destFile = destDir.appending(path: file)
                try fileManager.copyItem(at: sourceFile, to: destFile)
            }

            print("[Rhythms] Successfully migrated data to App Group container")
        } catch {
            print("[Rhythms] Failed to migrate data: \(error)")
        }
    }

    /// Creates the ModelContainer for the main app
    /// - Parameter inMemory: If true, creates an in-memory store (for previews/testing)
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let storeURL = inMemory ? URL(fileURLWithPath: "/dev/null") : sharedStoreURL

        // Ensure directory exists
        if !inMemory {
            try? FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        }

        let modelConfiguration = ModelConfiguration(
            "Rhythms",
            schema: schema,
            url: storeURL,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }

    /// Creates a read-only ModelContainer for widgets
    /// Widgets should only read data, not write
    static func makeWidgetContainer() throws -> ModelContainer {
        let storeURL = sharedStoreURL

        let modelConfiguration = ModelConfiguration(
            "Rhythms",
            schema: schema,
            url: storeURL,
            allowsSave: false,  // Widgets should not write
            cloudKitDatabase: .none  // Widgets don't sync directly
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
