//
//  AppEnvironment.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

// MARK: - App Environment

/// Container for app-wide services accessible via SwiftUI environment
struct AppEnvironment {
    let hapticService: HapticService
    let notificationService: NotificationService

    init() {
        self.hapticService = HapticService()
        self.notificationService = NotificationService()
    }
}

// MARK: - Environment Keys

private struct AppEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppEnvironment()
}

private struct HapticServiceKey: EnvironmentKey {
    static let defaultValue = HapticService()
}

private struct NotificationServiceKey: EnvironmentKey {
    static let defaultValue = NotificationService()
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }

    var hapticService: HapticService {
        get { self[HapticServiceKey.self] }
        set { self[HapticServiceKey.self] = newValue }
    }

    var notificationService: NotificationService {
        get { self[NotificationServiceKey.self] }
        set { self[NotificationServiceKey.self] = newValue }
    }
}

// MARK: - View Extension for Environment

extension View {
    func withAppEnvironment(_ environment: AppEnvironment) -> some View {
        self
            .environment(\.appEnvironment, environment)
            .environment(\.hapticService, environment.hapticService)
            .environment(\.notificationService, environment.notificationService)
    }
}
