//
//  RunHistoryView.swift
//  FitnessApp
//

import SwiftUI

struct RunHistoryView: View {
    @Environment(\.presentationMode) var presentationMode

    @FetchRequest(
        entity: Workout.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: false)],
        predicate: NSPredicate(format: "type == %@", "Кардио")
    ) private var runs: FetchedResults<Workout>

    // Статистика за всё время
    private var totalDistance: Double { runs.reduce(0) { $0 + $1.distance } }
    private var totalTime: Int { runs.reduce(0) { $0 + Int($1.time) } }
    private var totalRuns: Int { runs.count }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Общая статистика
                        if !runs.isEmpty {
                            totalStatsCard
                                .padding(.horizontal)
                        }

                        // Список пробежек
                        VStack(spacing: 12) {
                            if runs.isEmpty {
                                emptyState
                            } else {
                                ForEach(runs, id: \.self) { run in
                                    RunCard(run: run)
                                }
                                .padding(.horizontal)
                            }
                        }

                        Spacer().frame(height: 30)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("История пробежек")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { presentationMode.wrappedValue.dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                }
            }
        }
    }

    // MARK: - Total Stats Card

    private var totalStatsCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Всего за всё время")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Image(systemName: "flame.fill")
                    .foregroundColor(.white.opacity(0.8))
            }

            HStack(spacing: 0) {
                totalStatItem(value: String(format: "%.1f", totalDistance), label: "км")
                Divider().frame(height: 36).background(Color.white.opacity(0.3))
                totalStatItem(value: "\(totalRuns)", label: "пробежек")
                Divider().frame(height: 36).background(Color.white.opacity(0.3))
                totalStatItem(value: "\(totalTime)", label: "минут")
            }
        }
        .padding(20)
        .background(LinearGradient.cardioGradient)
        .cornerRadius(22)
        .shadow(color: Color.cardioOrange.opacity(0.35), radius: 14, x: 0, y: 6)
    }

    private func totalStatItem(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.35))
                .padding(.top, 40)
            Text("Нет пробежек")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Запишите свою первую пробежку\nс помощью GPS трекинга")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

// MARK: - Run Card

struct RunCard: View {
    let run: Workout

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy • HH:mm"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: run.date ?? Date())
    }

    private var pace: String {
        guard run.distance > 0, run.time > 0 else { return "--:--" }
        let secs = Double(run.time) * 60.0 / run.distance
        let m = Int(secs / 60)
        let s = Int(secs) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    var body: some View {
        HStack(spacing: 16) {
            // Иконка
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient.cardioGradient)
                    .frame(width: 52, height: 52)
                Image(systemName: "figure.run")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }

            // Основная информация
            VStack(alignment: .leading, spacing: 4) {
                Text(run.name ?? "Пробежка")
                    .font(.headline)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Метрики
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundColor(.cardioOrange)
                    Text(String(format: "%.2f км", run.distance))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("\(run.time) мин")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                Text("⚡ \(pace) мин/км")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
