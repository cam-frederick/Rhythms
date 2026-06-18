//
//  AllDoneCelebrationOverlay.swift
//  Rhythms
//
//  Created by Cici on 4/3/26.
//

import SwiftUI

// MARK: - Particle

private struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var size: CGFloat
    var angle: Double
    var speed: CGFloat
    var opacity: Double
}

// MARK: - All Done Celebration Overlay

struct AllDoneCelebrationOverlay: View {
    @Binding var isShowing: Bool
    @State private var particles: [Particle] = []
    @State private var shimmerOpacity: Double = 0
    @State private var textScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    @State private var particleProgress: CGFloat = 0

    private let celebrationColors: [Color] = [
        .yellow, .orange, .green, .blue, .purple, .pink
    ]

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // Shimmer / glow background
            RoundedRectangle(cornerRadius: 32)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.15),
                            Color.green.opacity(0.10),
                            Color.yellow.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 260)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.yellow.opacity(0.4), lineWidth: 1.5)
                )
                .opacity(shimmerOpacity)

            // Particle canvas
            Canvas { context, size in
                for particle in particles {
                    let rect = CGRect(
                        x: particle.x - particle.size / 2,
                        y: particle.y - particle.size / 2,
                        width: particle.size,
                        height: particle.size
                    )
                    context.opacity = particle.opacity
                    context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                }
            }
            .frame(width: 320, height: 320)
            .allowsHitTesting(false)

            // Message card
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 56))

                Text("All done!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("You completed every rhythm today.\nKeep the momentum going! 🔥")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    dismiss()
                } label: {
                    Text("Let's go!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.yellow)
                        )
                }
                .padding(.top, 4)
            }
            .padding(32)
            .scaleEffect(textScale)
            .opacity(textOpacity)
        }
        .onAppear {
            startAnimation()
        }
    }

    private func startAnimation() {
        spawnParticles()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
            textScale = 1.0
            textOpacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.3)) {
            shimmerOpacity = 1.0
        }
    }

    private func spawnParticles() {
        let centerX: CGFloat = 160
        let centerY: CGFloat = 160
        let count = 40

        particles = (0..<count).map { i in
            let angle = Double(i) * (360.0 / Double(count))
            let speed = CGFloat.random(in: 40...130)
            return Particle(
                x: centerX,
                y: centerY,
                color: celebrationColors[i % celebrationColors.count],
                size: CGFloat.random(in: 5...12),
                angle: angle,
                speed: speed,
                opacity: Double.random(in: 0.7...1.0)
            )
        }

        // Animate particles outward over 0.8s, then fade
        withAnimation(.easeOut(duration: 0.8)) {
            for i in particles.indices {
                let radians = particles[i].angle * .pi / 180
                particles[i].x = centerX + cos(radians) * particles[i].speed
                particles[i].y = centerY + sin(radians) * particles[i].speed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6)) {
                for i in particles.indices {
                    particles[i].opacity = 0
                }
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) {
            textScale = 0.85
            textOpacity = 0
            shimmerOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

#Preview {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        AllDoneCelebrationOverlay(isShowing: .constant(true))
    }
}
