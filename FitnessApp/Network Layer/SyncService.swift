//
//  SyncService.swift
//  FitnessApp
//
//  Offline-first sync engine: uploads local CoreData → Supabase.
//  CoreData is source of truth; Supabase is the cloud backup.
//

import Foundation
import CoreData
import Supabase

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing:    Bool    = false
    @Published var lastSyncDate: Date?
    @Published var syncError:    String?

    private var viewContext: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    private init() {
        // Load last sync date from UserDefaults
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    // ── Entry point ────────────────────────────────────────────────

    func syncAll(userId: String) async {
        guard !isSyncing else { return }
        isSyncing = true
        syncError = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.uploadWorkouts(userId: userId) }
            group.addTask { await self.uploadFoodEntries(userId: userId) }
        }

        lastSyncDate = Date()
        UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")
        await updateLastSynced(userId: userId)
        isSyncing = false
    }

    // ── Workouts ───────────────────────────────────────────────────

    private func uploadWorkouts(userId: String) async {
        let request = NSFetchRequest<Workout>(entityName: "Workout")
        guard let workouts = try? viewContext.fetch(request), !workouts.isEmpty else { return }

        let dtos = workouts.map { WorkoutDTO.from($0, userId: userId) }
        do {
            try await SupabaseManager.shared.client
                .from("workouts")
                .upsert(dtos, onConflict: "local_id")
                .execute()
        } catch {
            syncError = "Ошибка загрузки тренировок: \(error.localizedDescription)"
        }
    }

    // ── Food Entries ───────────────────────────────────────────────

    private func uploadFoodEntries(userId: String) async {
        let request = NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
        guard let entries = try? viewContext.fetch(request), !entries.isEmpty else { return }

        let dtos = entries.map { FoodEntryDTO.from($0, userId: userId) }
        do {
            try await SupabaseManager.shared.client
                .from("food_entries")
                .upsert(dtos, onConflict: "local_id")
                .execute()
        } catch {
            syncError = "Ошибка загрузки питания: \(error.localizedDescription)"
        }
    }

    // ── Update last_synced_at in profiles ─────────────────────────

    private func updateLastSynced(userId: String) async {
        let patch: [String: String] = ["last_synced_at": ISO8601DateFormatter().string(from: Date())]
        try? await SupabaseManager.shared.client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId)
            .execute()
    }

    // ── Sync status display helpers ────────────────────────────────

    var syncStatusText: String {
        if isSyncing { return "Синхронизация..." }
        guard let date = lastSyncDate else { return "Не синхронизировано" }

        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Только что" }
        if diff < 3600 { return "Синхр. \(Int(diff/60)) мин назад" }
        if diff < 86400 { return "Синхр. \(Int(diff/3600)) ч назад" }

        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "ru_RU")
        return "Синхр. \(f.string(from: date))"
    }
}
