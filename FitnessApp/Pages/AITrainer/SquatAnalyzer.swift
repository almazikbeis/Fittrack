import Vision
import Combine

@MainActor
final class SquatAnalyzer: ObservableObject {
    enum Phase { case standing, descending, bottom, ascending }

    @Published var repCount: Int = 0
    @Published var phase: Phase  = .standing
    @Published var feedback      = "Встань прямо перед камерой"
    @Published var formScore: Double = 1.0

    private var repResults: [RepResult] = []
    private var currentRepScore: Double = 1.0
    private var formSum: Double = 0

    func analyze(pose: BodyPose) {
        let kneeAngle = pose.angle(a: .leftHip,   b: .leftKnee,  c: .leftAnkle)
                     ?? pose.angle(a: .rightHip,  b: .rightKnee, c: .rightAnkle)

        guard let knee = kneeAngle else {
            feedback = "Встань в кадр полностью"
            return
        }

        updatePhase(knee: knee)
        updateFeedback(knee: knee)
    }

    private func updatePhase(knee: Double) {
        switch phase {
        case .standing:
            if knee < 150 { phase = .descending }
        case .descending:
            if knee < 115 { phase = .bottom; currentRepScore = 1.0 }
            else if knee > 165 { phase = .standing }
        case .bottom:
            let quality = (knee >= 80 && knee <= 110) ? 1.0 : 0.6
            currentRepScore = min(currentRepScore, quality)
            if knee > 125 { phase = .ascending }
        case .ascending:
            if knee > 162 {
                repCount += 1
                repResults.append(RepResult(repNumber: repCount, formScore: currentRepScore, timestamp: Date()))
                formSum  += currentRepScore
                formScore = formSum / Double(repResults.count)
                phase     = .standing
            }
        }
    }

    private func updateFeedback(knee: Double) {
        switch phase {
        case .standing, .ascending:
            feedback = knee > 158 ? "Отлично! Приседай" : "Выпрямись до конца"
        case .descending:
            feedback = "Вниз... ещё глубже ⬇️"
        case .bottom:
            if knee >= 80 && knee <= 110      { feedback = "Идеально! Вверх 🔥" }
            else if knee > 110               { feedback = "Глубже! Ещё немного" }
            else                             { feedback = "Слишком глубоко, держи форму" }
        }
    }

    func sessionResult(duration: TimeInterval) -> SessionResult {
        let avg = repResults.isEmpty ? 0.0 : formSum / Double(repResults.count)
        return SessionResult(
            exercise: .squats,
            reps: repCount,
            duration: duration,
            formScore: avg,
            xpEarned: repCount * ExerciseType.squats.xpPerUnit
        )
    }

    func reset() {
        repCount        = 0
        phase           = .standing
        feedback        = "Встань прямо перед камерой"
        formScore       = 1.0
        repResults      = []
        currentRepScore = 1.0
        formSum         = 0
    }
}
