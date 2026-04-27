//
//  TrackingView.swift
//  FitnessApp
//

import SwiftUI
import MapKit

enum RunPhase {
    case ready, running, paused, summary
}

struct TrackingView: View {
    @StateObject private var loc = LocationManager()
    @Environment(\.managedObjectContext) private var viewContext

    @State private var phase: RunPhase = .ready
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var summaryCamera: MapCameraPosition = .automatic
    @State private var distance: Double = 0.0
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer? = nil
    @State private var showHistory = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .bottom) {
            mapLayer

            VStack {
                headerOverlay
                Spacer()
            }

            switch phase {
            case .ready:   readyPanel
            case .running: runningPanel
            case .paused:  pausedPanel
            case .summary: Color.clear
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .overlay {
            if phase == .summary {
                summaryView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.45, dampingFraction: 0.82), value: phase)
            }
        }
        .sheet(isPresented: $showHistory) {
            RunHistoryView().environment(\.managedObjectContext, viewContext)
        }
        .onAppear { loc.requestAuthorization() }
        .onDisappear { if phase == .running { pauseRun() } }
    }

    // MARK: - Map

    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            if loc.routeCoordinates.count > 1 {
                MapPolyline(coordinates: loc.routeCoordinates)
                    .stroke(
                        LinearGradient(
                            colors: [.primaryGreen, Color(red: 0.0, green: 0.75, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
            }

            if let first = loc.routeCoordinates.first {
                Annotation("", coordinate: first) {
                    ZStack {
                        Circle().fill(Color.primaryGreen).frame(width: 20, height: 20)
                        Circle().stroke(Color.white, lineWidth: 3).frame(width: 20, height: 20)
                        Text("S").font(.system(size: 8, weight: .black)).foregroundColor(.white)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .ignoresSafeArea()
    }

    // MARK: - Header Overlay

    private var headerOverlay: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Бег")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(phase == .running ? "Запись активна" :
                     phase == .paused  ? "На паузе"       : "Готов к старту")
                    .font(.caption).foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            if phase == .running { recIndicator }

            Button(action: { showHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.black.opacity(0.42), in: Circle())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, DS.xxl)
        .padding(.top, 58)
        .padding(.bottom, 28)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.52), .clear],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private var recIndicator: some View {
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
            Text(formattedTime)
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.white)
                .monospacedDigit()
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.black.opacity(0.5), in: Capsule())
    }

    // MARK: - Ready Panel

    private var readyPanel: some View {
        VStack(spacing: 0) {
            dragHandle

            VStack(spacing: DS.xl) {
                HStack(spacing: 0) {
                    statItem(label: "Дистанция", value: "0.00", unit: "км",     color: .primaryGreen)
                    Divider().frame(height: 44).opacity(0.2)
                    statItem(label: "Темп",      value: "--:--", unit: "мин/км", color: .cardioOrange)
                    Divider().frame(height: 44).opacity(0.2)
                    statItem(label: "Время",     value: "00:00", unit: "",       color: .blue)
                }

                Button(action: startRun) {
                    HStack(spacing: DS.md) {
                        Image(systemName: "play.fill").font(.system(size: 20, weight: .bold))
                        Text("Начать пробежку").font(.headline).fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.lg)
                    .background(LinearGradient.primaryGradient,
                                in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
                    .foregroundColor(.white)
                    .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 5)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(DS.xxl)
        }
        .background(Color(.systemBackground))
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: -4)
    }

    // MARK: - Running Panel

    private var runningPanel: some View {
        VStack(spacing: 0) {
            dragHandle

            HStack(spacing: 0) {
                statItem(label: "Дистанция", value: String(format: "%.2f", distance), unit: "км",     color: .primaryGreen)
                Divider().frame(height: 44).opacity(0.2)
                statItem(label: "Темп",      value: paceText,                          unit: "мин/км", color: .cardioOrange)
                Divider().frame(height: 44).opacity(0.2)
                statItem(label: "Время",     value: formattedTime,                     unit: "",       color: .blue)
            }
            .padding(.top, DS.lg)

            HStack(spacing: DS.xxxl) {
                controlButton(icon: "pause.fill", label: "Пауза",
                              bg: Color(.secondarySystemBackground), fg: .primary,
                              action: pauseRun)

                VStack(spacing: 4) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.strengthPurple)
                    Text(String(format: "+%.0fm", loc.elevationGain))
                        .font(.system(size: 13, weight: .bold))
                    Text("Набор").font(.caption2).foregroundColor(.secondary)
                }

                controlButton(icon: "stop.fill", label: "Стоп",
                              bg: Color.cardioRed, fg: .white,
                              action: stopRun)
            }
            .padding(.horizontal, DS.xxl)
            .padding(.vertical, DS.xl)

            if !loc.splits.isEmpty {
                Divider().padding(.horizontal, DS.xxl)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.md) {
                        ForEach(loc.splits.suffix(3)) { split in
                            splitBadge(split)
                        }
                    }
                    .padding(.horizontal, DS.xxl).padding(.vertical, DS.md)
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: -4)
    }

    // MARK: - Paused Panel

    private var pausedPanel: some View {
        VStack(spacing: 0) {
            dragHandle

            HStack(spacing: 0) {
                statItem(label: "Дистанция", value: String(format: "%.2f", distance), unit: "км",     color: .primaryGreen)
                Divider().frame(height: 44).opacity(0.2)
                statItem(label: "Темп",      value: paceText,                          unit: "мин/км", color: .cardioOrange)
                Divider().frame(height: 44).opacity(0.2)
                statItem(label: "Время",     value: formattedTime,                     unit: "",       color: .blue)
            }
            .padding(.top, DS.lg)

            HStack(spacing: DS.lg) {
                Button(action: stopRun) {
                    HStack(spacing: DS.sm) {
                        Image(systemName: "stop.circle.fill").font(.system(size: 18))
                        Text("Завершить").font(.headline).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.lg)
                    .background(Color.cardioRed.opacity(0.1),
                                in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
                    .foregroundColor(.cardioRed)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                            .stroke(Color.cardioRed.opacity(0.3), lineWidth: 1.5)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: resumeRun) {
                    HStack(spacing: DS.sm) {
                        Image(systemName: "play.fill").font(.system(size: 18))
                        Text("Продолжить").font(.headline).fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.lg)
                    .background(LinearGradient.primaryGradient,
                                in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
                    .foregroundColor(.white)
                    .shadow(color: Color.primaryGreen.opacity(0.35), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, DS.xxl)
            .padding(.vertical, DS.xl)
        }
        .background(Color(.systemBackground))
        .cornerRadius(28, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.1), radius: 18, x: 0, y: -4)
    }

    // MARK: - Summary View

    private var summaryView: some View {
        ZStack(alignment: .top) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Static route map
                    Map(position: .constant(summaryCamera)) {
                        if loc.routeCoordinates.count > 1 {
                            MapPolyline(coordinates: loc.routeCoordinates)
                                .stroke(
                                    LinearGradient(
                                        colors: [.primaryGreen, Color(red: 0.0, green: 0.75, blue: 1.0)],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                        }
                        if let first = loc.routeCoordinates.first {
                            Annotation("", coordinate: first) {
                                Circle().fill(Color.primaryGreen).frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            }
                        }
                        if let last = loc.routeCoordinates.last {
                            Annotation("", coordinate: last) {
                                Circle().fill(Color.cardioRed).frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2.5))
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    .frame(height: 280)
                    .ignoresSafeArea(edges: .top)

                    VStack(spacing: DS.lg) {
                        VStack(spacing: DS.xs) {
                            Text("Пробежка завершена!")
                                .font(.title2).fontWeight(.black)
                            Text(runDateString)
                                .font(.subheadline).foregroundColor(.secondary)
                        }
                        .padding(.top, DS.xxl)

                        // Key stats 2×2
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                  spacing: DS.lg) {
                            summaryStatCard(icon: "figure.run",    title: "Дистанция",
                                           value: String(format: "%.2f", distance), unit: "км",
                                           color: .primaryGreen)
                            summaryStatCard(icon: "clock.fill",    title: "Время",
                                           value: formattedTime,                     unit: "",
                                           color: .blue)
                            summaryStatCard(icon: "speedometer",   title: "Средний темп",
                                           value: avgPaceText,                        unit: "мин/км",
                                           color: .cardioOrange)
                            summaryStatCard(icon: "mountain.2.fill", title: "Набор высоты",
                                           value: String(format: "%.0f", loc.elevationGain), unit: "м",
                                           color: .strengthPurple)
                        }
                        .padding(.horizontal, DS.lg)

                        // Splits
                        if !loc.splits.isEmpty {
                            splitsCard.padding(.horizontal, DS.lg)
                        }

                        // Actions
                        VStack(spacing: DS.md) {
                            Button(action: saveRun) {
                                HStack(spacing: DS.md) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Сохранить пробежку")
                                        .font(.headline).fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DS.lg)
                                .background(LinearGradient.primaryGradient,
                                            in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
                                .foregroundColor(.white)
                                .shadow(color: Color.primaryGreen.opacity(0.4), radius: 12, x: 0, y: 5)
                            }
                            .buttonStyle(ScaleButtonStyle())

                            Button(action: discardRun) {
                                Text("Не сохранять")
                                    .font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, DS.xxl)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
    }

    // MARK: - Summary Components

    private func summaryStatCard(icon: String, title: String,
                                 value: String, unit: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .iconBadge(color: color, radius: DS.rSM, size: 34)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(title)
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
    }

    private var splitsCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            Text("СПЛИТЫ").nrcLabel()

            VStack(spacing: 0) {
                ForEach(Array(loc.splits.enumerated()), id: \.element.id) { idx, split in
                    HStack {
                        Text("Км \(split.km)")
                            .font(.subheadline).fontWeight(.semibold)
                        Spacer()
                        Text(paceString(split.pace))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(paceColor(split.pace))
                        Text("мин/км")
                            .font(.caption).foregroundColor(.secondary)
                            .padding(.leading, 2)
                    }
                    .padding(.horizontal, DS.md)
                    .padding(.vertical, DS.md)

                    if idx < loc.splits.count - 1 {
                        Divider().padding(.horizontal, DS.md)
                    }
                }
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
    }

    private func splitBadge(_ split: RunSplit) -> some View {
        VStack(spacing: 2) {
            Text("Км \(split.km)")
                .font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary)
            Text(paceString(split.pace))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(paceColor(split.pace))
        }
        .padding(.horizontal, DS.md).padding(.vertical, DS.sm)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
    }

    private func statItem(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .minimumScaleFactor(0.65)
                .lineLimit(1)
                .monospacedDigit()
            Text(label)
                .font(.caption2).foregroundColor(.secondary)
            if !unit.isEmpty {
                Text(unit).font(.system(size: 9)).foregroundColor(.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func controlButton(icon: String, label: String,
                               bg: Color, fg: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(fg)
                    .frame(width: 60, height: 60)
                    .background(bg, in: Circle())
                Text(label).font(.caption).foregroundColor(.secondary)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var dragHandle: some View {
        Capsule()
            .fill(Color(.separator))
            .frame(width: 36, height: 4)
            .padding(.top, DS.md)
    }

    // MARK: - Run Control

    private func startRun() {
        loc.startTracking()
        distance = 0
        timeElapsed = 0
        cameraPosition = .userLocation(fallback: .automatic)
        startTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { phase = .running }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func pauseRun() {
        loc.pauseTracking()
        timer?.invalidate(); timer = nil
        fitCameraToRoute()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { phase = .paused }
    }

    private func resumeRun() {
        loc.resumeTracking()
        cameraPosition = .userLocation(fallback: .automatic)
        startTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { phase = .running }
    }

    private func stopRun() {
        loc.stopTracking()
        timer?.invalidate(); timer = nil
        if let region = boundingRegion() {
            summaryCamera = .region(region)
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) { phase = .summary }
    }

    private func saveRun() {
        let workout = Workout(context: viewContext)
        workout.id = UUID()
        workout.name = "Пробежка"
        workout.type = "Кардио"
        workout.distance = distance
        workout.time = Int16(timeElapsed / 60)
        workout.date = Date()
        workout.completed = true
        try? viewContext.save()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        resetRun()
    }

    private func discardRun() {
        resetRun()
    }

    private func resetRun() {
        loc.resetForNewRun()
        distance = 0
        timeElapsed = 0
        cameraPosition = .userLocation(fallback: .automatic)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) { phase = .ready }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            recalcDistance()
        }
    }

    private func recalcDistance() {
        guard loc.route.count > 1 else { return }
        var total: Double = 0
        for i in 1..<loc.route.count {
            total += loc.route[i].distance(from: loc.route[i - 1])
        }
        distance = total / 1000.0
    }

    private func fitCameraToRoute() {
        if let region = boundingRegion() {
            withAnimation(.easeInOut(duration: 0.8)) { cameraPosition = .region(region) }
        }
    }

    private func boundingRegion() -> MKCoordinateRegion? {
        let coords = loc.routeCoordinates
        guard coords.count > 1 else { return nil }
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude:  (lats.min()! + lats.max()!) / 2,
                longitude: (lons.min()! + lons.max()!) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta:  max(lats.max()! - lats.min()!, 0.005) * 1.8,
                longitudeDelta: max(lons.max()! - lons.min()!, 0.005) * 1.8
            )
        )
    }

    // MARK: - Formatted Values

    private var formattedTime: String {
        let h = timeElapsed / 3600
        let m = (timeElapsed % 3600) / 60
        let s = timeElapsed % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s)
                     : String(format: "%02d:%02d", m, s)
    }

    private var paceText: String {
        guard distance > 0.01, timeElapsed > 0 else { return "--:--" }
        return paceString(Double(timeElapsed) / distance)
    }

    private var avgPaceText: String {
        guard distance > 0.01, timeElapsed > 0 else { return "--:--" }
        return paceString(Double(timeElapsed) / distance)
    }

    private func paceString(_ secPerKm: Double) -> String {
        let m = Int(secPerKm / 60)
        let s = Int(secPerKm) % 60
        return "\(m):\(String(format: "%02d", s))"
    }

    private func paceColor(_ pace: Double) -> Color {
        if pace < 300 { return .primaryGreen }
        if pace < 390 { return .cardioOrange }
        return .cardioRed
    }

    private var runDateString: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy, HH:mm"
        f.locale = Locale(identifier: "ru_RU")
        return f.string(from: Date())
    }
}
