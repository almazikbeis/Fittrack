//
//  AddWorkoutView.swift
//  FitnessApp
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
    @State private var notes = ""

    let workoutTypes = ["Силовая", "Кардио"]

    init(selectedDate: Date) {
        self._date = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Type selector
                        typeSelectorSection

                        // Name
                        nameSection

                        // Parameters
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

                        // Notes
                        notesSection

                        // Date picker
                        dateSection

                        // Save button
                        Button(action: saveWorkout) {
                            Text("Добавить тренировку")
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
            .navigationTitle("Новая тренировка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        presentationMode.wrappedValue.dismiss()
                    }
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
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

            TextField(type == "Силовая" ? "Например: Жим лёжа" : "Например: Утренняя пробежка", text: $name)
                .font(.body)
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Strength Section

    private var strengthSection: some View {
        VStack(spacing: 12) {
            parameterCard(
                title: "Вес", value: "\(weight) кг",
                icon: "scalemass.fill", color: .strengthPurple,
                stepper: Stepper("", value: $weight, in: 1...500).labelsHidden()
            )
            parameterCard(
                title: "Подходы", value: "\(sets)",
                icon: "repeat", color: .blue,
                stepper: Stepper("", value: $sets, in: 1...20).labelsHidden()
            )
            parameterCard(
                title: "Повторения", value: "\(reps)",
                icon: "arrow.clockwise", color: .orange,
                stepper: Stepper("", value: $reps, in: 1...100).labelsHidden()
            )
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Cardio Section

    private var cardioSection: some View {
        VStack(spacing: 12) {
            parameterCard(
                title: "Дистанция", value: "\(distance) км",
                icon: "location.fill", color: .cardioOrange,
                stepper: Stepper("", value: $distance, in: 1...100).labelsHidden()
            )
            parameterCard(
                title: "Время", value: "\(time) мин",
                icon: "clock.fill", color: .cardioRed,
                stepper: Stepper("", value: $time, in: 1...300).labelsHidden()
            )
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
                    .frame(minHeight: 80)
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
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
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

    private func parameterCard(title: String, value: String, icon: String, color: Color, stepper: some View) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            stepper
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Save

    private func saveWorkout() {
        guard !name.isEmpty else { return }
        let newWorkout = Workout(context: viewContext)
        newWorkout.id = UUID()
        newWorkout.name = name
        newWorkout.type = type
        newWorkout.date = date
        if type == "Силовая" {
            newWorkout.weight = Double(weight)
            newWorkout.sets = Int16(sets)
            newWorkout.reps = Int16(reps)
        } else {
            newWorkout.distance = Double(distance)
            newWorkout.time = Int16(time)
        }
        newWorkout.notes = notes.isEmpty ? nil : notes
        try? viewContext.save()
        presentationMode.wrappedValue.dismiss()
    }
}
