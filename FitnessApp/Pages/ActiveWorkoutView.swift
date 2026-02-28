//
//  ActiveWorkoutView.swift
//  FitnessApp
//

import SwiftUI

struct ActiveWorkoutView: View {
    let workoutType: String // "Силовая" or "Кардио"

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // Workout timer
    @State private var elapsedSeconds = 0
    @State private var workoutTimer: Timer? = nil

    // Current set input
    @State private var currentExercise = ""
    @State private var currentWeight   = 40
    @State private var currentReps     = 10
    @State private var currentDistance = 3
    @State private var currentDuration = 30

    // Logged sets
    @State private var loggedSets: [LoggedSet] = []

    // Rest timer
    @State private var isResting       = false
    @State private var restRemaining   = 90
    @State private var restProgress    = 1.0
    @State private var restTimer: Timer? = nil

    // UI state
    @State private var showFinishAlert = false
    @State private var showExercisePicker = false

    private let isStrength: Bool

    private let quickExercises = [
        "Жим лёжа", "Приседания", "Становая тяга",
        "Жим в плечи", "Подтягивания", "Тяга блока",
        "Жим гантелей", "Выпады", "Планка"
    ]

    private let quickCardio = [
        "Велосипед", "Эллипс", "Гребля", "Прыжки", "Скакалка"
    ]

