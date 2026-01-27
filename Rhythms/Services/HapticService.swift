//
//  HapticService.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import UIKit

/// Service for providing haptic feedback throughout the app
final class HapticService {
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    init() {
        // Prepare generators for faster response
        lightImpact.prepare()
        mediumImpact.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Feedback Methods

    /// Light tap for subtle interactions
    func playLight() {
        lightImpact.impactOccurred()
    }

    /// Medium tap for confirmations
    func playMedium() {
        mediumImpact.impactOccurred()
    }

    /// Heavy tap for significant actions
    func playHeavy() {
        heavyImpact.impactOccurred()
    }

    /// Selection changed feedback
    func playSelection() {
        selectionFeedback.selectionChanged()
    }

    /// Success feedback for completed actions
    func playSuccess() {
        notificationFeedback.notificationOccurred(.success)
    }

    /// Warning feedback
    func playWarning() {
        notificationFeedback.notificationOccurred(.warning)
    }

    /// Error feedback
    func playError() {
        notificationFeedback.notificationOccurred(.error)
    }

    /// Double tap for milestones (e.g., streak achievements)
    func playMilestone() {
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyImpact.impactOccurred()
        }
    }

    /// Triple celebration for major achievements
    func playCelebration() {
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.notificationFeedback.notificationOccurred(.success)
        }
    }
}
