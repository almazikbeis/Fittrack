//
//  ProfileView.swift
//  FitnessApp
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("userName") private var userName: String = "Almaz"
    @AppStorage("userAge") private var userAge: Int = 20
    @AppStorage("userWeight") private var userWeight: Double = 85.0
    @AppStorage("userHeight") private var userHeight: Double = 181.0

    @State private var showEditProfile  = false
    @State private var friends: [Friend] = [
        Friend(id: UUID(), name: "Дима", avatarURL: nil, isOnline: true),
        Friend(id: UUID(), name: "Алина", avatarURL: nil, isOnline: false),
        Friend(id: UUID(), name: "Маша", avatarURL: nil, isOnline: true),
        Friend(id: UUID(), name: "Рома", avatarURL: nil, isOnline: true)
    ]

    private var bmi: Double {
        let h = userHeight / 100.0
        return userWeight / (h * h)
    }

    private var bmiCategory: String {
        switch bmi {
        case ..<18.5: return "Дефицит"
        case 18.5..<25: return "Норма"
        case 25..<30: return "Избыток"
        default: return "Ожирение"
        }
    }

    private var bmiColor: Color {
        switch bmi {
        case 18.5..<25: return .primaryGreen
        case 25..<30: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero header
                    heroHeader

                    VStack(spacing: 20) {
                        // Stats grid
                        statsGrid
                            .padding(.horizontal)
                            .padding(.top, 20)

                        // Goals card
                        goalsCard
                            .padding(.horizontal)

                        // Friends section
                        friendsSection
                            .padding(.horizontal)

                        Spacer().frame(height: 110)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .top) {
            LinearGradient.heroGradient
                .frame(height: 280)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Edit button row
                HStack {
                    Spacer()
                    Button(action: { showEditProfile.toggle() }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)

                Spacer()

                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 90, height: 90)
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 2)
                        .frame(width: 90, height: 90)
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)

                VStack(spacing: 4) {
                    Text(userName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("\(userAge) лет")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(title: "Вес", value: String(format: "%.0f", userWeight), unit: "кг", color: .primaryGreen)
            statCard(title: "Рост", value: String(format: "%.0f", userHeight), unit: "см", color: .blue)
            VStack(spacing: 4) {
                Text(String(format: "%.1f", bmi))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(bmiColor)
                Text("ИМТ")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(bmiCategory)
                    .font(.caption2)
                    .foregroundColor(bmiColor)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }

    private func statCard(title: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Goals Card

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Мои цели", systemImage: "target")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 12) {
                goalRow(icon: "figure.strengthtraining.traditional", title: "Силовые тренировки", target: "3 раза в неделю", color: .strengthPurple)
                Divider()
                goalRow(icon: "figure.run", title: "Кардио", target: "5 км в день", color: .cardioOrange)
                Divider()
                goalRow(icon: "scalemass.fill", title: "Целевой вес", target: String(format: "%.0f кг", userWeight), color: .primaryGreen)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func goalRow(icon: String, title: String, target: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(target)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))
        }
    }

    // MARK: - Friends Section

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Друзья", systemImage: "person.2.fill")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(friends.filter { $0.isOnline }.count) онлайн")
                    .font(.caption)
                    .foregroundColor(.primaryGreen)
                    .fontWeight(.medium)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(friends) { friend in
                        friendCard(friend)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(18)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func friendCard(_ friend: Friend) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 54, height: 54)
                    Text(String(friend.name.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                Circle()
                    .fill(friend.isOnline ? Color.green : Color(.systemGray4))
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
            }
            Text(friend.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .frame(width: 68)
    }
}
