//
//  ThemeTypography.swift
//  Rhythms
//
//  Created by Cam Frederick on 2/3/26.
//

import SwiftUI

/// Refined/Minimal design system typography
/// Display/Titles: Serif font (New York via .design(.serif))
/// Body/UI: System font (SF Pro)
struct ThemeTypography {

    // MARK: - Display Fonts (Serif)

    /// Large display - hero text, main titles
    /// 34pt serif bold
    static var displayLarge: Font {
        .system(size: 34, weight: .bold, design: .serif)
    }

    /// Medium display - section headers, card titles
    /// 28pt serif semibold
    static var displayMedium: Font {
        .system(size: 28, weight: .semibold, design: .serif)
    }

    /// Small display - sub-section headers
    /// 22pt serif medium
    static var displaySmall: Font {
        .system(size: 22, weight: .medium, design: .serif)
    }

    // MARK: - Title Fonts (Serif)

    /// Title large - navigation titles, modal headers
    /// 20pt serif semibold
    static var titleLarge: Font {
        .system(size: 20, weight: .semibold, design: .serif)
    }

    /// Title medium - card headers
    /// 17pt serif medium
    static var titleMedium: Font {
        .system(size: 17, weight: .medium, design: .serif)
    }

    /// Title small - list item titles
    /// 15pt serif medium
    static var titleSmall: Font {
        .system(size: 15, weight: .medium, design: .serif)
    }

    // MARK: - Body Fonts (San Francisco)

    /// Body large - primary content
    /// 17pt regular
    static var bodyLarge: Font {
        .system(size: 17, weight: .regular)
    }

    /// Body medium - secondary content
    /// 15pt regular
    static var bodyMedium: Font {
        .system(size: 15, weight: .regular)
    }

    /// Body small - supporting content
    /// 13pt regular
    static var bodySmall: Font {
        .system(size: 13, weight: .regular)
    }

    // MARK: - Label Fonts

    /// Label large - buttons, important labels
    /// 15pt semibold
    static var labelLarge: Font {
        .system(size: 15, weight: .semibold)
    }

    /// Label medium - standard labels
    /// 13pt medium
    static var labelMedium: Font {
        .system(size: 13, weight: .medium)
    }

    /// Label small - badges, tags
    /// 11pt medium
    static var labelSmall: Font {
        .system(size: 11, weight: .medium)
    }

    // MARK: - Section Label (Uppercase)

    /// Section label - 11pt uppercase with 2pt tracking
    /// Used for section headers like "RHYTHMS", "COMPLETED"
    static var sectionLabel: Font {
        .system(size: 11, weight: .semibold)
    }

    /// Tracking for section labels (2pt)
    static let sectionLabelTracking: CGFloat = 2

    // MARK: - Numeric Fonts

    /// Large numbers - progress counts, stats
    /// 36pt rounded bold
    static var numericLarge: Font {
        .system(size: 36, weight: .bold, design: .rounded)
    }

    /// Medium numbers - secondary stats
    /// 24pt rounded semibold
    static var numericMedium: Font {
        .system(size: 24, weight: .semibold, design: .rounded)
    }

    /// Small numbers - inline counts
    /// 17pt rounded medium
    static var numericSmall: Font {
        .system(size: 17, weight: .medium, design: .rounded)
    }

    // MARK: - Caption Fonts

    /// Caption - timestamps, metadata
    /// 12pt regular
    static var caption: Font {
        .system(size: 12, weight: .regular)
    }

    /// Caption emphasized - important metadata
    /// 12pt medium
    static var captionEmphasis: Font {
        .system(size: 12, weight: .medium)
    }
}
