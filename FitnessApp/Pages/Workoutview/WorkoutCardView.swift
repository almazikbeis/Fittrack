//
//  WorkoutCardView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//
import SwiftUI

struct WorkoutCardView: View {
    var workout: Workout
    var toggleCompletion: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.name ?? "Без названия")
                    .font(.headline)
                    .foregroundColor(.black)

                if workout.type == "Силовая" {
                    Text("Вес: \(workout.weight, specifier: "%.1f") кг | Сеты: \(workout.sets) | Повторения: \(workout.reps)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if workout.type == "Кардио" {
                    Text("Дистанция: \(workout.distance, specifier: "%.1f") км | Время: \(workout.time) мин")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Кнопка статуса выполнения
            Button(action: {
                withAnimation {
                    toggleCompletion()
                }
            }) {
                VStack {
                    Image(systemName: workout.completed ? "checkmark.circle.fill" : "circle")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(workout.completed ? .green : .gray)

                    if workout.completed {
                        Text("Сделано")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("Не сделано")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(workout.completed ? Color.green.opacity(0.2) : Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        .animation(.easeInOut, value: workout.completed)
    }
}
