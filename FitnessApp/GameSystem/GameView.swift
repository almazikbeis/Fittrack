//
//  GameView.swift
//  FitnessApp
//
//  "Путь Стихий" — character, quest map, quest cards, mentor gallery.
//

import SwiftUI

struct GameView: View {

    @StateObject private var gam    = GamificationEngine.shared
    @StateObject private var engine = QuestEngine.shared
    @AppStorage("userName") private var userName = "Ученик"

    @State private var selectedMentor: NPCMentor? = nil
    @State private var characterAppeared = false
    @State private var auraScale: CGFloat = 1.0
    @State private var orbiting = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    characterCard
                    questMapCard
                    activeQuestsSection
                    mentorGallery
                    sideQuestsSection
                    Spacer().frame(height: 110)
                }
            }

            // Dialogue overlay
            DialogueOverlay()
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.1)) {
                characterAppeared = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                auraScale = 1.12
            }
        }
        .sheet(item: $selectedMentor) { mentor in
            MentorDetailView(mentor: mentor)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Character Card

    private var characterCard: some View {
        ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 30)
                .fill(gam.currentElement.gradient)

            ElementParticlesView(element: gam.currentElement)
                .clipShape(RoundedRectangle(cornerRadius: 30))

            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)

            HStack(spacing: 20) {
                // Character avatar
                characterAvatar

                // Stats column
                VStack(alignment: .leading, spacing: 12) {
                    // Name + level
                    VStack(alignment: .leading, spacing: 3) {
                        Text(userName)
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Image(systemName: gam.currentElement.icon)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.8))
                            Text("Ур. \(gam.level) · \(gam.levelTitle)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    // Stat bars
                    VStack(spacing: 7) {
                        statBar("Сила",     value: engine.statStrength,  color: .strengthPurple)
                        statBar("Ловкость", value: engine.statAgility,   color: .airBlue)
                        statBar("Баланс",   value: engine.statBalance,   color: .waterCyan)
                        statBar("Воля",     value: engine.statWillpower, color: .fireOrange)
                    }
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .shadow(color: gam.currentElement.color.opacity(0.4), radius: 24, x: 0, y: 10)
        .scaleEffect(characterAppeared ? 1 : 0.9)
        .opacity(characterAppeared ? 1 : 0)
    }

    private var characterAvatar: some View {
        ZStack {
            // Outer aura
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 110, height: 110)
                .scaleEffect(auraScale)

            // Middle ring
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                .frame(width: 90, height: 90)

            // Inner circle
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 80, height: 80)

            // Character symbol
            VStack(spacing: 2) {
                Image(systemName: characterSymbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white)
                Text("\(gam.xpInCurrentLevel) XP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.75))
            }

            // Unlock badges orbiting
            ForEach(Array(unlockedElements.enumerated()), id: \.offset) { i, el in
                Image(systemName: el.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(el.gradient)
                    .clipShape(Circle())
                    .shadow(color: el.color.opacity(0.5), radius: 5)
                    .offset(orbitOffset(index: i, total: unlockedElements.count, radius: 52))
            }
        }
        .frame(width: 120, height: 120)
    }

    private var characterSymbol: String {
        switch gam.level {
        case 1...3:  return "person.fill"
        case 4...7:  return "figure.martial.arts"
        case 8...12: return "figure.mind.and.body"
        case 13...17: return "star.circle.fill"
        default:     return "crown.fill"
        }
    }

    private var unlockedElements: [AvatarElement] {
        AvatarElement.allCases.filter { el in
            engine.quests.first(where: { $0.element == el && $0.isMainQuest && $0.isCompleted }) != nil
        }
    }

    private func orbitOffset(index: Int, total: Int, radius: CGFloat) -> CGSize {
        guard total > 0 else { return .zero }
        let angle = (Double(index) / Double(total)) * .pi * 2 - .pi / 2
        return CGSize(width: radius * CGFloat(cos(angle)),
                      height: radius * CGFloat(sin(angle)))
    }

    private func statBar(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: geo.size.width * CGFloat(value) / 100)
                        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: value)
                }
            }
            .frame(height: 5)

            Text("\(value)")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 24, alignment: .trailing)
        }
    }

    // MARK: - Quest Map

    private var questMapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Карта Стихий")
                .font(.headline).padding(.horizontal, 16)

            ElementMapView(unlockedElements: unlockedElements, currentElement: gam.currentElement)
                .frame(height: 200)
                .padding(.horizontal, 16)
        }
        .staggeredAppear(index: 1)
    }

    // MARK: - Active Main Quests

    private var activeQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Главные квесты")
                .font(.headline).padding(.horizontal, 16)

            ForEach(Array(engine.quests.filter(\.isMainQuest).enumerated()), id: \.element.id) { i, quest in
                QuestCard(quest: quest)
                    .padding(.horizontal, 16)
                    .staggeredAppear(index: i + 2)
            }
        }
    }

    // MARK: - Mentor Gallery

    private var mentorGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Менторы")
                .font(.headline).padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(NPCMentor.all) { mentor in
                        MentorCard(mentor: mentor)
                            .onTapGesture { selectedMentor = mentor }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .staggeredAppear(index: 6)
    }

    // MARK: - Side Quests

    private var sideQuestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Побочные задания")
                .font(.headline).padding(.horizontal, 16)

            ForEach(Array(engine.quests.filter { !$0.isMainQuest }.enumerated()), id: \.element.id) { i, quest in
                QuestCard(quest: quest, compact: true)
                    .padding(.horizontal, 16)
                    .staggeredAppear(index: i + 7)
            }
        }
    }
}

