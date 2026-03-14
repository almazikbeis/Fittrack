//
//  ProfileView.swift
//  FitnessApp
//
//  Complete redesign: hero header, stats, goals, achievements, sync, notifications, account.
//

import SwiftUI
import CoreData

struct ProfileView: View {
    @EnvironmentObject private var auth:        AuthViewModel
    @EnvironmentObject private var syncService: SyncService

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(entity: Workout.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \Workout.date, ascending: false)])
    private var workouts: FetchedResults<Workout>

    @FetchRequest(entity: FoodEntry.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \FoodEntry.date, ascending: false)])
    private var foodEntries: FetchedResults<FoodEntry>

    @AppStorage("userName")   private var userName:   String = "Спортсмен"
    @AppStorage("userAge")    private var userAge:    Int    = 25
    @AppStorage("userWeight") private var userWeight: Double = 70.0
    @AppStorage("userHeight") private var userHeight: Double = 175.0

    @State private var showEditProfile  = false
    @State private var showGoals        = false
    @State private var showAllAchievements = false
    @State private var showLogoutAlert  = false
    @State private var isRotatingSync   = false
    @State private var statsAppeared    = false
    @State private var notifWorkout:    Bool = true
    @State private var notifNutrition:  Bool = true
    @State private var notifAchievement: Bool = true
    @State private var newlyUnlocked:   Set<String> = []

    private var achievements: [Achievement] {
        AchievementService.compute(
            workouts: Array(workouts),
            foodEntries: Array(foodEntries)
        )
    }

    private var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    private var bmi: Double {
        let h = userHeight / 100
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
                    heroHeader
                    VStack(spacing: 20) {
                        statsGrid
                            .padding(.horizontal)
                            .padding(.top, 20)
                        goalsCard.padding(.horizontal)
                        achievementsCard.padding(.horizontal)
                        syncCard.padding(.horizontal)
                        notificationsCard.padding(.horizontal)
                        accountCard.padding(.horizontal)
                        Spacer().frame(height: 110)
                    }
                }
            }
        }
        .onAppear(perform: loadState)
        .sheet(isPresented: $showEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showGoals) {
            GoalsView().environmentObject(auth)
        }
        .sheet(isPresented: $showAllAchievements) {
            AchievementsView(achievements: achievements)
        }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Выйти", role: .destructive) {
                Task { await auth.signOut() }
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Данные на устройстве останутся. Синхронизированные данные будут доступны после входа.")
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .top) {
            LinearGradient.heroGradient
                .frame(height: 300)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { showEditProfile = true }) {
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
                        .frame(width: 96, height: 96)
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 96, height: 96)
                    Text(String(userName.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
                .scaleEffect(statsAppeared ? 1.0 : 0.6)
                .opacity(statsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.1), value: statsAppeared)

                VStack(spacing: 4) {
                    Text(userName)
                        .font(.title2).fontWeight(.bold).foregroundColor(.white)
                    if let email = auth.currentUser?.email {
                        Text(email)
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Text("\(userAge) лет")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 10)
                .padding(.bottom, 28)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 12)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18), value: statsAppeared)
            }
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            ForEach(Array([
                (String(format: "%.0f", userWeight), "Вес", "кг", Color.primaryGreen),
                (String(format: "%.0f", userHeight), "Рост", "см", Color.blue),
            ].enumerated()), id: \.offset) { idx, item in
                statCard(value: item.0, title: item.1, unit: item.2, color: item.3)
                    .scaleEffect(statsAppeared ? 1.0 : 0.7)
                    .opacity(statsAppeared ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.75)
                        .delay(0.25 + Double(idx) * 0.06), value: statsAppeared)
            }
            // BMI card
            VStack(spacing: 4) {
                Text(String(format: "%.1f", bmi))
                    .font(.title2).fontWeight(.bold).foregroundColor(bmiColor)
                Text("ИМТ").font(.caption).foregroundColor(.secondary)
                Text(bmiCategory)
                    .font(.caption2).fontWeight(.semibold).foregroundColor(bmiColor)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
            .scaleEffect(statsAppeared ? 1.0 : 0.7)
            .opacity(statsAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.37), value: statsAppeared)
        }
    }

    private func statCard(value: String, title: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(unit).font(.caption2).foregroundColor(.secondary.opacity(0.7))
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
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Button(action: { showGoals = true }) {
                    Text("Изменить")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.primaryGreen.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            VStack(spacing: 12) {
                let p = auth.profile
                goalRow(icon: "flame.fill",
                        title: "Калории",
                        target: "\(p?.goalCalories ?? UserDefaults.standard.integer(forKey: "goalCalories").nonZero(or: 2000)) ккал",
                        color: .cardioOrange)
                Divider()
                goalRow(icon: "figure.strengthtraining.traditional",
                        title: "Тренировки",
                        target: "\(p?.goalWorkoutsPerWeek ?? 3) раз в неделю",
                        color: .strengthPurple)
                Divider()
                goalRow(icon: "figure.run",
                        title: "Кардио",
                        target: String(format: "%.1f км в день", p?.goalCardioKmPerDay ?? 5.0),
                        color: .cardioOrange)
                Divider()
                goalRow(icon: "figure.walk",
                        title: "Шаги",
                        target: "\(p?.goalSteps ?? 10000) шаг",
                        color: .primaryGreen)
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
                RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 15)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(target).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Достижения", systemImage: "trophy.fill")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Text("\(unlockedCount)/\(achievements.count)")
                    .font(.caption).foregroundColor(.secondary)
                Button(action: { showAllAchievements = true }) {
                    Text("Все")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.primaryGreen.opacity(0.1))
                        .cornerRadius(10)
                }
                .buttonStyle(ScaleButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { badge in
                        achievementBadge(badge)
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

    private func achievementBadge(_ a: Achievement) -> some View {
        VStack(spacing: 8) {
            ZStack {
                if a.isUnlocked {
                    RoundedRectangle(cornerRadius: 16).fill(a.gradient).frame(width: 60, height: 60)
                    Image(systemName: a.icon).font(.system(size: 24)).foregroundColor(.white)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray5)).frame(width: 60, height: 60)
                    Image(systemName: a.icon)
                        .font(.system(size: 24)).foregroundColor(.secondary.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5))
                        .offset(x: 18, y: 18)
                }
            }
            .shadow(color: a.isUnlocked ? a.color.opacity(0.35) : .clear, radius: 8, x: 0, y: 3)
            .scaleEffect(newlyUnlocked.contains(a.id) ? 1.0 : 1.0)

            Text(a.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(a.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 64)
        }
    }

    // MARK: - Sync Card

    private var syncCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(LinearGradient.primaryGradient).frame(width: 44, height: 44)
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18)).foregroundColor(.white)
                    .rotationEffect(.degrees(isRotatingSync ? 360 : 0))
                    .animation(syncService.isSyncing
                               ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                               : .default, value: isRotatingSync)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Синхронизация").font(.subheadline).fontWeight(.semibold)
                Text(syncService.syncStatusText)
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            if syncService.isSyncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGreen))
                    .scaleEffect(0.8)
            } else {
                Button(action: triggerSync) {
                    Text("Синхр.")
                        .font(.caption).fontWeight(.semibold)
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
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .onChange(of: syncService.isSyncing) { syncing in
            isRotatingSync = syncing
        }
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Уведомления", systemImage: "bell.fill")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
            }
            .padding(16)

            Divider()

            toggleRow("Напоминания о тренировке",
                      icon: "dumbbell.fill", color: .strengthPurple,
                      value: $notifWorkout) {
                saveNotifications()
            }
            Divider().padding(.horizontal, 16)
            toggleRow("Напоминания о питании",
                      icon: "fork.knife", color: .nutritionPurple,
                      value: $notifNutrition) {
                saveNotifications()
            }
            Divider().padding(.horizontal, 16)
            toggleRow("Разблокировка достижений",
                      icon: "trophy.fill", color: .cardioOrange,
                      value: $notifAchievement) {
                saveNotifications()
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func toggleRow(_ title: String, icon: String, color: Color,
                             value: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.12)).frame(width: 32, height: 32)
                Image(systemName: icon).font(.system(size: 13)).foregroundColor(color)
            }
            Text(title).font(.subheadline)
            Spacer()
            Toggle("", isOn: value)
                .tint(.primaryGreen)
                .onChange(of: value.wrappedValue) { _ in onChange() }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Account Card

    private var accountCard: some View {
        VStack(spacing: 0) {
            Button(action: { showLogoutAlert = true }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red).frame(width: 24)
                    Text("Выйти из аккаунта")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(16)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
    }

    // MARK: - Actions

    private func loadState() {
        withAnimation { statsAppeared = true }

        // Load notification prefs from profile
        if let p = auth.profile {
            notifWorkout     = p.notifWorkoutReminders
            notifNutrition   = p.notifNutritionReminders
            notifAchievement = p.notifAchievementAlerts
        } else {
            notifWorkout     = UserDefaults.standard.bool(forKey: "notifWorkout")
            notifNutrition   = UserDefaults.standard.bool(forKey: "notifNutrition")
            notifAchievement = UserDefaults.standard.bool(forKey: "notifAchievement")
        }
    }

    private func triggerSync() {
        guard let userId = auth.currentUser?.id.uuidString else { return }
        isRotatingSync = true
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await syncService.syncAll(userId: userId) }
    }

    private func saveNotifications() {
        let notif = UserNotifUpdate(
            notifWorkoutReminders:   notifWorkout,
            notifNutritionReminders: notifNutrition,
            notifAchievementAlerts:  notifAchievement,
            updatedAt: Date()
        )
        Task { await auth.saveNotifications(notif) }

        // Also persist locally
        UserDefaults.standard.set(notifWorkout,     forKey: "notifWorkout")
        UserDefaults.standard.set(notifNutrition,   forKey: "notifNutrition")
        UserDefaults.standard.set(notifAchievement, forKey: "notifAchievement")
    }
}

// MARK: - Int Extension (local)
private extension Int {
    func nonZero(or fallback: Int) -> Int { self == 0 ? fallback : self }
}
