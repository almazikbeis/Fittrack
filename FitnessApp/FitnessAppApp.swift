//
//  FitnessAppApp.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//

import SwiftUI

@main
struct FitnessAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
