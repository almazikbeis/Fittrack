//
//  BarcodeScannerView.swift
//  FitnessApp
//
//  AVFoundation-based barcode scanner wrapped as SwiftUI view.
//  Supports EAN-8, EAN-13, UPC-E, QR, DataMatrix.
//

import SwiftUI
import UIKit
import AVFoundation

// MARK: - SwiftUI wrapper

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> BarcodeScannerVC {
        let vc = BarcodeScannerVC()
        vc.onScan   = onScan
        vc.onCancel = onCancel
        return vc
    }
    func updateUIViewController(_ uiViewController: BarcodeScannerVC, context: Context) {}
    func makeCoordinator() -> Void {}
}

// MARK: - BarcodeScannerVC

final class BarcodeScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan:   ((String) -> Void)?
    var onCancel: (() -> Void)?

    private let session      = AVCaptureSession()
    private var preview:     AVCaptureVideoPreviewLayer?
    private var scanFrame:   UIView?
    private var scanLine:    UIView?
    private var hasScanned   = false
    private var lineAnim:    CABasicAnimation?

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
        startLineAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if session.isRunning { session.stopRunning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.bounds
    }

    // MARK: Camera setup

    private func setupCamera() {
        guard
            let device = AVCaptureDevice.default(for: .video),
            let input  = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else { return }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .qr, .dataMatrix]

        let p = AVCaptureVideoPreviewLayer(session: session)
        p.videoGravity = .resizeAspectFill
        p.frame = view.bounds
        view.layer.addSublayer(p)
        preview = p
    }

    // MARK: Overlay UI

    private func setupOverlay() {
        // Dimming
        let dim = UIView(frame: view.bounds)
        dim.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(dim)

        // Central scan frame (clear hole)
        let frameW: CGFloat = UIScreen.main.bounds.width * 0.72
        let frameH: CGFloat = 150
        let frameX = (view.bounds.width  - frameW) / 2
        let frameY = (view.bounds.height - frameH) / 2 - 40

        let frameView = UIView(frame: CGRect(x: frameX, y: frameY, width: frameW, height: frameH))
        frameView.backgroundColor   = .clear
        frameView.layer.borderColor = UIColor.white.cgColor
        frameView.layer.borderWidth = 2.5
        frameView.layer.cornerRadius = 16
        frameView.clipsToBounds = true
        view.addSubview(frameView)
        scanFrame = frameView

        // Corner accents (TL, TR, BL, BR)
        addCorner(to: view, x: frameX,           y: frameY,           w: 20, h: 20, corners: [.topLeft])
        addCorner(to: view, x: frameX+frameW-20,  y: frameY,           w: 20, h: 20, corners: [.topRight])
        addCorner(to: view, x: frameX,           y: frameY+frameH-20, w: 20, h: 20, corners: [.bottomLeft])
        addCorner(to: view, x: frameX+frameW-20,  y: frameY+frameH-20, w: 20, h: 20, corners: [.bottomRight])

        // Scan line
        let line = UIView(frame: CGRect(x: frameX + 8, y: frameY + 4, width: frameW - 16, height: 2))
        line.backgroundColor = UIColor(red: 0.13, green: 0.77, blue: 0.45, alpha: 1)
        line.layer.cornerRadius = 1
        view.addSubview(line)
        scanLine = line

        // Label
        let label         = UILabel()
        label.text        = "Наведите камеру на штрихкод"
        label.textColor   = .white
        label.font        = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        // Close button
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "xmark.circle.fill",
                             withConfiguration: UIImage.SymbolConfiguration(pointSize: 28))!, for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: 20)
        ])
    }

    private func addCorner(to view: UIView, x: CGFloat, y: CGFloat,
                           w: CGFloat, h: CGFloat, corners: UIRectCorner) {
        let v       = UIView(frame: CGRect(x: x, y: y, width: w, height: h))
        let border  = CAShapeLayer()
        border.path = UIBezierPath(
            roundedRect: v.bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: 6, height: 6)
        ).cgPath
        border.strokeColor  = UIColor(red: 0.13, green: 0.77, blue: 0.45, alpha: 1).cgColor
        border.fillColor    = UIColor.clear.cgColor
        border.lineWidth    = 4
        v.layer.addSublayer(border)
        view.addSubview(v)
    }

    private func startLineAnimation() {
        guard let scanLine, let scanFrame else { return }

        let start = scanFrame.frame.minY + 4
        let end   = scanFrame.frame.maxY - 6

        let anim              = CABasicAnimation(keyPath: "position.y")
        anim.fromValue        = start
        anim.toValue          = end
        anim.duration         = 1.6
        anim.repeatCount      = .infinity
        anim.autoreverses     = true
        anim.timingFunction   = CAMediaTimingFunction(name: .easeInEaseOut)
        scanLine.layer.add(anim, forKey: "scanLine")
    }

    // MARK: AVCapture delegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput objects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !hasScanned,
              let obj  = objects.first as? AVMetadataMachineReadableCodeObject,
              let code = obj.stringValue
        else { return }

        hasScanned = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        session.stopRunning()
        onScan?(code)
    }

    @objc private func closeTapped() {
        onCancel?()
    }
}
