//
//  HomeView.swift
//  FitnessApp
//

import SwiftUI
import Charts

struct HomeView: View {
    @AppStorage("userName") private var userName = "Спортсмен"

    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
    ) private var allWorkouts: FetchedResults<Workout>

    @State private var todaySteps: Double    = 0
    @State private var todayCalories: Double = 0

    // Goals
    private let stepsGoal: Double    = 10_000
    private let caloriesGoal: Double = 500

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    headerSection
                    activityRingsCard
                    weeklyChartCard
                    todayWorkoutsCard
                    Spacer().frame(height: 110)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            HealthManager.shared.requestAuthorization()
            HealthManager.shared.fetchTodayStats { s, c in
                todaySteps    = s
                todayCalories = c
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            Spacer()
            // Streak badge
            if streak > 0 {
                VStack(spacing: 2) {
                    Text("🔥")
                        .font(.title2)
                    Text("\(streak) дн.")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(14)
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Activity Rings Card

    private var activityRingsCard: some View {
        HStack(spacing: 20) {
            // Concentric rings
            ActivityRings(
                stepsProgress:    min(todaySteps / stepsGoal, 1.0),
                caloriesProgress: min(todayCalories / caloriesGoal, 1.0),
                workoutsProgress: min(Double(todayWorkoutsCount) / 3.0, 1.0)
            )
            .frame(width: 120, height: 120)

            // Legend
            VStack(alignment: .leading, spacing: 10) {
                legendRow(color: .blue,         icon: "figure.walk",
                          label: "Шаги",
                          value: formatSteps(todaySteps),
                          goal: "/ \(Int(stepsGoal / 1000))k")

                legendRow(color: .orange,       icon: "flame.fill",
                          label: "Калории",
                          value: "\(Int(todayCalories))",
                          goal: "/ \(Int(caloriesGoal)) ккал")

                legendRow(color: .primaryGreen, icon: "dumbbell.fill",
                          label: "Тренировки",
                          value: "\(todayWorkoutsCount)",
                          goal: "/ 3 цель")
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
    }

    private func legendRow(color: Color, icon: String, label: String, value: String, goal: String) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(goal)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Weekly Chart Card

    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Эта неделя")
                    .font(.headline)
                Spacer()
                Text("\(weekTotal) тренировок")
                    .font(.subheadline)
                    .foregroundColor(.primaryGreen)
                    .fontWeight(.semibold)
            }

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(weeklyData, id: \.day) { item in
                    VStack(spacing: 6) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(item.isToday ? LinearGradient.primaryGradient : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray5)], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(CGFloat(item.count) * 22 + 8, 8))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: item.count)

                        // Count badge
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(item.isToday ? .primaryGreen : .secondary)
                        }

                        // Day label
                        Text(item.day)
                            .font(.caption2)
                            .foregroundColor(item.isToday ? .primaryGreen : .secondary)
                            .fontWeight(item.isToday ? .bold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100, alignment: .bottom)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Today Workouts Card

    private var todayWorkoutsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Сегодня")
                    .font(.headline)
                Spacer()
                Text(Calendar.current.isDateInToday(Date()) ? formattedToday : "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if todayWorkouts.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Тренировок нет")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Нажмите + чтобы начать")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            } else {
                ForEach(todayWorkouts.prefix(3), id: \.self) { w in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(w.type == "Силовая" ? LinearGradient.strengthGradient : LinearGradient.cardioGradient)
                                .frame(width: 38, height: 38)
                            Image(systemName: w.type == "Силовая" ? "dumbbell.fill" : "figure.run")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(w.name ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            Text(w.type ?? "")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: w.completed ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(w.completed ? .primaryGreen : .secondary.opacity(0.4))
                            .font(.system(size: 20))
                    }
                    if w != todayWorkouts.prefix(3).last {
                        Divider()
                    }
                }
                if todayWorkouts.count > 3 {
                    Text("+ ещё \(todayWorkouts.count - 3)...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Computed Properties

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Доброе утро ☀️" }
        if h < 17 { return "Добрый день 🌤" }
        return "Добрый вечер 🌙"
    }

    private var streak: Int {
        let cal = Calendar.current
        var count = 0
        var date = cal.startOfDay(for: Date())
        // Skip today if no workout yet
        if !allWorkouts.contains(where: { cal.isDateInToday($0.date ?? Date()) }) {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }
        for _ in 0..<365 {
            let has = allWorkouts.contains { cal.isDate($0.date ?? Date(), inSameDayAs: date) }
            if has {
                count += 1
                date = cal.date(byAdding: .day, value: -1, to: date) ?? date
            } else { break }
        }
        return count
    }

    private var todayWorkouts: [Workout] {
        allWorkouts.filter { Calendar.current.isDateInToday($0.date ?? Date()) }
    }

    private var todayWorkoutsCount: Int { todayWorkouts.count }

    private struct WeekDay {
        let day: String
        let count: Int
        let isToday: Bool
    }

    private var weeklyData: [WeekDay] {
        let cal = Calendar.current
        let fmt = DateFormatter()
        fmt.dateFormat = "EE"
        fmt.locale = Locale(identifier: "ru_RU")
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: offset - 6, to: Date()) ?? Date()
            let cnt  = allWorkouts.filter { cal.isDate($0.date ?? Date(), inSameDayAs: date) }.count
            let name = String(fmt.string(from: date).prefix(2)).capitalized
            return WeekDay(day: name, count: cnt, isToday: cal.isDateInToday(date))
        }
    }

    private var weekTotal: Int { weeklyData.map(\.count).reduce(0, +) }

    private var formattedToday: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: Date())
    }

    private func formatSteps(_ s: Double) -> String {
        s >= 1000 ? String(format: "%.1fk", s / 1000) : "\(Int(s))"
    }
}

// MARK: - Activity Rings

struct ActivityRings: View {
    let stepsProgress: Double
    let caloriesProgress: Double
    let workoutsProgress: Double

    var body: some View {
        ZStack {
            ProgressRing(progress: stepsProgress,    color: .blue,         thickness: 12, diameter: 120)
            ProgressRing(progress: caloriesProgress, color: .orange,       thickness: 12, diameter: 92)
            ProgressRing(progress: workoutsProgress, color: .primaryGreen, thickness: 12, diameter: 64)
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    let thickness: CGFloat
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: thickness)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
        }
        .frame(width: diameter, height: diameter)
    }
}
