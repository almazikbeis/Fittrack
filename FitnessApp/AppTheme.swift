//
//  AppTheme.swift
//  FitnessApp
//

import SwiftUI

// MARK: - Design System Colors

extension Color {
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
        colors: [Color(red: 0.13, green: 0.77, blue: 0.45), Color(red: 0.05, green: 0.25, blue: 0.55)],
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

// MARK: - Shimmer Modifier

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

// MARK: - View Extensions

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
