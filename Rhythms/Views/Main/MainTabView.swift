//
//  MainTabView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case rhythms = "Rhythms"
        case stats = "Stats"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .rhythms: return "list.bullet.circle.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(Tab.today.rawValue, systemImage: Tab.today.icon)
                }
                .tag(Tab.today)

            RhythmListView()
                .tabItem {
                    Label(Tab.rhythms.rawValue, systemImage: Tab.rhythms.icon)
                }
                .tag(Tab.rhythms)

            NavigationStack {
                StatsTabView()
            }
                .tabItem {
                    Label(Tab.stats.rawValue, systemImage: Tab.stats.icon)
                }
                .tag(Tab.stats)

            NavigationStack {
                SettingsView()
            }
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
}
