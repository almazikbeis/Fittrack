//
//  TrackingView.swift
//  FitnessApp
//

import SwiftUI
import MapKit

struct TrackingView: View {
    @StateObject private var locationManager = LocationManager()
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var isTracking = false
    @State private var distance: Double = 0.0
    @State private var timeElapsed: Int = 0
    @State private var showSavedAlert = false
    @State private var showHistory = false
    @State private var timer: Timer? = nil
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottom) {
            // Полноэкранная карта с полилинией маршрута
            Map(position: $cameraPosition) {
                // Позиция пользователя
                UserAnnotation()

                // Маршрут бега (полилиния)
                if locationManager.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: locationManager.routeCoordinates)
                        .stroke(
                            LinearGradient(
                                colors: [.primaryGreen, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                        )
                }

                // Маркер старта
                if let first = locationManager.routeCoordinates.first {
                    Annotation("Старт", coordinate: first) {
                        ZStack {
                            Circle()
                                .fill(Color.primaryGreen)
                                .frame(width: 18, height: 18)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 18, height: 18)
                            Text("S")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Маркер последней точки
                if locationManager.routeCoordinates.count > 1,
                   let last = locationManager.routeCoordinates.last {
                    Annotation("Сейчас", coordinate: last) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 18, height: 18)
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 18, height: 18)
                        }
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea()
            .onAppear { locationManager.requestAuthorization() }

            // Верхний overlay (заголовок + история + REC)
            VStack {
                headerOverlay
                Spacer()
            }

            // Нижняя панель со статистикой и кнопками
            bottomPanel
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showHistory) {
            RunHistoryView()
                .environment(\.managedObjectContext, viewContext)
        }
        .alert(isPresented: $showSavedAlert) {
            Alert(
                title: Text("🎉 Тренировка сохранена!"),
                message: Text("Дистанция: \(String(format: "%.2f", distance)) км\nВремя: \(formattedTime())\nТемп: \(paceText) мин/км"),
                dismissButton: .default(Text("Отлично!"))
            )
        }
        .onDisappear { stopTracking() }
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Трекинг")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(isTracking ? "Запись активна" : "Готов к старту")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()

            // REC индикатор
            if isTracking {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                                pulseScale = 1.6
                            }
                        }
                        .onDisappear { pulseScale = 1.0 }
                    Text("REC")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.5))
                .cornerRadius(20)
            }

            // Кнопка история
            Button(action: { showHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }

            // Кнопка закрытия
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 30)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Bottom Panel

    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Три метрики
            HStack(spacing: 0) {
                statItem(
                    icon: "location.fill",
                    label: "Дистанция",
                    value: String(format: "%.2f", distance),
                    unit: "км",
                    color: .primaryGreen
                )
                Divider().frame(height: 44).opacity(0.25)
                statItem(
                    icon: "timer",
                    label: "Время",
                    value: formattedTime(),
                    unit: "",
                    color: .blue
                )
                Divider().frame(height: 44).opacity(0.25)
                statItem(
                    icon: "speedometer",
                    label: "Темп",
                    value: paceText,
                    unit: "мин/км",
                    color: .orange
                )
            }
            .padding(.vertical, 20)
            .background(Color(.systemBackground))

            Divider()

            // Кнопки управления
            VStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isTracking ? stopTracking() : startTracking()
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: isTracking ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 24))
                        Text(isTracking ? "Остановить" : "Начать тренировку")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Group {
                            if isTracking {
                                RoundedRectangle(cornerRadius: 16).fill(Color.red)
                            } else {
                                RoundedRectangle(cornerRadius: 16).fill(LinearGradient.primaryGradient)
                            }
                        }
                    )
                    .foregroundColor(.white)
                    .shadow(
                        color: isTracking ? Color.red.opacity(0.4) : Color.primaryGreen.opacity(0.4),
                        radius: 10, x: 0, y: 4
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                if !isTracking && distance > 0 {
                    Button(action: saveRun) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22))
                            Text("Сохранить тренировку")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.primaryGreen, lineWidth: 1.5)
                        )
                        .foregroundColor(.primaryGreen)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 36)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(30, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.14), radius: 20, x: 0, y: -5)
    }

    private func statItem(icon: String, label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(unit.isEmpty ? label : "\(label)\n\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tracking Logic

    private func startTracking() {
        locationManager.startTracking()
        distance = 0
        timeElapsed = 0
        isTracking = true
        // Камера следует за пользователем
        cameraPosition = .userLocation(fallback: .automatic)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            calculateDistance()
        }
    }

    private func stopTracking() {
        locationManager.stopTracking()
        timer?.invalidate()
        timer = nil
        isTracking = false
        // Показать весь маршрут на карте
        if let region = routeBoundingRegion() {
            withAnimation(.easeInOut(duration: 0.8)) {
                cameraPosition = .region(region)
            }
        }
    }

    private func saveRun() {
        let newWorkout = Workout(context: viewContext)
        newWorkout.id = UUID()
        newWorkout.name = "Пробежка"
        newWorkout.type = "Кардио"
        newWorkout.distance = distance
        newWorkout.time = Int16(timeElapsed / 60)
        newWorkout.date = Date()
        newWorkout.completed = true
        try? viewContext.save()
        showSavedAlert = true
        resetTracking()
    }

    private func resetTracking() {
        distance = 0
        timeElapsed = 0
    }

    private func calculateDistance() {
        guard locationManager.route.count > 1 else { return }
        var total: Double = 0
        for i in 1..<locationManager.route.count {
            total += locationManager.route[i].distance(from: locationManager.route[i - 1])
        }
        distance = total / 1000.0
    }

    private func routeBoundingRegion() -> MKCoordinateRegion? {
        let coords = locationManager.routeCoordinates
        guard coords.count > 1 else { return nil }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(lats.max()! - lats.min()!, 0.005) * 1.8,
            longitudeDelta: max(lons.max()! - lons.min()!, 0.005) * 1.8
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    // MARK: - Helpers

    private var paceText: String {
        guard distance > 0, timeElapsed > 0 else { return "--:--" }
        let secs = Double(timeElapsed) / distance
        let m = Int(secs / 60)
        let s = Int(secs) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    private func formattedTime() -> String {
        let m = timeElapsed / 60
        let s = timeElapsed % 60
        return String(format: "%02d:%02d", m, s)
    }
}
