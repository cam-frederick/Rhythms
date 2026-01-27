//
//  ConfettiView.swift
//  Rhythms
//
//  Created by Cam Frederick on 12/27/25.
//

import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []

    private let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
    private let particleCount = 50

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    createParticles(in: geometry.size)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isActive = false
                        particles.removeAll()
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                xVelocity: CGFloat.random(in: -100...100),
                yVelocity: CGFloat.random(in: 200...500),
                rotationSpeed: Double.random(in: -360...360),
                shape: ConfettiShape.allCases.randomElement() ?? .circle
            )
        }
    }
}

struct ConfettiPiece: View {
    let particle: ConfettiParticle

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        particle.shape.view
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size * 0.6)
            .rotationEffect(.degrees(rotation))
            .offset(x: particle.x + offset.width, y: particle.y + offset.height)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    offset = CGSize(
                        width: particle.xVelocity,
                        height: particle.yVelocity
                    )
                    rotation = particle.rotation + particle.rotationSpeed
                    opacity = 0
                }
            }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let xVelocity: CGFloat
    let yVelocity: CGFloat
    let rotationSpeed: Double
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle
    case rectangle
    case triangle

    var view: some Shape {
        switch self {
        case .circle:
            return AnyShape(Circle())
        case .rectangle:
            return AnyShape(Rectangle())
        case .triangle:
            return AnyShape(Triangle())
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// MARK: - Streak Milestone Overlay

struct StreakMilestoneOverlay: View {
    let streak: Int
    @Binding var isShowing: Bool

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)
                .onTapGesture {
                    dismiss()
                }

            // Milestone card
            VStack(spacing: 20) {
                Text("🔥")
                    .font(.system(size: 64))

                Text("\(streak) Day Streak!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(milestoneMessage)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    dismiss()
                } label: {
                    Text("Keep Going!")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top)
            }
            .padding(32)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 20)
            .padding(40)
            .scaleEffect(scale)
            .opacity(opacity)

            // Confetti
            ConfettiView(isActive: $showConfetti)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showConfetti = true
            }
        }
    }

    private var milestoneMessage: String {
        switch streak {
        case 7: return "One week strong! 💪"
        case 14: return "Two weeks of dedication!"
        case 21: return "Three weeks! Habit forming!"
        case 30: return "One month! Incredible!"
        case 50: return "50 days! You're unstoppable!"
        case 100: return "100 days! Legendary!"
        case 365: return "ONE YEAR! 🏆"
        default:
            if streak % 100 == 0 {
                return "Amazing milestone!"
            } else if streak % 50 == 0 {
                return "Halfway to \(streak + 50)!"
            } else {
                return "You're on fire!"
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 0.8
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isShowing = false
        }
    }
}

// MARK: - Milestone Detection

extension Int {
    var isStreakMilestone: Bool {
        let milestones = [7, 14, 21, 30, 50, 100, 150, 200, 250, 300, 365, 500, 750, 1000]
        return milestones.contains(self) || (self > 100 && self % 100 == 0)
    }
}

#Preview("Confetti") {
    struct PreviewWrapper: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Button("Trigger Confetti") {
                    showConfetti = true
                }

                ConfettiView(isActive: $showConfetti)
            }
        }
    }

    return PreviewWrapper()
}

#Preview("Milestone Overlay") {
    struct PreviewWrapper: View {
        @State private var showMilestone = true

        var body: some View {
            ZStack {
                Color.blue

                if showMilestone {
                    StreakMilestoneOverlay(streak: 30, isShowing: $showMilestone)
                }
            }
        }
    }

    return PreviewWrapper()
}
