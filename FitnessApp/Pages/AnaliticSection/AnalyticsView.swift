//
//  AnalyticsView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 16.12.2024.
//
import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var stepsData: [Double] = []
    @State private var caloriesData: [Double] = []
    @State private var distanceData: [Double] = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Загрузка данных...")
                            .padding(.top, 50)
                    } else {
                        Text("Аналитика за последние 30 дней")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.green)
                            .padding(.top)

                        // Карточка с шагами + линейный график
                        analyticsCard(
                            title: "Шаги",
                            data: stepsData,
                            chartView: LineChartView(data: stepsData.map { Int($0) }, color: .blue, title: "Шаги")
                        )

                        // Карточка с калориями + столбчатый график
                        analyticsCard(
                            title: "Калории",
                            data: caloriesData,
                            chartView: BarChartView(data: caloriesData.map { Int($0) }, color: .orange, title: "Калории")
                        )

                        // Карточка с дистанцией + линейный график
                        analyticsCard(
                            title: "Дистанция",
                            data: distanceData,
                            chartView: LineChartView(data: distanceData.map { Int($0) }, color: .purple, title: "Дистанция")
                        )
                        // Карточка с этажами + столбчатый график
                        analyticsCard(
                            title: "Этажи",
                            data: flightsData,
                            chartView: BarChartView(data: flightsData.map { Int($0) }, color: .pink, title: "Этажи")
                        )

                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                loadData()
            }
        }
    }

    // Карточка для аналитики
    private func analyticsCard(title: String, data: [Double], chartView: some View) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text("Среднее: \(Int(data.average))")
                    .font(.title3)
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

    // Загрузка данных
    @State private var flightsData: [Double] = []

    private func loadData() {
        isLoading = true

        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        HealthManager.shared.fetchStepsForLast30Days { steps in
            self.stepsData = steps
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        HealthManager.shared.fetchCaloriesForLast30Days { calories in
            self.caloriesData = calories
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        HealthManager.shared.fetchDistanceForLast30Days { distance in
            self.distanceData = distance
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        HealthManager.shared.fetchFlightsForLast30Days { flights in
            self.flightsData = flights
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
        }
    }

        // Добавьте вызовы для калорий, дистанции и этажей
    
}

extension Array where Element: BinaryFloatingPoint {
    var average: Double {
        guard !isEmpty else { return 0 }
        let sum = self.reduce(0, +)
        return Double(sum) / Double(self.count)
    }
}
