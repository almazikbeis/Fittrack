//
//  AnimatedCalendarView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//


import SwiftUI

struct AnimatedCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var isExpanded: Bool

    private let calendar = Calendar.current
    private var currentWeek: [Date] {
        let today = Date()
        let weekStart = calendar.dateInterval(of: .weekOfMonth, for: today)?.start ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Календарь")
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Text(isExpanded ? "Свернуть" : "Развернуть")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }

            if isExpanded {
                MonthCalendarView(selectedDate: $selectedDate)
                    .transition(.slide)
                    .animation(.easeInOut, value: isExpanded)
            } else {
                WeekCalendarView(selectedDate: $selectedDate)
                    .transition(.opacity)
                    .animation(.easeInOut, value: isExpanded)
            }
        }
    }
}
