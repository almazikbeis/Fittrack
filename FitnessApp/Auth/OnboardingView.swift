//
//  OnboardingView.swift
//  FitnessApp
//
//  4-step onboarding after registration — dark NRC style
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
                progressBar
                    .padding(.horizontal, DS.xxl)
                    .padding(.top, 60)
                    .padding(.bottom, DS.xxxl)

                ZStack {
                    stepView(0) { stepName }
                    stepView(1) { stepAge }
                    stepView(2) { stepBody }
                    stepView(3) { stepGoals }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if let err = auth.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.cardioRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.xxl)
                        .padding(.top, DS.sm)
                        .transition(.opacity)
                }

                navButtons
                    .padding(.horizontal, DS.xxl)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: DS.sm) {
            HStack {
                Text("Настройка профиля")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Text("\(step + 1) из \(totalSteps)")
                    .font(.caption).foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: DS.xs)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 5)
                    RoundedRectangle(cornerRadius: DS.xs)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(step + 1) / CGFloat(totalSteps),
                               height: 5)
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: step)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Step Wrapper

    private func stepView<Content: View>(_ idx: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(step == idx ? 1 : 0)
            .offset(x: step == idx ? 0 : (step > idx ? -30 : 30))
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: step)
            .allowsHitTesting(step == idx)
    }

    // MARK: - Step 1: Name

    private var stepName: some View {
        VStack(spacing: DS.xxxl) {
            stepIcon("person.fill", gradient: .primaryGradient)

            VStack(spacing: DS.sm) {
                Text("Как тебя зовут?")
                    .font(.title2).fontWeight(.bold)
                Text("Мы будем обращаться к тебе по имени")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            TextField("Введи имя", text: $name)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(DS.lg)
                .background(Color(.systemBackground),
                            in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                .padding(.horizontal, DS.xxxl)
        }
        .padding(.horizontal, DS.xxl)
    }

    // MARK: - Step 2: Age

    private var stepAge: some View {
        VStack(spacing: DS.xxxl) {
            stepIcon("birthday.cake.fill", gradient: .cardioGradient)

            VStack(spacing: DS.sm) {
                Text("Сколько тебе лет?")
                    .font(.title2).fontWeight(.bold)
                Text("Нужно для расчёта норм и рекомендаций")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: DS.lg) {
                Text("\(age)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.primaryGreen)
                    .animation(.spring(response: 0.2), value: age)
                    .contentTransition(.numericText())

                HStack(spacing: DS.xxxl) {
                    stepperButton(icon: "minus", color: .cardioOrange) {
                        if age > 10 { age -= 1 }
                    }
                    stepperButton(icon: "plus", color: .primaryGreen) {
                        if age < 100 { age += 1 }
                    }
                }
            }
            .padding(DS.xxl)
            .background(Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: DS.rXL, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 5)
            .padding(.horizontal, DS.xxxl)
        }
        .padding(.horizontal, DS.xxl)
    }

    // MARK: - Step 3: Body

    private var stepBody: some View {
        VStack(spacing: DS.xxl) {
            stepIcon("figure.arms.open", gradient: .strengthGradient)

            VStack(spacing: DS.sm) {
                Text("Параметры тела")
                    .font(.title2).fontWeight(.bold)
                Text("Используем для расчёта ИМТ и КБЖУ")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: DS.lg) {
                sliderCard(title: "Вес",  value: $weight, range: 30...200, unit: "кг", color: .primaryGreen)
                sliderCard(title: "Рост", value: $height, range: 100...250, unit: "см", color: .strengthPurple)
            }
            .padding(.horizontal, DS.xxl)
        }
        .padding(.horizontal, DS.xxl)
    }

    // MARK: - Step 4: Goals

    private var stepGoals: some View {
        VStack(spacing: DS.xxl) {
            stepIcon("target", gradient: .nutritionGradient)

            VStack(spacing: DS.sm) {
                Text("Твои цели")
                    .font(.title2).fontWeight(.bold)
                Text("Установи начальные цели — потом можно изменить")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: DS.lg) {
                goalCard(icon: "flame.fill",   title: "Калории в день",
                         value: $calGoal,   range: 1200...4000, step: 50,  unit: "ккал", color: .cardioOrange)
                goalCard(icon: "figure.walk",  title: "Шаги в день",
                         value: $stepsGoal, range: 2000...25000, step: 500, unit: "шаг",  color: .primaryGreen)
            }
            .padding(.horizontal, DS.xxl)
        }
        .padding(.horizontal, DS.xxl)
    }

    // MARK: - Nav Buttons

    private var navButtons: some View {
        HStack(spacing: DS.md) {
            if step > 0 {
                Button(action: prevStep) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 52, height: 52)
                        .background(Color(.systemBackground), in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
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
                .padding(.vertical, DS.lg)
                .background(
                    isStepValid
                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                    : AnyShapeStyle(Color(.systemGray4)),
                    in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous)
                )
                .shadow(color: isStepValid ? Color.primaryGreen.opacity(0.45) : .clear,
                        radius: 14, x: 0, y: 5)
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
                    name:      name.trimmingCharacters(in: .whitespaces),
                    age:       age,
                    weight:    weight,
                    height:    height,
                    calGoal:   calGoal,
                    stepsGoal: stepsGoal
                )
            }
        }
    }

    private func prevStep() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) { step -= 1 }
    }

    private func stepIcon(_ name: String, gradient: LinearGradient) -> some View {
        ZStack {
            Circle()
                .fill(gradient)
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.25), radius: 18, x: 0, y: 8)
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
                .background(color.opacity(0.12), in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func sliderCard(title: String, value: Binding<Double>,
                             range: ClosedRange<Double>, unit: String, color: Color) -> some View {
        VStack(spacing: DS.md) {
            HStack {
                Text(title).font(.subheadline).fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f \(unit)", value.wrappedValue))
                    .font(.subheadline).fontWeight(.bold).foregroundColor(color)
            }
            Slider(value: value, in: range, step: 0.5).tint(color)
        }
        .padding(DS.lg)
        .background(Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
    }

    private func goalCard(icon: String, title: String, value: Binding<Int>,
                           range: ClosedRange<Int>, step: Int, unit: String, color: Color) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .iconBadge(color: color, radius: DS.rSM, size: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text("\(value.wrappedValue) \(unit)")
                    .font(.caption).foregroundColor(color).fontWeight(.semibold)
            }
            Spacer()
            Stepper("", value: value, in: range, step: step).labelsHidden()
        }
        .padding(DS.md)
        .background(Color(.systemBackground),
                    in: RoundedRectangle(cornerRadius: DS.rLG, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
    }
}
