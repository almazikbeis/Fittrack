import Foundation

struct RepResult {
    let repNumber: Int
    let formScore: Double
    let timestamp: Date
}

struct SessionResult {
    let exercise: ExerciseType
    let reps: Int
    let duration: TimeInterval
    let formScore: Double
    let xpEarned: Int
}