// MARK: - Element Map View

struct ElementMapView: View {
    let unlockedElements: [AvatarElement]
    let currentElement: AvatarElement

    @State private var pathProgress: CGFloat = 0
    @State private var glowPhase = false

    private let elements: [(element: AvatarElement, pos: UnitPoint)] = [
        (.air,   UnitPoint(x: 0.25, y: 0.18)),
        (.water, UnitPoint(x: 0.75, y: 0.18)),
        (.earth, UnitPoint(x: 0.25, y: 0.80)),
        (.fire,  UnitPoint(x: 0.75, y: 0.80)),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.07), radius: 12)

                // Connection paths
                Canvas { ctx, size in
                    drawPaths(ctx: ctx, size: size)
                }
                .padding(8)

                // Element nodes
                ForEach(elements, id: \.element.rawValue) { item in
                    let isUnlocked = unlockedElements.contains(item.element) || item.element == currentElement
                    let isCurrent = item.element == currentElement

                    elementNode(item.element, unlocked: isUnlocked, current: isCurrent)
                        .position(
                            x: item.pos.x * geo.size.width,
                            y: item.pos.y * geo.size.height
                        )
                        .scaleEffect(isCurrent ? (glowPhase ? 1.12 : 1.0) : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: glowPhase)
                }

                // Avatar label in center
                Text("Аватар")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) { pathProgress = 1 }
            glowPhase = true
        }
    }

    private func drawPaths(ctx: GraphicsContext, size: CGSize) {
        let pts = elements.map { CGPoint(x: $0.pos.x * size.width, y: $0.pos.y * size.height) }
        // Connect all 4 nodes in a diamond
        let connections = [(0,1),(0,2),(1,3),(2,3),(0,3),(1,2)]
        for (a, b) in connections {
            var path = Path()
            path.move(to: pts[a])
            path.addLine(to: pts[b])
            ctx.stroke(path, with: .color(Color(.systemGray4)), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
        }
    }

    private func elementNode(_ element: AvatarElement, unlocked: Bool, current: Bool) -> some View {
        ZStack {
            if unlocked {
                Circle()
                    .fill(element.gradient)
                    .frame(width: current ? 52 : 44, height: current ? 52 : 44)
                    .shadow(color: element.color.opacity(current ? 0.6 : 0.3), radius: current ? 14 : 8)
            } else {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)
            }

            Image(systemName: element.icon)
                .font(.system(size: current ? 22 : 18, weight: .semibold))
                .foregroundColor(unlocked ? .white : Color(.systemGray3))

            if current {
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .frame(width: 60, height: 60)
            }
        }
        .overlay(alignment: .bottom) {
            Text(element.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(unlocked ? element.color : .secondary)
                .offset(y: 28)
        }
    }
}

// MARK: - Quest Card

struct QuestCard: View {
    let quest: Quest
    var compact: Bool = false

    @StateObject private var engine = QuestEngine.shared
    @State private var cardScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { cardScale = 0.97 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.08)) { cardScale = 1.0 }
            if !quest.isCompleted {
                engine.openDialogue(questId: quest.id, phase: quest.progress == 0 ? .intro : .greeting)
            }
        }) {
            HStack(spacing: 14) {
                // Element icon
                ZStack {
                    RoundedRectangle(cornerRadius: compact ? 10 : 14)
                        .fill(quest.isCompleted ? AnyShapeStyle(quest.element.gradient) : AnyShapeStyle(Color(.systemGray5)))
                        .frame(width: compact ? 40 : 50, height: compact ? 40 : 50)
                        .shadow(color: quest.isCompleted ? quest.element.color.opacity(0.35) : .clear, radius: 8)

                    Image(systemName: quest.element.icon)
                        .font(.system(size: compact ? 16 : 20, weight: .semibold))
                        .foregroundColor(quest.isCompleted ? .white : quest.element.color)
                }

                VStack(alignment: .leading, spacing: compact ? 3 : 5) {
                    HStack {
                        Text(quest.title)
                            .font(compact ? .subheadline : .headline)
                            .fontWeight(.bold)
                            .foregroundColor(quest.isCompleted ? .secondary : .primary)
                        Spacer()
                        if quest.isCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(quest.element.color)
                                .font(.system(size: compact ? 14 : 16))
                        } else {
                            Text("+\(quest.xpReward) XP")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(quest.element.color)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(quest.element.color.opacity(0.12))
                                .cornerRadius(8)
                        }
                    }

                    if !compact {
                        Text(quest.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Text(quest.requirementDescription)
                        .font(.caption2)
                        .foregroundColor(quest.element.color.opacity(0.85))

                    if !quest.isCompleted {
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(quest.element.gradient)
                                    .frame(width: geo.size.width * CGFloat(quest.progress), height: 4)
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: quest.progress)
                            }
                        }
                        .frame(height: 4)

                        Text("\(quest.currentCount) / \(quest.targetCount)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(compact ? 12 : 16)
            .background(Color(.systemBackground))
            .cornerRadius(compact ? 16 : 22)
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 16 : 22)
                    .stroke(quest.isCompleted ? quest.element.color.opacity(0.3) : .clear, lineWidth: 1.5)
            )
            .opacity(quest.isCompleted ? 0.75 : 1.0)
        }
        .buttonStyle(.plain)
        .scaleEffect(cardScale)
    }
}

