//
//  StatsTabView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct StatsTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSection: StatsSection = .overview

    enum StatsSection: String, CaseIterable {
        case overview = "Overview"
        case calendar = "Calendar"
        case insights = "Insights"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section picker
            Picker("Section", selection: $selectedSection) {
                ForEach(StatsSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(ThemeSpacing.md)

            // Content
            Group {
                switch selectedSection {
                case .overview:
                    StatisticsView()
                case .calendar:
                    ScrollView {
                        CalendarHeatMapView()
                            .padding(ThemeSpacing.md)
                    }
                case .insights:
                    InsightsView()
                }
            }
        }
        .background(ThemeColors.bgPrimary(colorScheme))
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StatsTabView()
    }
    .modelContainer(for: [Rhythm.self, RhythmEntry.self], inMemory: true)
}
