//
//  WeekCalendarView.swift
//  FitnessApp
//
//  Created by Almaz Beisenov on 15.12.2024.
//

import SwiftUI

struct WeekCalendarView: View {
    @Binding var selectedDate: Date
    private let calendar = Calendar.current

    @State private var currentWeekStart: Date = Date()

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation {
                        moveWeek(by: -1)
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.green)
                }

                Spacer()

                Text(weekDateRange())
                    .font(.headline)
                    .foregroundColor(.green)

                Spacer()

                Button(action: {
                    withAnimation {
                        moveWeek(by: 1)
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.green)
                }
            }

            HStack(spacing: 10) {
                ForEach(weekDays(), id: \.self) { day in
                    VStack {
                        Text(dayFormatter.string(from: day))
                            .font(.subheadline)
                            .foregroundColor(calendar.isDate(day, inSameDayAs: selectedDate) ? .white : .gray)
                        Text(dateFormatter.string(from: day))
                            .font(.headline)
                            .foregroundColor(calendar.isDate(day, inSameDayAs: selectedDate) ? .white : .black)
                            .padding(8)
                            .background(calendar.isDate(day, inSameDayAs: selectedDate) ? Color.green : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedDate = day
                            }
                    }
                }
            }
        }
    }

    private func moveWeek(by offset: Int) {
        guard let newWeekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else { return }
        currentWeekStart = newWeekStart
    }

    private func weekDays() -> [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: currentWeekStart) }
    }

    private func weekDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: currentWeekStart)!
        return "\(formatter.string(from: currentWeekStart)) - \(formatter.string(from: endOfWeek))"
    }

    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Например: Пн, Вт
        return formatter
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d" // День месяца
        return formatter
    }
}
