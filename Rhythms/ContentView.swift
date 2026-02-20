//
//  ContentView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var showingOnboarding: Bool = false

    var body: some View {
        MainTabView()
            .onAppear {
                if !hasCompletedOnboarding {
                    // Small delay so the main UI renders first (better perceived performance)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingOnboarding = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showingOnboarding, onDismiss: {
                hasCompletedOnboarding = true
            }) {
                OnboardingView(isPresented: $showingOnboarding)
            }
    }
}

#Preview {
    ContentView()
}
