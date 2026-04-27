//
//  GamificationEngine.swift
//  FitnessApp
//
//  Avatar-inspired XP / level / element progression system.
//

import SwiftUI

// MARK: - Avatar Element

enum AvatarElement: String, CaseIterable {
    case air   = "Воздух"
    case water = "Вода"
    case earth = "Земля"
    case fire  = "Огонь"

    var icon: String {
        switch self {
        case .air:   return "wind"
        case .water: return "drop.fill"
        case .earth: return "mountain.2.fill"
        case .fire:  return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .air:   return .airBlue
        case .water: return .waterCyan
        case .earth: return .earthGreen
        case .fire:  return .fireOrange
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .air:   return .airGradient
        case .water: return .deepWaterGradient
        case .earth: return .earthGradient
        case .fire:  return .fireElementGradient
        }
    }

    var particleIcon: String {
        switch self {
        case .air:   return "circle.fill"
        case .water: return "drop.fill"
        case .earth: return "square.fill"
        case .fire:  return "triangle.fill"
        }
    }

    var description: String {
        switch self {
        case .air:   return "Лёгкость и скорость"
        case .water: return "Сила потока"
        case .earth: return "Твёрдость и стойкость"
        case .fire:  return "Неугасимый огонь воли"
        }
    }

    // XP per level in this element tier
    static func element(for level: Int) -> AvatarElement {
        switch level {
        case 1...5:  return .air
        case 6...10: return .water
        case 11...15: return .earth
        default:     return .fire
        }
    }
}

// MARK: - XP Source

enum XPSource: String {
    case workout    = "Тренировка"
    case meal       = "Питание"
    case steps      = "Шаги"
    case streak     = "Серия"
    case achievement = "Достижение"
    case firstLogin  = "Первый вход"
}

// MARK: - Gamification Engine

@MainActor
final class GamificationEngine: ObservableObject {

    static let shared = GamificationEngine()

    // Persistent
    @AppStorage("gam_total_xp")      var totalXP:      Int = 0
    @AppStorage("gam_coins")         var coins:         Int = 0
    @AppStorage("gam_daily_checked") var dailyChecked:  Bool = false
    @AppStorage("gam_daily_date")    var dailyDateStr:  String = ""

    // Transient banner
    @Published var showXPBanner  = false
    @Published var bannerXP      = 0
    @Published var bannerSource  = ""

    // Level-up celebration
    @Published var showLevelUp   = false
    @Published var levelUpValue  = 1

    // MARK: Computed

    var level: Int { min(20, totalXP / 500 + 1) }

    var levelTitle: String {
        switch level {
        case 1...3:  return "Обычный человек"
        case 4...5:  return "Ученик Стихий"
        case 6...8:  return "Практикант"
        case 9...10: return "Посвящённый"
        case 11...13: return "Мастер"
        case 14...15: return "Великий Мастер"
        case 16...18: return "Легенда"
        case 19:     return "Повелитель Стихий"
        default:     return "Аватар"
        }
    }

    var currentElement: AvatarElement { AvatarElement.element(for: level) }

    var xpInCurrentLevel: Int { totalXP % 500 }
    var levelProgress: Double  { Double(xpInCurrentLevel) / 500.0 }

    var nextMilestone: Int     { level * 500 }
    var xpToNextLevel: Int     { max(0, nextMilestone - totalXP) }

    // MARK: Add XP

    func addXP(_ amount: Int, source: XPSource) {
        let previousLevel = level
        totalXP += amount
        coins   += max(1, amount / 10)

        bannerXP     = amount
        bannerSource = source.rawValue

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showXPBanner = true
        }
        Task {
            try? await Task.sleep(for: .seconds(2.8))
            withAnimation(.easeOut(duration: 0.4)) { showXPBanner = false }
        }

        let newLevel = level
        if newLevel > previousLevel {
            levelUpValue = newLevel
            Task {
                try? await Task.sleep(for: .seconds(0.4))
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showLevelUp = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: Daily check-in bonus

    func claimDailyBonus() -> Bool {
        let today = ISO8601DateFormatter().string(from: Date()).prefix(10).description
        guard dailyDateStr != today else { return false }
        dailyDateStr = today
        addXP(50, source: .firstLogin)
        return true
    }
}

// MARK: - XP Banner

struct XPBannerView: View {
    let xp: Int
    let source: String
    let element: AvatarElement

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(element.gradient)
                    .frame(width: 36, height: 36)
                Image(systemName: element.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("+ \(xp) XP")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(source)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(element.color.opacity(0.95))
                .shadow(color: element.color.opacity(0.5), radius: 16, x: 0, y: 6)
        )
        .padding(.horizontal, 20)
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                appeared = true
            }
        }
    }
}

