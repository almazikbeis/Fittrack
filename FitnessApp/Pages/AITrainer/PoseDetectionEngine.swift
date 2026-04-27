import AVFoundation
import Vision
import Combine

final class PoseDetectionEngine: NSObject, ObservableObject {
    @Published var currentPose: BodyPose = [:]
    @Published var isRunning = false
    @Published var fps: Double = 0

    let captureSession = AVCaptureSession()

    private let videoOutput  = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "ai.trainer.session", qos: .userInteractive)
    private let poseRequest  = VNDetectHumanBodyPoseRequest()

    private var frameCount   = 0
    private var fpsTimestamp = Date()

    func start() {
        sessionQueue.async { [weak self] in
            self?.configure()
            self?.captureSession.startRunning()
            DispatchQueue.main.async { self?.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isRunning = false
                self?.currentPose = [:]
            }
        }
    }

    private func configure() {
        guard !captureSession.isRunning else { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input  = try? AVCaptureDeviceInput(device: device),
            captureSession.canAddInput(input)
        else { captureSession.commitConfiguration(); return }

        captureSession.addInput(input)
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        captureSession.commitConfiguration()
    }
}

extension PoseDetectionEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Front camera portrait: upMirrored is correct for portrait pose detection
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored)
        try? handler.perform([poseRequest])

        guard let observation = poseRequest.results?.first else {
            DispatchQueue.main.async { [weak self] in self?.currentPose = [:] }
            return
        }

        var pose: BodyPose = [:]
        if let points = try? observation.recognizedPoints(.all) {
            for (name, point) in points {
                pose[name] = PoseKeypoint(name: name, point: point.location, confidence: Float(point.confidence))
            }
        }

        frameCount += 1
        let elapsed = Date().timeIntervalSince(fpsTimestamp)
        if elapsed >= 1.0 {
            let measured = Double(frameCount) / elapsed
            frameCount   = 0
            fpsTimestamp = Date()
            DispatchQueue.main.async { [weak self] in self?.fps = measured }
        }

        DispatchQueue.main.async { [weak self] in self?.currentPose = pose }
    }
}
