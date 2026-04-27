//
//  AICoachView.swift
//  FitnessApp
//
//  Avatar-style AI fitness coach powered by Anthropic.
//  Personality: wise, warm, occasionally philosophical — like a seasoned sensei.
//

import SwiftUI

// MARK: - Chat Message

struct CoachMessage: Identifiable {
    let id = UUID().uuidString
    let role: String   // "user" | "assistant"
    let text: String
    let date: Date
}

// MARK: - Coach View Model

@MainActor
final class AICoachVM: ObservableObject {

    @Published var messages:    [CoachMessage] = []
    @Published var inputText:   String = ""
    @Published var isLoading:   Bool   = false
    @Published var errorText:   String? = nil
    @Published var apiKey:      String = AnthropicService.shared.apiKey

    private let service = AnthropicService.shared

    // Profile context injected from outside
    var userName:     String = ""
    var userAge:      Int    = 25
    var userWeight:   Double = 70
    var userHeight:   Double = 175
    var goalCalories: Int    = 2000
    var goalSteps:    Int    = 10000
    var level:        Int    = 1
    var levelTitle:   String = "Ученик"
    var streak:       Int    = 0
    var workoutCount: Int    = 0
    var element:      AvatarElement = .air

    func saveKey() {
        AnthropicService.shared.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
    }

    var systemPrompt: String {
        """
        Ты — Сенсей, мудрый ИИ-тренер фитнес-приложения FitTrack. \
        Твоя личность вдохновлена дядей Айро из «Аватара: легенды об Ааге»: \
        мудрый, тёплый, вдохновляющий, иногда философски мыслящий, всегда поддерживающий.

        Профиль пользователя:
        - Имя: \(userName.isEmpty ? "Ученик" : userName)
        - Возраст: \(userAge) лет
        - Вес: \(Int(userWeight)) кг, Рост: \(Int(userHeight)) см
        - Цель калорий: \(goalCalories) ккал/день
        - Цель шагов: \(goalSteps) шаг/день
        - Уровень: \(level) (\(levelTitle)) — Стихия: \(element.rawValue)
        - Серия тренировок: \(streak) дней подряд
        - Всего тренировок: \(workoutCount)

        Правила:
        1. Отвечай ТОЛЬКО на русском языке.
        2. Давай конкретные, применимые советы на основе данных пользователя.
        3. Упоминай уровень и стихию, когда это уместно.
        4. Отвечай лаконично: 2-4 предложения обычно достаточно.
        5. Иногда добавляй короткую философскую мысль о пути воина.
        6. Используй эмодзи умеренно (1-2 на ответ).
        7. Не давай медицинских диагнозов — только фитнес-советы.
        """
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }

        messages.append(CoachMessage(role: "user", text: text, date: .now))
        inputText = ""
        isLoading = true
        errorText = nil

        let history = messages.map { (role: $0.role, content: $0.text) }

        do {
            let reply = try await service.send(messages: history, system: systemPrompt)
            messages.append(CoachMessage(role: "assistant", text: reply, date: .now))
        } catch {
            errorText = error.localizedDescription
        }
        isLoading = false
    }

    func sendSuggestion(_ s: String) {
        inputText = s
        Task { await send() }
    }

    var suggestions: [String] {
        [
            "Что мне делать сегодня?",
            "Как улучшить восстановление?",
            "Совет по питанию",
            "Как увеличить серию?",
            "Мотивируй меня!",
        ]
    }
}

// MARK: - Main View

struct AICoachView: View {

    @StateObject private var vm = AICoachVM()
    @Environment(\.dismiss) private var dismiss

    // Profile injection via @AppStorage
    @AppStorage("userName")      private var userName:     String = "Ученик"
    @AppStorage("userAge")       private var userAge:      Int    = 25
    @AppStorage("userWeight")    private var userWeight:   Double = 70
    @AppStorage("userHeight")    private var userHeight:   Double = 175
    @AppStorage("goalCalories")  private var goalCalories: Int    = 2000
    @AppStorage("goalSteps")     private var goalSteps:    Int    = 10000

    @StateObject private var gam = GamificationEngine.shared
    @State private var showKeySetup = false
    @FocusState private var inputFocused: Bool

    var workoutCount: Int = 0

    var body: some View {
        ZStack(alignment: .top) {
            // Background gradient
            gam.currentElement.gradient
                .opacity(0.12)
                .ignoresSafeArea()

            Color(.systemGroupedBackground)
                .ignoresSafeArea()
                .opacity(0.6)

            VStack(spacing: 0) {
                coachHeader
                Divider()

                if !AnthropicService.shared.hasKey {
                    apiKeySetupView
                } else {
                    chatContent
                }
            }
        }
        .onAppear { injectContext() }
        .sheet(isPresented: $showKeySetup) { apiKeySheet }
    }

    // MARK: - Header

