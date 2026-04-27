//
//  AuthView.swift
//  FitnessApp
//
//  Login / Register screen — dark NRC style
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
    @State private var logoPulse       = false

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.06),
                         Color(red: 0.04, green: 0.16, blue: 0.32),
                         Color(red: 0.02, green: 0.08, blue: 0.16)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Ambient blobs
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .offset(x: -130, y: -220)
                Circle()
                    .fill(Color.strengthPurple.opacity(0.05))
                    .frame(width: 220, height: 220)
                    .offset(x: 150, y: 280)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    logoSection
                        .padding(.top, 80)
                        .padding(.bottom, 44)

                    formCard
                        .padding(.horizontal, DS.xxl)
                        .padding(.bottom, DS.xxxl)

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
                Task { forgotSent = await auth.resetPassword(email: forgotEmail) }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text(forgotSent ? "Письмо отправлено!" : "Введите email для сброса пароля")
        }
    }

    // MARK: - Logo

    private var logoSection: some View {
        VStack(spacing: DS.lg) {
            ZStack {
                Circle()
                    .fill(Color.primaryGreen.opacity(0.12))
                    .frame(width: 104, height: 104)
                    .scaleEffect(logoPulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                               value: logoPulse)

                Circle()
                    .stroke(Color.primaryGreen.opacity(0.25), lineWidth: 1.5)
                    .frame(width: 104, height: 104)

                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(LinearGradient.primaryGradient)
            }
            .onAppear { logoPulse = true }

            VStack(spacing: DS.xs) {
                Text("FitTrack")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("Твой персональный тренер")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.55))
            }
        }
    }

    // MARK: - Form Card

    private var formCard: some View {
        VStack(spacing: DS.xl) {
            modeToggle

            if let error = auth.errorMessage {
                if error.contains("Проверьте почту") || error.contains("создан") {
                    infoBanner(error)
                } else {
                    errorBanner(error)
                }
            }

            emailField
            passwordField

            if !isLogin { confirmPasswordField }

            actionButton

            if isLogin {
                Button("Забыли пароль?") { showForgot = true }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.45))
                    .padding(.top, DS.xs)
            }
        }
        .padding(DS.xxl)
        .background(Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rXXL, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 32, x: 0, y: 12)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeTab(title: "Войти", active: isLogin) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isLogin = true; auth.errorMessage = nil
                }
            }
            modeTab(title: "Регистрация", active: !isLogin) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isLogin = false; auth.errorMessage = nil
                }
            }
        }
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
    }

    private func modeTab(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundColor(active ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.md)
                .background(
                    active
                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                    : AnyShapeStyle(Color.clear),
                    in: RoundedRectangle(cornerRadius: DS.rMD - 2, style: .continuous)
                )
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
                if showPassword { TextField("Пароль", text: $password) }
                else            { SecureField("Пароль", text: $password) }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button(action: { showPassword.toggle() }) {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.secondary).font(.system(size: 14))
            }
        }
    }

    private var confirmPasswordField: some View {
        fieldContainer(icon: "lock.shield.fill", color: .cardioOrange) {
            Group {
                if showConfirm { TextField("Подтвердите пароль", text: $confirmPassword) }
                else           { SecureField("Подтвердите пароль", text: $confirmPassword) }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Button(action: { showConfirm.toggle() }) {
                Image(systemName: showConfirm ? "eye.slash" : "eye")
                    .foregroundColor(.secondary).font(.system(size: 14))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                .stroke(!confirmPassword.isEmpty && confirmPassword != password
                        ? Color.red.opacity(0.5) : .clear, lineWidth: 1.5)
        )
    }

    private func fieldContainer<Content: View>(icon: String, color: Color,
                                               @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .iconBadge(color: color, radius: DS.rSM, size: 32)
            content()
        }
        .padding(DS.md)
        .background(Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
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
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.lg)
            .background(
                isFormValid
                ? AnyShapeStyle(LinearGradient.primaryGradient)
                : AnyShapeStyle(Color(.systemGray4)),
                in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
            )
            .shadow(color: isFormValid ? Color.primaryGreen.opacity(0.45) : .clear,
                    radius: 14, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isFormValid || auth.isLoading)
        .animation(.spring(response: 0.3), value: isFormValid)
    }

    // MARK: - Toggle Link

    private var toggleLink: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isLogin.toggle(); auth.errorMessage = nil
            }
        }) {
            HStack(spacing: DS.xs) {
                Text(isLogin ? "Нет аккаунта?" : "Уже есть аккаунт?")
                    .foregroundColor(.white.opacity(0.5))
                Text(isLogin ? "Создать" : "Войти")
                    .fontWeight(.semibold).foregroundColor(.white)
            }
            .font(.subheadline)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Banners

    private func infoBanner(_ msg: String) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13)).foregroundColor(.primaryGreen)
            Text(msg).font(.caption).foregroundColor(.primaryGreen)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(DS.md)
        .background(Color.primaryGreen.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                .stroke(Color.primaryGreen.opacity(0.25), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13)).foregroundColor(.cardioRed)
            Text(msg).font(.caption).foregroundColor(.cardioRed)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(DS.md)
        .background(Color.cardioRed.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: DS.rMD, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                .stroke(Color.cardioRed.opacity(0.2), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let emailOK    = email.contains("@") && email.contains(".")
        let passwordOK = password.count >= 6
        if isLogin { return emailOK && passwordOK }
        return emailOK && passwordOK && confirmPassword == password
    }

    private func handleAction() {
        Task {
            if isLogin { await auth.signIn(email: email, password: password) }
            else       { await auth.signUp(email: email, password: password) }
        }
    }
}
