import SwiftUI

struct AITrainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercise: ExerciseType?
    @State private var showSession = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    howItWorksCard
                    exerciseCards
                    Spacer().frame(height: 120)
                }
            }

            if let exercise = selectedExercise {
                startButton(exercise: exercise)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.35, dampingFraction: 0.72), value: selectedExercise)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSession) {
            if let exercise = selectedExercise {
                ExerciseSessionView(exercise: exercise)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemBackground))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.08), radius: 6)
                }
                Spacer()
                Label("Apple Vision", systemImage: "camera.metering.spot")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.primaryGreen.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 56)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI Тренировка")
                    .font(.largeTitle).fontWeight(.bold)
                Text("Камера анализирует технику в реальном времени")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - How It Works

    private var howItWorksCard: some View {
        HStack(spacing: 16) {
            ForEach([
                ("camera.fill",       "Фронт-камера"),
                ("figure.walk",       "19 точек тела"),
                ("checkmark.seal.fill","Счёт + форма"),
            ], id: \.0) { icon, label in
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(LinearGradient.primaryGradient)
                    Text(label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Exercise Cards

    private var exerciseCards: some View {
        VStack(spacing: 14) {
            ForEach(Array(ExerciseType.allCases.enumerated()), id: \.element.id) { idx, exercise in
                ExerciseSelectCard(
                    exercise: exercise,
                    isSelected: selectedExercise == exercise
                ) {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedExercise = selectedExercise == exercise ? nil : exercise
                    }
                }
                .staggeredAppear(index: idx)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Start Button

    private func startButton(exercise: ExerciseType) -> some View {
        Button { showSession = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Начать · \(exercise.rawValue)")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(exercise.gradient)
            .cornerRadius(18)
            .shadow(color: exercise.accentColor.opacity(0.4), radius: 14, x: 0, y: 6)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Exercise Select Card

struct ExerciseSelectCard: View {
    let exercise: ExerciseType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(exercise.gradient)
                        .frame(width: 56, height: 56)
                    Image(systemName: exercise.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.rawValue)
                        .font(.headline).foregroundColor(.primary)
                    Text(exercise.description)
                        .font(.subheadline).foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? exercise.accentColor : Color(.systemGray4))
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? exercise.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(
                color: isSelected ? exercise.accentColor.opacity(0.15) : .black.opacity(0.05),
                radius: isSelected ? 12 : 6,
                x: 0, y: 3
            )
        }
        .buttonStyle(.plain)
    }
}
