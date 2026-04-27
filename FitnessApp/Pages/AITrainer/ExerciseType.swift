import SwiftUI

enum ExerciseType: String, CaseIterable, Identifiable {
    case squats   = "Приседания"
    case pushUps  = "Отжимания"
    case plank    = "Планка"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .squats:  return "figure.strengthtraining.traditional"
        case .pushUps: return "figure.strengthtraining.functional"
        case .plank:   return "figure.core.training"
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .squats:  return .strengthGradient
        case .pushUps: return .cardioGradient
        case .plank:   return LinearGradient(
            colors: [.waterCyan, .waterDeep],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        }
    }

    var accentColor: Color {
        switch self {
        case .squats:  return .strengthPurple
        case .pushUps: return .cardioOrange
        case .plank:   return .waterCyan
        }
    }

    var description: String {
        switch self {
        case .squats:  return "Ноги и ягодицы · Угол 90°"
        case .pushUps: return "Грудь и трицепс · Локти 90°"
        case .plank:   return "Кор и стабилизация · Время"
        }
    }

    var isTimeBased: Bool { self == .plank }

    var xpPerUnit: Int {
        switch self {
        case .squats, .pushUps: return 5
        case .plank:            return 2
        }
    }
}
