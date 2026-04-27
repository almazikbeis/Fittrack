import SwiftUI
import AVFoundation

struct ExerciseSessionView: View {
    let exercise: ExerciseType

    @StateObject private var engine = PoseDetectionEngine()
    @StateObject private var squat  = SquatAnalyzer()
    @StateObject private var pushUp = PushUpAnalyzer()
    @StateObject private var plank  = PlankAnalyzer()

    @Environment(\.dismiss) private var dismiss

    @State private var elapsed: Int = 0
    @State private var sessionTimer: Timer?
    @State private var isReady = false
    @State private var showSummary = false
    @State private var sessionResult: SessionResult?

    private let videoSize = CGSize(
        width: UIScreen.main.bounds.width,
        height: UIScreen.main.bounds.height
    )

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreviewView(session: engine.captureSession)
                .ignoresSafeArea()

            PoseOverlayView(pose: engine.currentPose, size: videoSize)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                Spacer()
                feedbackBubble
                bottomPanel
            }
            .ignoresSafeArea(edges: .top)
        }
        .statusBarHidden()
        .onAppear {
            engine.start()
            startTimer()
        }
        .onDisappear {
            engine.stop()
            sessionTimer?.invalidate()
        }
        .task {
            for await pose in engine.$currentPose.values {
                guard isReady else { continue }
                switch exercise {
                case .squats:  squat.analyze(pose: pose)
                case .pushUps: pushUp.analyze(pose: pose)
                case .plank:   plank.analyze(pose: pose)
                }
            }
        }
        .fullScreenCover(isPresented: $showSummary) {
            if let result = sessionResult {
                ExerciseSummaryView(result: result) { dismiss() }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                sessionTimer?.invalidate()
                engine.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(isReady ? Color.primaryGreen : .orange)
                    .frame(width: 8, height: 8)
                    .glowPulse(color: isReady ? .primaryGreen : .orange, radius: 6)
                Text(formatTime(elapsed))
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)

            Spacer()

            Text("\(Int(engine.fps)) fps")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .frame(width: 50)
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
    }

    // MARK: - Feedback

    private var feedbackBubble: some View {
        Text(currentFeedback)
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.25), radius: 8)
            .padding(.bottom, 16)
            .animation(.easeInOut(duration: 0.2), value: currentFeedback)
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(exercise.isTimeBased ? formatTime(plank.timeHeld) : "\(currentReps)")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(exercise.isTimeBased ? "секунд" : "повторений")
                    .font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("\(Int(currentFormScore * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(formScoreColor)
                Text("форма")
                    .font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Button { finishSession() } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(exercise.gradient)
                        .clipShape(Circle())
                        .shadow(color: exercise.accentColor.opacity(0.5), radius: 10)
                }
                Text("готово")
                    .font(.subheadline).foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24).padding(.vertical, 24)
        .background(.ultraThinMaterial)
        .cornerRadius(28, corners: [.topLeft, .topRight])
    }

    // MARK: - Helpers

    private var currentReps: Int {
        switch exercise {
        case .squats:  return squat.repCount
        case .pushUps: return pushUp.repCount
        case .plank:   return plank.timeHeld
        }
    }

    private var currentFeedback: String {
        switch exercise {
        case .squats:  return squat.feedback
        case .pushUps: return pushUp.feedback
        case .plank:   return plank.feedback
        }
    }

    private var currentFormScore: Double {
        switch exercise {
        case .squats:  return squat.formScore
        case .pushUps: return pushUp.formScore
        case .plank:   return plank.formScore
        }
    }

    private var formScoreColor: Color {
        currentFormScore >= 0.8 ? .primaryGreen : currentFormScore >= 0.6 ? .cardioOrange : .cardioRed
    }

    private func formatTime(_ s: Int) -> String {
        String(format: "%02d:%02d", s / 60, s % 60)
    }

    private func startTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { isReady = true }
        }
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            elapsed += 1
        }
    }

    private func finishSession() {
        sessionTimer?.invalidate()
        engine.stop()
        let duration = TimeInterval(elapsed)
        sessionResult = switch exercise {
        case .squats:  squat.sessionResult(duration: duration)
        case .pushUps: pushUp.sessionResult(duration: duration)
        case .plank:   plank.sessionResult()
        }
        if let xp = sessionResult?.xpEarned {
            GamificationEngine.shared.addXP(xp, source: .workout)
        }
        showSummary = true
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> _CameraHostView { _CameraHostView(session: session) }
    func updateUIView(_ uiView: _CameraHostView, context: Context) {}
}

final class _CameraHostView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }
    required init?(coder: NSCoder) { fatalError() }
}
