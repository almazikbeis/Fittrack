//
//  ProfileView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//
import SwiftUI

// Модель друга
struct Friend: Identifiable {
    let id: UUID
    let name: String
    let avatarURL: URL?
    let isOnline: Bool
}

struct ProfileView: View {
    @AppStorage("userName") private var userName: String = "Almaz"
    @AppStorage("userAge") private var userAge: Int = 20
    @AppStorage("userWeight") private var userWeight: Double = 85.0
    @AppStorage("userHeight") private var userHeight: Double = 181.0

    // Список друзей (тестовые данные)
    @State private var friends: [Friend] = [
        Friend(id: UUID(), name: "Дима", avatarURL: nil, isOnline: true),
        Friend(id: UUID(), name: "Алина", avatarURL: nil, isOnline: false),
        Friend(id: UUID(), name: "Маша", avatarURL: nil, isOnline: true)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Заголовок профиля
                    ProfileHeaderView(userName: userName, userAge: userAge)

                    InfoSectionView(title: "Вес", value: String(format: "%.1f кг", userWeight), color: .green)
                    InfoSectionView(title: "Рост", value: String(format: "%.1f см", userHeight), color: .blue)

                    // Секция с друзьями
                    FriendsSectionView(friends: friends)
                }
                .padding(.horizontal)
                .navigationTitle("Профиль")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            print("Настройки нажаты")
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Компоненты интерфейса

struct InfoSectionView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct FriendsSectionView: View {
    let friends: [Friend]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Друзья")
                .font(.title3)
                .fontWeight(.bold)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(friends) { friend in
                        VStack {
                            Image(systemName: friend.isOnline ? "person.circle.fill" : "person.circle")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(friend.isOnline ? .green : .gray)
                            Text(friend.name)
                                .font(.caption)
                        }
                        .frame(width: 70, height: 100)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}
