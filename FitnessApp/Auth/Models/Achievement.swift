//
//  Achievement.swift
//  FitnessApp
//
//  Achievement model + service that computes unlocked badges from local data.
//

import SwiftUI

// MARK: - Model

struct Achievement: Identifiable {
    let id:          String
    let title:       String
    let description: String
    let icon:        String          // SF Symbol name
    let color:       Color
    let gradient:    LinearGradient
    var isUnlocked:  Bool
    var unlockedDate: Date?
}

// MARK: - Catalog

extension Achievement {
    static let catalog: [Achievement] = [
        Achievement(
            id: "first_workout",
            title: "Первый шаг",
            description: "Выполнить первую тренировку",
            icon: "figure.walk",
            color: .primaryGreen,
            gradient: .primaryGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "streak_3",
            title: "3 дня подряд",
            description: "Тренироваться 3 дня без перерыва",
            icon: "flame.fill",
            color: .cardioOrange,
            gradient: .cardioGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "streak_7",
            title: "Неделя силы",
            description: "7-дневная серия тренировок",
            icon: "bolt.fill",
            color: .strengthPurple,
            gradient: .strengthGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "streak_30",
            title: "Месяц побед",
            description: "30-дневная серия тренировок",
            icon: "trophy.fill",
            color: Color(red: 1, green: 0.8, blue: 0),
            gradient: LinearGradient(colors: [Color(red: 1, green: 0.85, blue: 0.1), Color(red: 0.85, green: 0.6, blue: 0)], startPoint: .topLeading, endPoint: .bottomTrailing),
            isUnlocked: false
        ),
        Achievement(
            id: "distance_5",
            title: "Первые 5 км",
            description: "Пробежать суммарно 5 км",
            icon: "figure.run",
            color: .primaryGreen,
            gradient: .primaryGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "distance_50",
            title: "50 км позади",
            description: "Суммарно 50 км кардио",
            icon: "road.lanes",
            color: .nutritionBlue,
            gradient: LinearGradient(colors: [.nutritionBlue, .waterBlue], startPoint: .topLeading, endPoint: .bottomTrailing),
            isUnlocked: false
        ),
        Achievement(
            id: "distance_100",
            title: "Сотка!",
            description: "Суммарно 100 км кардио",
            icon: "medal.fill",
            color: Color(red: 1, green: 0.75, blue: 0),
            gradient: LinearGradient(colors: [Color(red: 1, green: 0.8, blue: 0.1), Color(red: 0.9, green: 0.55, blue: 0)], startPoint: .topLeading, endPoint: .bottomTrailing),
            isUnlocked: false
        ),
        Achievement(
            id: "steps_10k",
            title: "10 000 шагов",
            description: "Пройти 10 000 шагов за один день",
            icon: "shoe.fill",
            color: .cardioOrange,
            gradient: .cardioGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "nutrition_scan",
            title: "Шеф-повар",
            description: "Отсканировать блюдо через ИИ",
            icon: "camera.viewfinder",
            color: .nutritionPurple,
            gradient: .nutritionGradient,
            isUnlocked: false
        ),
        Achievement(
            id: "nutrition_week",
            title: "Неделя питания",
            description: "Логировать еду 7 дней подряд",
            icon: "fork.knife",
            color: .primaryGreen,
            gradient: .primaryGradient,
            isUnlocked: false
        )
    ]
}

// MARK: - Service

struct AchievementService {

    /// Compute which achievements are unlocked based on local data.
    static func compute(workouts: [Workout],
                        foodEntries: [FoodEntry],
                        maxDailySteps: Double = 0) -> [Achievement] {
        var result = Achievement.catalog

        let totalWorkouts = workouts.count
        let completedWorkouts = workouts.filter { $0.completed }
        let totalCardioKm = workouts
            .filter { $0.type == "Кардио" }
            .reduce(0.0) { $0 + $1.distance }

        let streak = computeStreak(from: completedWorkouts)
        let nutritionStreak = computeNutritionStreak(from: foodEntries)
        let hasAIScanned = foodEntries.contains { $0.photoPath != nil }

        for i in result.indices {
            switch result[i].id {
            case "first_workout":
                result[i].isUnlocked = totalWorkouts >= 1
            case "streak_3":
                result[i].isUnlocked = streak >= 3
            case "streak_7":
                result[i].isUnlocked = streak >= 7
            case "streak_30":
                result[i].isUnlocked = streak >= 30
            case "distance_5":
                result[i].isUnlocked = totalCardioKm >= 5
            case "distance_50":
                result[i].isUnlocked = totalCardioKm >= 50
            case "distance_100":
                result[i].isUnlocked = totalCardioKm >= 100
            case "steps_10k":
                result[i].isUnlocked = maxDailySteps >= 10_000
            case "nutrition_scan":
                result[i].isUnlocked = hasAIScanned
            case "nutrition_week":
                result[i].isUnlocked = nutritionStreak >= 7
            default:
                break
            }
        }

        return result
    }

    // MARK: - Helpers

    private static func computeStreak(from workouts: [Workout]) -> Int {
        let cal = Calendar.current
        let days = Set(workouts.compactMap { w -> Date? in
            guard let d = w.date else { return nil }
            return cal.startOfDay(for: d)
        }).sorted(by: >)

        guard !days.isEmpty else { return 0 }
        var streak = 1
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i], to: days[i-1]).day ?? 0
            if diff == 1 { streak += 1 } else { break }
        }
        return streak
    }

    private static func computeNutritionStreak(from entries: [FoodEntry]) -> Int {
        let cal = Calendar.current
        let days = Set(entries.compactMap { e -> Date? in
            guard let d = e.date else { return nil }
            return cal.startOfDay(for: d)
        }).sorted(by: >)

        guard !days.isEmpty else { return 0 }
        var streak = 1
        for i in 1..<days.count {
            let diff = cal.dateComponents([.day], from: days[i], to: days[i-1]).day ?? 0
            if diff == 1 { streak += 1 } else { break }
        }
        return streak
    }
}
