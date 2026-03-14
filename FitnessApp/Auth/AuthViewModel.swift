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
            currentUser = response.user
            authState   = .onboarding
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

    func saveOnboardingProfile(name: String, age: Int, weight: Double, height: Double) async {
        guard let userId = currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        let patch = UserProfileUpdate(name: name, age: age,
                                      weight: weight, height: height,
                                      updatedAt: Date())
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .upsert(patch)
                .eq("id", value: userId.uuidString)
                .execute()
            await loadProfile(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
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
        if msg.contains("invalid login") || msg.contains("credentials") {
            return "Неверный email или пароль."
        }
        if msg.contains("already registered") || msg.contains("already exists") {
            return "Этот email уже зарегистрирован. Войдите."
        }
        if msg.contains("network") || msg.contains("internet") {
            return "Нет подключения к интернету."
        }
        if msg.contains("weak password") {
            return "Пароль слишком простой. Минимум 6 символов."
        }
        return error.localizedDescription
    }
}
