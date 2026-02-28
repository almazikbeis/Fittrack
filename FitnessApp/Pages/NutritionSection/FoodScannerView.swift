//
//  FoodScannerView.swift
//  FitnessApp
//
//  Cal AI–style food photo scanner.
//  States: idle → scanning → result / error
//

import SwiftUI
import PhotosUI

// MARK: - State

private enum ScanState: Equatable {
    case idle
    case scanning
    case result
    case error(String)
}

// MARK: - View

struct FoodScannerView: View {
    let mealType: String
    /// Called with (result, capturedImage, chosenPortionGrams) when user taps Add
    let onAdd: (FoodAnalysisResult, UIImage, Double) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var scanState: ScanState = .idle
    @State private var capturedImage: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var analysisResult: FoodAnalysisResult?
    @State private var portionGrams: Double = 200
    @State private var showCamera = false

    // Animations
    @State private var scanLineY: CGFloat = -130
    @State private var resultCardOffset: CGFloat = 500
    @State private var pulseOpacity: Double = 0

    var meal: MealType { MealType(rawValue: mealType) ?? .breakfast }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch scanState {
            case .idle:    idleView
            case .scanning: scanningView
            case .result:  resultView
            case .error(let msg): errorView(msg)
            }
        }
        .onChange(of: pickerItem) { Task { await loadPickerPhoto() } }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView { img in
                capturedImage = img
                Task { await startAnalysis(img) }
            }
        }
        .statusBarHidden(true)
    }

    // ── IDLE ──────────────────────────────────────────────────────────────────

    private var idleView: some View {
        VStack(spacing: 0) {
            idleHeader

            Spacer()

            // Viewfinder frame
            ZStack {
                // Dimmed background
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color.white.opacity(0.18),
                            style: StrokeStyle(lineWidth: 1.5, dash: [10, 8]))
                    .frame(width: 270, height: 270)

                // Corner brackets
                cornerBrackets(size: 270, radius: 28)

                VStack(spacing: 14) {
                    Image(systemName: "fork.knife.circle")
                        .font(.system(size: 52))
                        .foregroundColor(.white.opacity(0.35))
                    Text("Наведите камеру\nна блюдо")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 14) {
                // Camera
                Button(action: { showCamera = true }) {
                    Label("Сделать фото", systemImage: "camera.fill")
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(LinearGradient.primaryGradient)
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .shadow(color: Color.primaryGreen.opacity(0.45), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())

                // Gallery
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Выбрать из галереи", systemImage: "photo.on.rectangle.angled")
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.10))
                        .foregroundColor(.white)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 56)
        }
    }

    private var idleHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            VStack(spacing: 3) {
                Text("Сканировать еду")
                    .font(.headline).foregroundColor(.white)
                HStack(spacing: 5) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(meal.gradient).frame(width: 20, height: 20)
                        Image(systemName: meal.icon)
                            .font(.system(size: 10)).foregroundColor(.white)
                    }
                    Text(mealType)
                        .font(.caption).foregroundColor(.white.opacity(0.65))
                }
            }

            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    // ── SCANNING ──────────────────────────────────────────────────────────────

    private var scanningView: some View {
        ZStack {
            // Full bleed blurred photo
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 3)
                    .overlay(Color.black.opacity(0.55))
            }

            VStack(spacing: 32) {
                // Cropped photo with scan animation
                ZStack {
                    if let img = capturedImage {
                        Image(uiImage: img)
                            .resizable().scaledToFill()
                            .frame(width: 300, height: 300)
                            .cornerRadius(24).clipped()
                    }

                    // Scan line
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.clear, Color.primaryGreen.opacity(0.85), .clear],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 300, height: 5)
                        .cornerRadius(2.5)
                        .offset(y: scanLineY)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.3)
                                            .repeatForever(autoreverses: true)) {
                                scanLineY = 130
                            }
                        }

                    // Green frame
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.primaryGreen, lineWidth: 1.5)
                        .frame(width: 300, height: 300)

                    // Corner highlights
                    cornerBrackets(size: 300, radius: 24)
                }

                // Pulsing dots + label
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { i in
                            BouncingDot(delay: Double(i) * 0.18)
                        }
                    }
                    Text("ИИ анализирует блюдо...")
                        .font(.headline).foregroundColor(.white)
                    Text("Определяю КБЖУ по фото")
                        .font(.caption).foregroundColor(.white.opacity(0.55))
                }
            }
        }
    }

    // ── RESULT ────────────────────────────────────────────────────────────────

    private var resultView: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed photo background
            if let img = capturedImage {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .ignoresSafeArea()
                    .overlay(
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.7)],
                            startPoint: .center, endPoint: .bottom)
                        .ignoresSafeArea()
                    )
            }

            // Top buttons
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(Color.black.opacity(0.4)).clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Spacer()

                    Button(action: { resetToIdle() }) {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Пересканировать")
                                .font(.caption).fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.black.opacity(0.4)).cornerRadius(20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 20).padding(.top, 60)
                Spacer()
            }

            // Slide-up result card
            if let result = analysisResult {
                resultCard(result)
                    .offset(y: resultCardOffset)
                    .onAppear {
                        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                            resultCardOffset = 0
                        }
                    }
            }
        }
    }

    private func resultCard(_ r: FoodAnalysisResult) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(Color(.systemGray4))
                .frame(width: 36, height: 4)
                .padding(.top, 12).padding(.bottom, 18)

            VStack(spacing: 16) {
                // Name + AI badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(r.name)
                            .font(.title3).fontWeight(.bold)
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11))
                            Text("ИИ уверен на \(Int(r.confidence * 100))%")
                                .font(.caption2).fontWeight(.semibold)
                        }
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.primaryGreen.opacity(0.10))
                        .cornerRadius(10)
                    }
                    Spacer()
                    // Meal badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 12).fill(meal.gradient)
                            .frame(width: 46, height: 46)
                        Image(systemName: meal.icon)
                            .font(.system(size: 20)).foregroundColor(.white)
                    }
                }

                // Macro strip
                HStack(spacing: 0) {
                    macroBlock("\(Int(r.calories(for: portionGrams)))", "ккал", .primaryGreen)
                    macroBlock("\(Int(r.protein(for: portionGrams)))г",  "белки", .nutritionPurple)
                    macroBlock("\(Int(r.fat(for: portionGrams)))г",      "жиры", .cardioOrange)
                    macroBlock("\(Int(r.carbs(for: portionGrams)))г",    "углев", .nutritionBlue)
                }
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(16)

                // Portion slider
                VStack(spacing: 8) {
                    HStack {
                        Text("Размер порции")
                            .font(.subheadline).fontWeight(.medium)
                        Spacer()
                        Text("\(Int(portionGrams)) г")
                            .font(.subheadline).fontWeight(.bold)
                            .foregroundColor(.primaryGreen)
                    }
                    HStack(spacing: 10) {
                        Button { portionGrams = max(10, portionGrams - 25) } label: {
                            Image(systemName: "minus")
                                .frame(width: 34, height: 34)
                                .background(Color(.systemGray5)).clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Slider(value: $portionGrams, in: 10...800, step: 5)
                            .tint(.primaryGreen)

                        Button { portionGrams = min(800, portionGrams + 25) } label: {
                            Image(systemName: "plus")
                                .frame(width: 34, height: 34)
                                .background(Color.primaryGreen.opacity(0.14)).clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                // CTA
                Button(action: confirmAdd) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                        Text("Добавить в \(mealType)")
                            .font(.headline).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 17)
                    .background(LinearGradient.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(18)
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .cornerRadius(30, corners: [.topLeft, .topRight])
    }

    private func macroBlock(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.headline).fontWeight(.bold).foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // ── ERROR ─────────────────────────────────────────────────────────────────

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                Circle().fill(Color.red.opacity(0.12)).frame(width: 100, height: 100)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 42)).foregroundColor(.red)
            }
            VStack(spacing: 8) {
                Text("Ошибка распознавания")
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
                Text(message)
                    .font(.subheadline).foregroundColor(.white.opacity(0.65))
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Spacer()
            VStack(spacing: 12) {
                Button(action: resetToIdle) {
                    Text("Попробовать снова")
                        .font(.headline).fontWeight(.semibold)
                        .frame(maxWidth: .infinity).padding(.vertical, 17)
                        .background(LinearGradient.primaryGradient)
                        .foregroundColor(.white).cornerRadius(18)
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: { dismiss() }) {
                    Text("Отмена")
                        .font(.subheadline).foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 28).padding(.bottom, 52)
        }
    }

    // ── Corner brackets helper ────────────────────────────────────────────────

    private func cornerBrackets(size: CGFloat, radius: CGFloat) -> some View {
        let half = size / 2
        let len: CGFloat = 22
        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let xs: CGFloat = i < 2 ? -1 : 1
                let ys: CGFloat = i % 2 == 0 ? -1 : 1
                bracketShape(len: len)
                    .stroke(Color.primaryGreen,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: len, height: len)
                    .rotationEffect(.degrees(Double(i) * 90))
                    .offset(x: xs * (half - len / 2 + 2),
                            y: ys * (half - len / 2 + 2))
            }
        }
    }

    private func bracketShape(len: CGFloat) -> Path {
        Path { p in
            p.move(to: .init(x: 0, y: len))
            p.addLine(to: .init(x: 0, y: 0))
            p.addLine(to: .init(x: len, y: 0))
        }
    }

    // ── Logic ─────────────────────────────────────────────────────────────────

    private func loadPickerPhoto() async {
        guard let item = pickerItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let img  = UIImage(data: data) else { return }
        capturedImage = img
        await startAnalysis(img)
    }

    private func startAnalysis(_ img: UIImage) async {
        withAnimation(.easeInOut(duration: 0.3)) { scanState = .scanning }
        do {
            let result = try await FoodRecognitionService.shared.analyze(image: img)
            portionGrams = result.estimatedWeightG
            analysisResult = result
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                scanState = .result
            }
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation { scanState = .error(error.localizedDescription) }
        }
    }

    private func confirmAdd() {
        guard let result = analysisResult, let img = capturedImage else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onAdd(result, img, portionGrams)
        dismiss()
    }

    private func resetToIdle() {
        capturedImage  = nil
        analysisResult = nil
        pickerItem     = nil
        scanLineY      = -130
        resultCardOffset = 500
        withAnimation(.easeInOut(duration: 0.25)) { scanState = .idle }
    }
}

// MARK: - Camera Picker

struct CameraPickerView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        // Fall back to photo library in simulator (no camera)
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera : .photoLibrary
        p.delegate   = context.coordinator
        return p
    }
    func updateUIViewController(_: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate,
                       UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ p: CameraPickerView) { parent = p }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let img = info[.originalImage] as? UIImage { parent.onCapture(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Bouncing Dot

private struct BouncingDot: View {
    let delay: Double
    @State private var up = false

    var body: some View {
        Circle()
            .fill(Color.primaryGreen)
            .frame(width: 9, height: 9)
            .offset(y: up ? -8 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(delay)) { up = true }
            }
    }
}
