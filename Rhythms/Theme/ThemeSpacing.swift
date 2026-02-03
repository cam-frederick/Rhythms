//
//  ThemeSpacing.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

/// Refined/Minimal design system spacing and layout constants
struct ThemeSpacing {

    // MARK: - Base Spacing Scale

    /// 4pt - Minimal spacing between tightly related elements
    static let xs: CGFloat = 4

    /// 8pt - Small spacing for related elements
    static let sm: CGFloat = 8

    /// 16pt - Medium spacing, default padding
    static let md: CGFloat = 16

    /// 24pt - Large spacing for section separation
    static let lg: CGFloat = 24

    /// 32pt - Extra large spacing for major sections
    static let xl: CGFloat = 32

    /// 48pt - Maximum spacing for hero sections
    static let xxl: CGFloat = 48

    // MARK: - Insets

    /// Standard card padding
    static var cardPadding: EdgeInsets {
        EdgeInsets(top: md, leading: md, bottom: md, trailing: md)
    }

    /// Section content padding
    static var sectionPadding: EdgeInsets {
        EdgeInsets(top: lg, leading: md, bottom: lg, trailing: md)
    }

    /// Horizontal screen padding
    static let screenHorizontal: CGFloat = md
}

/// Corner radius constants for the refined/minimal design
struct ThemeRadius {

    /// 4pt - Subtle rounding for small elements (badges, tags)
    static let small: CGFloat = 4

    /// 8pt - Standard rounding for buttons, inputs
    static let medium: CGFloat = 8

    /// 12pt - Cards and larger interactive elements
    static let large: CGFloat = 12

    /// 16pt - Modal sheets, large cards
    static let xlarge: CGFloat = 16

    /// 24pt - Full-screen overlays
    static let xxlarge: CGFloat = 24

    /// Circular (use with .clipShape(Capsule()))
    static let full: CGFloat = 1000
}

/// Animation durations for smooth transitions
struct ThemeAnimation {

    /// Quick interactions (0.15s)
    static let quick: Double = 0.15

    /// Standard transitions (0.25s)
    static let standard: Double = 0.25

    /// Smooth, refined transitions (0.4s)
    static let smooth: Double = 0.4

    /// Slow, dramatic animations (0.6s)
    static let slow: Double = 0.6

    /// Quick ease-in-out animation
    static var quickEase: Animation {
        .easeInOut(duration: quick)
    }

    /// Standard ease-in-out animation
    static var standardEase: Animation {
        .easeInOut(duration: standard)
    }

    /// Smooth ease-in-out animation (primary style)
    static var smoothEase: Animation {
        .easeInOut(duration: smooth)
    }

    /// Refined spring animation
    static var refinedSpring: Animation {
        .spring(duration: smooth, bounce: 0.2)
    }
}

/// Border and stroke styling constants
struct ThemeBorder {

    /// Ultra-thin border width (1pt)
    static let thin: CGFloat = 1

    /// Standard border width (1.5pt)
    static let standard: CGFloat = 1.5

    /// Thick border width for emphasis (2pt)
    static let thick: CGFloat = 2
}
