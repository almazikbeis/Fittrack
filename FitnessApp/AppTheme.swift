//
//  AppTheme.swift
//  FitnessApp

import SwiftUI

// MARK: - Design Tokens

enum DS {
    // Spacing (4pt grid)
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 20
    static let xxl:  CGFloat = 24
    static let xxxl: CGFloat = 32

    // Corner radius
    static let rSM:  CGFloat = 10
    static let rMD:  CGFloat = 14
    static let rLG:  CGFloat = 20
    static let rXL:  CGFloat = 24
    static let rXXL: CGFloat = 28
}

// MARK: - Design System Colors

extension Color {
    // Primary palette
    static let primaryGreen      = Color(red: 0.13, green: 0.77, blue: 0.45)
    static let primaryGreenDark  = Color(red: 0.05, green: 0.55, blue: 0.30)
    static let strengthPurple    = Color(red: 0.40, green: 0.20, blue: 0.90)
    static let strengthPurpleDark = Color(red: 0.20, green: 0.10, blue: 0.70)
    static let cardioOrange      = Color(red: 1.0,  green: 0.45, blue: 0.20)
    static let cardioRed         = Color(red: 0.95, green: 0.25, blue: 0.40)

    // Nutrition
    static let nutritionPurple   = Color(red: 0.55, green: 0.20, blue: 0.90)
    static let nutritionBlue     = Color(red: 0.20, green: 0.60, blue: 1.00)
    static let waterBlue         = Color(red: 0.20, green: 0.55, blue: 1.00)

    // Avatar Elements
    static let airBlue     = Color(red: 0.42, green: 0.72, blue: 0.98)
    static let airLight    = Color(red: 0.82, green: 0.93, blue: 1.00)
    static let waterCyan   = Color(red: 0.08, green: 0.72, blue: 0.88)
    static let waterDeep   = Color(red: 0.04, green: 0.38, blue: 0.68)
    static let earthGreen  = Color(red: 0.22, green: 0.58, blue: 0.28)
    static let earthGold   = Color(red: 0.70, green: 0.56, blue: 0.10)
    static let fireOrange  = Color(red: 0.98, green: 0.48, blue: 0.06)
    static let fireCrimson = Color(red: 0.80, green: 0.10, blue: 0.15)

    // Dark surface tokens
    static let surface0 = Color(red: 0.06, green: 0.06, blue: 0.07)
    static let surface1 = Color(red: 0.11, green: 0.11, blue: 0.12)
    static let surface2 = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let surfaceBorder = Color(.separator)
}

// MARK: - Gradient Presets

extension LinearGradient {
    static let primaryGradient = LinearGradient(
        colors: [.primaryGreen, .primaryGreenDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let strengthGradient = LinearGradient(
        colors: [.strengthPurple, .strengthPurpleDark],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let cardioGradient = LinearGradient(
        colors: [.cardioOrange, .cardioRed],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.08, blue: 0.10),
                 Color(red: 0.05, green: 0.20, blue: 0.40),
                 Color(red: 0.03, green: 0.10, blue: 0.20)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let nutritionGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.20, blue: 0.90), Color(red: 0.30, green: 0.05, blue: 0.65)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let waterGradient = LinearGradient(
        colors: [Color(red: 0.20, green: 0.55, blue: 1.0), Color(red: 0.10, green: 0.35, blue: 0.90)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let snackGradient = LinearGradient(
        colors: [Color(red: 0.20, green: 0.60, blue: 1.0), Color(red: 0.10, green: 0.40, blue: 0.90)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Avatar Element Gradients
    static let airGradient = LinearGradient(
        colors: [Color(red: 0.55, green: 0.82, blue: 1.00), Color(red: 0.25, green: 0.55, blue: 0.92)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let deepWaterGradient = LinearGradient(
        colors: [Color(red: 0.08, green: 0.72, blue: 0.88), Color(red: 0.04, green: 0.35, blue: 0.68)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let earthGradient = LinearGradient(
        colors: [Color(red: 0.28, green: 0.68, blue: 0.34), Color(red: 0.10, green: 0.38, blue: 0.18)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let fireElementGradient = LinearGradient(
        colors: [Color(red: 1.00, green: 0.62, blue: 0.08), Color(red: 0.80, green: 0.12, blue: 0.15)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let avatarGradient = LinearGradient(
        colors: [Color(red: 0.60, green: 0.30, blue: 1.0),
                 Color(red: 0.10, green: 0.50, blue: 0.95),
                 Color(red: 0.98, green: 0.48, blue: 0.06)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Achievement Gradients

extension LinearGradient {
    static let achievementGold = LinearGradient(
        colors: [Color(red: 1, green: 0.85, blue: 0.1), Color(red: 0.85, green: 0.60, blue: 0)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let achievementSilver = LinearGradient(
        colors: [Color(red: 0.75, green: 0.75, blue: 0.78), Color(red: 0.55, green: 0.55, blue: 0.60)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let achievementBronze = LinearGradient(
        colors: [Color(red: 0.80, green: 0.50, blue: 0.20), Color(red: 0.60, green: 0.30, blue: 0.10)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Unified Card Modifier

struct NRCCardModifier: ViewModifier {
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 3)
    }
}

extension View {
    func nrcCard(radius: CGFloat = DS.rLG) -> some View {
        modifier(NRCCardModifier(radius: radius))
    }
}

// MARK: - Section Label

extension Text {
    func nrcLabel() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.secondary)
            .tracking(0.6)
            .textCase(.uppercase)
    }
}

// MARK: - Icon Badge

extension View {
    func iconBadge(color: Color, radius: CGFloat = DS.rMD, size: CGFloat = 44) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            self
        }
    }

    func gradientBadge(_ gradient: LinearGradient, radius: CGFloat = DS.rMD, size: CGFloat = 44) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(gradient)
                .frame(width: size, height: size)
            self
        }
    }
}

// MARK: - Animation Modifiers

struct StaggeredAppear: ViewModifier {
    let index: Int
    let direction: Edge
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(
                x: !appeared && direction == .leading  ? -24 : (!appeared && direction == .trailing ? 24 : 0),
                y: !appeared && direction == .bottom   ? 28 : 0
            )
            .scaleEffect(appeared ? 1 : 0.94)
            .animation(
                .spring(response: 0.52, dampingFraction: 0.8).delay(Double(index) * 0.055),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

extension View {
    func staggeredAppear(index: Int, from direction: Edge = .bottom) -> some View {
        modifier(StaggeredAppear(index: index, direction: direction))
    }
}

struct GlowPulse: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var pulsing = false

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(pulsing ? 0.65 : 0.28),
                    radius: pulsing ? radius * 1.4 : radius * 0.8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}

extension View {
    func glowPulse(color: Color, radius: CGFloat = 14) -> some View {
        modifier(GlowPulse(color: color, radius: radius))
    }
}

extension View {
    func tabPageStyle(isVisible: Bool, index: Int, selected: Int) -> some View {
        let isLeft = index < selected
        return self
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.96)
            .offset(x: isVisible ? 0 : (isLeft ? -18 : 18))
            .animation(.spring(response: 0.38, dampingFraction: 0.84), value: selected)
            .allowsHitTesting(isVisible)
    }
}

// MARK: - Shimmer

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 2)
                    .offset(x: geo.size.width * phase)
                    .onAppear {
                        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                            phase = 1
                        }
                    }
                }
                .clipped()
            )
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
