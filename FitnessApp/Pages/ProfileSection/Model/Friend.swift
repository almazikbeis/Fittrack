//
//  Friend.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 17.12.2024.
//

import Foundation
struct Friend: Identifiable {
    let id: UUID
    let name: String
    let avatarURL: URL?
    let isOnline: Bool
}
