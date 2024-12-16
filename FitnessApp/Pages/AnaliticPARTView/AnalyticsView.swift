//
//  AnalyticsView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var steps: Double = 0
    @State private var calories: Double = 0
    @State private var distance: Double = 0

    // Реальные данные за последние 7 дней
    @State private var weeklySteps: [Double] = []
    @State private var weeklyCalories: [Double] = []
    @State private var weeklyDistance: [Double] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Аналитика активности")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.green)
                        .padding(.top)

                    // Карточка с шагами + линейный график
                    analyticsCard(
                        title: "Шаги",
                        value: Int(steps),
                        unit: "шагов",
                        chartView: LineChartView(data: weeklySteps.map { Int($0) }, color: .blue, title: "Шаги за неделю")
                    )

                    // Карточка с калориями + столбчатый график
                    analyticsCard(
                        title: "Калории",
                        value: Int(calories),
                        unit: "ккал",
                        chartView: BarChartView(data: weeklyCalories.map { Int($0) }, color: .orange, title: "Калории за неделю")
                    )

                    // Карточка с дистанцией + круговая диаграмма
                    analyticsCard(
                        title: "Дистанция",
                        value: Int(distance),
                        unit: "м",
                        chartView: LineChartView(data: weeklyDistance.map { Int($0) }, color: .purple, title: "Дистанция за неделю")
                    )
                }
                .padding(.horizontal)
            }
            .onAppear {
                HealthManager.shared.requestAuthorization()
                loadHealthData()
            }
        }
    }

    // Карточка для показателя
    private func analyticsCard(title: String, value: Int, unit: String, chartView: some View) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text("\(value) \(unit)")
                    .font(.title)
                    .bold()
            }
            chartView
                .frame(height: 200)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 5)
    }

    private func loadHealthData() {
        // Сегодняшние шаги
        HealthManager.shared.fetchSteps { steps in
            DispatchQueue.main.async {
                self.steps = steps
            }
        }

        // Сегодняшние калории
        HealthManager.shared.fetchCalories { calories in
            DispatchQueue.main.async {
                self.calories = calories
            }
        }

        // Сегодняшняя дистанция
        HealthManager.shared.fetchDistance { distance in
            DispatchQueue.main.async {
                self.distance = distance
            }
        }

        // Еженедельные данные
        fetchWeeklyData()
    }

    private func fetchWeeklyData() {
        // Пример для шагов
        HealthManager.shared.fetchSteps { steps in
            DispatchQueue.main.async {
                // Пример заполнения weeklySteps (в реальности нужно использовать статистику по дням)
                self.weeklySteps = [1200, 3500, 5000, 7800, 6000, 8000, steps]
            }
        }

        // Повторить для калорий и дистанции
    }
}