    init(workoutType: String) {
        self.workoutType = workoutType
        self.isStrength  = (workoutType == "Силовая")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        timerCard
                        exerciseInputCard
                        if !loggedSets.isEmpty { loggedSetsCard }
                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal)
                    .padding(.top, 14)
                }
            }

            // Rest timer overlay
            if isResting {
                restTimerOverlay
                    .transition(.opacity)
            }
        }
        .onAppear { startWorkoutTimer() }
        .onDisappear { stopAllTimers() }
        .alert("Завершить тренировку?", isPresented: $showFinishAlert) {
            Button("Сохранить и выйти", role: .destructive) { finishWorkout() }
            Button("Продолжить", role: .cancel) { }
        } message: {
            Text("Записано \(loggedSets.count) сетов. Сохранить тренировку?")
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: {
                if loggedSets.isEmpty { dismiss() } else { showFinishAlert = true }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Завершить")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: isStrength ? "dumbbell.fill" : "bicycle")
                    .font(.system(size: 14))
                    .foregroundColor(isStrength ? .strengthPurple : .blue)
                Text(workoutType)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Green live dot
            HStack(spacing: 5) {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
                Text("ЗАПИСЬ")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.primaryGreen.opacity(0.1))
            .cornerRadius(20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 14)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Timer Card

    private var timerCard: some View {
        HStack(spacing: 0) {
            statBlock(value: formattedTime(), label: "Время")
            Divider().frame(height: 36).opacity(0.3)
            statBlock(value: "\(loggedSets.count)", label: "Сетов")
            Divider().frame(height: 36).opacity(0.3)
            statBlock(value: "\(uniqueExercises.count)", label: "Упражнений")
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3).fontWeight(.bold)
            Text(label)
                .font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Exercise Input Card

    private var exerciseInputCard: some View {
        VStack(spacing: 14) {
            // Quick exercises chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(isStrength ? quickExercises : quickCardio, id: \.self) { name in
                        Button(action: { currentExercise = name }) {
                            Text(name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(currentExercise == name
                                    ? (isStrength ? Color.strengthPurple : Color.blue)
                                    : Color(.systemGray5))
                                .foregroundColor(currentExercise == name ? .white : .primary)
                                .cornerRadius(20)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -18)

            // Name field
            HStack {
                Image(systemName: "pencil.line")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                TextField("Название упражнения", text: $currentExercise)
                    .font(.body)
            }
            .padding(14)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)

            Divider()

            // Parameters
            if isStrength {
                HStack(spacing: 14) {
                    paramStepper(
                        icon: "scalemass.fill", color: .strengthPurple,
                        label: "Вес", value: "\(currentWeight) кг",
                        minus: { if currentWeight > 1 { currentWeight -= 5 } },
                        plus:  { if currentWeight < 500 { currentWeight += 5 } }
                    )

                    Divider().frame(height: 50).opacity(0.3)

                    paramStepper(
                        icon: "arrow.clockwise", color: .orange,
                        label: "Повт.", value: "\(currentReps)",
                        minus: { if currentReps > 1 { currentReps -= 1 } },
                        plus:  { if currentReps < 100 { currentReps += 1 } }
                    )
                }
            } else {
                HStack(spacing: 14) {
                    paramStepper(
                        icon: "location.fill", color: .cardioOrange,
                        label: "км", value: "\(currentDistance)",
                        minus: { if currentDistance > 1 { currentDistance -= 1 } },
                        plus:  { if currentDistance < 100 { currentDistance += 1 } }
                    )

                    Divider().frame(height: 50).opacity(0.3)

                    paramStepper(
                        icon: "clock.fill", color: .blue,
                        label: "мин", value: "\(currentDuration)",
                        minus: { if currentDuration > 5 { currentDuration -= 5 } },
                        plus:  { if currentDuration < 300 { currentDuration += 5 } }
                    )
                }
            }

            // Log set button
            Button(action: logSet) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                    Text("Записать сет")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    Group {
                        if currentExercise.isEmpty {
                            RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray4))
                        } else {
                            RoundedRectangle(cornerRadius: 16).fill(LinearGradient.primaryGradient)
                        }
                    }
                )
                .foregroundColor(currentExercise.isEmpty ? .secondary : .white)
                .shadow(
                    color: currentExercise.isEmpty ? .clear : Color.primaryGreen.opacity(0.35),
                    radius: 10, x: 0, y: 4
                )
            }
            .disabled(currentExercise.isEmpty)
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func paramStepper(icon: String, color: Color, label: String, value: String,
                               minus: @escaping () -> Void, plus: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .frame(minWidth: 60)
            HStack(spacing: 12) {
                Button(action: minus) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: plus) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 32, height: 32)
                        .background(color.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Logged Sets Card

    private var loggedSetsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Записано")
                .font(.headline)

            ForEach(uniqueExercises, id: \.self) { name in
                let sets = loggedSets.filter { $0.exercise == name }
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(sets.count) сет\(setSuffix(sets.count))")
                            .font(.caption)
                            .foregroundColor(.primaryGreen)
                            .fontWeight(.medium)
                    }
                    HStack(spacing: 6) {
                        ForEach(sets) { s in
                            Text(isStrength ? "\(Int(s.weight))кг×\(s.reps)" : "\(Int(s.distance))км")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                if name != uniqueExercises.last { Divider() }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Rest Timer Overlay

    private var restTimerOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Отдых")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 160, height: 160)
                    Circle()
                        .trim(from: 0, to: restProgress)
                        .stroke(Color.primaryGreen,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: restProgress)

                    VStack(spacing: 4) {
                        Text("\(restRemaining)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("секунд")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Button(action: skipRest) {
                    Text("Пропустить")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    // MARK: - Data Model

    struct LoggedSet: Identifiable {
        let id = UUID()
        let exercise: String
        let weight: Double
        let reps: Int
        let distance: Double
        let duration: Int
    }

    // MARK: - Actions

    private func logSet() {
        guard !currentExercise.isEmpty else { return }
        let set = LoggedSet(
            exercise: currentExercise,
            weight:   Double(currentWeight),
            reps:     currentReps,
            distance: Double(currentDistance),
            duration: currentDuration
        )
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            loggedSets.append(set)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        startRestTimer()
    }

    private func startRestTimer() {
        restRemaining = 90
        restProgress  = 1.0
        isResting     = true
        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if restRemaining > 0 {
                restRemaining -= 1
                restProgress = Double(restRemaining) / 90.0
            } else {
                skipRest()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func skipRest() {
        restTimer?.invalidate()
        restTimer = nil
        withAnimation { isResting = false }
    }

    private func startWorkoutTimer() {
        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func stopAllTimers() {
        workoutTimer?.invalidate()
        restTimer?.invalidate()
    }

    private func finishWorkout() {
        stopAllTimers()
        var seen = Set<String>()
        let names = loggedSets.map(\.exercise).filter { seen.insert($0).inserted }

        for name in names {
            let sets = loggedSets.filter { $0.exercise == name }
            let w = Workout(context: viewContext)
            w.id        = UUID()
            w.name      = name
            w.type      = workoutType
            w.date      = Date()
            w.completed = true
            w.sets      = Int16(sets.count)
            if isStrength {
                w.weight = sets.map(\.weight).max() ?? 0
                w.reps   = Int16(sets.map(\.reps).reduce(0, +) / max(sets.count, 1))
            } else {
                w.distance = sets.map(\.distance).reduce(0, +)
                w.time     = Int16(sets.map(\.duration).reduce(0, +))
            }
        }
        try? viewContext.save()
        dismiss()
    }

    // MARK: - Helpers

    private var uniqueExercises: [String] {
        var seen = Set<String>()
        return loggedSets.map(\.exercise).filter { seen.insert($0).inserted }
    }

    private func formattedTime() -> String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private func setSuffix(_ n: Int) -> String {
        switch n % 10 {
        case 1: return ""
        case 2, 3, 4: return "а"
        default: return "ов"
        }
    }
}
