//
//  EditWorkoutView.swift
//  FitnessApp
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
    @State private var notes: String

    init(workout: Workout) {
        self.workout = workout
        _name     = State(initialValue: workout.name ?? "")
        _type     = State(initialValue: workout.type ?? "Силовая")
        _weight   = State(initialValue: Int(workout.weight))
        _sets     = State(initialValue: Int(workout.sets))
        _reps     = State(initialValue: Int(workout.reps))
        _distance = State(initialValue: Int(workout.distance))
        _time     = State(initialValue: Int(workout.time))
        _date     = State(initialValue: workout.date ?? Date())
        _notes    = State(initialValue: workout.notes ?? "")
    }

    private let workoutTypes = ["Силовая", "Кардио"]

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Тип тренировки
                        typeSelectorSection

                        // Название
                        nameSection

                        // Параметры
                        if type == "Силовая" {
                            strengthSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            cardioSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }

                        // Заметки
                        notesSection

                        // Дата
                        dateSection

                        // Кнопка сохранить
                        Button(action: saveChanges) {
                            Text("Сохранить изменения")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    Group {
                                        if name.isEmpty {
                                            RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray4))
                                        } else {
                                            RoundedRectangle(cornerRadius: 16).fill(LinearGradient.primaryGradient)
                                        }
                                    }
                                )
                                .foregroundColor(name.isEmpty ? .secondary : .white)
                                .shadow(color: name.isEmpty ? .clear : Color.primaryGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                        }
                        .disabled(name.isEmpty)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: type)
        }
    }

    // MARK: - Type Selector

    private var typeSelectorSection: some View {
        HStack(spacing: 10) {
            ForEach(workoutTypes, id: \.self) { workoutType in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        type = workoutType
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: workoutType == "Силовая" ? "dumbbell.fill" : "figure.run")
                            .font(.system(size: 24, weight: .medium))
                        Text(workoutType)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(type == workoutType ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if type == workoutType && workoutType == "Силовая" {
                                RoundedRectangle(cornerRadius: 16).fill(LinearGradient.strengthGradient)
                            } else if type == workoutType && workoutType == "Кардио" {
                                RoundedRectangle(cornerRadius: 16).fill(LinearGradient.cardioGradient)
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground))
                            }
                        }
                    )
                    .shadow(
                        color: type == workoutType
                            ? (workoutType == "Силовая" ? Color.strengthPurple.opacity(0.3) : Color.cardioOrange.opacity(0.3))
                            : .black.opacity(0.05),
                        radius: 8, x: 0, y: 3
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Название", systemImage: "text.cursor")
                .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                .padding(.horizontal, 20)

            TextField("Название упражнения", text: $name)
                .font(.body)
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Strength Parameters

    private var strengthSection: some View {
        VStack(spacing: 12) {
            paramCard(title: "Вес", value: "\(weight) кг",
                      icon: "scalemass.fill", color: .strengthPurple,
                      stepper: Stepper("", value: $weight, in: 1...500).labelsHidden())
            paramCard(title: "Подходы", value: "\(sets)",
                      icon: "repeat", color: .blue,
                      stepper: Stepper("", value: $sets, in: 1...20).labelsHidden())
            paramCard(title: "Повторения", value: "\(reps)",
                      icon: "arrow.clockwise", color: .orange,
                      stepper: Stepper("", value: $reps, in: 1...100).labelsHidden())
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Cardio Parameters

    private var cardioSection: some View {
        VStack(spacing: 12) {
            paramCard(title: "Дистанция", value: "\(distance) км",
                      icon: "location.fill", color: .cardioOrange,
                      stepper: Stepper("", value: $distance, in: 1...100).labelsHidden())
            paramCard(title: "Время", value: "\(time) мин",
                      icon: "clock.fill", color: .cardioRed,
                      stepper: Stepper("", value: $time, in: 1...300).labelsHidden())
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Заметки", systemImage: "note.text")
                .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                .padding(.horizontal, 20)

            ZStack(alignment: .topLeading) {
                if notes.isEmpty {
                    Text("Как прошла тренировка?")
                        .foregroundColor(.secondary.opacity(0.6))
                        .font(.body)
                        .padding(.top, 18)
                        .padding(.leading, 20)
                }
                TextEditor(text: $notes)
                    .font(.body)
                    .frame(minHeight: 90)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .scrollContentBackground(.hidden)
            }
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Date Section

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Дата", systemImage: "calendar")
                .font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
                .padding(.horizontal, 20)

            HStack {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                Spacer()
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Parameter Card Builder

    private func paramCard(title: String, value: String, icon: String, color: Color, stepper: some View) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            Text(title).font(.body).fontWeight(.medium)
            Spacer()
            Text(value).font(.title3).fontWeight(.semibold)
            stepper
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Save

    private func saveChanges() {
        guard !name.isEmpty else { return }
        workout.name     = name
        workout.type     = type
        workout.weight   = Double(weight)
        workout.sets     = Int16(sets)
        workout.reps     = Int16(reps)
        workout.distance = Double(distance)
        workout.time     = Int16(time)
        workout.date     = date
        workout.notes    = notes.isEmpty ? nil : notes
        try? viewContext.save()
        presentationMode.wrappedValue.dismiss()
    }
}
