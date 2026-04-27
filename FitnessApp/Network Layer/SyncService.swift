//
//  SyncService.swift
//  FitnessApp
//
//  Offline-first sync engine: uploads local CoreData → Supabase.
//  CoreData is source of truth; Supabase is the cloud backup.
//
//  v2: resilience (NWPathMonitor + retry), Supabase Storage photo backup.
//

import Foundation
import CoreData
import Network
import Supabase

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()

    @Published var isSyncing:    Bool    = false
    @Published var lastSyncDate: Date?
    @Published var syncError:    String?
    @Published var pendingCount: Int     = 0
    @Published var isOnline:     Bool    = true

    private var viewContext: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    private let monitor = NWPathMonitor()
    private let monitorQ = DispatchQueue(label: "SyncMonitor", qos: .background)
    private var pendingUserId: String?

    private init() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
        pendingCount = UserDefaults.standard.integer(forKey: "pendingSyncCount")
        setupNetworkMonitor()
    }

    // MARK: - Network Monitor

    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                let online = path.status == .satisfied
                self?.isOnline = online
                if online, let uid = self?.pendingUserId {
                    Task { await self?.syncAll(userId: uid) }
                }
            }
        }
        monitor.start(queue: monitorQ)
    }

    // MARK: - Entry point

    func syncAll(userId: String) async {
        guard !isSyncing else { return }

        pendingUserId = userId

        guard isOnline else {
            syncError = "Нет соединения. Данные синхронизируются автоматически."
            pendingCount += 1
            UserDefaults.standard.set(pendingCount, forKey: "pendingSyncCount")
            return
        }

        isSyncing  = true
        syncError  = nil

        var errors: [String] = []

        let workoutError = await uploadWorkoutsWithRetry(userId: userId)
        let foodError    = await uploadFoodEntriesWithRetry(userId: userId)
        let photoError   = await uploadPhotosWithRetry(userId: userId)

        for e in [workoutError, foodError, photoError].compactMap({ $0 }) {
            errors.append(e)
        }

        if errors.isEmpty {
            lastSyncDate = Date()
            pendingCount = 0
            UserDefaults.standard.set(lastSyncDate,   forKey: "lastSyncDate")
            UserDefaults.standard.set(pendingCount,    forKey: "pendingSyncCount")
            pendingUserId = nil
            await updateLastSynced(userId: userId)
        } else {
            syncError = errors.first
        }

        isSyncing = false
    }

    // MARK: - Retry wrapper

    private func withRetry<T>(attempts: Int = 3,
                               delay: TimeInterval = 2,
                               label: String,
                               operation: () async throws -> T) async throws -> T {
        var lastError: Error?
        for attempt in 1...attempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < attempts {
                    try? await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        throw lastError!
    }

    // MARK: - Workouts

    private func uploadWorkoutsWithRetry(userId: String) async -> String? {
        do {
            try await withRetry(label: "workouts") {
                try await self.uploadWorkouts(userId: userId)
            }
            return nil
        } catch {
            return "Тренировки: \(error.localizedDescription)"
        }
    }

    private func uploadWorkouts(userId: String) async throws {
        let request = NSFetchRequest<Workout>(entityName: "Workout")
        guard let workouts = try? viewContext.fetch(request), !workouts.isEmpty else { return }

        let dtos = workouts.map { WorkoutDTO.from($0, userId: userId) }
        try await SupabaseManager.shared.client
            .from("workouts")
            .upsert(dtos, onConflict: "local_id")
            .execute()
    }

    // MARK: - Food Entries

    private func uploadFoodEntriesWithRetry(userId: String) async -> String? {
        do {
            try await withRetry(label: "food_entries") {
                try await self.uploadFoodEntries(userId: userId)
            }
            return nil
        } catch {
            return "Питание: \(error.localizedDescription)"
        }
    }

    private func uploadFoodEntries(userId: String) async throws {
        let request = NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
        guard let entries = try? viewContext.fetch(request), !entries.isEmpty else { return }

        let dtos = entries.map { FoodEntryDTO.from($0, userId: userId) }
        try await SupabaseManager.shared.client
            .from("food_entries")
            .upsert(dtos, onConflict: "local_id")
            .execute()
    }

    // MARK: - Photo Backup (Supabase Storage)
    //
    // Bucket: food-photos (set to public in Supabase → Storage → Policies)
    // Path:   {userId}/{photoName}.jpg

    private func uploadPhotosWithRetry(userId: String) async -> String? {
        do {
            try await withRetry(label: "photos") {
                try await self.uploadPendingPhotos(userId: userId)
            }
            return nil
        } catch {
            return "Фото: \(error.localizedDescription)"
        }
    }

    private func uploadPendingPhotos(userId: String) async throws {
        let request = NSFetchRequest<FoodEntry>(entityName: "FoodEntry")
        request.predicate = NSPredicate(format: "photoPath != nil")
        guard let entries = try? viewContext.fetch(request) else { return }

        let uploaded = UserDefaults.standard.stringArray(forKey: "uploadedPhotoNames") ?? []

        for entry in entries {
            guard let name = entry.photoPath, !uploaded.contains(name) else { continue }

            let localURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("\(name).jpg")

            guard let data = try? Data(contentsOf: localURL), !data.isEmpty else { continue }

            let remotePath = "\(userId)/\(name).jpg"

            _ = try await SupabaseManager.shared.client.storage
                .from("food-photos")
                .upload(
                    remotePath,
                    data: data,
                    options: FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: true)
                )

            var updated = uploaded
            updated.append(name)
            UserDefaults.standard.set(updated, forKey: "uploadedPhotoNames")
        }
    }

    func remotePhotoURL(userId: String, photoName: String) -> URL? {
        URL(string: "\(AppSecrets.supabaseURL)/storage/v1/object/public/food-photos/\(userId)/\(photoName).jpg")
    }

    // MARK: - Profile last_synced_at

    private func updateLastSynced(userId: String) async {
        let patch: [String: String] = ["last_synced_at": ISO8601DateFormatter().string(from: Date())]
        try? await SupabaseManager.shared.client
            .from("profiles")
            .update(patch)
            .eq("id", value: userId)
            .execute()
    }

    // MARK: - Status helpers

    var syncStatusText: String {
        if isSyncing { return "Синхронизация..." }
        if !isOnline { return "Нет соединения\(pendingCount > 0 ? " · \(pendingCount) в очереди" : "")" }
        guard let date = lastSyncDate else { return "Не синхронизировано" }

        let diff = Date().timeIntervalSince(date)
        if diff < 60    { return "Только что" }
        if diff < 3600  { return "Синхр. \(Int(diff/60)) мин назад" }
        if diff < 86400 { return "Синхр. \(Int(diff/3600)) ч назад" }

        let f = DateFormatter()
        f.dateFormat = "d MMMM"; f.locale = Locale(identifier: "ru_RU")
        return "Синхр. \(f.string(from: date))"
    }
}
