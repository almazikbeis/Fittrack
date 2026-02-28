//
//  ExerciseProgressView.swift
//  FitnessApp
//

import SwiftUI
import Charts

struct ExerciseProgressView: View {
    let exerciseName: String
    let workoutType: String

    @Environment(\.presentationMode) var presentationMode
    @FetchRequest private var history: FetchedResults<Workout>

    init(exercise: Workout) {
        self.exerciseName = exercise.name ?? ""
        self.workoutType  = exercise.type ?? ""
        self._history = FetchRequest(
            entity: Workout.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: true)],
            predicate: NSPredicate(
                format: "name ==[c] %@ AND type == %@",
                exercise.name ?? "", exercise.type ?? ""
            )
        )
    }

    // MARK: - Computed Stats

    private var isStrength: Bool { workoutType == "Силовая" }

    private var chartValues: [(date: Date, value: Double)] {
        history.compactMap { w in
            guard let d = w.date else { return nil }
            let v = isStrength ? w.weight : w.distance
            return (date: d, value: v)
        }
    }

    private var maxValue: Double { chartValues.map(\.value).max() ?? 0 }
    private var avgValue: Double {
        guard !chartValues.isEmpty else { return 0 }
        return chartValues.map(\.value).reduce(0, +) / Double(chartValues.count)
    }
    private var trend: Double {
        guard chartValues.count >= 2 else { return 0 }
        return chartValues.last!.value - chartValues.first!.value
    }

    private var unit: String { isStrength ? "кг" : "км" }
    private var chartLabel: String { isStrength ? "Вес (кг)" : "Дистанция (км)" }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Карточка метаданных упражнения
                        exerciseHeader

                        if history.count < 2 {
                            notEnoughDataView
                        } else {
                            // Сводные карточки
                            statsRow

                            // Основной график
                            chartCard

                            // Таблица истории
                            historyList
                        }

                        Spacer().frame(height: 30)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Прогресс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { presentationMode.wrappedValue.dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                }
            }
        }
    }

    // MARK: - Exercise Header

    private var exerciseHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(isStrength ? LinearGradient.strengthGradient : LinearGradient.cardioGradient)
                    .frame(width: 54, height: 54)
                Image(systemName: isStrength ? "dumbbell.fill" : "figure.run")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(exerciseName)
                    .font(.title3).fontWeight(.bold)
                Text("\(history.count) тренировок • \(workoutType)")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(
                title: "Лучший",
                value: String(format: "%.1f", maxValue),
                unit: unit,
                color: .primaryGreen,
                icon: "trophy.fill"
            )
            miniStat(
                title: "Среднее",
                value: String(format: "%.1f", avgValue),
                unit: unit,
                color: .blue,
                icon: "chart.bar.fill"
            )
            miniStat(
                title: "Прогресс",
                value: (trend >= 0 ? "+" : "") + String(format: "%.1f", trend),
                unit: unit,
                color: trend >= 0 ? .primaryGreen : .red,
                icon: trend >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
            )
        }
    }

    private func miniStat(title: String, value: String, unit: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.headline).fontWeight(.bold)
            Text("\(title), \(unit)")
                .font(.caption2).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(chartLabel)
                    .font(.headline)
                Spacer()
                // Тренд badge
                HStack(spacing: 4) {
                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption)
                    Text((trend >= 0 ? "+" : "") + String(format: "%.1f", trend) + " \(unit)")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(trend >= 0 ? .primaryGreen : .red)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((trend >= 0 ? Color.primaryGreen : Color.red).opacity(0.1))
                .cornerRadius(10)
            }

            Chart {
                ForEach(chartValues, id: \.date) { point in
                    LineMark(
                        x: .value("Дата", point.date),
                        y: .value(chartLabel, point.value)
                    )
                    .foregroundStyle(isStrength ? Color.strengthPurple : Color.cardioOrange)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Дата", point.date),
                        y: .value(chartLabel, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                (isStrength ? Color.strengthPurple : Color.cardioOrange).opacity(0.25),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Дата", point.date),
                        y: .value(chartLabel, point.value)
                    )
                    .foregroundStyle(isStrength ? Color.strengthPurple : Color.cardioOrange)
                    .symbolSize(30)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))\(unit)")
                                .font(.caption2)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(dash: [4]))
                        .foregroundStyle(Color.secondary.opacity(0.2))
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("История")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(history.reversed().prefix(10), id: \.self) { w in
                    historyRow(w)
                }
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private func historyRow(_ w: Workout) -> some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedDate(w.date))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    if isStrength {
                        Text("\(w.sets)×\(w.reps) повт.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(w.time) мин")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Text(isStrength
                     ? String(format: "%.1f кг", w.weight)
                     : String(format: "%.2f км", w.distance))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isStrength ? .strengthPurple : .cardioOrange)
            }
            .padding(.vertical, 8)
            Divider()
        }
    }

    // MARK: - Not Enough Data

    private var notEnoughDataView: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.35))
            Text("Недостаточно данных")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Добавь ещё хотя бы одну тренировку\nс таким же названием, чтобы видеть прогресс")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(22)
    }

    // MARK: - Helpers

    private func formattedDate(_ d: Date?) -> String {
        guard let d else { return "" }
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: d)
    }
}
