//
//  WeightLogView.swift
//  FitnessApp
//
//  Body weight history: log daily weight, view trend line chart.
//  Data stored in UserDefaults as JSON (no CoreData migration needed).
//

import SwiftUI
import Charts

// MARK: - Model

struct WeightEntry: Codable, Identifiable {
    let id:     UUID
    let date:   Date
    let weight: Double

    init(weight: Double, date: Date = Date()) {
        self.id     = UUID()
        self.date   = date
        self.weight = weight
    }
}

// MARK: - Storage helper

final class WeightLogStore: ObservableObject {
    static let shared = WeightLogStore()

    @Published private(set) var entries: [WeightEntry] = []

    private let key = "weightLogEntries"

    private init() { load() }

    func add(weight: Double) {
        let today = Calendar.current.startOfDay(for: Date())
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: today) }
        entries.append(WeightEntry(weight: weight, date: today))
        entries.sort { $0.date < $1.date }
        save()
    }

    func delete(entry: WeightEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data)
        else { return }
        entries = decoded
    }
}

// MARK: - View

struct WeightLogView: View {
    @StateObject private var store  = WeightLogStore.shared
    @AppStorage("userWeight") private var profileWeight: Double = 70.0

    @State private var weightInput  = ""
    @State private var showInput    = false
    @State private var animateChart = false

    @Environment(\.dismiss) private var dismiss

    private var last30: [WeightEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return store.entries.filter { $0.date >= cutoff }
    }

    private var minWeight: Double { (last30.map(\.weight).min() ?? profileWeight) - 2 }
    private var maxWeight: Double { (last30.map(\.weight).max() ?? profileWeight) + 2 }
    private var trend: Double? {
        guard last30.count >= 2 else { return nil }
        return last30.last!.weight - last30.first!.weight
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        summaryCards
                        chartCard
                        logCard
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Вес тела")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showInput = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showInput) { addWeightSheet }
            .onAppear {
                withAnimation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.2)) {
                    animateChart = true
                }
            }
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            summaryCard(
                value: last30.last.map { String(format: "%.1f", $0.weight) } ?? String(format: "%.1f", profileWeight),
                unit: "кг",
                label: "Сейчас",
                color: .primaryGreen
            )
            summaryCard(
                value: trend.map { String(format: "%+.1f", $0) } ?? "—",
                unit: "кг",
                label: "За 30 дней",
                color: trendColor
            )
            summaryCard(
                value: last30.isEmpty ? "—" : String(format: "%.1f", last30.map(\.weight).reduce(0,+) / Double(last30.count)),
                unit: "кг",
                label: "Среднее",
                color: .nutritionBlue
            )
        }
    }

    private func summaryCard(value: String, unit: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value).font(.title3).fontWeight(.bold).foregroundColor(color)
                Text(unit).font(.caption2).foregroundColor(.secondary)
            }
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private var trendColor: Color {
        guard let t = trend else { return .secondary }
        return t <= 0 ? .primaryGreen : .cardioOrange
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("График веса", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                if let t = trend {
                    HStack(spacing: 4) {
                        Image(systemName: t <= 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                        Text(String(format: "%+.1f кг", t))
                    }
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(trendColor)
                }
            }

            if last30.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32)).foregroundColor(.secondary.opacity(0.3))
                        Text("Добавьте первую запись")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(last30) { entry in
                        LineMark(
                            x: .value("Дата", entry.date),
                            y: .value("Вес", animateChart ? entry.weight : (last30.first?.weight ?? entry.weight))
                        )
                        .foregroundStyle(LinearGradient.primaryGradient)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Дата", entry.date),
                            yStart: .value("Min", minWeight),
                            yEnd:   .value("Вес", animateChart ? entry.weight : (last30.first?.weight ?? entry.weight))
                        )
                        .foregroundStyle(
                            LinearGradient(colors: [Color.primaryGreen.opacity(0.25), .clear],
                                           startPoint: .top, endPoint: .bottom)
                        )

                        PointMark(
                            x: .value("Дата", entry.date),
                            y: .value("Вес", animateChart ? entry.weight : (last30.first?.weight ?? entry.weight))
                        )
                        .foregroundStyle(Color.primaryGreen)
                        .symbolSize(30)
                    }
                }
                .chartYScale(domain: minWeight...maxWeight)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine().foregroundStyle(Color(.systemGray5))
                        AxisValueLabel(format: .dateTime.day().month(), centered: true)
                            .foregroundStyle(Color.secondary)
                            .font(.caption2)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisGridLine().foregroundStyle(Color(.systemGray5))
                        AxisValueLabel { if let v = val.as(Double.self) { Text("\(Int(v))кг").font(.caption2).foregroundColor(.secondary) } }
                    }
                }
                .frame(height: 180)
                .animation(.spring(response: 1.0, dampingFraction: 0.8), value: animateChart)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Log Card

    private var logCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("История")
                .font(.headline).fontWeight(.semibold)
                .padding(.horizontal, 18).padding(.top, 16).padding(.bottom, 10)

            Divider()

            if store.entries.isEmpty {
                Text("Нет записей")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(store.entries.reversed().prefix(20))) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entryDateString(entry.date))
                                .font(.subheadline).fontWeight(.medium)
                            Text(entryWeekdayString(entry.date))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.1f кг", entry.weight))
                            .font(.subheadline).fontWeight(.semibold)
                            .foregroundColor(.primaryGreen)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation { store.delete(entry: entry) }
                        } label: { Label("Удалить", systemImage: "trash") }
                    }
                    Divider().padding(.horizontal, 18)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Add Weight Sheet

    private var addWeightSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Текущий вес")
                    .font(.title2).fontWeight(.bold)

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    TextField("70.0", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .frame(width: 140)
                    Text("кг")
                        .font(.title2).foregroundColor(.secondary)
                }

                Button(action: addWeight) {
                    Text("Сохранить")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(LinearGradient.primaryGradient)
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(Double(weightInput) == nil)
                .opacity(Double(weightInput) != nil ? 1 : 0.5)
                .padding(.horizontal, 32)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { showInput = false }.foregroundColor(.secondary)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            weightInput = String(format: "%.1f", store.entries.last?.weight ?? profileWeight)
        }
    }

    private func entryDateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date)
    }

    private func entryWeekdayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: date).capitalized
    }

    private func addWeight() {
        guard let w = Double(weightInput), w > 0 else { return }
        store.add(weight: w)
        profileWeight = w
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showInput = false
    }
}
