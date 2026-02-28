//
//  AnalyticsView.swift
//  FitnessApp
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @State private var stepsData: [Double] = []
    @State private var caloriesData: [Double] = []
    @State private var distanceData: [Double] = []
    @State private var flightsData: [Double] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    if isLoading {
                        loadingView
                    } else {
                        // Summary grid
                        summaryGrid
                            .padding(.horizontal)

                        // Charts
                        chartCard(
                            title: "Шаги",
                            subtitle: "Среднее за день: \(Int(stepsData.average))",
                            icon: "figure.walk",
                            color: .blue,
                            chartView: LineChartView(data: stepsData.map { Int($0) }, color: .blue, title: "Шаги")
                        )
                        .padding(.horizontal)

                        chartCard(
                            title: "Калории",
                            subtitle: "Среднее за день: \(Int(caloriesData.average)) ккал",
                            icon: "flame.fill",
                            color: .orange,
                            chartView: BarChartView(data: caloriesData.map { Int($0) }, color: .orange, title: "Калории")
                        )
                        .padding(.horizontal)

                        chartCard(
                            title: "Дистанция",
                            subtitle: "Среднее за день: \(String(format: "%.2f", distanceData.average / 1000)) км",
                            icon: "location.fill",
                            color: .purple,
                            chartView: LineChartView(data: distanceData.map { Int($0) }, color: .purple, title: "Дистанция")
                        )
                        .padding(.horizontal)

                        chartCard(
                            title: "Этажи",
                            subtitle: "Среднее за день: \(Int(flightsData.average))",
                            icon: "stairs",
                            color: .pink,
                            chartView: BarChartView(data: flightsData.map { Int($0) }, color: .pink, title: "Этажи")
                        )
                        .padding(.horizontal)
                    }

                    Spacer().frame(height: 110)
                }
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Аналитика")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Последние 30 дней")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .padding(.top, 60)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(.primaryGreen)
            Text("Загрузка данных...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(60)
    }

    // MARK: - Summary Grid

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard(
                title: "Шаги",
                value: formatNumber(Int(stepsData.reduce(0, +))),
                unit: "всего",
                icon: "figure.walk",
                color: .blue
            )
            summaryCard(
                title: "Калории",
                value: formatNumber(Int(caloriesData.reduce(0, +))),
                unit: "ккал сожжено",
                icon: "flame.fill",
                color: .orange
            )
            summaryCard(
                title: "Дистанция",
                value: String(format: "%.0f", distanceData.reduce(0, +) / 1000),
                unit: "км пройдено",
                icon: "location.fill",
                color: .purple
            )
            summaryCard(
                title: "Этажи",
                value: "\(Int(flightsData.reduce(0, +)))",
                unit: "этажей",
                icon: "stairs",
                color: .pink
            )
        }
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Chart Card

    private func chartCard(title: String, subtitle: String, icon: String, color: Color, chartView: some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

            chartView
                .frame(height: 180)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helpers

    private func formatNumber(_ n: Int) -> String {
        if n >= 1000 { return String(format: "%.1fk", Double(n) / 1000) }
        return "\(n)"
    }

    private func loadData() {
        isLoading = true
        let group = DispatchGroup()

        group.enter()
        HealthManager.shared.fetchStepsForLast30Days { steps in
            self.stepsData = steps
            group.leave()
        }
        group.enter()
        HealthManager.shared.fetchCaloriesForLast30Days { calories in
            self.caloriesData = calories
            group.leave()
        }
        group.enter()
        HealthManager.shared.fetchDistanceForLast30Days { distance in
            self.distanceData = distance
            group.leave()
        }
        group.enter()
        HealthManager.shared.fetchFlightsForLast30Days { flights in
            self.flightsData = flights
            group.leave()
        }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
}

extension Array where Element: BinaryFloatingPoint {
    var average: Double {
        guard !isEmpty else { return 0 }
        return Double(self.reduce(0, +)) / Double(self.count)
    }
}