// MARK: - Mentor Card (horizontal scroll)

struct MentorCard: View {
    let mentor: NPCMentor
    @StateObject private var engine = QuestEngine.shared
    @State private var pulse = false

    var completedQuests: Int {
        engine.quests.filter { $0.mentorId == mentor.id && $0.isCompleted }.count
    }
    var totalQuests: Int {
        engine.quests.filter { $0.mentorId == mentor.id }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(mentor.element.gradient)
                    .frame(width: 64, height: 64)
                    .shadow(color: mentor.element.color.opacity(pulse ? 0.55 : 0.25), radius: pulse ? 16 : 10)
                    .scaleEffect(pulse ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)

                Image(systemName: mentor.sfSymbol)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 3) {
                Text(mentor.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(mentor.element.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(mentor.element.color)
            }

            // Quest completion
            HStack(spacing: 3) {
                ForEach(0..<totalQuests, id: \.self) { i in
                    Circle()
                        .fill(i < completedQuests ? mentor.element.color : Color(.systemGray5))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .frame(width: 110)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.07), radius: 10, x: 0, y: 4)
        .onAppear { pulse = true }
    }
}

// MARK: - Mentor Detail Sheet

struct MentorDetailView: View {
    let mentor: NPCMentor
    @StateObject private var engine = QuestEngine.shared
    @Environment(\.dismiss) private var dismiss
    @State private var wisdomIndex = 0
    @State private var wisdomOpacity = 1.0

    var mentorQuests: [Quest] { engine.quests.filter { $0.mentorId == mentor.id } }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Portrait hero
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(mentor.element.gradient)
                            .frame(height: 200)

                        ElementParticlesView(element: mentor.element)
                            .clipShape(RoundedRectangle(cornerRadius: 24))

                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.18))
                                    .frame(width: 90, height: 90)
                                Image(systemName: mentor.sfSymbol)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(mentor.name)
                                .font(.title2).fontWeight(.black).foregroundColor(.white)
                            Text(mentor.title)
                                .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .shadow(color: mentor.element.color.opacity(0.4), radius: 20)
                    .padding(.horizontal)

                    // Personality
                    Text(mentor.personality)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Rotating wisdom
                    VStack(spacing: 8) {
                        Text("«\(mentor.wisdom[wisdomIndex])»")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(wisdomOpacity)
                            .padding(.horizontal, 24)

                        Button(action: cycleWisdom) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13))
                                .foregroundColor(mentor.element.color)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(18)
                    .padding(.horizontal)

                    // Quests from this mentor
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Задания от \(mentor.name.components(separatedBy: " ").first ?? mentor.name)")
                            .font(.headline)
                            .padding(.horizontal)
                        ForEach(mentorQuests) { quest in
                            QuestCard(quest: quest, compact: true)
                                .padding(.horizontal)
                        }
                    }

                    // Talk button
                    if let firstActive = mentorQuests.first(where: { !$0.isCompleted }) {
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                engine.openDialogue(questId: firstActive.id, phase: .greeting)
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "message.fill")
                                Text("Поговорить с \(mentor.name.components(separatedBy: " ").last ?? mentor.name)")
                            }
                            .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(mentor.element.gradient)
                            .cornerRadius(18)
                            .shadow(color: mentor.element.color.opacity(0.4), radius: 12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal)
                    }

                    Spacer().frame(height: 30)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { dismiss() }
                        .foregroundColor(mentor.element.color)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func cycleWisdom() {
        withAnimation(.easeOut(duration: 0.2)) { wisdomOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            wisdomIndex = (wisdomIndex + 1) % mentor.wisdom.count
            withAnimation(.easeIn(duration: 0.3)) { wisdomOpacity = 1 }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// Make NPCMentor identifiable for sheet(item:)
extension NPCMentor: Hashable {
    static func == (lhs: NPCMentor, rhs: NPCMentor) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
