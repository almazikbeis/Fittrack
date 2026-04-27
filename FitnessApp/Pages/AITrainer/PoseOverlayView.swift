import SwiftUI
import Vision

struct PoseOverlayView: View {
    let pose: BodyPose
    let size: CGSize

    private typealias Joint = VNHumanBodyPoseObservation.JointName

    private let connections: [(Joint, Joint)] = [
        (.neck, .leftShoulder), (.neck, .rightShoulder),
        (.leftShoulder, .rightShoulder),
        (.leftShoulder, .leftHip), (.rightShoulder, .rightHip),
        (.leftHip, .rightHip),
        (.leftShoulder, .leftElbow),  (.leftElbow, .leftWrist),
        (.rightShoulder, .rightElbow), (.rightElbow, .rightWrist),
        (.leftHip, .leftKnee),   (.leftKnee, .leftAnkle),
        (.rightHip, .rightKnee), (.rightKnee, .rightAnkle),
    ]

    private let joints: [Joint] = [
        .neck,
        .leftShoulder, .rightShoulder,
        .leftElbow,    .rightElbow,
        .leftWrist,    .rightWrist,
        .leftHip,      .rightHip,
        .leftKnee,     .rightKnee,
        .leftAnkle,    .rightAnkle,
    ]

    var body: some View {
        Canvas { ctx, canvasSize in
            guard size != .zero else { return }
            let sx = canvasSize.width  / size.width
            let sy = canvasSize.height / size.height

            for (a, b) in connections {
                guard
                    let pa = pose.screenPoint(a, in: size),
                    let pb = pose.screenPoint(b, in: size)
                else { continue }

                var path = Path()
                path.move(to:    CGPoint(x: pa.x * sx, y: pa.y * sy))
                path.addLine(to: CGPoint(x: pb.x * sx, y: pb.y * sy))
                ctx.stroke(path, with: .color(.white.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            for joint in joints {
                guard let pt = pose.screenPoint(joint, in: size) else { continue }
                let center = CGPoint(x: pt.x * sx, y: pt.y * sy)
                let dot = CGRect(x: center.x - 5, y: center.y - 5, width: 10, height: 10)
                ctx.fill(Path(ellipseIn: dot), with: .color(.primaryGreen))
                ctx.stroke(Path(ellipseIn: dot), with: .color(.white.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.5))
            }
        }
    }
}
