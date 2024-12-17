//
//  ProfileView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//
import SwiftUI


struct ProfileView: View {
    @AppStorage("userName") private var userName: String = "Almaz"
    @AppStorage("userAge") private var userAge: Int = 20
    @AppStorage("userWeight") private var userWeight: Double = 85.0
    @AppStorage("userHeight") private var userHeight: Double = 181.0

    
    @State private var showEditProfile = false

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
                            showEditProfile.toggle() // Показать экран редактирования
                        }) {
                            Image(systemName: "gear")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            // Показываем модальное окно для редактирования профиля
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

