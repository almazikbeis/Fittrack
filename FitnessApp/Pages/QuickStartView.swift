//
//  QuickStartView.swift
//  FitnessApp
//

import SwiftUI

struct QuickStartView: View {
    @Binding var selectedTab:       Int
    @Binding var showActiveWorkout: Bool
    @Binding var activeWorkoutType: String
    @Binding var showTracking:      Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            // Title
            VStack(spacing: 4) {
                Text("Начать тренировку")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                Text("Выберите тип активности")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 24)

            // Options
            VStack(spacing: 14) {
                startCard(
                    icon:     "dumbbell.fill",
                    title:    "Силовая тренировка",
                    subtitle: "Упражнения со штангой, гантелями",
                    gradient: .strengthGradient
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        activeWorkoutType = "Силовая"
                        showActiveWorkout  = true
                    }
                }

                startCard(
                    icon:     "figure.run",
                    title:    "Пробежка",
                    subtitle: "GPS трекинг маршрута и темпа",
                    gradient: .cardioGradient
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showTracking = true
                    }
                }

                startCard(
                    icon:     "bicycle",
                    title:    "Кардио",
                    subtitle: "Велосипед, плавание, эллипс...",
                    gradient: LinearGradient(
                        colors: [Color(red: 0.20, green: 0.60, blue: 1.0),
                                 Color(red: 0.10, green: 0.40, blue: 0.90)],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                ) {
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        activeWorkoutType = "Кардио"
                        showActiveWorkout  = true
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func startCard(icon: String, title: String, subtitle: String,
                           gradient: LinearGradient, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
