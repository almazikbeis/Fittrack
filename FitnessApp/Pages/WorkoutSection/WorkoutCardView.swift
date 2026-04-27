import SwiftUI

struct WorkoutCardView: View {
    var workout: Workout
    var toggleCompletion: () -> Void

    @State private var checkScale: CGFloat = 1
    @State private var cardPressing = false
    @StateObject private var gam = GamificationEngine.shared

    private var isStrength: Bool { workout.type == "Силовая" }
    private var typeColor:  Color { isStrength ? .strengthPurple : .cardioOrange }

    var body: some View {
        HStack(spacing: DS.md) {
            // Gradient icon badge
            Image(systemName: isStrength ? "dumbbell.fill" : "figure.run")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .gradientBadge(
                    isStrength ? .strengthGradient : .cardioGradient,
                    radius: DS.rMD, size: 52
                )
                .shadow(color: typeColor.opacity(0.35), radius: 8, x: 0, y: 4)
                .scaleEffect(cardPressing ? 0.92 : 1.0)

            // Content
            VStack(alignment: .leading, spacing: DS.xs) {
                Text(workout.name ?? "Без названия")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(detailsText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let notes = workout.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.65))
                        .lineLimit(1)
                        .italic()
                }

                // Type chip
                Text(workout.type ?? "")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(typeColor)
                    .padding(.horizontal, DS.sm).padding(.vertical, 3)
                    .background(typeColor.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
            }

            Spacer()

            // Completion button
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    toggleCompletion()
                    checkScale = 1.5
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.08)) {
                    checkScale = 1.0
                }
                if !workout.completed {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(workout.completed
                              ? AnyShapeStyle(LinearGradient.primaryGradient)
                              : AnyShapeStyle(Color(.secondarySystemBackground)))
                        .frame(width: 38, height: 38)
                        .shadow(
                            color: workout.completed ? Color.primaryGreen.opacity(0.45) : .clear,
                            radius: 8, x: 0, y: 3
                        )

                    if workout.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(checkScale)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: workout.completed)
            }
            .buttonStyle(.plain)
        }
        .padding(DS.lg)
        .background(
            RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(workout.completed ? 0.12 : 0.22),
                        radius: 14, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                .stroke(
                    workout.completed ? Color.primaryGreen.opacity(0.35) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .opacity(workout.completed ? 0.80 : 1.0)
        .scaleEffect(cardPressing ? 0.98 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: workout.completed)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: cardPressing)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in cardPressing = true }
                .onEnded   { _ in cardPressing = false }
        )
    }

    private var detailsText: String {
        if isStrength {
            return "\(Int(workout.weight)) кг  ·  \(workout.sets)×\(workout.reps)"
        } else {
            return "\(String(format: "%.1f", workout.distance)) км  ·  \(formattedTime(Int(workout.time)))"
        }
    }

    private func formattedTime(_ t: Int) -> String {
        t >= 60 ? "\(t / 60) ч \(t % 60) мин" : "\(t) мин"
    }
}