// MARK: - Level Up Overlay

struct LevelUpView: View {
    let level: Int
    let element: AvatarElement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var particleOffset: CGFloat = 0
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 28) {
                // Element burst
                ZStack {
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(element.gradient)
                            .frame(width: 12, height: 12)
                            .offset(y: -particleOffset)
                            .rotationEffect(.degrees(Double(i) * 45))
                            .opacity(opacity)
                    }
                    ZStack {
                        Circle()
                            .fill(element.gradient)
                            .frame(width: 110, height: 110)
                            .shadow(color: element.color.opacity(0.6), radius: 30, x: 0, y: 0)
                        Image(systemName: element.icon)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 160)

                VStack(spacing: 8) {
                    Text("УРОВЕНЬ \(level)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .tracking(4)
                        .foregroundColor(element.color)

                    Text("Ты достиг нового уровня!")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(element.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                Button(action: onDismiss) {
                    Text("Продолжить путь")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(element.gradient)
                        .cornerRadius(18)
                }
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground).opacity(0.15))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
            )
            .padding(24)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                scale = 1
                opacity = 1
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                particleOffset = 70
            }
        }
    }
}

// MARK: - Element Particle View

struct ElementParticlesView: View {
    let element: AvatarElement
    @State private var phase: Double = 0

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawParticles(ctx: ctx, size: size, t: t)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticles(ctx: GraphicsContext, size: CGSize, t: Double) {
        let count = 12
        for i in 0..<count {
            let seed = Double(i) * 137.508
            let xBase = (sin(seed * 0.3) * 0.5 + 0.5) * size.width
            let speed = 0.4 + (Double(i).truncatingRemainder(dividingBy: 3)) * 0.15
            let cycle = (t * speed + seed * 0.1).truncatingRemainder(dividingBy: 1)

            let (x, y, sz, alpha) = particleParams(
                element: element, i: i, xBase: xBase,
                cycle: cycle, size: size, t: t, seed: seed
            )

            var ctx2 = ctx
            ctx2.opacity = alpha * 0.45

            let rect = CGRect(x: x - sz/2, y: y - sz/2, width: sz, height: sz)
            switch element {
            case .air:
                ctx2.fill(Path(ellipseIn: rect), with: .color(.airBlue))
            case .water:
                ctx2.fill(Path(ellipseIn: rect), with: .color(.waterCyan))
            case .earth:
                ctx2.fill(Path(rect), with: .color(.earthGreen))
            case .fire:
                var triangle = Path()
                triangle.move(to: CGPoint(x: x, y: y - sz/2))
                triangle.addLine(to: CGPoint(x: x + sz/2, y: y + sz/2))
                triangle.addLine(to: CGPoint(x: x - sz/2, y: y + sz/2))
                triangle.closeSubpath()
                ctx2.fill(triangle, with: .color(.fireOrange))
            }
        }
    }

    private func particleParams(
        element: AvatarElement, i: Int, xBase: CGFloat,
        cycle: Double, size: CGSize, t: Double, seed: Double
    ) -> (x: CGFloat, y: CGFloat, sz: CGFloat, alpha: Double) {
        let sz = CGFloat(4 + (i % 4) * 3)
        switch element {
        case .air:
            let x = xBase + CGFloat(sin(t * 0.8 + seed) * 18)
            let y = size.height * CGFloat(1 - cycle) - 10
            let alpha = cycle < 0.15 ? cycle / 0.15 : (cycle > 0.85 ? (1 - cycle) / 0.15 : 1.0)
            return (x, y, sz, alpha)
        case .water:
            let x = size.width * CGFloat(cycle)
            let y = CGFloat(Double(i) / 12.0) * size.height + CGFloat(sin(t * 1.2 + seed) * 12)
            let alpha = cycle < 0.1 ? cycle / 0.1 : (cycle > 0.9 ? (1 - cycle) / 0.1 : 0.8)
            return (x, y, sz, alpha)
        case .earth:
            let x = xBase
            let y = size.height * 0.7 + CGFloat(sin(t * 0.3 + seed) * 8)
            let alpha = 0.6 + sin(t * 0.4 + seed) * 0.2
            return (x, y, sz * 1.4, alpha)
        case .fire:
            let x = xBase + CGFloat(sin(t * 1.5 + seed) * 10)
            let y = size.height * CGFloat(1 - cycle * 0.8) - 10
            let alpha = (1 - cycle) * 0.9
            return (x, y, sz, alpha)
        }
    }
}
