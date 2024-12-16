//
//  MonthCalendarView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//


import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    var body: some View {
        let daysInMonth = generateDaysInMonth()

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
            ForEach(daysInMonth, id: \.self) { day in
                Text(dayFormatter.string(from: day))
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(calendar.isDate(selectedDate, inSameDayAs: day) ? Color.green : Color.clear)
                    .foregroundColor(calendar.isDate(selectedDate, inSameDayAs: day) ? .white : .black)
                    .clipShape(Circle())
                    .onTapGesture {
                        selectedDate = day
                    }
            }
        }
        .padding()
    }

    private func generateDaysInMonth() -> [Date] {
        let today = Date()
        let range = calendar.range(of: .day, in: .month, for: today)!
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!

        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: startOfMonth) }
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // День месяца
        return formatter
    }
}
