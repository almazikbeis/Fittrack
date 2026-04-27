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

    @State private var selectedDate  = Date()
    @State private var showAddWorkout = false
    @State private var showAITrainer  = false
    @State private var editingWorkout: Workout?
    @State private var progressWorkout: Workout?
    @State private var headerReady   = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroHeader
                    contentStack
                    Spacer().frame(height: 110)
                }
            }

            fabButton
        }
        .fullScreenCover(isPresented: $showAITrainer) {
            AITrainerView().environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showAddWorkout) {
            AddWorkoutView(selectedDate: selectedDate)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $editingWorkout) { w in
            EditWorkoutView(workout: w).environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $progressWorkout) { w in
            ExerciseProgressView(exercise: w).environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.05)) {
                headerReady = true
            }
        }
    }

    // MARK: - NRC-style Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Color(.systemBackground)
                .frame(height: 200)
                .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [Color.primaryGreen.opacity(0.08), Color(.systemBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea(edges: .top)

            VStack(alignment: .leading, spacing: DS.sm) {
                Text("ТРЕНИРОВКИ")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primaryGreen)
                    .tracking(2)

                Text(dateTitle)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: DS.sm) {
                    if streak > 0 {
                        statPill(icon: "flame.fill",    text: "\(streak) дн.",          color: .cardioOrange)
                    }
                    statPill(icon: "dumbbell.fill", text: "\(weekWorkoutCount) за нед.", color: .strengthPurple)
                }
            }
            .padding(.horizontal, DS.xxl)
            .padding(.top, 68)
            .padding(.bottom, DS.xxl)
            .offset(y: headerReady ? 0 : 20)
            .opacity(headerReady ? 1 : 0)
        }
    }

    private func statPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(color)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, DS.md)
        .padding(.vertical, DS.xs + 2)
        .background(color.opacity(0.1), in: Capsule())
    }

    // MARK: - Content Stack

    private var contentStack: some View {
        VStack(alignment: .leading, spacing: DS.lg) {
            // Calendar
            WeekCalendarView(selectedDate: $selectedDate)
                .padding(.horizontal, DS.lg)

            // AI Trainer banner
            aiTrainerBanner
                .padding(.horizontal, DS.lg)

            // Progress card (shows only when workouts exist)
            if !workoutsForSelectedDate.isEmpty {
                progressCard
                    .padding(.horizontal, DS.lg)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Workouts list
            VStack(alignment: .leading, spacing: DS.md) {
                if !workoutsForSelectedDate.isEmpty {
                    Text("ТРЕНИРОВКИ")
                        .nrcLabel()
                        .padding(.horizontal, DS.lg)
                }
                workoutsList
                    .padding(.horizontal, DS.lg)
            }
        }
        .padding(.top, DS.lg)
    }

    // MARK: - AI Trainer Banner

    private var aiTrainerBanner: some View {
        Button { showAITrainer = true } label: {
            HStack(spacing: DS.md) {
                Image(systemName: "camera.metering.spot")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .gradientBadge(.strengthGradient, radius: DS.rMD, size: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text("AI Тренировка")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Приседания · Отжимания · Планка")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(DS.lg)
            .nrcCard(radius: DS.rLG)
            .overlay(
                RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                    .stroke(Color.strengthPurple.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        let completed = workoutsForSelectedDate.filter(\.completed).count
        let total     = workoutsForSelectedDate.count
        let progress  = CGFloat(completed) / CGFloat(max(total, 1))

        return HStack(spacing: DS.xl) {
            VStack(alignment: .leading, spacing: DS.xs) {
                Text("ПРОГРЕСС")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.65))
                    .tracking(1.5)
                Text("\(completed) из \(total)")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(completed == total ? "Все выполнено! 🎉" : "выполнено")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 6)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .padding(DS.xl)
        .background(LinearGradient.primaryGradient,
                    in: RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
        .shadow(color: Color.primaryGreen.opacity(0.4), radius: 16, x: 0, y: 6)
    }

    // MARK: - Workouts List

    private var workoutsList: some View {
        Group {
            if workoutsForSelectedDate.isEmpty {
                EmptyWorkoutState()
            } else {
                VStack(spacing: DS.md) {
                    ForEach(Array(workoutsForSelectedDate.enumerated()), id: \.element) { idx, workout in
                        WorkoutCardView(workout: workout, toggleCompletion: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                workout.completed.toggle()
                                saveContext()
                            }
                        })
                        .staggeredAppear(index: idx)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { deleteWorkout(workout) } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                            Button { editingWorkout = workout } label: {
                                Label("Изменить", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button { progressWorkout = workout } label: {
                                Label("Прогресс", systemImage: "chart.line.uptrend.xyaxis")
                            }
                            Button { editingWorkout = workout } label: {
                                Label("Редактировать", systemImage: "pencil")
                            }
                            Button(role: .destructive) { deleteWorkout(workout) } label: {
                                Label("Удалить", systemImage: "trash.fill")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - FAB

    private var fabButton: some View {
        Button(action: { showAddWorkout.toggle() }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 58, height: 58)
                .background(LinearGradient.primaryGradient,
                            in: Circle())
                .shadow(color: Color.primaryGreen.opacity(0.5), radius: 16, x: 0, y: 6)
        }
        .padding(.trailing, DS.xxl)
        .padding(.bottom, 110)
    }

    // MARK: - Computed

    private var dateTitle: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Сегодня" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Вчера" }
        let f = DateFormatter(); f.dateFormat = "d MMMM"; f.locale = Locale(identifier: "ru_RU")
        return f.string(from: selectedDate)
    }

    private var workoutsForSelectedDate: [Workout] {
        workouts.filter { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: selectedDate) }
    }

    private var weekWorkoutCount: Int {
        let cal = Calendar.current
        return workouts.filter {
            guard let d = $0.date else { return false }
            return cal.isDate(d, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
    }

    private var streak: Int {
        let cal = Calendar.current
        var count = 0
        var date = cal.startOfDay(for: Date())
        if !workouts.contains(where: { cal.isDateInToday($0.date ?? Date()) }) {
            guard let yd = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yd
        }
        for _ in 0..<365 {
            if workouts.contains(where: { cal.isDate($0.date ?? Date(), inSameDayAs: date) }) {
                count += 1
                date = cal.date(byAdding: .day, value: -1, to: date) ?? date
            } else { break }
        }
        return count
    }

    private func deleteWorkout(_ workout: Workout) {
        withAnimation { viewContext.delete(workout); saveContext() }
    }

    private func saveContext() {
        try? viewContext.save()
    }
}

// MARK: - Animated Empty State

struct EmptyWorkoutState: View {
    @State private var bounce = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: DS.xl) {
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.08))
                    .frame(width: 120, height: 120)
                    .scaleEffect(bounce ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                               value: bounce)

                Image(systemName: "figure.run.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(LinearGradient.primaryGradient)
                    .offset(y: bounce ? -4 : 4)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                               value: bounce)
            }
            .frame(height: 130)

            VStack(spacing: DS.xs) {
                Text("Нет тренировок")
                    .font(.title3).fontWeight(.bold)
                Text("Нажми + чтобы добавить тренировку на этот день")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .padding(.horizontal, DS.xxxl)
        .nrcCard(radius: DS.rXL)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared ? 1 : 0.93)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) { appeared = true }
            bounce = true
        }
    }
}
