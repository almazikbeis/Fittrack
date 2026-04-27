//
//  ContentView.swift
//  FitnessApp
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                HomeView()
                    .tabPageStyle(isVisible: selectedTab == 0, index: 0, selected: selectedTab)
                WorkoutsView()
                    .tabPageStyle(isVisible: selectedTab == 1, index: 1, selected: selectedTab)
                TrackingView()
                    .tabPageStyle(isVisible: selectedTab == 2, index: 2, selected: selectedTab)
                NutritionView()
                    .tabPageStyle(isVisible: selectedTab == 3, index: 3, selected: selectedTab)
                ProfileView()
                    .tabPageStyle(isVisible: selectedTab == 4, index: 4, selected: selectedTab)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .environment(\.managedObjectContext, viewContext)

            PrimeTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Prime Tab Bar

struct PrimeTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var ns
    @State private var bounceTab: Int = -1

    private struct TabItem {
        let icon: String
        let label: String
        let idx: Int
    }

    private let tabs: [TabItem] = [
        TabItem(icon: "house.fill",    label: "Главная",    idx: 0),
        TabItem(icon: "dumbbell.fill", label: "Тренировки", idx: 1),
        TabItem(icon: "figure.run",    label: "Бег",        idx: 2),
        TabItem(icon: "fork.knife",    label: "Питание",    idx: 3),
        TabItem(icon: "person.fill",   label: "Профиль",    idx: 4),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            barBackground
            HStack(spacing: 0) {
                ForEach(tabs, id: \.idx) { tab in
                    regularTab(tab)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, bottomPadding)
        }
    }

    private var barBackground: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.regularMaterial)
                Rectangle()
                    .fill(Color(.separator).opacity(0.3))
                    .frame(height: 0.5)
            }
            .frame(height: barHeight + bottomPadding)
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -2)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func regularTab(_ tab: TabItem) -> some View {
        let selected = selectedTab == tab.idx
        return Button {
            guard selectedTab != tab.idx else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                selectedTab = tab.idx
            }
            bounceTab = tab.idx
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.primaryGreen.opacity(0.12))
                            .frame(width: 44, height: 30)
                            .matchedGeometryEffect(id: "TAB_PILL", in: ns)
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 19, weight: selected ? .semibold : .regular))
                        .foregroundColor(selected ? .primaryGreen : Color(.tertiaryLabel))
                        .scaleEffect(selected ? 1.06 : 1.0)
                        .symbolEffect(.bounce.up.byLayer, value: bounceTab == tab.idx)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.68), value: selected)
                .frame(height: 30)

                Text(tab.label)
                    .font(.system(size: 9, weight: selected ? .bold : .medium))
                    .foregroundColor(selected ? .primaryGreen : Color(.tertiaryLabel))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private var barHeight: CGFloat { 60 }
    private var bottomPadding: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first
        return (window?.safeAreaInsets.bottom ?? 0) + 4
    }
}
