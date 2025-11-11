//
//  ParticleBurstView.swift
//  thinqsync
//
//  Particle burst effect for star favorite toggle
//

import SwiftUI

struct ParticleBurstView: View {
    let center: CGPoint
    let color: Color
    @State private var particles: [Particle] = []
    @State private var isAnimating = false

    var body: some View {
        Canvas { context, size in
            for particle in particles {
                // Calculate position
                let x = center.x + cos(particle.angle) * particle.distance
                let y = center.y + sin(particle.angle) * particle.distance

                // Draw particle
                var contextCopy = context
                contextCopy.opacity = particle.opacity

                let rect = CGRect(x: x - 3, y: y - 3, width: 6, height: 6)
                contextCopy.fill(
                    Circle().path(in: rect),
                    with: .color(color)
                )
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }

    private func createParticles() {
        particles = (0..<8).map { i in
            let angle = (Double.pi * 2.0 * Double(i)) / 8.0
            return Particle(
                position: center,
                angle: angle,
                distance: 0,
                opacity: 1.0
            )
        }
    }

    private func animateParticles() {
        withAnimation(.easeOut(duration: 0.8)) {
            for i in 0..<particles.count {
                particles[i].distance = 30
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Particle Burst Overlay

struct ParticleBurstOverlay: View {
    @Binding var triggers: [ParticleBurstTrigger]
    let color: Color

    var body: some View {
        ZStack {
            ForEach(triggers) { trigger in
                ParticleBurstView(center: trigger.position, color: color)
                    .onAppear {
                        // Remove trigger after animation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            triggers.removeAll { $0.id == trigger.id }
                        }
                    }
            }
        }
        .allowsHitTesting(false)
    }
}

struct ParticleBurstTrigger: Identifiable {
    let id = UUID()
    let position: CGPoint
}
