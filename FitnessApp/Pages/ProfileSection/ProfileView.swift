//
//  ProfileView.swift
//  FitnessApp
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

    @State private var showEditProfile     = false
    @State private var showGoals           = false
    @State private var showAllAchievements = false
    @State private var showLogoutAlert     = false
    @State private var showFriends         = false
    @State private var showWeightLog       = false
    @State private var isRotatingSync      = false
    @State private var statsAppeared       = false
    @State private var notifWorkout:       Bool = true
    @State private var notifNutrition:     Bool = true
    @State private var notifAchievement:   Bool = true
    @State private var newlyUnlocked:      Set<String> = []

    @ObservedObject private var notifManager = NotificationManager.shared

    private var achievements: [Achievement] {
        AchievementService.compute(
            workouts: Array(workouts),
            foodEntries: Array(foodEntries)
        )
    }
    private var unlockedCount: Int { achievements.filter { $0.isUnlocked }.count }

    private var bmi: Double {
        let h = userHeight / 100
        guard h > 0 else { return 0 }
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
        case 25..<30:   return .cardioOrange
        default:        return .cardioRed
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroHeader
                    VStack(spacing: DS.xl) {
                        statsGrid
                            .padding(.horizontal, DS.lg)
                            .padding(.top, DS.xl)
                        goalsCard.padding(.horizontal, DS.lg)
                        achievementsCard.padding(.horizontal, DS.lg)
                        socialCard.padding(.horizontal, DS.lg)
                        bodyCard.padding(.horizontal, DS.lg)
                        syncCard.padding(.horizontal, DS.lg)
                        notificationsCard.padding(.horizontal, DS.lg)
                        accountCard.padding(.horizontal, DS.lg)
                        Spacer().frame(height: 110)
                    }
                }
            }
        }
        .onAppear(perform: loadState)
        .sheet(isPresented: $showEditProfile) { EditProfileView() }
        .sheet(isPresented: $showGoals) { GoalsView().environmentObject(auth) }
        .sheet(isPresented: $showAllAchievements) { AchievementsView(achievements: achievements) }
        .sheet(isPresented: $showFriends) { FriendsView().environmentObject(auth) }
        .sheet(isPresented: $showWeightLog) { WeightLogView() }
        .alert("Выйти из аккаунта?", isPresented: $showLogoutAlert) {
            Button("Выйти", role: .destructive) { Task { await auth.signOut() } }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Данные на устройстве останутся. Синхронизированные данные будут доступны после входа.")
        }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.primaryGreen.opacity(0.10), Color(.systemGroupedBackground)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 300)
            .ignoresSafeArea(edges: .top)

            RadialGradient(
                colors: [Color.primaryGreen.opacity(0.12), .clear],
                center: UnitPoint(x: 0.5, y: 0.3),
                startRadius: 10, endRadius: 180
            )
            .frame(height: 300)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { showEditProfile = true }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 36, height: 36)
                            .background(Color(.systemBackground).opacity(0.75), in: Circle())
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, DS.xxl)
                .padding(.top, 60)

                Spacer()

                // Avatar
                ZStack {
                    Circle()
                        .stroke(LinearGradient.primaryGradient, lineWidth: 3)
                        .frame(width: 96, height: 96)
                    Circle()
                        .fill(Color.primaryGreen.opacity(0.12))
                        .frame(width: 90, height: 90)
                    Text(String(userName.prefix(1)).uppercased())
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.primaryGreen)
                }
                .scaleEffect(statsAppeared ? 1.0 : 0.6)
                .opacity(statsAppeared ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.72).delay(0.1),
                           value: statsAppeared)
                .padding(.top, DS.lg)

                // Name + email
                VStack(spacing: DS.xs) {
                    Text(userName)
                        .font(.title2).fontWeight(.bold).foregroundColor(.primary)
                    if let email = auth.currentUser?.email {
                        Text(email)
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.top, DS.sm)
                .padding(.bottom, DS.xxl)
                .opacity(statsAppeared ? 1 : 0)
                .offset(y: statsAppeared ? 0 : 12)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.18),
                           value: statsAppeared)
            }
        }
        .frame(height: 300)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: DS.md) {
            statsCell(
                value: String(format: "%.0f", userWeight),
                label: "Вес", unit: "кг",
                color: .primaryGreen, delay: 0.25
            )
            statsCell(
                value: String(format: "%.0f", userHeight),
                label: "Рост", unit: "см",
                color: .waterCyan, delay: 0.31
            )
            // BMI
            VStack(spacing: DS.xs) {
                Text(bmi > 0 ? String(format: "%.1f", bmi) : "—")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(bmiColor)
                Text("ИМТ").font(.caption).foregroundColor(.secondary)
                if bmi > 0 {
                    Text(bmiCategory)
                        .font(.caption2).fontWeight(.semibold).foregroundColor(bmiColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.lg)
            .nrcCard(radius: DS.rMD)
            .scaleEffect(statsAppeared ? 1.0 : 0.7)
            .opacity(statsAppeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.37),
                       value: statsAppeared)
        }
    }

    private func statsCell(value: String, label: String, unit: String,
                           color: Color, delay: Double) -> some View {
        VStack(spacing: DS.xs) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
            Text(unit).font(.caption2).foregroundColor(.secondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.lg)
        .nrcCard(radius: DS.rMD)
        .scaleEffect(statsAppeared ? 1.0 : 0.7)
        .opacity(statsAppeared ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.75).delay(delay),
                   value: statsAppeared)
    }

    // MARK: - Goals Card

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
            HStack {
                Label("Мои цели", systemImage: "target")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Button(action: { showGoals = true }) {
                    Text("Изменить")
                        .font(.caption).fontWeight(.semibold)
                        .foregroundColor(.primaryGreen)
                        .padding(.horizontal, DS.md).padding(.vertical, DS.xs)
                        .background(Color.primaryGreen.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            VStack(spacing: DS.md) {
                let p = auth.profile
                goalRow(icon: "flame.fill",
                        title: "Калории",
                        target: "\(p?.goalCalories ?? safeGoal("goalCalories", or: 2000)) ккал",
                        color: .cardioOrange)
                Divider().overlay(Color.surfaceBorder)
                goalRow(icon: "figure.strengthtraining.traditional",
                        title: "Тренировки",
                        target: "\(p?.goalWorkoutsPerWeek ?? 3) раз в неделю",
                        color: .strengthPurple)
                Divider().overlay(Color.surfaceBorder)
                goalRow(icon: "figure.run",
                        title: "Кардио",
                        target: String(format: "%.1f км в день", p?.goalCardioKmPerDay ?? 5.0),
                        color: .cardioOrange)
                Divider().overlay(Color.surfaceBorder)
                goalRow(icon: "figure.walk",
                        title: "Шаги",
                        target: "\(p?.goalSteps ?? 10000) шаг",
                        color: .primaryGreen)
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
    }

    private func goalRow(icon: String, title: String, target: String, color: Color) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .iconBadge(color: color, radius: DS.rSM, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(target).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        VStack(alignment: .leading, spacing: DS.md) {
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
                        .padding(.horizontal, DS.md).padding(.vertical, DS.xs)
                        .background(Color.primaryGreen.opacity(0.1),
                                    in: RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.md) {
                    ForEach(achievements) { badge in
                        achievementBadge(badge)
                    }
                }
                .padding(.vertical, DS.xs)
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
    }

    private func achievementBadge(_ a: Achievement) -> some View {
        VStack(spacing: DS.sm) {
            ZStack {
                if a.isUnlocked {
                    RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .fill(a.gradient).frame(width: 60, height: 60)
                    Image(systemName: a.icon).font(.system(size: 24)).foregroundColor(.white)
                } else {
                    RoundedRectangle(cornerRadius: DS.rMD, style: .continuous)
                        .fill(Color(.systemGray5)).frame(width: 60, height: 60)
                    Image(systemName: a.icon)
                        .font(.system(size: 24)).foregroundColor(.secondary.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5))
                        .offset(x: 18, y: 18)
                }
            }
            .shadow(color: a.isUnlocked ? a.color.opacity(0.35) : .clear, radius: 8, x: 0, y: 3)

            Text(a.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(a.isUnlocked ? .primary : .secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 64)
        }
    }

    // MARK: - Social Card

    private var socialCard: some View {
        listNavRow(
            icon: "person.2.fill",
            gradient: .strengthGradient,
            title: "Друзья",
            subtitle: "Добавляйте друзей и следите за прогрессом"
        ) { showFriends = true }
    }

    // MARK: - Body Card

    private var bodyCard: some View {
        listNavRow(
            icon: "scalemass.fill",
            gradient: .cardioGradient,
            title: "Вес тела",
            subtitle: WeightLogStore.shared.entries.last.map {
                "Последнее: \(String(format: "%.1f", $0.weight)) кг"
            } ?? "Ведите журнал веса с графиком"
        ) { showWeightLog = true }
    }

    // MARK: - Sync Card

    private var syncCard: some View {
        HStack(spacing: DS.md) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 17))
                .foregroundColor(.white)
                .rotationEffect(.degrees(isRotatingSync ? 360 : 0))
                .animation(syncService.isSyncing
                           ? .linear(duration: 0.9).repeatForever(autoreverses: false)
                           : .default, value: isRotatingSync)
                .gradientBadge(.primaryGradient, radius: DS.rMD, size: 44)

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
                        .padding(.horizontal, DS.md).padding(.vertical, DS.xs)
                        .background(LinearGradient.primaryGradient,
                                    in: RoundedRectangle(cornerRadius: DS.rSM, style: .continuous))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(DS.lg)
        .nrcCard(radius: DS.rLG)
        .onChange(of: syncService.isSyncing) { syncing in isRotatingSync = syncing }
    }

    // MARK: - Notifications Card

    private var notificationsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Уведомления", systemImage: "bell.fill")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
            }
            .padding(DS.lg)

            Divider().overlay(Color.surfaceBorder)

            toggleRow("Напоминания о тренировке",
                      icon: "dumbbell.fill", color: .strengthPurple,
                      value: $notifWorkout) { saveNotifications() }
            Divider().overlay(Color.surfaceBorder).padding(.horizontal, DS.lg)
            toggleRow("Напоминания о питании",
                      icon: "fork.knife", color: .nutritionPurple,
                      value: $notifNutrition) { saveNotifications() }
            Divider().overlay(Color.surfaceBorder).padding(.horizontal, DS.lg)
            toggleRow("Разблокировка достижений",
                      icon: "trophy.fill", color: .cardioOrange,
                      value: $notifAchievement) { saveNotifications() }
        }
        .nrcCard(radius: DS.rLG)
    }

    private func toggleRow(_ title: String, icon: String, color: Color,
                           value: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(color)
                .iconBadge(color: color, radius: DS.rSM, size: 32)
            Text(title).font(.subheadline)
            Spacer()
            Toggle("", isOn: value)
                .tint(.primaryGreen)
                .onChange(of: value.wrappedValue) { _ in onChange() }
        }
        .padding(.horizontal, DS.lg).padding(.vertical, DS.md)
    }

    // MARK: - Account Card

    private var accountCard: some View {
        Button(action: { showLogoutAlert = true }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.cardioRed).frame(width: 24)
                Text("Выйти из аккаунта")
                    .foregroundColor(.cardioRed)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(DS.lg)
            .nrcCard(radius: DS.rLG)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Reusable Nav Row

    private func listNavRow(icon: String, gradient: LinearGradient,
                            title: String, subtitle: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: DS.md) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .gradientBadge(gradient, radius: DS.rMD, size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.subheadline).fontWeight(.semibold)
                    Text(subtitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(DS.lg)
            .nrcCard(radius: DS.rLG)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Actions

    private func loadState() {
        withAnimation { statsAppeared = true }
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
        notifManager.applyPreferences(
            workout:     notifWorkout,
            nutrition:   notifNutrition,
            achievement: notifAchievement
        )
    }

    private func safeGoal(_ key: String, or fallback: Int) -> Int {
        let v = UserDefaults.standard.integer(forKey: key)
        return v == 0 ? fallback : v
    }
}
