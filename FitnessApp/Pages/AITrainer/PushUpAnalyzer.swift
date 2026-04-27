import Vision
import Combine

@MainActor
final class PushUpAnalyzer: ObservableObject {
    enum Phase { case top, descending, bottom, ascending }

    @Published var repCount: Int = 0
    @Published var phase: Phase  = .top
    @Published var feedback      = "Прими упор лёжа"
    @Published var formScore: Double = 1.0

    private var repResults: [RepResult] = []
    private var currentRepScore: Double = 1.0
    private var formSum: Double = 0

    func analyze(pose: BodyPose) {
        let elbowAngle = pose.angle(a: .leftShoulder,  b: .leftElbow,  c: .leftWrist)
                      ?? pose.angle(a: .rightShoulder, b: .rightElbow, c: .rightWrist)
        let hipAngle   = pose.angle(a: .leftShoulder,  b: .leftHip,   c: .leftKnee)
                      ?? pose.angle(a: .rightShoulder, b: .rightHip,  c: .rightKnee)

        guard let elbow = elbowAngle else {
            feedback = "Ляг в кадр горизонтально"
            return
        }

        updatePhase(elbow: elbow, hip: hipAngle)
        updateFeedback(elbow: elbow, hip: hipAngle)
    }

    private func updatePhase(elbow: Double, hip: Double?) {
        switch phase {
        case .top:
            if elbow < 140 { phase = .descending }
        case .descending:
            if elbow < 100 { phase = .bottom; currentRepScore = 1.0 }
            else if elbow > 155 { phase = .top }
        case .bottom:
            let elbowOk = elbow >= 80 && elbow <= 100
            let hipOk   = hip.map { $0 >= 160 } ?? true
            currentRepScore = min(currentRepScore, (elbowOk ? 0.5 : 0.0) + (hipOk ? 0.5 : 0.0))
            if elbow > 115 { phase = .ascending }
        case .ascending:
            if elbow > 152 {
                repCount += 1
                repResults.append(RepResult(repNumber: repCount, formScore: currentRepScore, timestamp: Date()))
                formSum  += currentRepScore
                formScore = formSum / Double(repResults.count)
                phase     = .top
            }
        }
    }

    private func updateFeedback(elbow: Double, hip: Double?) {
        let bodyBent = hip.map { $0 < 155 } ?? false

        switch phase {
        case .top, .ascending:
            feedback = bodyBent ? "Держи тело прямым!" : (elbow > 155 ? "Вниз! Опускайся" : "Выпрямись вверху")
        case .descending:
            feedback = "Ниже... локти к телу"
        case .bottom:
            if bodyBent              { feedback = "Опусти таз ровно!" }
            else if elbow >= 80 && elbow <= 100 { feedback = "Держи! Теперь вверх 💪" }
            else if elbow > 100      { feedback = "Глубже! Ещё чуть" }
            else                     { feedback = "Хорошо, поднимайся" }
        }
    }

    func sessionResult(duration: TimeInterval) -> SessionResult {
        let avg = repResults.isEmpty ? 0.0 : formSum / Double(repResults.count)
        return SessionResult(
            exercise: .pushUps,
            reps: repCount,
            duration: duration,
            formScore: avg,
            xpEarned: repCount * ExerciseType.pushUps.xpPerUnit
        )
    }

    func reset() {
        repCount        = 0
        phase           = .top
        feedback        = "Прими упор лёжа"
        formScore       = 1.0
        repResults      = []
        currentRepScore = 1.0
        formSum         = 0
    }
}
