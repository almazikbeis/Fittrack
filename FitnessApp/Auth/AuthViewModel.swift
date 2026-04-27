//
//  AuthViewModel.swift
//  FitnessApp
//
//  Central auth state machine — inject as @EnvironmentObject at root.
//

import SwiftUI
import Supabase

// MARK: - Auth State

enum AuthState {
    case loading
    case unauthenticated
    case onboarding
    case authenticated
}

// MARK: - ViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var authState:     AuthState = .loading
    @Published var currentUser:   User?
    @Published var profile:       UserProfile?
    @Published var errorMessage:  String?
    @Published var isLoading:     Bool = false

    private var authListenerTask: Task<Void, Never>?

    init() {
        listenToAuthChanges()
    }

    deinit {
        authListenerTask?.cancel()
    }

    // ── Auth state listener ────────────────────────────────────────

    private func listenToAuthChanges() {
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            for await (event, session) in SupabaseManager.shared.auth.authStateChanges {
                switch event {
                case .initialSession:
                    if let session {
                        self.currentUser = session.user
                        await self.loadProfile(userId: session.user.id)
                    } else {
                        self.authState = .unauthenticated
                    }
                case .signedIn:
                    if let session {
                        self.currentUser = session.user
                        await self.loadProfile(userId: session.user.id)
                    }
                case .signedOut:
                    self.currentUser = nil
                    self.profile     = nil
                    self.authState   = .unauthenticated
                default:
                    break
                }
            }
        }
    }

    // ── Auth Actions ───────────────────────────────────────────────

    func signIn(email: String, password: String) async {
        isLoading     = true
        errorMessage  = nil
        defer { isLoading = false }
        do {
            let session = try await SupabaseManager.shared.auth
                .signIn(email: email, password: password)
            currentUser = session.user
            await loadProfile(userId: session.user.id)
        } catch {
            errorMessage = localizedAuthError(error)
        }
    }

    func signUp(email: String, password: String) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await SupabaseManager.shared.auth
                .signUp(email: email, password: password)

            if let session = response.session {
                // Email confirmation disabled — signed in immediately
                currentUser = session.user
                authState   = .onboarding
            } else {
                // Email confirmation required — user created but no session yet
                currentUser = response.user
                errorMessage = "Аккаунт создан! Проверьте почту \(email) и подтвердите email, затем войдите."
                authState   = .unauthenticated
            }
        } catch {
            errorMessage = localizedAuthError(error)
        }
    }

    func signOut() async {
        try? await SupabaseManager.shared.auth.signOut()
        // authStateChanges listener will set authState = .unauthenticated
    }

    func resetPassword(email: String) async -> Bool {
        do {
            try await SupabaseManager.shared.auth.resetPasswordForEmail(email)
            return true
        } catch {
            errorMessage = localizedAuthError(error)
            return false
        }
    }

    // ── Profile ────────────────────────────────────────────────────

    func loadProfile(userId: UUID) async {
        do {
            let data: UserProfile = try await SupabaseManager.shared.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            profile = data
            syncProfileToAppStorage(data)
            authState = data.name.trimmingCharacters(in: .whitespaces).isEmpty
                ? .onboarding
                : .authenticated
        } catch {
            // Profile row may not exist yet
            authState = .onboarding
        }
    }

    func saveOnboardingProfile(
        name: String, age: Int, weight: Double, height: Double,
        calGoal: Int = 2000, stepsGoal: Int = 10000
    ) async {
        guard let userId = currentUser?.id else {
            errorMessage = "Ошибка: пользователь не найден. Попробуйте войти снова."
            return
        }
        isLoading = true
        defer { isLoading = false }

        var patch = UserProfileUpdate(
            id:        userId,
            name:      name,
            age:       age,
            weight:    weight,
            height:    height,
            updatedAt: Date()
        )
        patch.goalCalories = calGoal
        patch.goalSteps    = stepsGoal

        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .upsert(patch)   // upsert без .eq() — id в payload → Supabase сам разрешит конфликт
                .execute()
            await loadProfile(userId: userId)
        } catch {
            errorMessage = "Не удалось сохранить профиль: \(error.localizedDescription)"
        }
    }

    func saveGoals(_ goals: UserGoalsUpdate) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(goals)
                .eq("id", value: userId.uuidString)
                .execute()
            await loadProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveNotifications(_ notif: UserNotifUpdate) async {
        guard let userId = currentUser?.id else { return }
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(notif)
                .eq("id", value: userId.uuidString)
                .execute()
            await loadProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ── AppStorage sync ────────────────────────────────────────────
    // Mirrors remote profile into @AppStorage so existing views continue to work

    func syncProfileToAppStorage(_ p: UserProfile) {
        let ud = UserDefaults.standard
        ud.set(p.name,              forKey: "userName")
        ud.set(p.age,               forKey: "userAge")
        ud.set(p.weight,            forKey: "userWeight")
        ud.set(p.height,            forKey: "userHeight")
        ud.set(p.goalCalories,      forKey: "goalCalories")
        ud.set(p.goalProtein,       forKey: "goalProtein")
        ud.set(p.goalFat,           forKey: "goalFat")
        ud.set(p.goalCarbs,         forKey: "goalCarbs")
        ud.set(p.goalSteps,         forKey: "goalSteps")
        ud.set(p.goalWater,         forKey: "goalWater")
    }

    // ── Error localization ────────────────────────────────────────

    private func localizedAuthError(_ error: Error) -> String {
        let msg = error.localizedDescription.lowercased()

        // Network
        if msg.contains("network") || msg.contains("internet")
            || msg.contains("hostname") || msg.contains("connection")
            || msg.contains("-1003") || msg.contains("offline") {
            return "Нет подключения к интернету. Проверьте сеть."
        }
        // Invalid credentials
        if msg.contains("invalid login") || msg.contains("credentials")
            || msg.contains("invalid email") || msg.contains("wrong password") {
            return "Неверный email или пароль."
        }
        // Already registered
        if msg.contains("already registered") || msg.contains("already exists")
            || msg.contains("user already") || msg.contains("email already") {
            return "Этот email уже зарегистрирован. Войдите."
        }
        // Weak password
        if msg.contains("weak password") || msg.contains("password should")
            || msg.contains("at least 6") || msg.contains("password is too") {
            return "Пароль слишком простой. Минимум 6 символов."
        }
        // Email not confirmed
        if msg.contains("email not confirmed") || msg.contains("not confirmed") {
            return "Email не подтверждён. Проверьте почту и перейдите по ссылке."
        }
        // Rate limit
        if msg.contains("rate limit") || msg.contains("too many") || msg.contains("after") {
            return "Слишком много попыток. Подождите немного."
        }
        // Unexpected / server error
        if msg.contains("unexpected") || msg.contains("server error")
            || msg.contains("500") || msg.contains("internal") {
            return "Ошибка сервера. Попробуйте через минуту."
        }
        // Timeout
        if msg.contains("timeout") || msg.contains("timed out") {
            return "Время ожидания истекло. Проверьте соединение."
        }

        return "Ошибка: \(error.localizedDescription)"
    }
}
