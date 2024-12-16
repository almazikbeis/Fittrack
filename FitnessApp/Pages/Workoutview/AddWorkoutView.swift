//
//  AddWorkoutView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//
import SwiftUI

struct AddWorkoutView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode

    @State private var name = ""
    @State private var type = "Силовая"
    @State private var weight: Int = 50
    @State private var sets: Int = 3
    @State private var reps: Int = 10
    @State private var distance: Int = 5
    @State private var time: Int = 30
    @State private var date: Date

    let workoutTypes = ["Силовая", "Кардио"]

    init(selectedDate: Date) {
        self._date = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6) // Фон
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Заголовок
                    Text("Добавить тренировку")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.green)
                        .transition(.slide)

                    Form {
                        Section(header: Text("Информация").foregroundColor(.green)) {
                            TextField("Название тренировки", text: $name)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Picker("Тип тренировки", selection: $type) {
                                ForEach(workoutTypes, id: \.self) { workoutType in
                                    Text(workoutType)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .transition(.opacity)
                        }

                        if type == "Силовая" {
                            Section(header: Text("Силовая тренировка").foregroundColor(.green)) {
                                animatedPicker(label: "Вес:", value: $weight, range: 1...1000, unit: "кг")
                                animatedPicker(label: "Сеты:", value: $sets, range: 1...20, unit: "")
                                animatedPicker(label: "Повторения:", value: $reps, range: 1...50, unit: "")
                            }
                        } else if type == "Кардио" {
                            Section(header: Text("Кардио тренировка").foregroundColor(.green)) {
                                Stepper("Дистанция: \(distance) км", value: $distance, in: 1...100)
                                Stepper("Время: \(time) мин", value: $time, in: 1...300)
                            }
                        }

                        Section(header: Text("Дата").foregroundColor(.green)) {
                            DatePicker("Дата", selection: $date, displayedComponents: .date)
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 5)

                    // Кнопки
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Text("Отмена")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }

                        Button(action: saveWorkout) {
                            Text("Сохранить")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .animation(.easeInOut, value: type)
    }

    private func animatedPicker(label: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.green)
            Spacer()
            Picker("", selection: value) {
                ForEach(range, id: \.self) { i in
                    Text("\(i) \(unit)")
                }
            }
            .pickerStyle(WheelPickerStyle())
            .frame(width: 120, height: 120)
            .clipped()
        }
    }

    private func saveWorkout() {
        let newWorkout = Workout(context: viewContext)
        newWorkout.id = UUID()
        newWorkout.name = name
        newWorkout.type = type
        newWorkout.date = date

        if type == "Силовая" {
            newWorkout.weight = Double(weight)
            newWorkout.sets = Int16(sets)
            newWorkout.reps = Int16(reps)
        } else if type == "Кардио" {
            newWorkout.distance = Double(distance)
            newWorkout.time = Int16(time)
        }

        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Ошибка сохранения: \(error)")
        }
    }
}
