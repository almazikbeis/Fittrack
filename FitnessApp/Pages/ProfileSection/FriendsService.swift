//
//  FriendsService.swift
//  FitnessApp
//
//  Supabase backend for friends/social features.
//
//  ── SQL to run in Supabase → SQL Editor ──────────────────────────────
//
//  CREATE TABLE IF NOT EXISTS friends (
//    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//    user_id    UUID REFERENCES auth.users(id) ON DELETE CASCADE,
//    friend_id  UUID REFERENCES auth.users(id) ON DELETE CASCADE,
//    status     TEXT NOT NULL DEFAULT 'pending',   -- 'pending' | 'accepted'
//    created_at TIMESTAMPTZ DEFAULT now(),
//    UNIQUE(user_id, friend_id)
//  );
//
//  ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
//
//  CREATE POLICY "see own friends" ON friends FOR SELECT
//    USING (auth.uid() = user_id OR auth.uid() = friend_id);
//  CREATE POLICY "send requests" ON friends FOR INSERT
//    WITH CHECK (auth.uid() = user_id);
//  CREATE POLICY "accept requests" ON friends FOR UPDATE
//    USING (auth.uid() = friend_id);
//  CREATE POLICY "delete friends" ON friends FOR DELETE
//    USING (auth.uid() = user_id OR auth.uid() = friend_id);
//
//  ─────────────────────────────────────────────────────────────────────

import Foundation
import Supabase

// MARK: - DTOs

struct FriendRow: Codable, Identifiable {
    let id:        UUID
    let userId:    UUID
    let friendId:  UUID
    var status:    String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId    = "user_id"
        case friendId  = "friend_id"
        case status
        case createdAt = "created_at"
    }
}

struct PublicProfile: Codable, Identifiable {
    let id:     UUID
    let name:   String
    let age:    Int?
    let weight: Double?
    let height: Double?

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct FriendWithProfile: Identifiable {
    let id:         UUID
    let profile:    PublicProfile
    let status:     String
    let isIncoming: Bool

    var isAccepted: Bool { status == "accepted" }
    var isPending:  Bool { status == "pending" }
}

// MARK: - Service

@MainActor
final class FriendsService: ObservableObject {
    static let shared = FriendsService()

    @Published var friends:  [FriendWithProfile] = []
    @Published var isLoading = false
    @Published var error:    String?

    private init() {}

    // MARK: - Load friends

    func loadFriends(userId: String) async {
        isLoading = true
        error     = nil
        defer { isLoading = false }

        do {
            let rows: [FriendRow] = try await SupabaseManager.shared.client
                .from("friends")
                .select()
                .or("user_id.eq.\(userId),friend_id.eq.\(userId)")
                .execute()
                .value

            var result: [FriendWithProfile] = []
            for row in rows {
                let otherId = row.userId.uuidString == userId ? row.friendId : row.userId
                let isIncoming = row.friendId.uuidString == userId && row.status == "pending"

                if let profile = await fetchProfile(id: otherId.uuidString) {
                    result.append(FriendWithProfile(
                        id:         row.id,
                        profile:    profile,
                        status:     row.status,
                        isIncoming: isIncoming
                    ))
                }
            }
            friends = result
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Search users

    func searchUsers(query: String, currentUserId: String) async -> [PublicProfile] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }

        do {
            let profiles: [PublicProfile] = try await SupabaseManager.shared.client
                .from("profiles")
                .select("id, name, age, weight, height")
                .ilike("name", pattern: "%\(query)%")
                .neq("id", value: currentUserId)
                .limit(20)
                .execute()
                .value
            return profiles
        } catch {
            return []
        }
    }

    // MARK: - Send friend request

    func sendRequest(from userId: String, to friendId: String) async -> Bool {
        let row: [String: String] = ["user_id": userId, "friend_id": friendId, "status": "pending"]
        do {
            try await SupabaseManager.shared.client
                .from("friends")
                .upsert(row)
                .execute()
            await loadFriends(userId: userId)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    // MARK: - Accept request

    func acceptRequest(friendRowId: UUID, userId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("friends")
                .update(["status": "accepted"])
                .eq("id", value: friendRowId.uuidString)
                .execute()
            await loadFriends(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Remove friend / cancel request

    func removeFriend(friendRowId: UUID, userId: String) async {
        do {
            try await SupabaseManager.shared.client
                .from("friends")
                .delete()
                .eq("id", value: friendRowId.uuidString)
                .execute()
            await loadFriends(userId: userId)
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func fetchProfile(id: String) async -> PublicProfile? {
        try? await SupabaseManager.shared.client
            .from("profiles")
            .select("id, name, age, weight, height")
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    var acceptedFriends: [FriendWithProfile] { friends.filter { $0.isAccepted } }
    var pendingIncoming: [FriendWithProfile] { friends.filter { $0.isPending && $0.isIncoming } }
    var pendingOutgoing: [FriendWithProfile] { friends.filter { $0.isPending && !$0.isIncoming } }
}
