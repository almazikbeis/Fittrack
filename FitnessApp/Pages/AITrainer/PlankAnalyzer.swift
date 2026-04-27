import Vision
import Combine

@MainActor
final class PlankAnalyzer: ObservableObject {
    @Published var timeHeld: Int = 0
    @Published var feedback      = "Прими позицию планки"
    @Published var formScore: Double = 1.0
    @Published var isInPosition  = false

    private var holdStart: Date?
    private var accumulatedTime: TimeInterval = 0  // total time across all holds
    private var formSamples: [Double] = []
    private var formSum: Double = 0
    private let maxFormSamples = 1800  // 60s at 30fps

    func analyze(pose: BodyPose) {
        let hipAngle = pose.angle(a: .leftShoulder,  b: .leftHip,  c: .leftKnee)
                    ?? pose.angle(a: .rightShoulder, b: .rightHip, c: .rightKnee)
        let bodyVisible = pose[.leftShoulder]?.isReliable == true
                       || pose[.rightShoulder]?.isReliable == true

        guard bodyVisible, let hip = hipAngle else {
            if !bodyVisible { feedback = "Встань в кадр боком" }
            snapHoldIfNeeded()
            return
        }

        let nowInPosition = hip >= 150

        if nowInPosition && !isInPosition {
            holdStart    = Date()
            isInPosition = true
        } else if !nowInPosition && isInPosition {
            snapHoldIfNeeded()
        }

        if isInPosition, let start = holdStart {
            timeHeld = Int(accumulatedTime + Date().timeIntervalSince(start))
        }

        let sample: Double = hip >= 168 ? 1.0 : hip >= 155 ? 0.75 : 0.4
        appendFormSample(sample)
        updateFeedback(hip: hip)
    }

    private func snapHoldIfNeeded() {
        if isInPosition, let start = holdStart {
            accumulatedTime += Date().timeIntervalSince(start)
        }
        isInPosition = false
        holdStart    = nil
    }

    private func appendFormSample(_ value: Double) {
        if formSamples.count >= maxFormSamples {
            formSum -= formSamples.removeFirst()
        }
        formSamples.append(value)
        formSum += value
        formScore = formSum / Double(formSamples.count)
    }

    private func updateFeedback(hip: Double) {
        if hip >= 168       { feedback = "Идеально! Держи 🔥" }
        else if hip >= 155  { feedback = "Хорошо, не опускай таз" }
        else if hip >= 140  { feedback = "Подними таз! ⬆️" }
        else                { feedback = "Слишком высоко, опусти таз" }
    }

    func sessionResult() -> SessionResult {
        snapHoldIfNeeded()
        let finalTime = Int(accumulatedTime)
        let avg = formSamples.isEmpty ? 0.0 : formSum / Double(formSamples.count)
        return SessionResult(
            exercise: .plank,
            reps: finalTime,
            duration: accumulatedTime,
            formScore: avg,
            xpEarned: finalTime * ExerciseType.plank.xpPerUnit
        )
    }

    func reset() {
        timeHeld        = 0
        feedback        = "Прими позицию планки"
        formScore       = 1.0
        isInPosition    = false
        holdStart       = nil
        accumulatedTime = 0
        formSamples     = []
        formSum         = 0
    }
}
