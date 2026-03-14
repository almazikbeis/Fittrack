//
//  GoalsView.swift
//  FitnessApp
//
//  Editable goals sheet — saves to Supabase via AuthViewModel.
//

import SwiftUI

struct GoalsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    // Local editing state (init from current profile)
    @State private var calGoal:         Int    = 2000
    @State private var proteinGoal:     Int    = 150
    @State private var fatGoal:         Int    = 65
    @State private var carbsGoal:       Int    = 250
    @State private var stepsGoal:       Int    = 10000
    @State private var waterGoal:       Int    = 8
    @State private var workoutsPerWeek: Int    = 3
    @State private var cardioKmPerDay:  Double = 5.0
    @State private var targetWeight:    Double = 70.0

    @State private var isSaving = false
    @State private var saved    = false

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    goalsSection(
                        title: "Питание",
                        icon: "fork.knife",
                        color: .nutritionPurple
                    ) {
                        intGoalRow("Калории", value: $calGoal, range: 1200...5000, step: 50, unit: "ккал", color: .cardioOrange)
                        Divider().padding(.horizontal)
                        intGoalRow("Белки",   value: $proteinGoal, range: 30...300, step: 5, unit: "г", color: .nutritionPurple)
                        Divider().padding(.horizontal)
                        intGoalRow("Жиры",    value: $fatGoal, range: 20...200, step: 5, unit: "г", color: .cardioOrange)
                        Divider().padding(.horizontal)
                        intGoalRow("Углеводы", value: $carbsGoal, range: 50...500, step: 10, unit: "г", color: .nutritionBlue)
                    }

                    goalsSection(
                        title: "Активность",
                        icon: "figure.walk",
                        color: .primaryGreen
                    ) {
                        intGoalRow("Шаги в день", value: $stepsGoal, range: 2000...30000, step: 500, unit: "шаг", color: .primaryGreen)
                        Divider().padding(.horizontal)
                        intGoalRow("Стаканы воды", value: $waterGoal, range: 4...16, step: 1, unit: "ст.", color: .waterBlue)
                    }

                    goalsSection(
                        title: "Тренировки",
                        icon: "dumbbell.fill",
                        color: .strengthPurple
                    ) {
                        intGoalRow("Трен. в неделю", value: $workoutsPerWeek, range: 1...14, step: 1, unit: "раз", color: .strengthPurple)
                        Divider().padding(.horizontal)
                        doubleGoalRow("Кардио км/день", value: $cardioKmPerDay, range: 1...50, step: 0.5, unit: "км", color: .cardioOrange)
                        Divider().padding(.horizontal)
                        doubleGoalRow("Целевой вес", value: $targetWeight, range: 30...200, step: 0.5, unit: "кг", color: .primaryGreen)
                    }

                    Spacer().frame(height: 20)
                }
                .padding(.horizontal)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Мои цели")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text(saved ? "Сохранено ✓" : "Сохранить")
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryGreen)
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear(perform: loadCurrentGoals)
    }

    // MARK: - Section Builder

    private func goalsSection<Content: View>(title: String, icon: String, color: Color,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 30, height: 30)
                    Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
                }
                Text(title).font(.subheadline).fontWeight(.semibold)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            Divider()
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func intGoalRow(_ label: String, value: Binding<Int>,
                              range: ClosedRange<Int>, step: Int,
                              unit: String, color: Color) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                Text("\(value.wrappedValue) \(unit)")
                    .font(.caption).foregroundColor(color).fontWeight(.semibold)
            }
            Spacer()
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func doubleGoalRow(_ label: String, value: Binding<Double>,
                                 range: ClosedRange<Double>, step: Double,
                                 unit: String, color: Color) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.subheadline)
                Text(String(format: "%.1f \(unit)", value.wrappedValue))
                    .font(.caption).foregroundColor(color).fontWeight(.semibold)
            }
            Spacer()
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Load / Save

    private func loadCurrentGoals() {
        guard let p = auth.profile else {
            // Fall back to @AppStorage values
            calGoal         = UserDefaults.standard.integer(forKey: "goalCalories").nonZero(or: 2000)
            proteinGoal     = UserDefaults.standard.integer(forKey: "goalProtein").nonZero(or: 150)
            fatGoal         = UserDefaults.standard.integer(forKey: "goalFat").nonZero(or: 65)
            carbsGoal       = UserDefaults.standard.integer(forKey: "goalCarbs").nonZero(or: 250)
            stepsGoal       = UserDefaults.standard.integer(forKey: "goalSteps").nonZero(or: 10000)
            waterGoal       = UserDefaults.standard.integer(forKey: "goalWater").nonZero(or: 8)
            workoutsPerWeek = 3
            cardioKmPerDay  = 5.0
            targetWeight    = UserDefaults.standard.double(forKey: "userWeight").nonZero(or: 70)
            return
        }
        calGoal         = p.goalCalories
        proteinGoal     = p.goalProtein
        fatGoal         = p.goalFat
        carbsGoal       = p.goalCarbs
        stepsGoal       = p.goalSteps
        waterGoal       = p.goalWater
        workoutsPerWeek = p.goalWorkoutsPerWeek
        cardioKmPerDay  = p.goalCardioKmPerDay
        targetWeight    = p.goalTargetWeight
    }

    private func save() {
        isSaving = true
        let goals = UserGoalsUpdate(
            goalCalories:        calGoal,
            goalProtein:         proteinGoal,
            goalFat:             fatGoal,
            goalCarbs:           carbsGoal,
            goalSteps:           stepsGoal,
            goalWater:           waterGoal,
            goalWorkoutsPerWeek: workoutsPerWeek,
            goalCardioKmPerDay:  cardioKmPerDay,
            goalTargetWeight:    targetWeight,
            updatedAt:           Date()
        )
        Task {
            await auth.saveGoals(goals)
            isSaving = false
            withAnimation { saved = true }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
        }
    }
}

// MARK: - Helpers

private extension Int {
    func nonZero(or fallback: Int) -> Int { self == 0 ? fallback : self }
}
private extension Double {
    func nonZero(or fallback: Double) -> Double { self == 0 ? fallback : self }
}
