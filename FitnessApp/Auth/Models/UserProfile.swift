//
//  UserProfile.swift
//  FitnessApp
//
//  Codable mirror of the `profiles` Supabase table.
//

import Foundation

// MARK: - Main Profile

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var name: String
    var age: Int
    var weight: Double
    var height: Double
    var avatarURL: String?

    // Nutrition goals
    var goalCalories: Int
    var goalProtein:  Int
    var goalFat:      Int
    var goalCarbs:    Int
    var goalSteps:    Int
    var goalWater:    Int

    // Workout goals
    var goalWorkoutsPerWeek: Int
    var goalCardioKmPerDay:  Double
    var goalTargetWeight:    Double

    // Notification prefs
    var notifWorkoutReminders:   Bool
    var notifNutritionReminders: Bool
    var notifAchievementAlerts:  Bool

    var lastSyncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, age, weight, height
        case avatarURL               = "avatar_url"
        case goalCalories            = "goal_calories"
        case goalProtein             = "goal_protein"
        case goalFat                 = "goal_fat"
        case goalCarbs               = "goal_carbs"
        case goalSteps               = "goal_steps"
        case goalWater               = "goal_water"
        case goalWorkoutsPerWeek     = "goal_workouts_per_week"
        case goalCardioKmPerDay      = "goal_cardio_km_per_day"
        case goalTargetWeight        = "goal_target_weight"
        case notifWorkoutReminders   = "notif_workout_reminders"
        case notifNutritionReminders = "notif_nutrition_reminders"
        case notifAchievementAlerts  = "notif_achievement_alerts"
        case lastSyncedAt            = "last_synced_at"
    }

    // Convenience computed
    var bmi: Double {
        let h = height / 100
        return weight / (h * h)
    }
}

// MARK: - Update Payloads

struct UserProfileUpdate: Codable {
    var id:        UUID
    var name:      String
    var age:       Int
    var weight:    Double
    var height:    Double
    // Default goals included so Supabase can INSERT new row without NULLs
    var goalCalories:        Int    = 2000
    var goalProtein:         Int    = 150
    var goalFat:             Int    = 65
    var goalCarbs:           Int    = 250
    var goalSteps:           Int    = 10000
    var goalWater:           Int    = 8
    var goalWorkoutsPerWeek: Int    = 3
    var goalCardioKmPerDay:  Double = 5.0
    var goalTargetWeight:    Double = 70.0
    var notifWorkoutReminders:   Bool = true
    var notifNutritionReminders: Bool = true
    var notifAchievementAlerts:  Bool = true
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, age, weight, height
        case goalCalories            = "goal_calories"
        case goalProtein             = "goal_protein"
        case goalFat                 = "goal_fat"
        case goalCarbs               = "goal_carbs"
        case goalSteps               = "goal_steps"
        case goalWater               = "goal_water"
        case goalWorkoutsPerWeek     = "goal_workouts_per_week"
        case goalCardioKmPerDay      = "goal_cardio_km_per_day"
        case goalTargetWeight        = "goal_target_weight"
        case notifWorkoutReminders   = "notif_workout_reminders"
        case notifNutritionReminders = "notif_nutrition_reminders"
        case notifAchievementAlerts  = "notif_achievement_alerts"
        case updatedAt               = "updated_at"
    }
}

struct UserGoalsUpdate: Codable {
    var goalCalories:        Int
    var goalProtein:         Int
    var goalFat:             Int
    var goalCarbs:           Int
    var goalSteps:           Int
    var goalWater:           Int
    var goalWorkoutsPerWeek: Int
    var goalCardioKmPerDay:  Double
    var goalTargetWeight:    Double
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case goalCalories        = "goal_calories"
        case goalProtein         = "goal_protein"
        case goalFat             = "goal_fat"
        case goalCarbs           = "goal_carbs"
        case goalSteps           = "goal_steps"
        case goalWater           = "goal_water"
        case goalWorkoutsPerWeek = "goal_workouts_per_week"
        case goalCardioKmPerDay  = "goal_cardio_km_per_day"
        case goalTargetWeight    = "goal_target_weight"
        case updatedAt           = "updated_at"
    }
}

struct UserNotifUpdate: Codable {
    var notifWorkoutReminders:   Bool
    var notifNutritionReminders: Bool
    var notifAchievementAlerts:  Bool
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case notifWorkoutReminders   = "notif_workout_reminders"
        case notifNutritionReminders = "notif_nutrition_reminders"
        case notifAchievementAlerts  = "notif_achievement_alerts"
        case updatedAt               = "updated_at"
    }
}
