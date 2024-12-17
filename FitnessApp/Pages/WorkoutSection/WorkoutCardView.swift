import SwiftUI

struct WorkoutCardView: View {
    var workout: Workout
    var toggleCompletion: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                // Название тренировки
                Text(workout.name ?? "Без названия")
                    .font(.headline)
                    .foregroundColor(.primary)

                // Детали тренировки в зависимости от типа
                if workout.type == "Силовая" {
                    Text("Вес: \(workout.weight, specifier: "%.1f") кг | Сеты: \(workout.sets) | Повторения: \(workout.reps)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if workout.type == "Кардио" {
                    Text("Дистанция: \(workout.distance, specifier: "%.2f") км | Время: \(formattedTime(Int(workout.time)))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Кнопка статуса выполнения
            Button(action: {
                withAnimation {
                    toggleCompletion()
                }
            }) {
                VStack(spacing: 5) {
                    Image(systemName: workout.completed ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(workout.completed ? .green : .gray)

                    Text(workout.completed ? "Сделано" : "Не сделано")
                        .font(.caption)
                        .foregroundColor(workout.completed ? .green : .gray)
                }
            }
        }
        .padding()
        .background(workout.completed ? Color.green.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .animation(.easeInOut, value: workout.completed)
    }

    // Форматирование времени (секунды в формат MM:SS)
    private func formattedTime(_ time: Int) -> String {
        let minutes = time / 60
        let seconds = time % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

