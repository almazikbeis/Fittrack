//
//  AuthView.swift
//  FitnessApp
//
//  Login / Register screen with animated toggle.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var isLogin         = true
    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var showPassword    = false
    @State private var showConfirm     = false
    @State private var showForgot      = false
    @State private var forgotEmail     = ""
    @State private var forgotSent      = false

    // Logo pulse
    @State private var logoPulse = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient.heroGradient
                .ignoresSafeArea()

            // Floating blobs
            blobsBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    logoSection
                        .padding(.top, 80)
                        .padding(.bottom, 40)

                    formCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)

                    toggleLink
                }
                .padding(.bottom, 60)
            }
        }
        .alert("Сброс пароля", isPresented: $showForgot) {
            TextField("Email", text: $forgotEmail)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Отправить") {
                Task {
                    forgotSent = await auth.resetPassword(email: forgotEmail)
                }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(forgotSent ? "Письмо отправлено!" : "Введите email для сброса пароля")
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)
                    .scaleEffect(logoPulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                               value: logoPulse)

                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)

                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .onAppear { logoPulse = true }

            VStack(spacing: 6) {
                Text("FitTrack")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Твой персональный тренер")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: 20) {
            // Mode toggle
            modeToggle

            // Error banner
            if let error = auth.errorMessage {
                errorBanner(error)
            }

            // Fields
            emailField
            passwordField

            if !isLogin {
                confirmPasswordField
            }

            // CTA
            actionButton

            // Forgot password
            if isLogin {
                Button("Забыли пароль?") { showForgot = true }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
    }

    // MARK: - Mode Toggle (Segmented)

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab(title: "Войти",    active: isLogin) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isLogin = true
                    auth.errorMessage = nil
                }
            }
            modeTab(title: "Регистрация", active: !isLogin) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isLogin = false
                    auth.errorMessage = nil
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .cornerRadius(14)
    }

    private func modeTab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(active ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(active ? LinearGradient.primaryGradient : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
                .padding(3)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Fields

    private var emailField: some View {
        fieldContainer(icon: "envelope.fill", color: .primaryGreen) {
            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
        }
    }

    private var passwordField: some View {
        fieldContainer(icon: "lock.fill", color: .strengthPurple) {
            Group {
                if showPassword {
                    TextField("Пароль", text: $password)
                } else {
                    SecureField("Пароль", text: $password)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
        }
    }

    private var confirmPasswordField: some View {
        fieldContainer(icon: "lock.shield.fill", color: .cardioOrange) {
            Group {
                if showConfirm {
                    TextField("Подтвердите пароль", text: $confirmPassword)
                } else {
                    SecureField("Подтвердите пароль", text: $confirmPassword)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button(action: { showConfirm.toggle() }) {
                Image(systemName: showConfirm ? "eye.slash" : "eye")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(!confirmPassword.isEmpty && confirmPassword != password
                        ? Color.red.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }

    private func fieldContainer<Content: View>(icon: String, color: Color,
                                               @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
            }
            content()
        }
        .padding(14)
        .background(Color(.systemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Action Button

    private var actionButton: some View {
        Button(action: handleAction) {
            ZStack {
                Text(isLogin ? "Войти" : "Создать аккаунт")
                    .font(.headline).fontWeight(.semibold)
                    .foregroundColor(.white)
                    .opacity(auth.isLoading ? 0 : 1)

                if auth.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isFormValid ? LinearGradient.primaryGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
            .cornerRadius(18)
            .shadow(color: isFormValid ? Color.primaryGreen.opacity(0.4) : .clear,
                    radius: 12, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isFormValid || auth.isLoading)
        .animation(.spring(response: 0.3), value: isFormValid)
    }

    // MARK: - Toggle Link

    private var toggleLink: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isLogin.toggle()
                auth.errorMessage = nil
            }
        }) {
            HStack(spacing: 4) {
                Text(isLogin ? "Нет аккаунта?" : "Уже есть аккаунт?")
                    .foregroundColor(.white.opacity(0.75))
                Text(isLogin ? "Создать" : "Войти")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .font(.subheadline)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Blobs Background

    private var blobsBackground: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -200)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 200, height: 200)
                .offset(x: 140, y: 260)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(.red)
            Text(msg)
                .font(.caption)
                .foregroundColor(.red)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if isLogin {
            return emailOK && passwordOK
        } else {
            return emailOK && passwordOK && confirmPassword == password
        }
    }

    private func handleAction() {
        Task {
            if isLogin {
                await auth.signIn(email: email, password: password)
            } else {
                await auth.signUp(email: email, password: password)
            }
        }
    }
}
