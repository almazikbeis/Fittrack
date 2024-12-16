//
//  ContentView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Тренировки")
                }
            TrackingView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Трекинг")
                }
            AnalyticsView()
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Аналитика")
                }
            ProfileView()
                .tabItem {
                    Image(systemName: "person")
                    Text("Профиль")
                }
        }


    }
}
