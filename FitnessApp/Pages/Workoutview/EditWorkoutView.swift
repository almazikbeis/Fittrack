//
//  EditWorkoutView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import SwiftUI

struct EditWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    var workout: Workout

    @State private var name: String
    @State private var type: String
    @State private var weight: Int
    @State private var sets: Int
    @State private var reps: Int
    @State private var distance: Int
    @State private var time: Int
    @State private var date: Date

    init(workout: Workout) {
        self.workout = workout
        _name = State(initialValue: workout.name ?? "")
        _type = State(initialValue: workout.type ?? "Силовая")
        _weight = State(initialValue: Int(workout.weight))
        _sets = State(initialValue: Int(workout.sets))
        _reps = State(initialValue: Int(workout.reps))
        _distance = State(initialValue: Int(workout.distance))
        _time = State(initialValue: Int(workout.time))
        _date = State(initialValue: workout.date ?? Date())
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all) // Фоновый цвет формы

                Form {
                    Section(header: Text("Информация")
                        .font(.headline)
                        .foregroundColor(.blue)) {
                        TextField("Название тренировки", text: $name)
                            .foregroundColor(.primary)
                    }

                    Section(header: Text("Тип тренировки")
                        .font(.headline)
                        .foregroundColor(.blue)) {
                        Picker("Тип тренировки", selection: $type) {
                            ForEach(["Силовая", "Кардио"], id: \.self) { type in
                                Text(type)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .foregroundColor(.blue)
                    }

                    if type == "Силовая" {
                        Section(header: Text("Силовая тренировка")
                            .font(.headline)
                            .foregroundColor(.blue)) {
                            Stepper("Вес: \(weight) кг", value: $weight, in: 1...1000)
                                .accentColor(.blue)
                            Stepper("Сеты: \(sets)", value: $sets, in: 1...20)
                                .accentColor(.blue)
                            Stepper("Повторения: \(reps)", value: $reps, in: 1...50)
                                .accentColor(.blue)
                        }
                    } else if type == "Кардио" {
                        Section(header: Text("Кардио тренировка")
                            .font(.headline)
                            .foregroundColor(.blue)) {
                            Stepper("Дистанция: \(distance) км", value: $distance, in: 1...100)
                                .accentColor(.blue)
                            Stepper("Время: \(time) мин", value: $time, in: 1...300)
                                .accentColor(.blue)
                        }
                    }

                    Section(header: Text("Дата")
                        .font(.headline)
                        .foregroundColor(.blue)) {
                        DatePicker("Дата", selection: $date, displayedComponents: .date)
                            .accentColor(.blue)
                    }
                }
                .background(Color(.systemGroupedBackground)) // Фон для формы
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Отмена")
                        .foregroundColor(.blue)
                        .bold()
                },
                trailing: Button(action: {
                    saveChanges()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Сохранить")
                        .foregroundColor(.blue)
                        .bold()
                }
            )
        }
    }

    private func saveChanges() {
        workout.name = name
        workout.type = type
        workout.weight = Double(weight)
        workout.sets = Int16(sets)
        workout.reps = Int16(reps)
        workout.distance = Double(distance)
        workout.time = Int16(time)
        workout.date = date

        do {
            try viewContext.save()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
}
