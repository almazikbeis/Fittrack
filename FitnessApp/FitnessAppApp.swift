//
//  FitnessAppApp.swift
//  FitnessApp
//

import SwiftUI

@main
struct FitnessAppApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var syncService   = SyncService.shared

    var body: some Scene {
        WindowGroup {
            rootView
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authViewModel)
                .environmentObject(syncService)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch authViewModel.authState {
        case .loading:
            splashView

        case .unauthenticated:
            AuthView()
                .transition(.opacity)

        case .onboarding:
            OnboardingView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .opacity
                ))

        case .authenticated:
            ContentView()
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal:   .opacity
                ))
        }
    }

    private var splashView: some View {
        ZStack {
            LinearGradient.heroGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bolt.heart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                Text("FitTrack")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white.opacity(0.7)))
                    .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }
}
