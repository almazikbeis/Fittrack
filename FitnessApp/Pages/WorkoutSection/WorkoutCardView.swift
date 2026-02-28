import SwiftUI

struct WorkoutCardView: View {
    var workout: Workout
    var toggleCompletion: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Type icon badge
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(iconGradient)
                    .frame(width: 54, height: 54)
                Image(systemName: iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
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
                        .foregroundColor(.secondary.opacity(0.7))
                        .lineLimit(1)
                        .italic()
                }

                Text(workout.type ?? "")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(typeColor.opacity(0.12))
                    .cornerRadius(6)
            }

            Spacer()

            // Completion button
            Button(action: toggleCompletion) {
                ZStack {
                    Circle()
                        .fill(workout.completed ? Color.primaryGreen : Color(.systemGray5))
                        .frame(width: 36, height: 36)
                    if workout.completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .shadow(color: workout.completed ? Color.primaryGreen.opacity(0.35) : .clear, radius: 6, x: 0, y: 3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(workout.completed ? 0.04 : 0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(workout.completed ? Color.primaryGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
        .opacity(workout.completed ? 0.88 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: workout.completed)
    }

    // MARK: - Helpers

    private var iconName: String {
        workout.type == "Силовая" ? "dumbbell.fill" : "figure.run"
    }

    private var iconGradient: LinearGradient {
        workout.type == "Силовая" ? .strengthGradient : .cardioGradient
    }

    private var typeColor: Color {
        workout.type == "Силовая" ? .strengthPurple : .cardioOrange
    }

    private var detailsText: String {
        if workout.type == "Силовая" {
            return "\(Int(workout.weight)) кг  •  \(workout.sets) сета  •  \(workout.reps) повт."
        } else {
            return "\(String(format: "%.1f", workout.distance)) км  •  \(formattedTime(Int(workout.time)))"
        }
    }

    private func formattedTime(_ time: Int) -> String {
        if time >= 60 { return "\(time / 60) ч \(time % 60) мин" }
        return "\(time) мин"
    }
}
