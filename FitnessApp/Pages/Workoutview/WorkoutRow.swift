//
//  WorkoutRow.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//


import SwiftUI

struct WorkoutRow: View {
    var workout: Workout

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name ?? "Без названия")
                    .font(.headline)
                    .foregroundColor(.black)

                if workout.type == "Силовая" {
                    Text("Вес: \(workout.weight, specifier: "%.1f") кг, Сеты: \(workout.sets), Повторения: \(workout.reps)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else if workout.type == "Кардио" {
                    Text("Дистанция: \(workout.distance, specifier: "%.1f") км, Время: \(workout.time) мин")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()

            // Иконка статуса выполнения
            Image(systemName: workout.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(workout.completed ? .green : .gray)
                .font(.system(size: 24))
        }
        .padding(.vertical, 8)
    }
}
