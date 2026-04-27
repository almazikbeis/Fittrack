//
//  FriendsView.swift
//  FitnessApp
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var service = FriendsService.shared

    @State private var searchText    = ""
    @State private var searchResults: [PublicProfile] = []
    @State private var isSearching   = false
    @State private var selectedTab   = 0   // 0=friends, 1=requests, 2=search
    @State private var sentIds:      Set<UUID> = []

    @Environment(\.dismiss) private var dismiss

    private var userId: String { auth.currentUser?.id.uuidString ?? "" }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        Text("Друзья").tag(0)
                        Text("Заявки \(requestsBadge)").tag(1)
                        Text("Поиск").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    if service.isLoading && service.friends.isEmpty {
                        Spacer()
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                switch selectedTab {
                                case 0: friendsList
                                case 1: requestsList
                                default: searchTab
                                }
                                Spacer().frame(height: 40)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                    }
                }
            }
            .navigationTitle("Друзья")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { dismiss() }
                        .foregroundColor(.primaryGreen)
                }
            }
            .task { await service.loadFriends(userId: userId) }
        }
    }

    // MARK: - Friends List

    private var friendsList: some View {
        Group {
            if service.acceptedFriends.isEmpty {
                emptyState(
                    icon: "person.2.fill",
                    title: "Нет друзей",
                    subtitle: "Найдите знакомых во вкладке «Поиск»"
                )
            } else {
                ForEach(service.acceptedFriends) { friend in
                    friendCard(friend)
                }
            }
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        Group {
            if service.pendingIncoming.isEmpty && service.pendingOutgoing.isEmpty {
                emptyState(
                    icon: "envelope.fill",
                    title: "Нет заявок",
                    subtitle: "Ваши входящие заявки появятся здесь"
                )
            } else {
                if !service.pendingIncoming.isEmpty {
                    sectionHeader("Входящие")
                    ForEach(service.pendingIncoming) { req in
                        requestCard(req, incoming: true)
                    }
                }
                if !service.pendingOutgoing.isEmpty {
                    sectionHeader("Исходящие")
                    ForEach(service.pendingOutgoing) { req in
                        requestCard(req, incoming: false)
                    }
                }
            }
        }
    }

    // MARK: - Search Tab

    private var searchTab: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Имя пользователя...", text: $searchText)
                    .submitLabel(.search)
                    .onSubmit { Task { await performSearch() } }
                if !searchText.isEmpty {
                    Button(action: { searchText = ""; searchResults = [] }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)

            if isSearching {
                ProgressView().padding()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                emptyState(icon: "person.slash.fill", title: "Не найдено",
                           subtitle: "Попробуйте другое имя")
            } else {
                ForEach(searchResults) { profile in
                    searchResultCard(profile)
                }
            }
        }
    }

    // MARK: - Friend Card

    private func friendCard(_ friend: FriendWithProfile) -> some View {
        HStack(spacing: 14) {
            avatarCircle(friend.profile.initials, color: .primaryGreen)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.profile.name)
                    .font(.subheadline).fontWeight(.semibold)
                if let age = friend.profile.age {
                    Text("\(age) лет").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Task { await service.removeFriend(friendRowId: friend.id, userId: userId) }
            }) {
                Text("Удалить")
                    .font(.caption).fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Request Card

    private func requestCard(_ req: FriendWithProfile, incoming: Bool) -> some View {
        HStack(spacing: 14) {
            avatarCircle(req.profile.initials, color: incoming ? .strengthPurple : .secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(req.profile.name)
                    .font(.subheadline).fontWeight(.semibold)
                Text(incoming ? "Хочет добавить вас" : "Заявка отправлена")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()

            if incoming {
                HStack(spacing: 8) {
                    Button(action: {
                        Task { await service.acceptRequest(friendRowId: req.id, userId: userId) }
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 34, height: 34)
                            .background(LinearGradient.primaryGradient)
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: {
                        Task { await service.removeFriend(friendRowId: req.id, userId: userId) }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 34, height: 34)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            } else {
                Button(action: {
                    Task { await service.removeFriend(friendRowId: req.id, userId: userId) }
                }) {
                    Text("Отменить")
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Search Result Card

    private func searchResultCard(_ profile: PublicProfile) -> some View {
        let alreadySent = sentIds.contains(profile.id)
        let isFriend = service.friends.contains { $0.profile.id == profile.id }

        return HStack(spacing: 14) {
            avatarCircle(profile.initials, color: .nutritionBlue)

            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.subheadline).fontWeight(.semibold)
                if let age = profile.age {
                    Text("\(age) лет").font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()

            if isFriend {
                Label("Друг", systemImage: "checkmark.circle.fill")
                    .font(.caption).fontWeight(.semibold)
                    .foregroundColor(.primaryGreen)
            } else if alreadySent {
                Text("Отправлено")
                    .font(.caption).foregroundColor(.secondary)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    sentIds.insert(profile.id)
                    Task { await service.sendRequest(from: userId, to: profile.id.uuidString) }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Добавить")
                            .font(.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(LinearGradient.primaryGradient)
                    .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }

    // MARK: - Helpers

    private func avatarCircle(_ initials: String, color: Color) -> some View {
        ZStack {
            Circle().fill(color.opacity(0.15)).frame(width: 46, height: 46)
            Text(initials)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption).fontWeight(.semibold)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36)).foregroundColor(.secondary.opacity(0.4))
            Text(title).font(.headline).foregroundColor(.secondary)
            Text(subtitle).font(.caption).foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }

    private var requestsBadge: String {
        service.pendingIncoming.isEmpty ? "" : " (\(service.pendingIncoming.count))"
    }

    private func performSearch() async {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching   = true
        searchResults = await service.searchUsers(query: searchText, currentUserId: userId)
        isSearching   = false
    }
}
