//
//  NotificationManager.swift
//  FitnessApp
//

import UserNotifications
import Foundation

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {}

    // MARK: - Permission

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted { applyStoredPreferences() }
        } catch {
            isAuthorized = false
        }
    }

    func checkPermission() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Workout Reminder

    func scheduleWorkoutReminder(enabled: Bool, hour: Int = 10, minute: Int = 0) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["workout_reminder"])
        guard enabled, isAuthorized else { return }

        let content        = UNMutableNotificationContent()
        content.title      = "Время тренироваться! 💪"
        content.body       = "Не забудьте про тренировку сегодня. Ты уже близко к цели!"
        content.sound      = .default
        content.categoryIdentifier = "WORKOUT"

        var c = DateComponents()
        c.hour   = hour
        c.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
        let request = UNNotificationRequest(identifier: "workout_reminder",
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Nutrition Reminders

    func scheduleNutritionReminders(enabled: Bool) {
        let ids = ["nutrition_lunch", "nutrition_dinner"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled, isAuthorized else { return }

        let schedule: [(String, Int, Int, String, String)] = [
            ("nutrition_lunch",  13, 0,
             "🍽 Обед не за горами!",     "Самое время добавить приём пищи в дневник."),
            ("nutrition_dinner", 19, 0,
             "🌙 Время ужина!",            "Зафиксируйте ужин и закройте день по питанию.")
        ]

        for (id, hour, minute, title, body) in schedule {
            let content   = UNMutableNotificationContent()
            content.title = title
            content.body  = body
            content.sound = .default

            var c = DateComponents()
            c.hour = hour; c.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            )
        }
    }

    // MARK: - Water Reminders (every 2 h, 08:00–20:00)

    func scheduleWaterReminders(enabled: Bool) {
        let ids = stride(from: 8, through: 20, by: 2).map { "water_\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        guard enabled, isAuthorized else { return }

        for hour in stride(from: 8, through: 20, by: 2) {
            let content   = UNMutableNotificationContent()
            content.title = "💧 Выпейте воды"
            content.body  = "Не забывайте про водный баланс — \(hour):00 самое время!"
            content.sound = .default

            var c = DateComponents()
            c.hour = hour; c.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: c, repeats: true)
            UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: "water_\(hour)", content: content, trigger: trigger)
            )
        }
    }

    // MARK: - Achievement Notification (immediate)

    func notifyAchievement(title: String, description: String, enabled: Bool) {
        guard enabled, isAuthorized else { return }

        let content        = UNMutableNotificationContent()
        content.title      = "🏆 Достижение разблокировано!"
        content.body       = "\"\(title)\" — \(description)"
        content.sound      = .default
        content.badge      = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id      = "achievement_\(UUID().uuidString)"
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        )
    }

    // MARK: - Apply preferences

    func applyPreferences(workout: Bool, nutrition: Bool, achievement: Bool) {
        UserDefaults.standard.set(workout,     forKey: "notifWorkout")
        UserDefaults.standard.set(nutrition,   forKey: "notifNutrition")
        UserDefaults.standard.set(achievement, forKey: "notifAchievement")

        scheduleWorkoutReminder(enabled: workout)
        scheduleNutritionReminders(enabled: nutrition)
    }

    private func applyStoredPreferences() {
        let workout   = UserDefaults.standard.bool(forKey: "notifWorkout")
        let nutrition = UserDefaults.standard.bool(forKey: "notifNutrition")
        scheduleWorkoutReminder(enabled: workout)
        scheduleNutritionReminders(enabled: nutrition)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
