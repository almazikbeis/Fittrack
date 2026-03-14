//
//  OnboardingView.swift
//  FitnessApp
//
//  4-step onboarding after registration: name → age → body → goals.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var auth: AuthViewModel

    @State private var step      = 0
    @State private var name      = ""
    @State private var age       = 25
    @State private var weight    = 70.0
    @State private var height    = 175.0
    @State private var calGoal   = 2000
    @State private var stepsGoal = 10000

    private let totalSteps = 4

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                // Step content
                ZStack {
                    stepView(0) { stepName }
                    stepView(1) { stepAge }
                    stepView(2) { stepBody }
                    stepView(3) { stepGoals }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Navigation buttons
                navButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Настройка профиля")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Text("\(step + 1) из \(totalSteps)")
                    .font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps),
                               height: 6)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: step)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Step Content Wrapper

    private func stepView<Content: View>(_ idx: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(step == idx ? 1 : 0)
            .offset(x: step == idx ? 0 : (step > idx ? -30 : 30))
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
            .allowsHitTesting(step == idx)
    }

    // MARK: - Step 1: Name

    private var stepName: some View {
        VStack(spacing: 32) {
            stepIcon("person.fill", gradient: .primaryGradient)
            VStack(spacing: 8) {
                Text("Как тебя зовут?")
                    .font(.title2).fontWeight(.bold)
                Text("Мы будем обращаться к тебе по имени")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            TextField("Введи имя", text: $name)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
                .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 2: Age

    private var stepAge: some View {
        VStack(spacing: 32) {
            stepIcon("birthday.cake.fill", gradient: .cardioGradient)
            VStack(spacing: 8) {
                Text("Сколько тебе лет?")
                    .font(.title2).fontWeight(.bold)
                Text("Нужно для расчёта норм и рекомендаций")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            // Large age picker
            VStack(spacing: 16) {
                Text("\(age)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.primaryGreen)
                    .animation(.spring(response: 0.2), value: age)
                HStack(spacing: 32) {
                    stepperButton(icon: "minus", color: .cardioOrange) {
                        if age > 10 { age -= 1 }
                    }
                    stepperButton(icon: "plus", color: .primaryGreen) {
                        if age < 100 { age += 1 }
                    }
                }
            }
            .padding(28)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
            .padding(.horizontal, 32)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 3: Body

    private var stepBody: some View {
        VStack(spacing: 28) {
            stepIcon("figure.arms.open", gradient: .strengthGradient)
            VStack(spacing: 8) {
                Text("Параметры тела")
                    .font(.title2).fontWeight(.bold)
                Text("Используем для расчёта ИМТ и КБЖУ")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                sliderCard(
                    title: "Вес",
                    value: $weight,
                    range: 30...200,
                    unit: "кг",
                    color: .primaryGreen
                )
                sliderCard(
                    title: "Рост",
                    value: $height,
                    range: 100...250,
                    unit: "см",
                    color: .strengthPurple
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 4: Goals

    private var stepGoals: some View {
        VStack(spacing: 28) {
            stepIcon("target", gradient: .nutritionGradient)
            VStack(spacing: 8) {
                Text("Твои цели")
                    .font(.title2).fontWeight(.bold)
                Text("Установи начальные цели — потом можно изменить")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 16) {
                goalCard(
                    icon: "flame.fill",
                    title: "Калории в день",
                    value: $calGoal,
                    range: 1200...4000,
                    step: 50,
                    unit: "ккал",
                    color: .cardioOrange
                )
                goalCard(
                    icon: "figure.walk",
                    title: "Шаги в день",
                    value: $stepsGoal,
                    range: 2000...25000,
                    step: 500,
                    unit: "шаг",
                    color: .primaryGreen
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation Buttons

    private var navButtons: some View {
        HStack(spacing: 14) {
            if step > 0 {
                Button(action: prevStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Button(action: nextStep) {
                ZStack {
                    Text(step == totalSteps - 1 ? "Начать 🚀" : "Далее")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundColor(.white)
                        .opacity(auth.isLoading ? 0 : 1)
                    if auth.isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(isStepValid ? LinearGradient.primaryGradient : LinearGradient(colors: [Color(.systemGray4)], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(18)
                .shadow(color: isStepValid ? Color.primaryGreen.opacity(0.4) : .clear,
                        radius: 12, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isStepValid || auth.isLoading)
        }
    }

    // MARK: - Helpers

    private var isStepValid: Bool {
        switch step {
        case 0: return !name.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private func nextStep() {
        if step < totalSteps - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { step += 1 }
        } else {
            Task {
                await auth.saveOnboardingProfile(
                    name: name.trimmingCharacters(in: .whitespaces),
                    age: age,
                    weight: weight,
                    height: height
                )
            }
        }
    }

    private func prevStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { step -= 1 }
    }

    private func stepIcon(_ name: String, gradient: LinearGradient) -> some View {
        ZStack {
            Circle().fill(gradient).frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
            Image(systemName: name)
                .font(.system(size: 38))
                .foregroundColor(.white)
        }
    }

    private func stepperButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 52, height: 52)
                .background(color.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func sliderCard(title: String, value: Binding<Double>,
                             range: ClosedRange<Double>, unit: String, color: Color) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f \(unit)", value.wrappedValue))
                    .font(.subheadline).fontWeight(.bold).foregroundColor(color)
            }
            Slider(value: value, in: range, step: 0.5).tint(color)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    private func goalCard(icon: String, title: String, value: Binding<Int>,
                           range: ClosedRange<Int>, step: Int, unit: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 38, height: 38)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text("\(value.wrappedValue) \(unit)")
                    .font(.caption).foregroundColor(color).fontWeight(.semibold)
            }
            Spacer()
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
