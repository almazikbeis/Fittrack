//
//  AchievementsView.swift
//  FitnessApp
//
//  Full-screen achievements grid.
//

import SwiftUI

struct AchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Progress header
                    let unlocked = achievements.filter { $0.isUnlocked }.count
                    progressHeader(unlocked: unlocked, total: achievements.count)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(achievements.enumerated()), id: \.element.id) { idx, badge in
                            achievementCard(badge, delay: Double(idx) * 0.04)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Достижения")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.primaryGreen)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Progress Header

    private func progressHeader(unlocked: Int, total: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(unlocked) из \(total)")
                        .font(.title2).fontWeight(.bold)
                    Text("достижений разблокировано")
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: CGFloat(unlocked) / CGFloat(max(total, 1)))
                        .stroke(LinearGradient.primaryGradient,
                                style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(CGFloat(unlocked) / CGFloat(max(total, 1)) * 100))%")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color(.systemGray5)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * CGFloat(unlocked) / CGFloat(max(total, 1)), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    // MARK: - Achievement Card

    @State private var appeared = false

    private func achievementCard(_ a: Achievement, delay: Double) -> some View {
        VStack(spacing: 12) {
            ZStack {
                if a.isUnlocked {
                    RoundedRectangle(cornerRadius: 20).fill(a.gradient)
                        .shadow(color: a.color.opacity(0.4), radius: 10, x: 0, y: 4)
                } else {
                    RoundedRectangle(cornerRadius: 20).fill(Color(.systemGray6))
                }

                VStack(spacing: 10) {
                    Image(systemName: a.icon)
                        .font(.system(size: 32))
                        .foregroundColor(a.isUnlocked ? .white : .secondary.opacity(0.4))
                    if !a.isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                }
            }
            .frame(height: 110)
            .overlay(
                a.isUnlocked
                    ? RoundedRectangle(cornerRadius: 20)
                        .stroke(a.color.opacity(0.3), lineWidth: 1)
                    : nil
            )

            VStack(spacing: 4) {
                Text(a.title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(a.isUnlocked ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(a.description)
                    .font(.caption2).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}
