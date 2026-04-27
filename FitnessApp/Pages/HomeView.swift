//
//  HomeView.swift
//  FitnessApp
//

import SwiftUI

struct HomeView: View {
    @AppStorage("userName") private var userName = "Спортсмен"

    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: false)]
    ) private var allWorkouts: FetchedResults<Workout>

    @State private var todaySteps:    Double = 0
    @State private var todayCalories: Double = 0
    @State private var showCoach     = false

    private let stepsGoal:    Double = 10_000
    private let caloriesGoal: Double = 500

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    greetingHeader
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .onAppear {
            HealthManager.shared.requestAuthorization()
            HealthManager.shared.fetchTodayStats { s, c in
                withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                    todaySteps = s; todayCalories = c
                }
            }
        }
        .sheet(isPresented: $showCoach) {
            AICoachView(workoutCount: allWorkouts.count)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground)

            VStack(alignment: .leading, spacing: DS.xs) {
                Text(greetingText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .tracking(1.5)
                Text(userName)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                Text(formattedToday)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.lg)
            .padding(.top, 60)
            .padding(.bottom, DS.xl)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: DS.lg) {
            activityCard.staggeredAppear(index: 0)
            todaySection.staggeredAppear(index: 1)
            coachCard.staggeredAppear(index: 2)
            weekChartCard.staggeredAppear(index: 3)
            Spacer().frame(height: 110)
        }
        .padding(.horizontal, DS.lg)
        .padding(.top, DS.lg)
    }

    // MARK: - Activity Rings Card

    private var activityCard: some View {
        HStack(spacing: DS.xl) {
            ActivityRings(
                stepsProgress:    min(todaySteps / stepsGoal, 1.0),
                caloriesProgress: min(todayCalories / caloriesGoal, 1.0),
                workoutsProgress: min(Double(todayWorkoutsCount) / 3.0, 1.0)
            )
            .frame(width: 130, height: 130)

            VStack(alignment: .leading, spacing: DS.md) {
                ringStatRow(color: .primaryGreen,   label: "Шаги",       value: formatSteps(todaySteps),      goal: "/ 10k")
                Divider()
                ringStatRow(color: .cardioOrange,   label: "Ккал актив.", value: "\(Int(todayCalories))",      goal: "/ \(Int(caloriesGoal))")
                Divider()
                ringStatRow(color: .strengthPurple, label: "Тренировки",  value: "\(todayWorkoutsCount)",       goal: "/ 3")
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rXL)
    }

    private func ringStatRow(color: Color, label: String, value: String, goal: String) -> some View {
        HStack(spacing: DS.sm) {
            Circle().fill(color).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    Text(goal)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Сегодня")
                        .font(.title3).fontWeight(.bold)
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.cardioOrange)
                            Text("\(streak) дней подряд")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                if !todayWorkouts.isEmpty {
                    let done = todayWorkouts.filter(\.completed).count
                    Text("\(done)/\(todayWorkouts.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, DS.md).padding(.vertical, DS.xs)
                        .background(Color.primaryGreen.opacity(0.1), in: Capsule())
                }
            }

            if todayWorkouts.isEmpty {
                emptyTodayView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.md) {
                        ForEach(Array(todayWorkouts.prefix(6).enumerated()), id: \.offset) { _, w in
                            workoutMiniCard(w)
                        }
                    }
                    .padding(.horizontal, 2).padding(.vertical, DS.xs)
                }
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rXL)
    }

    private func workoutMiniCard(_ w: Workout) -> some View {
        let isStrength = w.type == "Силовая"
        return VStack(alignment: .leading, spacing: DS.md) {
            Image(systemName: isStrength ? "dumbbell.fill" : "figure.run")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .gradientBadge(isStrength ? .strengthGradient : .cardioGradient,
                               radius: DS.rMD, size: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(w.name ?? "")
                    .font(.system(size: 13, weight: .bold)).lineLimit(1)
                Text(w.type ?? "")
                    .font(.system(size: 11)).foregroundColor(.secondary)
            }

            Image(systemName: w.completed ? "checkmark.circle.fill" : "circle")
                .foregroundColor(w.completed ? .primaryGreen : Color(.systemGray4))
                .font(.system(size: 18))
        }
        .padding(DS.md)
        .frame(width: 116)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                .stroke(w.completed ? Color.primaryGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }

    private var emptyTodayView: some View {
        HStack(spacing: DS.lg) {
            ZStack {
                Circle().fill(Color.primaryGreen.opacity(0.1)).frame(width: 50, height: 50)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Пора начать")
                    .font(.subheadline).fontWeight(.semibold)
                Text("Добавь тренировку в разделе Тренировки")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, DS.sm)
    }

    // MARK: - AI Coach Card

    private var coachCard: some View {
        Button(action: { showCoach = true }) {
            HStack(spacing: DS.lg) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 52, height: 52)
                        .glowPulse(color: .primaryGreen, radius: 10)
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("Сенсей")
                            .font(.headline)
                        Circle().fill(Color.primaryGreen).frame(width: 6, height: 6)
                        Text("онлайн")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Text("Персональный AI-коуч")
                        .font(.subheadline).foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .iconBadge(color: .primaryGreen, radius: DS.rSM, size: 30)
            }
            .padding(DS.lg)
            .nrcCard(radius: DS.rXL)
            .overlay(
                RoundedRectangle(cornerRadius: DS.rXL, style: .continuous)
                    .stroke(Color.primaryGreen.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Week Chart Card

    private var weekChartCard: some View {
        VStack(alignment: .leading, spacing: DS.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Эта неделя").font(.title3).fontWeight(.bold)
                    Text("\(weekTotal) тренировок")
                        .font(.caption).foregroundColor(.primaryGreen).fontWeight(.semibold)
                        .contentTransition(.numericText())
                }
                Spacer()
                if weekTotal > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text("Активно")
                            .font(.caption2).fontWeight(.semibold)
                    }
                    .foregroundColor(.primaryGreen)
                    .padding(.horizontal, DS.sm).padding(.vertical, DS.xs)
                    .background(Color.primaryGreen.opacity(0.1), in: Capsule())
                }
            }

            HStack(alignment: .bottom, spacing: DS.xs) {
                ForEach(weeklyData, id: \.day) { item in
                    VStack(spacing: DS.xs) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: DS.rSM)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 72)

                            if item.count > 0 {
                                RoundedRectangle(cornerRadius: DS.rSM)
                                    .fill(item.isToday
                                          ? AnyShapeStyle(LinearGradient.primaryGradient)
                                          : AnyShapeStyle(Color.primaryGreen.opacity(0.4)))
                                    .frame(height: min(CGFloat(item.count) * 28 + 10, 72))
                                    .animation(.spring(response: 0.7, dampingFraction: 0.75), value: item.count)
                            }
                        }
                        .frame(height: 72)
                        .shadow(
                            color: item.isToday ? Color.primaryGreen.opacity(0.25) : .clear,
                            radius: 6, x: 0, y: 3
                        )

                        Text(item.day)
                            .font(.system(size: 10, weight: item.isToday ? .bold : .regular))
                            .foregroundColor(item.isToday ? .primaryGreen : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rXL)
    }

    // MARK: - Computed

    private var greetingText: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 5  { return "НОЧНАЯ СЕССИЯ" }
        if h < 12 { return "ДОБРОЕ УТРО" }
        if h < 17 { return "ДОБРЫЙ ДЕНЬ" }
        return "ДОБРЫЙ ВЕЧЕР"
    }

    private var streak: Int {
        let cal = Calendar.current
        var count = 0
        var date  = cal.startOfDay(for: Date())
        if !allWorkouts.contains(where: { cal.isDateInToday($0.date ?? Date()) }) {
            guard let yd = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yd
        }
        for _ in 0..<365 {
            if allWorkouts.contains(where: { cal.isDate($0.date ?? Date(), inSameDayAs: date) }) {
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

    private struct WeekDay { let day: String; let count: Int; let isToday: Bool }
    private var weeklyData: [WeekDay] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "EE"; fmt.locale = Locale(identifier: "ru_RU")
        return (0..<7).map { offset in
            let date = cal.date(byAdding: .day, value: offset - 6, to: Date()) ?? Date()
            let cnt  = allWorkouts.filter { cal.isDate($0.date ?? Date(), inSameDayAs: date) }.count
            let name = String(fmt.string(from: date).prefix(2)).capitalized
            return WeekDay(day: name, count: cnt, isToday: cal.isDateInToday(date))
        }
    }
    private var weekTotal: Int { weeklyData.map(\.count).reduce(0, +) }

    private var formattedToday: String {
        let f = DateFormatter(); f.dateFormat = "d MMMM"; f.locale = Locale(identifier: "ru_RU")
        return f.string(from: Date())
    }

    private func formatSteps(_ s: Double) -> String {
        s >= 1000 ? String(format: "%.1fk", s / 1000) : "\(Int(s))"
    }
}

// MARK: - Activity Rings

struct ActivityRings: View {
    let stepsProgress:    Double
    let caloriesProgress: Double
    let workoutsProgress: Double

    var body: some View {
        ZStack {
            ProgressRing(progress: stepsProgress,    color: .primaryGreen,   thickness: 12, diameter: 120)
            ProgressRing(progress: caloriesProgress, color: .cardioOrange,   thickness: 12, diameter: 92)
            ProgressRing(progress: workoutsProgress, color: .strengthPurple, thickness: 12, diameter: 64)
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
            Circle().stroke(color.opacity(0.15), lineWidth: thickness)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: progress)
        }
        .frame(width: diameter, height: diameter)
    }
}
