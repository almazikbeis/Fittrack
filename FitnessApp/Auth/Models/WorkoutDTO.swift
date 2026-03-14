//
//  WorkoutDTO.swift
//  FitnessApp
//
//  Transfer object for the `workouts` Supabase table.
//

import Foundation

struct WorkoutDTO: Codable {
    var id:        UUID
    var userId:    String
    var localId:   UUID?
    var name:      String
    var type:      String
    var date:      Date
    var completed: Bool
    var weight:    Double
    var sets:      Int
    var reps:      Int
    var distance:  Double
    var time:      Int
    var notes:     String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId   = "user_id"
        case localId  = "local_id"
        case name, type, date, completed
        case weight, sets, reps, distance, time, notes
    }

    static func from(_ w: Workout, userId: String) -> WorkoutDTO {
        WorkoutDTO(
            id:        UUID(),
            userId:    userId,
            localId:   w.id,
            name:      w.name      ?? "",
            type:      w.type      ?? "",
            date:      w.date      ?? Date(),
            completed: w.completed,
            weight:    w.weight,
            sets:      Int(w.sets),
            reps:      Int(w.reps),
            distance:  w.distance,
            time:      Int(w.time),
            notes:     w.notes
        )
    }
}
