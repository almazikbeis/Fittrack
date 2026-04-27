//
//  FoodEntryDTO.swift
//  FitnessApp
//
//  Transfer object for the `food_entries` Supabase table.
//

import Foundation

struct FoodEntryDTO: Codable {
    var id:        UUID
    var userId:    String
    var localId:   UUID?
    var name:      String
    var date:      Date
    var mealType:  String
    var calories:  Double
    var protein:   Double
    var fat:       Double
    var carbs:     Double
    var weight:    Double
    var photoUrl:  String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId   = "user_id"
        case localId  = "local_id"
        case name, date, calories, protein, fat, carbs, weight
        case mealType = "meal_type"
        case photoUrl = "photo_url"
    }

    static func from(_ e: FoodEntry, userId: String) -> FoodEntryDTO {
        // Build remote photo URL if photo was uploaded to Supabase Storage
        let photoUrl: String? = e.photoPath.flatMap { name in
            "\(AppSecrets.supabaseURL)/storage/v1/object/public/food-photos/\(userId)/\(name).jpg"
        }

        return FoodEntryDTO(
            id:       UUID(),
            userId:   userId,
            localId:  e.id,
            name:     e.name     ?? "",
            date:     e.date     ?? Date(),
            mealType: e.mealType ?? "",
            calories: e.calories,
            protein:  e.protein,
            fat:      e.fat,
            carbs:    e.carbs,
            weight:   e.weight,
            photoUrl: photoUrl
        )
    }
}
