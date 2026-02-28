//
//  WorkoutsView.swift
//  FitnessApp
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: true)]
    ) private var workouts: FetchedResults<Workout>

    @State private var selectedDate = Date()
    @State private var showAddWorkout = false
    @State private var editingWorkout: Workout?
    @State private var progressWorkout: Workout?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView

                    // Week Calendar
                    WeekCalendarView(selectedDate: $selectedDate)
                        .padding(.horizontal)

                    // Progress card (if workouts exist)
                    if !workoutsForSelectedDate.isEmpty {
                        progressCard
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Workouts list section
                    VStack(alignment: .leading, spacing: 12) {
                        if !workoutsForSelectedDate.isEmpty {
                            Text("Тренировки")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }

                        workoutsList
                            .padding(.horizontal)
                    }

                    Spacer().frame(height: 110)
                }
            }

            // FAB Button
            fabButton
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(selectedDate: selectedDate)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingWorkout) { workout in
            EditWorkoutView(workout: workout)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $progressWorkout) { workout in
            ExerciseProgressView(exercise: workout)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greetingText)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(dateTitle)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
        .padding(.top, 60)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Доброе утро ☀️" }
        else if hour < 17 { return "Добрый день 🌤" }
        else { return "Добрый вечер 🌙" }
    }

    private var dateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Сегодня" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Вчера" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: selectedDate)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        let completed = workoutsForSelectedDate.filter { $0.completed }.count
        let total = workoutsForSelectedDate.count
        let progress: CGFloat = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

        return HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Прогресс дня")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                Text("\(completed) из \(total)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(completed == total ? "Все выполнено! 🎉" : "выполнено")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(LinearGradient.primaryGradient)
        .cornerRadius(22)
        .shadow(color: Color.primaryGreen.opacity(0.35), radius: 14, x: 0, y: 6)
    }

    // MARK: - Workouts List

    private var workoutsList: some View {
        Group {
            if workoutsForSelectedDate.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 12) {
                    ForEach(workoutsForSelectedDate, id: \.self) { workout in
                        WorkoutCardView(workout: workout, toggleCompletion: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                workout.completed.toggle()
                                saveContext()
                            }
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteWorkout(workout)
                            } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            Button {
                                editingWorkout = workout
                            } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button {
                                progressWorkout = workout
                            } label: {
                                Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                            }
                            Button {
                                editingWorkout = workout
                            } label: {
                                Label("Редактировать", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                deleteWorkout(workout)
                            } label: {
                                Label("Удалить", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.top, 20)

            VStack(spacing: 6) {
                Text("Нет тренировок")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Нажмите + чтобы добавить\nтренировку на этот день")
                    .font(.subheadline)
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - FAB Button

    private var fabButton: some View {
        Button(action: { showAddWorkout.toggle() }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(LinearGradient.primaryGradient)
                .clipShape(Circle())
                .shadow(color: Color.primaryGreen.opacity(0.45), radius: 14, x: 0, y: 6)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 110)
    }

    // MARK: - Helpers

    private var workoutsForSelectedDate: [Workout] {
        workouts.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }

    private func deleteWorkout(_ workout: Workout) {
        withAnimation {
            viewContext.delete(workout)
            saveContext()
        }
    }

    private func saveContext() {
        try? viewContext.save()
    }
}
