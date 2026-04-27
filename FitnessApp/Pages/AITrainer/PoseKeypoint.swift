import Vision
import CoreGraphics

struct PoseKeypoint: Equatable {
    let name: VNHumanBodyPoseObservation.JointName
    let point: CGPoint
    let confidence: Float

    var isReliable: Bool { confidence > 0.4 }
}

typealias BodyPose = [VNHumanBodyPoseObservation.JointName: PoseKeypoint]

extension BodyPose {
    func angle(
        a: VNHumanBodyPoseObservation.JointName,
        b: VNHumanBodyPoseObservation.JointName,
        c: VNHumanBodyPoseObservation.JointName
    ) -> Double? {
        guard let pa = self[a], let pb = self[b], let pc = self[c],
              pa.isReliable, pb.isReliable, pc.isReliable else { return nil }

        let v1 = CGVector(dx: pa.point.x - pb.point.x, dy: pa.point.y - pb.point.y)
        let v2 = CGVector(dx: pc.point.x - pb.point.x, dy: pc.point.y - pb.point.y)
        let dot   = v1.dx * v2.dx + v1.dy * v2.dy
        let cross = v1.dx * v2.dy - v1.dy * v2.dx
        return Double(abs(atan2(cross, dot))) * 180.0 / Double.pi
    }

    // Vision origin is bottom-left; flip y for screen coordinates
    func screenPoint(
        _ joint: VNHumanBodyPoseObservation.JointName,
        in size: CGSize
    ) -> CGPoint? {
        guard let kp = self[joint], kp.isReliable else { return nil }
        return CGPoint(x: kp.point.x * size.width, y: (1 - kp.point.y) * size.height)
    }
}