    private var coachHeader: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(gam.currentElement.gradient)
                    .frame(width: 52, height: 52)
                    .shadow(color: gam.currentElement.color.opacity(0.4), radius: 10, x: 0, y: 4)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Сенсей")
                    .font(.headline).fontWeight(.bold)
                HStack(spacing: 4) {
                    Image(systemName: gam.currentElement.icon)
                        .font(.system(size: 10))
                        .foregroundColor(gam.currentElement.color)
                    Text("Мастер \(gam.currentElement.rawValue)а")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: { showKeySetup = true }) {
                Image(systemName: "key.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        if messages.isEmpty {
                            welcomeMessage
                                .padding(.top, 20)
                        }

                        ForEach(messages) { msg in
                            MessageBubble(message: msg, element: gam.currentElement)
                                .id(msg.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        if vm.isLoading {
                            TypingIndicator(element: gam.currentElement)
                                .id("typing_indicator")
                                .transition(.opacity)
                        }

                        if let err = vm.errorText {
                            Text("⚠️ \(err)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(12)
                                .background(Color.red.opacity(0.08))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messages.count)
                    .animation(.easeInOut(duration: 0.3), value: vm.isLoading)
                }
                .onChange(of: messages.count) { _ in
                    withAnimation { proxy.scrollTo(messages.last?.id) }
                }
                .onChange(of: vm.isLoading) { loading in
                    if loading { withAnimation { proxy.scrollTo("typing_indicator") } }
                }
            }

            // Suggestions (only when empty)
            if messages.isEmpty {
                suggestionsRow
            }

            inputBar
        }
    }

    private var messages: [CoachMessage] { vm.messages }

    // MARK: - Welcome

    private var welcomeMessage: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(gam.currentElement.gradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: gam.currentElement.color.opacity(0.4), radius: 20)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                Text("Привет, \(userName)!")
                    .font(.title3).fontWeight(.bold)
                Text("Я твой личный тренер Сенсей.\nСпроси меня о тренировках,\nпитании или мотивации.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Suggestions

    private var suggestionsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.suggestions, id: \.self) { s in
                    Button(action: { vm.sendSuggestion(s) }) {
                        Text(s)
                            .font(.caption).fontWeight(.medium)
                            .foregroundColor(gam.currentElement.color)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(gam.currentElement.color.opacity(0.1))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(gam.currentElement.color.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Спроси Сенсея...", text: $vm.inputText, axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit { Task { await vm.send() } }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGroupedBackground))
                .cornerRadius(20)

            Button(action: { Task { await vm.send() } }) {
                ZStack {
                    Circle()
                        .fill(vm.inputText.isEmpty
                              ? AnyShapeStyle(Color(.systemGray4))
                              : AnyShapeStyle(gam.currentElement.gradient))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(vm.inputText.isEmpty || vm.isLoading)
            .animation(.spring(response: 0.3), value: vm.inputText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - API Key Setup (inline)

    private var apiKeySetupView: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 90, height: 90)
                Image(systemName: "key.fill")
                    .font(.system(size: 38))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Нужен API-ключ")
                    .font(.title2).fontWeight(.bold)
                Text("Введи ключ Anthropic (claude.ai/account)\nчтобы активировать Сенсея")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                SecureField("sk-ant-...", text: $vm.apiKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(14)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(14)

                Button(action: {
                    vm.saveKey()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Text("Сохранить и начать")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(vm.apiKey.count > 10 ? LinearGradient.primaryGradient
                                    : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(vm.apiKey.count < 10)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - API Key Sheet

    private var apiKeySheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                SecureField("sk-ant-...", text: $vm.apiKey)
                    .font(.system(.body, design: .monospaced))
                    .padding(14)
                    .background(Color(.systemGroupedBackground))
                    .cornerRadius(14)
                    .padding()
                Spacer()
            }
            .navigationTitle("API-ключ Anthropic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        vm.saveKey()
                        showKeySetup = false
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryGreen)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") { showKeySetup = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Context Injection

    private func injectContext() {
        vm.userName     = userName
        vm.userAge      = userAge
        vm.userWeight   = userWeight
        vm.userHeight   = userHeight
        vm.goalCalories = goalCalories
        vm.goalSteps    = goalSteps
        vm.level        = gam.level
        vm.levelTitle   = gam.levelTitle
        vm.streak       = 0
        vm.workoutCount = workoutCount
        vm.element      = gam.currentElement
        vm.apiKey       = AnthropicService.shared.apiKey
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: CoachMessage
    let element: AvatarElement

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 60) }

            if !isUser {
                ZStack {
                    Circle()
                        .fill(element.gradient)
                        .frame(width: 30, height: 30)
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        if isUser { element.gradient } else { Color(.systemBackground) }
                    }
                    .cornerRadius(18)
                    .cornerRadius(isUser ? 4 : 18, corners: isUser ? .bottomRight : .bottomLeft)
                    .shadow(color: .black.opacity(isUser ? 0 : 0.06), radius: 6, x: 0, y: 2)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let element: AvatarElement
    @State private var phase = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ZStack {
                Circle()
                    .fill(element.gradient)
                    .frame(width: 30, height: 30)
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }

            HStack(spacing: 5) {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(element.color)
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.4 : 0.8)
                        .animation(.easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.18),
                                   value: phase)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(18)
            .cornerRadius(4, corners: .bottomLeft)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)

            Spacer(minLength: 60)
        }
        .onAppear { phase = 2 }
    }
}
