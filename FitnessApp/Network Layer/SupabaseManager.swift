//
//  SupabaseManager.swift
//  FitnessApp
//
//  Singleton wrapper around Supabase Swift SDK v2.
//  All other files use this instead of importing Supabase directly.
//

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: AppSecrets.supabaseURL)!,
            supabaseKey: AppSecrets.supabaseAnonKey
        )
    }

    var auth: AuthClient { client.auth }
}
