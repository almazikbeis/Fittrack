import SwiftUI

struct ExerciseSummaryView: View {
    let result: SessionResult
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    heroSection
                    statsGrid
                        .staggeredAppear(index: 1)
                    xpBanner
                        .staggeredAppear(index: 2)
                    doneButton
                        .staggeredAppear(index: 3)
                    Spacer().frame(height: 40)
                }
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(result.exercise.gradient)
                    .frame(width: 88, height: 88)
                    .shadow(color: result.exercise.accentColor.opacity(0.4), radius: 18)
                Image(systemName: result.exercise.icon)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.68).delay(0.1), value: appeared)

            Text("Тренировка завершена!")
                .font(.title2).fontWeight(.bold)
            Text(result.exercise.rawValue)
                .font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.top, 60)
        .onAppear { appeared = true }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            SummaryStatCell(
                icon: result.exercise.isTimeBased ? "timer" : "arrow.counterclockwise",
                title: result.exercise.isTimeBased ? "Удержано" : "Повторений",
                value: result.exercise.isTimeBased ? formatSec(result.reps) : "\(result.reps)",
                color: result.exercise.accentColor
            )
            SummaryStatCell(
                icon: "sparkles",
                title: "Форма",
                value: "\(Int(result.formScore * 100))%",
                color: formColor
            )
            SummaryStatCell(
                icon: "bolt.fill",
                title: "XP получено",
                value: "+\(result.xpEarned)",
                color: .primaryGreen
            )
            SummaryStatCell(
                icon: "clock",
                title: "Длительность",
                value: formatSec(Int(result.duration)),
                color: .cardioOrange
            )
        }
        .padding(.horizontal)
    }

    // MARK: - XP Banner

    private var xpBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .foregroundStyle(LinearGradient.achievementGold)
                .font(.title3)
            Text("+\(result.xpEarned) XP за тренировку!")
                .font(.headline)
            Spacer()
        }
        .padding(16)
        .background(Color.primaryGreen.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // MARK: - Done

    private var doneButton: some View {
        Button(action: onDismiss) {
            Text("Готово")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(result.exercise.gradient)
                .cornerRadius(18)
                .shadow(color: result.exercise.accentColor.opacity(0.4), radius: 12, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 24)
    }

    private var formColor: Color {
        result.formScore >= 0.8 ? .primaryGreen : result.formScore >= 0.6 ? .cardioOrange : .cardioRed
    }

    private func formatSec(_ s: Int) -> String {
        s < 60 ? "\(s)с" : String(format: "%d:%02d", s / 60, s % 60)
    }
}

private struct SummaryStatCell: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(title)
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
