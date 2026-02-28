//
//  ContentView.swift
//  FitnessApp
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab      = 0
    @State private var showQuickStart   = false
    @State private var showActiveWorkout = false
    @State private var activeWorkoutType = "Силовая"
    @State private var showTracking     = false

    // Animated tab switch
    @State private var tabTransitionID  = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // ─── Tab pages (all live in memory) ───
            Group {
                HomeView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)

                WorkoutsView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)

                NutritionView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)

                ProfileView()
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.managedObjectContext, viewContext)

            // ─── Custom tab bar ───
            CustomTabBar(
                selectedTab: $selectedTab,
                onStartTapped: { showQuickStart = true }
            )
        }
        .ignoresSafeArea(edges: .bottom)
        // Quick-start half-sheet
        .sheet(isPresented: $showQuickStart) {
            QuickStartView(
                selectedTab:      $selectedTab,
                showActiveWorkout: $showActiveWorkout,
                activeWorkoutType: $activeWorkoutType,
                showTracking:      $showTracking
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        // Active workout (strength / cardio)
        .fullScreenCover(isPresented: $showActiveWorkout) {
            ActiveWorkoutView(workoutType: activeWorkoutType)
                .environment(\.managedObjectContext, viewContext)
        }
        // GPS run tracking
        .fullScreenCover(isPresented: $showTracking) {
            TrackingView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var onStartTapped: () -> Void

    private let leftTabs  = [(icon: "house.fill",    label: "Главная",    idx: 0),
                             (icon: "dumbbell.fill",  label: "Тренировки", idx: 1)]
    private let rightTabs = [(icon: "fork.knife",     label: "Питание",    idx: 2),
                             (icon: "person.fill",    label: "Профиль",    idx: 3)]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Pill bar
            HStack(spacing: 0) {
                ForEach(leftTabs, id: \.idx) { tab in
                    tabItem(icon: tab.icon, label: tab.label, index: tab.idx)
                }
                Spacer().frame(width: 76)
                ForEach(rightTabs, id: \.idx) { tab in
                    tabItem(icon: tab.icon, label: tab.label, index: tab.idx)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .padding(.bottom, 4)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.18), radius: 24, x: 0, y: 8)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 26)

            // Centre START button
            Button(action: onStartTapped) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.primaryGreen.opacity(0.5), radius: 16, x: 0, y: 6)
                    Image(systemName: "plus")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.bottom, 34)
        }
    }

    @ViewBuilder
    private func tabItem(icon: String, label: String, index: Int) -> some View {
        let selected = selectedTab == index
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .scaleEffect(selected ? 1.1 : 1.0)
                if selected {
                    Text(label)
                        .font(.system(size: 10, weight: .semibold))
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .foregroundColor(selected ? .primaryGreen : Color(.systemGray3))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
    }
}
